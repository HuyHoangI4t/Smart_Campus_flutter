const axios = require('axios');
const https = require('https');
const cheerio = require('cheerio');
const db = require('../config/db');

const httpsAgent = new https.Agent({ rejectUnauthorized: false });

const RSS_ANNOUNCEMENTS_URL = 'https://www.ttn.edu.vn/index.php/svthongbao?format=feed&type=rss';
const RSS_NEWS_URL = 'https://www.ttn.edu.vn/index.php/mthongbao/tintuc?format=feed&type=rss';
const RSS_TIMEOUT_MS = 8000; // [PERF] Giảm timeout từ 25s xuống 8s để fail-fast và fallback ngay lập tức

// In-memory RAM cache cho chi tiết bài viết (Hot Cache 0.05ms)
const articleDetailMemoryCache = new Map();
const DETAIL_CACHE_TTL_MS = 60 * 60 * 1000; // 1 giờ lưu RAM

function buildArticleDetailFromDbRow(articleUrl, row) {
  let attachments = [];
  if (row.attachments) {
    try {
      attachments = typeof row.attachments === 'string' ? JSON.parse(row.attachments) : row.attachments;
    } catch (_) {}
  }
  const rawParas = (row.content || '').split('\n\n').map(p => p.trim()).filter(p => p.length > 0);
  const paragraphs = rawParas.length > 0 ? rawParas : [(row.content || row.summary || '').trim()];
  const images = (row.image_url && row.image_url.startsWith('http')) ? [row.image_url] : [];
  const contentBlocks = [];
  if (images.length > 0) {
    contentBlocks.push({ type: 'image', url: images[0], caption: '' });
  }
  for (const p of paragraphs) {
    contentBlocks.push({ type: 'text', text: p });
  }
  return {
    url: articleUrl,
    images,
    paragraphs,
    contentBlocks,
    attachments,
    fullContent: (row.content || row.summary || '').trim(),
    isCached: true
  };
}

function formatRssDate(dateStr) {
  if (!dateStr) return 'Mới cập nhật';
  try {
    const d = new Date(dateStr);
    if (!isNaN(d.getTime())) {
      const day = String(d.getDate()).padStart(2, '0');
      const month = String(d.getMonth() + 1).padStart(2, '0');
      const year = d.getFullYear();
      return `${day}/${month}/${year}`;
    }
  } catch (e) {
    // ignore
  }
  return dateStr;
}

function normalizeTitle(title) {
  if (!title) return '';
  return title
    .toLowerCase()
    .replace(/[“"”'’`]/g, '')
    .replace(/\s+/g, ' ')
    .trim();
}

function normalizeUrl(url) {
  if (!url) return '';
  return url
    .toLowerCase()
    .replace(/^https?:\/\//, '')
    .replace(/\/+$/, '')
    .trim();
}

function parseArticleTimestamp(item) {
  if (!item) return 0;
  if (item.rawDate) {
    const t = new Date(item.rawDate).getTime();
    if (!isNaN(t) && t > 0) return t;
  }
  if (item.pubDate) {
    const t = new Date(item.pubDate).getTime();
    if (!isNaN(t) && t > 0) return t;
  }
  if (item.pub_date) {
    const t = new Date(item.pub_date).getTime();
    if (!isNaN(t) && t > 0) return t;
  }
  if (item.date && typeof item.date === 'string') {
    const dmy = item.date.match(/^(\d{1,2})\/(\d{1,2})\/(\d{4})/);
    if (dmy) {
      return new Date(parseInt(dmy[3], 10), parseInt(dmy[2], 10) - 1, parseInt(dmy[1], 10)).getTime();
    }
    const t = new Date(item.date).getTime();
    if (!isNaN(t) && t > 0) return t;
  }
  return 0;
}

function sortByNewestDate(items) {
  if (!Array.isArray(items)) return [];
  return [...items].sort((a, b) => {
    const tA = parseArticleTimestamp(a);
    const tB = parseArticleTimestamp(b);
    return tB - tA;
  });
}

function deduplicateArticles(items) {
  const seenTitles = new Set();
  const seenUrls = new Set();
  const uniqueItems = [];

  for (const item of items) {
    if (!item) continue;
    const normTitle = normalizeTitle(item.title);
    const normUrl = normalizeUrl(item.link);

    if (normTitle && seenTitles.has(normTitle)) continue;
    if (normUrl && seenUrls.has(normUrl)) continue;

    if (normTitle) seenTitles.add(normTitle);
    if (normUrl) seenUrls.add(normUrl);
    uniqueItems.push(item);
  }

  return uniqueItems;
}

// ─── 1. GENERIC RSS ARTICLE PARSER ──────────────────────────────────────────
async function _fetchRssArticles({
  url,
  defaultType,
  defaultSource,
  defaultSourceName,
  defaultBadge,
  defaultBadgeColor,
  defaultCategory,
  defaultSender,
  defaultFallbackLink,
  includeImage = false,
}) {
  const items = [];
  try {
    const res = await axios.get(url, {
      httpsAgent,
      timeout: RSS_TIMEOUT_MS,
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      },
    });

    const $ = cheerio.load(res.data, { xmlMode: true });

    $('item').each((idx, el) => {
      const title = $(el).find('title').text().trim();
      const link = $(el).find('link').text().trim();
      const pubDate = $(el).find('pubDate').text().trim();
      const authorRaw = $(el).find('author').text().trim();
      const category = $(el).find('category').text().trim() || defaultCategory;
      const descHtml = $(el).find('description').text().trim();

      let authorName = '';
      const authorMatch = authorRaw.match(/\(([^)]+)\)/);
      if (authorMatch) {
        authorName = authorMatch[1].trim();
      }

      const $desc = cheerio.load(descHtml);
      let img = $desc('img').attr('src') || '';
      if (img && !img.startsWith('http')) {
        img = `https://www.ttn.edu.vn${img.startsWith('/') ? '' : '/'}${img}`;
      }
      if (
        img &&
        (img.includes('slideshow') ||
          img.includes('slideshow2') ||
          img.includes('demo') ||
          img.includes('mod_languages') ||
          img.includes('Icon') ||
          img.includes('banner') ||
          img.includes('file_icons') ||
          img.endsWith('.gif'))
      ) {
        img = '';
      }
      $desc('img').remove();

      const attachments = [];
      $desc('a').each((i, aEl) => {
        const href = $desc(aEl).attr('href');
        const text = $desc(aEl).text().trim() || 'Tài liệu đính kèm';
        if (href) {
          let fullHref = href.startsWith('/') ? `https://www.ttn.edu.vn${href}` : href;
          let attTitle = text;
          if (text.toUpperCase() === 'TẠI ĐÂY') {
            attTitle = fullHref.toLowerCase().includes('.pdf')
              ? `Văn bản PDF đính kèm (${i + 1})`
              : `Liên kết chi tiết (${i + 1})`;
          }
          attachments.push({
            title: attTitle,
            url: fullHref,
            isPdf: /\.pdf$/i.test(fullHref),
          });
        }
      });

      $desc('br').replaceWith('\n');
      $desc('p').each((_, pEl) => { $desc(pEl).append('\n\n'); });
      $desc('div').each((_, dEl) => { $desc(dEl).append('\n'); });

      const cleanContent = $desc.text()
        .replace(/\r\n/g, '\n')
        .replace(/[ \t]+/g, ' ')
        .replace(/\n +/g, '\n')
        .replace(/\n{3,}/g, '\n\n')
        .trim();

      const firstParagraph = cleanContent.split('\n\n')[0] || cleanContent;
      const cleanSummary = firstParagraph.length > 200
        ? `${firstParagraph.slice(0, 197)}...`
        : firstParagraph;

      if (title) {
        items.push({
          id: `${defaultType === 'announcement' ? 'ann' : 'news'}-${idx + 1}`,
          guid: link || `${defaultType === 'announcement' ? 'ann' : 'news'}-${title.slice(0, 50)}`,
          type: defaultType,
          source: defaultSource,
          sourceName: defaultSourceName,
          badge: defaultBadge,
          badgeColor: defaultBadgeColor,
          title,
          summary: cleanSummary || title,
          content: cleanContent || title,
          date: formatRssDate(pubDate),
          rawDate: pubDate,
          imageUrl: includeImage ? (img || undefined) : undefined,
          link: link || defaultFallbackLink,
          sender: authorName || defaultSender,
          author: authorName || defaultSender,
          category,
          attachments,
        });
      }
    });
  } catch (error) {
    console.warn(`Lỗi lấy RSS ${defaultType}:`, error.message);
  }

  return deduplicateArticles(items);
}

// ─── 1. FETCH LIVE ANNOUNCEMENTS FROM RSS ─────────────────────────────────────
async function fetchAnnouncementsFromRss() {
  return _fetchRssArticles({
    url: RSS_ANNOUNCEMENTS_URL,
    defaultType: 'announcement',
    defaultSource: 'Website TTN.edu.vn',
    defaultSourceName: 'Cổng Thông báo sinh viên TTN',
    defaultBadge: 'Thông báo SV',
    defaultBadgeColor: '#0F172A',
    defaultCategory: 'Thông báo sinh viên',
    defaultSender: 'Phòng Công tác Sinh viên',
    defaultFallbackLink: 'https://www.ttn.edu.vn/index.php/svthongbao',
    includeImage: false,
  });
}

// ─── 2. FETCH LIVE NEWS FROM RSS ─────────────────────────────────────────────
async function fetchNewsFromRss() {
  const items = await _fetchRssArticles({
    url: RSS_NEWS_URL,
    defaultType: 'news',
    defaultSource: 'Website TTN.edu.vn',
    defaultSourceName: 'Cổng Tin tức TTN.edu.vn',
    defaultBadge: 'Tin hoạt động',
    defaultBadgeColor: '#2563EB',
    defaultCategory: 'Tin tức',
    defaultSender: 'Ban Biên tập TTN',
    defaultFallbackLink: 'https://www.ttn.edu.vn/index.php/mthongbao/tintuc',
    includeImage: true,
  });

  // [PERF] Tải ảnh chi tiết song song (tối đa 4 request cùng lúc) thay vì tuần tự chậm chạp
  const missingItems = items.filter(item => {
    const isMissingOrSample = !item.imageUrl ||
      item.imageUrl.includes('slideshow') ||
      item.imageUrl.includes('demo') ||
      item.imageUrl.includes('mod_languages');
    return isMissingOrSample && item.link && item.link.startsWith('http');
  });

  if (missingItems.length > 0) {
    const BATCH_SIZE = 4;
    for (let i = 0; i < missingItems.length; i += BATCH_SIZE) {
      const batch = missingItems.slice(i, i + BATCH_SIZE);
      await Promise.allSettled(
        batch.map(async (item) => {
          try {
            const detail = await fetchFullArticleDetail(item.link);
            if (detail && detail.images && detail.images.length > 0) {
              item.imageUrl = detail.images[0];
            }
          } catch (_) {}
        })
      );
    }
  }

  return deduplicateArticles(items);
}

// ─── 2.5 BẢO LƯU DỮ LIỆU ĐÃ ENRICH TỪ DB VÀO BẢN RSS MỚI ──────────────────────
async function preserveCachedFields(items) {
  if (!Array.isArray(items) || items.length === 0) return items;
  try {
    const guids = items.map(it => it.guid).filter(Boolean);
    const links = items.map(it => it.link).filter(Boolean);
    if (guids.length === 0 && links.length === 0) return items;

    // [PERF] Chỉ load các bản ghi có guid/link nằm trong danh sách cần kiểm tra
    // Tránh Full Table Scan bảng news_cache và không nạp toàn bộ LONGTEXT content vào RAM
    const [rows] = await db.query(
      'SELECT guid, link, image_url, content FROM news_cache WHERE guid IN (?) OR link IN (?)',
      [guids.length > 0 ? guids : ['__none__'], links.length > 0 ? links : ['__none__']]
    );
    if (!rows || rows.length === 0) return items;
    const dbMap = new Map();
    for (const r of rows) {
      if (r.guid) dbMap.set(r.guid, r);
      if (r.link) dbMap.set(r.link, r);
    }
    for (const item of items) {
      const existing = (item.guid && dbMap.get(item.guid)) || (item.link && dbMap.get(item.link));
      if (existing) {
        if ((!item.imageUrl || !item.imageUrl.startsWith('http')) && existing.image_url) {
          item.imageUrl = existing.image_url;
        }
        if (existing.content && existing.content.length > (item.content || '').length) {
          item.content = existing.content;
        }
      }
    }
  } catch (err) {
    // Không làm gián đoạn luồng chính
  }
  return items;
}

// ─── 3. LƯU BỘ ĐỆM VÀO MYSQL (news_cache) ───────────────────────────────────
async function saveItemsToDb(items) {
  if (!Array.isArray(items) || items.length === 0) return 0;
  const validItems = items.filter((it) => it && it.title);
  if (validItems.length === 0) return 0;

  let savedCount = 0;
  const CHUNK_SIZE = 10; // [PERF] Tăng kích thước lô từ 5 lên 10 để tăng tốc độ ghi I/O

  for (let i = 0; i < validItems.length; i += CHUNK_SIZE) {
    const chunk = validItems.slice(i, i + CHUNK_SIZE);
    const results = await Promise.allSettled(
      chunk.map(async (item) => {
        const guid = item.guid || item.link || item.title;
        const type = item.type || 'news';
        const attachmentsJson = JSON.stringify(item.attachments || []);

        await db.query(
          `INSERT INTO news_cache 
           (guid, type, title, summary, content, link, pub_date, raw_date, author, category, image_url, badge, badge_color, source_name, attachments) 
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
           ON DUPLICATE KEY UPDATE 
             title = VALUES(title),
             summary = VALUES(summary),
             content = IF(CHAR_LENGTH(VALUES(content)) > CHAR_LENGTH(news_cache.content), VALUES(content), news_cache.content),
             pub_date = VALUES(pub_date),
             raw_date = VALUES(raw_date),
             author = VALUES(author),
             category = VALUES(category),
             image_url = IF(VALUES(image_url) IS NOT NULL AND VALUES(image_url) != '' AND VALUES(image_url) NOT LIKE '%slideshow%', VALUES(image_url), news_cache.image_url),
             badge = VALUES(badge),
             badge_color = VALUES(badge_color),
             source_name = VALUES(source_name),
             attachments = IF(VALUES(attachments) != '[]' AND VALUES(attachments) IS NOT NULL, VALUES(attachments), news_cache.attachments),
             updated_at = NOW()`,
          [
            guid,
            type,
            item.title,
            item.summary || item.title,
            item.content || item.title,
            item.link || '',
            item.date || '',
            item.rawDate || '',
            item.author || item.sender || '',
            item.category || '',
            item.imageUrl || null,
            item.badge || (type === 'announcement' ? 'Thông báo SV' : 'Tin hoạt động'),
            item.badgeColor || (type === 'announcement' ? '#0F172A' : '#2563EB'),
            item.sourceName || 'Cổng thông tin TTN',
            attachmentsJson,
          ]
        );
      })
    );

    for (const r of results) {
      if (r.status === 'fulfilled') savedCount++;
      else console.warn('Lỗi lưu tin vào MySQL:', r.reason?.message);
    }
  }

  return savedCount;
}

// ─── 4. LẤY TỪ MYSQL (news_cache) KHI OFFLINE HOẶC RSS KHÔNG PHẢN HỒI ────────
async function getItemsFromDb(type, limit) {
  try {
    let sql = 'SELECT * FROM news_cache';
    const params = [];

    if (type && type !== 'all') {
      sql += ' WHERE type = ?';
      params.push(type);
    }

    sql += ' ORDER BY id DESC';

    if (limit) {
      sql += ' LIMIT ?';
      params.push(parseInt(limit, 10));
    }

    const [rows] = await db.query(sql, params);
    if (!rows || rows.length === 0) return [];

    return rows.map((r) => {
      let attachments = [];
      if (r.attachments) {
        try {
          attachments = typeof r.attachments === 'string' ? JSON.parse(r.attachments) : r.attachments;
        } catch (e) {
          attachments = [];
        }
      }

      return {
        id: `${r.type}-${r.id}`,
        guid: r.guid,
        type: r.type,
        source: 'Website TTN.edu.vn (Bản lưu DB)',
        sourceName: r.source_name || 'Cổng thông tin TTN',
        badge: r.badge || (r.type === 'announcement' ? 'Thông báo SV' : 'Tin hoạt động'),
        badgeColor: r.badge_color || (r.type === 'announcement' ? '#0F172A' : '#2563EB'),
        title: r.title,
        summary: r.summary || r.title,
        content: r.content || r.title,
        date: r.pub_date,
        rawDate: r.raw_date,
        imageUrl: (r.type === 'announcement' || (r.image_url && r.image_url.includes('slideshow'))) ? undefined : (r.image_url || undefined),
        link: r.link || 'https://www.ttn.edu.vn',
        sender: r.author || 'Đại học Tây Nguyên',
        author: r.author || 'Đại học Tây Nguyên',
        category: r.category || '',
        attachments: attachments,
        isDbCached: true
      };
    });
  } catch (err) {
    console.warn('Lỗi đọc news_cache từ MySQL:', err.message);
    return [];
  }
}

// ─── 5. MẪU DỰ PHÒNG CUỐI CÙNG (Đã xóa bỏ dữ liệu giả lập theo LTDDDNT) ──────
const FALLBACK_ANNOUNCEMENTS = [];

const FALLBACK_NEWS = [];

// ─── 6. HÀM CHÍNH: LẤY DỮ LIỆU TỪ WEB -> NẠP VÀO DB -> NẠP LÊN CACHE ─────────
let announcementsMemCache = null;
let announcementsCacheTime = 0;
let newsMemCache = null;
let newsCacheTime = 0;
const CACHE_TTL_MS = 5 * 60 * 1000; // 5 phút lưu RAM
let isSyncingAnnouncements = false;
let isSyncingNews = false;

async function _syncAnnouncementsInBackground() {
  if (isSyncingAnnouncements) return;
  isSyncingAnnouncements = true;
  try {
    const live = await fetchAnnouncementsFromRss();
    if (live && live.length > 0) {
      await preserveCachedFields(live);
      const enriched = await enrichItemsWithDetails(live);
      await saveItemsToDb(enriched);
      announcementsMemCache = sortByNewestDate(enriched);
      announcementsCacheTime = Date.now();
    }
  } catch (err) {
    // Chạy nền bỏ qua lỗi
  } finally {
    isSyncingAnnouncements = false;
  }
}

async function _syncNewsInBackground() {
  if (isSyncingNews) return;
  isSyncingNews = true;
  try {
    const live = await fetchNewsFromRss();
    if (live && live.length > 0) {
      await preserveCachedFields(live);
      // Nạp ngay ảnh gốc cho các tin tức mới nhất nếu RSS bị thiếu thẻ <img>
      for (let i = 0; i < Math.min(live.length, 5); i++) {
        const item = live[i];
        if ((!item.imageUrl || !item.imageUrl.startsWith('http')) && item.link) {
          try {
            const detail = await fetchFullArticleDetail(item.link);
            if (detail && detail.images && detail.images.length > 0) {
              item.imageUrl = detail.images[0];
            }
          } catch (_) {}
        }
      }
      await saveItemsToDb(live);
      newsMemCache = sortByNewestDate(live);
      newsCacheTime = Date.now();

      enrichItemsWithDetails(live)
        .then(async (enriched) => {
          await saveItemsToDb(enriched);
          newsMemCache = sortByNewestDate(enriched);
        })
        .catch(() => {});
    }
  } catch (err) {
    // Chạy nền bỏ qua lỗi
  } finally {
    isSyncingNews = false;
  }
}

async function getAnnouncementsWithFallback(forceRefresh = false) {
  const now = Date.now();

  // 1. Kiểm tra RAM cache nếu có và còn mới (< 5 phút) và không ép reload
  if (!forceRefresh && announcementsMemCache && (now - announcementsCacheTime < CACHE_TTL_MS)) {
    return sortByNewestDate(announcementsMemCache);
  }

  // 2. Lấy từ MySQL news_cache (tốc độ siêu tốc 1-2ms, tránh làm treo ứng dụng di động)
  const cached = await getItemsFromDb('announcement', 50);
  if (cached && cached.length > 0) {
    const sorted = sortByNewestDate(cached);
    announcementsMemCache = sorted;
    announcementsCacheTime = now;

    // Khi người dùng vuốt xuống (forceRefresh) hoặc dữ liệu cũ (> 10 phút):
    // Kích hoạt đồng bộ ngầm: Web trường -> Nạp vào DB -> Cập nhật Cache
    if (forceRefresh || (now - announcementsCacheTime > 10 * 60 * 1000)) {
      _syncAnnouncementsInBackground();
    }

    return sorted;
  }

  // 3. Nếu DB trống hoàn toàn: Bắt buộc cào trực tiếp từ Web trường -> Nạp DB -> Nạp Cache
  try {
    const live = await fetchAnnouncementsFromRss();
    if (live && live.length > 0) {
      await saveItemsToDb(live);
      enrichItemsWithDetails(live).then((enriched) => saveItemsToDb(enriched)).catch(() => {});
      const sorted = sortByNewestDate(live);
      announcementsMemCache = sorted;
      announcementsCacheTime = now;
      return sorted;
    }
  } catch (e) {
    console.warn('Lỗi cào Web Thông báo khi DB trống:', e.message);
  }

  return [];
}

async function getNewsWithFallback(forceRefresh = false) {
  const now = Date.now();

  // 1. Kiểm tra RAM cache nếu có và còn mới (< 5 phút) và không ép reload
  if (!forceRefresh && newsMemCache && (now - newsCacheTime < CACHE_TTL_MS)) {
    return sortByNewestDate(newsMemCache);
  }

  // 2. Lấy từ MySQL news_cache (tốc độ siêu tốc 1-2ms, tránh làm treo ứng dụng di động)
  const cached = await getItemsFromDb('news', 50);
  if (cached && cached.length > 0) {
    const sorted = sortByNewestDate(cached);
    newsMemCache = sorted;
    newsCacheTime = now;

    // Tự động kiểm tra và làm giàu ảnh bài viết nếu có tin tức thiếu ảnh
    const missingImg = sorted.filter(it => (!it.imageUrl || !it.imageUrl.startsWith('http')) && it.link && it.link.startsWith('http'));
    if (missingImg.length > 0) {
      Promise.allSettled(
        missingImg.slice(0, 5).map(async (item) => {
          try {
            const detail = await fetchFullArticleDetail(item.link);
            if (detail && detail.images && detail.images.length > 0) {
              item.imageUrl = detail.images[0];
              await saveArticleDetailToCache(item.link, detail);
            }
          } catch (_) {}
        })
      ).then(() => {
        if (newsMemCache) newsMemCache = sortByNewestDate(cached);
      }).catch(() => {});
    }

    // Khi người dùng vuốt xuống (forceRefresh) hoặc dữ liệu cũ (> 10 phút):
    // Kích hoạt đồng bộ ngầm: Web trường -> Nạp vào DB -> Cập nhật Cache
    if (forceRefresh || (now - newsCacheTime > 10 * 60 * 1000)) {
      _syncNewsInBackground();
    }

    return sorted;
  }

  // 3. Nếu DB trống hoàn toàn: Bắt buộc cào trực tiếp từ Web trường -> Nạp DB -> Nạp Cache
  try {
    const live = await fetchNewsFromRss();
    if (live && live.length > 0) {
      await preserveCachedFields(live);
      for (let i = 0; i < Math.min(live.length, 5); i++) {
        const item = live[i];
        if ((!item.imageUrl || !item.imageUrl.startsWith('http')) && item.link) {
          try {
            const detail = await fetchFullArticleDetail(item.link);
            if (detail && detail.images && detail.images.length > 0) {
              item.imageUrl = detail.images[0];
            }
          } catch (_) {}
        }
      }
      await saveItemsToDb(live);
      enrichItemsWithDetails(live)
        .then(async (enriched) => {
          await saveItemsToDb(enriched);
          newsMemCache = sortByNewestDate(enriched);
        })
        .catch(() => {});
      const sorted = sortByNewestDate(live);
      newsMemCache = sorted;
      newsCacheTime = now;
      return sorted;
    }
  } catch (e) {
    console.warn('Lỗi cào Web Tin tức khi DB trống:', e.message);
  }

  return [];
}

// ─── 7. CÀO TOÀN VĂN VÀ DANH SÁCH ẢNH GỐC TỪ TRANG BÀI VIẾT TTN ──────────────
async function fetchFullArticleDetail(articleUrl) {
  if (!articleUrl || !articleUrl.startsWith('http')) return null;

  // 1. Kiểm tra RAM Cache (0.05ms)
  const cachedEntry = articleDetailMemoryCache.get(articleUrl);
  if (cachedEntry && Date.now() - cachedEntry.time < DETAIL_CACHE_TTL_MS) {
    if (cachedEntry.data && Array.isArray(cachedEntry.data.contentBlocks) && cachedEntry.data.contentBlocks.length > 0) {
      return cachedEntry.data;
    }
  }

  // 2. Kiểm tra MySQL news_cache: CHỈ dùng khi đã lưu detail_json chứa đầy đủ toàn bộ ảnh và khối nội dung
  try {
    const [rows] = await db.query(
      'SELECT detail_json FROM news_cache WHERE (link = ? OR guid = ?) AND detail_json IS NOT NULL LIMIT 1',
      [articleUrl, articleUrl]
    );
    if (rows && rows.length > 0 && rows[0].detail_json) {
      const parsed = JSON.parse(rows[0].detail_json);
      if (parsed && Array.isArray(parsed.images) && Array.isArray(parsed.contentBlocks) && parsed.contentBlocks.length > 0) {
        articleDetailMemoryCache.set(articleUrl, { data: parsed, time: Date.now() });
        return parsed;
      }
    }
  } catch (err) {
    // Tiếp tục cào nếu lỗi query DB
  }

  try {
    const res = await axios.get(articleUrl, {
      httpsAgent,
      timeout: 8000,
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Referer': 'https://www.ttn.edu.vn/'
      }
    });

    const $ = cheerio.load(res.data);
    const container = $('.item-page').length ? $('.item-page') : $('article').length ? $('article') : $('.contentpaneopen');
    if (!container.length) return null;

    const contentBlocks = [];
    const images = [];
    const paragraphs = [];
    const attachments = [];
    const seenAttUrls = new Set();

    // 1. Trích xuất danh sách file đính kèm từ com_attachments (bảng tệp đính kèm)
    container.find('.attachmentsContainer tr, .attachmentsList tr').each((i, tr) => {
      const linkEl = $(tr).find('a.at_url').length ? $(tr).find('a.at_url') : $(tr).find('a');
      let href = linkEl.attr('href');
      let title = linkEl.text().trim();
      const sizeText = $(tr).find('.at_file_size').text().trim();
      if (href) {
        if (!href.startsWith('http')) {
          href = `https://www.ttn.edu.vn${href.startsWith('/') ? '' : '/'}${href}`;
        }
        if (!seenAttUrls.has(href)) {
          seenAttUrls.add(href);
          attachments.push({
            title: title || `Tập tin đính kèm (${attachments.length + 1})`,
            url: href,
            size: sizeText || undefined,
            isPdf: /\.pdf$/i.test(href) || href.toLowerCase().includes('.pdf')
          });
        }
      }
    });

    // 2. Trích xuất các liên kết tải file khác trong bài viết (PDF, DOCX...)
    container.find('a').each((i, aEl) => {
      let href = $(aEl).attr('href') || '';
      let text = $(aEl).text().trim() || 'Tài liệu đính kèm';
      if (
        href &&
        (/\.pdf$/i.test(href) || /\.docx?$/i.test(href) || /\.xlsx?$/i.test(href) || href.includes('attachments/article'))
      ) {
        if (!href.startsWith('http')) {
          href = `https://www.ttn.edu.vn${href.startsWith('/') ? '' : '/'}${href}`;
        }
        if (!seenAttUrls.has(href)) {
          seenAttUrls.add(href);
          attachments.push({
            title: text.length > 3 ? text : `Văn bản đính kèm (${attachments.length + 1})`,
            url: href,
            isPdf: /\.pdf$/i.test(href) || href.toLowerCase().includes('.pdf')
          });
        }
      }
    });

    // 2.5. Trích xuất toàn bộ ảnh thực tế từ bài viết (bỏ qua biểu tượng, cờ, banner, slideshow, file đính kèm)
    // Đảm bảo images[0] luôn là ẢNH ĐẦU TIÊN CỦA BÀI VIẾT theo đúng thứ tự xuất hiện trong trang
    container.find('img').each((j, imgEl) => {
      const $img = $(imgEl);
      if ($img.closest('.attachmentsContainer, .attachmentsList, .article-info, .page-header, .social2s_behavior, .s2s_options').length > 0) return;

      let src = $img.attr('src') || '';
      if (
        src &&
        !src.includes('mod_languages') &&
        !src.includes('Icon') &&
        !src.includes('cackhoa') &&
        !src.includes('slideshow') &&
        !src.includes('demo') &&
        !src.includes('banner') &&
        !src.includes('file_icons') &&
        !src.includes('com_attachments') &&
        !src.endsWith('.gif')
      ) {
        if (!src.startsWith('http')) {
          src = `https://www.ttn.edu.vn${src.startsWith('/') ? '' : '/'}${src}`;
        }
        if (!images.includes(src)) {
          images.push(src);
        }
      }
    });

    // 3. Duyệt qua tất cả các khối p, table, div trong container theo thứ tự xuất hiện
    container.find('p, table, div').each((i, el) => {
      const $el = $(el);
      // Bỏ qua các khối metadata bài viết và bảng file đính kèm
      if ($el.closest('.attachmentsContainer, .attachmentsList, .article-info, .page-header, .social2s_behavior, .s2s_options').length > 0) return;

      // Bỏ qua nếu là thẻ cha bọc các thẻ p, table, div khác để tránh lặp nội dung
      if ($el.children('p, table, div').length > 0) return;

      const imgs = $el.find('img');
      const text = $el.text().replace(/\s+/g, ' ').trim();

      if (imgs.length > 0) {
        imgs.each((j, imgEl) => {
          let src = $(imgEl).attr('src') || '';
          if (
            src &&
            !src.includes('mod_languages') &&
            !src.includes('Icon') &&
            !src.includes('cackhoa') &&
            !src.includes('slideshow') &&
            !src.includes('demo') &&
            !src.includes('banner') &&
            !src.includes('file_icons') &&
            !src.includes('com_attachments') &&
            !src.endsWith('.gif')
          ) {
            if (!src.startsWith('http')) {
              src = `https://www.ttn.edu.vn${src.startsWith('/') ? '' : '/'}${src}`;
            }
            if (!images.includes(src)) {
              images.push(src);
            }
            contentBlocks.push({
              type: 'image',
              url: src,
              caption: text || $(imgEl).attr('alt') || $(imgEl).attr('title') || ''
            });
          }
        });
      } else if (text && text.length > 3) {
        if (
          !text.toLowerCase().includes('joomla') &&
          !text.toLowerCase().includes('bản quyền') &&
          !text.toLowerCase().includes('cơ quan chủ quản') &&
          !text.toLowerCase().includes('s2sdefault') &&
          !text.toLowerCase().includes('có thông báo đính kèm')
        ) {
          paragraphs.push(text);
          // Nếu đoạn văn ngắn ngay sau ảnh thì gán làm chú thích của ảnh đó
          const lastBlock = contentBlocks[contentBlocks.length - 1];
          if (lastBlock && lastBlock.type === 'image') {
            if (!lastBlock.caption && text.length < 180) {
              lastBlock.caption = text;
              return;
            }
            if (lastBlock.caption && (text === lastBlock.caption || lastBlock.caption.includes(text) || text.includes(lastBlock.caption))) {
              return;
            }
          }
          contentBlocks.push({
            type: 'text',
            text: text
          });
        }
      }
    });

    // Đảm bảo TẤT CẢ các ảnh có trong mảng images đều xuất hiện trong contentBlocks
    const existingBlockUrls = new Set(contentBlocks.filter(b => b.type === 'image').map(b => b.url));
    for (const imgUrl of images) {
      if (!existingBlockUrls.has(imgUrl)) {
        existingBlockUrls.add(imgUrl);
        contentBlocks.push({
          type: 'image',
          url: imgUrl,
          caption: ''
        });
      }
    }

    const result = {
      url: articleUrl,
      images,
      paragraphs,
      contentBlocks,
      attachments,
      fullContent: paragraphs.join('\n\n')
    };

    // Lưu vào RAM cache (0.05ms) và MySQL news_cache (1ms)
    articleDetailMemoryCache.set(articleUrl, { data: result, time: Date.now() });
    saveArticleDetailToCache(articleUrl, result).catch(() => {});

    return result;
  } catch (err) {
    console.warn('Lỗi cào chi tiết bài viết:', err.message);
    // Khi rớt mạng hoàn toàn mới dùng phao cứu sinh từ news_cache
    try {
      const [rows] = await db.query(
        'SELECT content, summary, attachments, image_url, title FROM news_cache WHERE (link = ? OR guid = ?) LIMIT 1',
        [articleUrl, articleUrl]
      );
      if (rows && rows.length > 0 && rows[0].content) {
        return buildArticleDetailFromDbRow(articleUrl, rows[0]);
      }
    } catch (_) {}
    return null;
  }
}

// Lưu chi tiết bài viết đã cào thành công vào MySQL news_cache
async function saveArticleDetailToCache(url, detail) {
  if (!url || !detail) return;
  try {
    articleDetailMemoryCache.set(url, { data: detail, time: Date.now() });
    const fullContent = detail.fullContent || (detail.paragraphs ? detail.paragraphs.join('\n\n') : '');
    const attachments = detail.attachments || [];
    const firstImage = detail.images && detail.images.length > 0 ? detail.images[0] : null;

    const updates = [];
    const params = [];

    if (fullContent && fullContent.trim().length > 10) {
      updates.push('content = ?');
      params.push(fullContent.trim());
    }
    if (attachments.length > 0) {
      updates.push('attachments = ?');
      params.push(JSON.stringify(attachments));
    }
    if (firstImage) {
      updates.push('image_url = ?');
      params.push(firstImage);
    }
    if (detail) {
      updates.push('detail_json = ?');
      params.push(JSON.stringify(detail));
    }

    if (updates.length > 0) {
      const sql = `UPDATE news_cache SET ${updates.join(', ')} WHERE link = ? OR guid = ?`;
      params.push(url, url);
      await db.query(sql, params);
    }
  } catch (err) {
    console.warn('[Cache Update] Lỗi lưu cache chi tiết:', err.message);
  }
}

// Làm giàu dữ liệu chi tiết toàn văn, ảnh và tệp đính kèm cho danh sách bài viết
async function enrichItemsWithDetails(items) {
  if (!Array.isArray(items) || items.length === 0) return items;
  // Làm giàu tối đa 10 bài viết mới nhất để lấy đầy đủ tệp đính kèm và ảnh thực tế
  const targetItems = items.slice(0, 10);
  for (const it of targetItems) {
    if (it.link && it.link.startsWith('http')) {
      try {
        const detail = await fetchFullArticleDetail(it.link);
        if (detail) {
          if (detail.fullContent && detail.fullContent.trim().length > 10) {
            it.content = detail.fullContent.trim();
          }
          if (detail.attachments && detail.attachments.length > 0) {
            it.attachments = detail.attachments;
          }
          if (detail.images && detail.images.length > 0) {
            it.imageUrl = detail.images[0];
          }
        }
      } catch (_) {}
    }
  }
  return items;
}

module.exports = {
  fetchAnnouncementsFromRss,
  fetchNewsFromRss,
  saveItemsToDb,
  enrichItemsWithDetails,
  getItemsFromDb,
  getAnnouncementsWithFallback,
  getNewsWithFallback,
  fetchFullArticleDetail,
  saveArticleDetailToCache,
  preserveCachedFields,
  deduplicateArticles,
  formatRssDate,
  parseArticleTimestamp,
  sortByNewestDate,
};
