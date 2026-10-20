import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/nav_header.dart';
import '../models/grade_model.dart';
import '../providers/grades_provider.dart';

class GradesDetailScreen extends ConsumerStatefulWidget {
  const GradesDetailScreen({super.key});

  @override
  ConsumerState<GradesDetailScreen> createState() => _GradesDetailScreenState();
}

class _GradesDetailScreenState extends ConsumerState<GradesDetailScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedSemester = 'Tất cả';

  final List<String> _semesters = [
    'Tất cả',
    'HK1 (2026)',
    'HK2 (2025)',
    'HK1 (2025)',
    'HK2 (2024)',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradesState = ref.watch(gradesProvider);
    final allItems = gradesState.items;

    final query = _searchController.text.trim().toLowerCase();
    final filtered = allItems.where((item) {
      final matchSearch = query.isEmpty ||
          item.courseName.toLowerCase().contains(query) ||
          item.courseCode.toLowerCase().contains(query);
      final matchSemester =
          _selectedSemester == 'Tất cả' || item.semester == _selectedSemester;
      return matchSearch && matchSemester;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ─── 1. NAVHEADER (Deep Navy #132F73) ───
          NavHeader(
            title: 'Chi tiết bảng điểm',
            subtitle: 'Điểm quá trình, thực hành và học phần',
            showBack: true,
            onBack: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/grades');
              }
            },
          ),

          // ─── 2. SEARCH & SEMESTER FILTER (White Header Card) ───
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Column(
              children: [
                // Search Bar
                Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, size: 20, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            hintText: 'Tìm theo tên môn học...',
                            hintStyle: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: AppColors.textForeground,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          child: const Icon(Icons.cancel, size: 18, color: Color(0xFF94A3B8)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Semester Filter Tabs
                SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: (gradesState.availableSemesters.isNotEmpty ? gradesState.availableSemesters : _semesters).length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final sems = gradesState.availableSemesters.isNotEmpty ? gradesState.availableSemesters : _semesters;
                      final sem = sems[index];
                      final isSelected = sem == _selectedSemester;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedSemester = sem),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              sem,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? Colors.white : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),

                // Credit summary banner: Tích lũy vs Chưa học
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Đã tích lũy: ${gradesState.accumulatedCredits} TC',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF059669),
                        ),
                      ),
                      Text(
                        'Chưa học: ${gradesState.inProgressCredits} TC',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFD97706),
                        ),
                      ),
                      Text(
                        'Tổng: ${gradesState.summary.totalCredits} TC',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ─── 3. DETAILED GRADE CARDS LIST ───
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox_outlined, size: 48, color: Color(0xFFCBD5E1)),
                        SizedBox(height: 10),
                        Text(
                          'Không tìm thấy học phần',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textForeground),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Vui lòng thử từ khóa tìm kiếm hoặc học kỳ khác',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _buildDetailCard(item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(GradeItem item) {
    final badge = _getBadge(item.letter);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            offset: Offset(0, 3),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Credits + Tuition Fee Badge + Letter Grade Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (item.courseCode.isNotEmpty) ...[
                    Text(
                      item.courseCode,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('• ', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                  ],
                  Text(
                    '${item.credits} tín chỉ',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (item.hocPhi != null && item.hocPhi!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: item.hocPhi!.contains('Nợ')
                            ? const Color(0xFFFEF2F2)
                            : const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: item.hocPhi!.contains('Nợ')
                              ? const Color(0xFFFECACA)
                              : const Color(0xFFBBF7D0),
                        ),
                      ),
                      child: Text(
                        item.hocPhi!,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: item.hocPhi!.contains('Nợ')
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF16A34A),
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              // Status / Letter Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badge.bg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: badge.border, width: 1),
                ),
                child: Text(
                  badge.label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: badge.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Course Name
          Text(
            item.courseName,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textForeground,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),

          // 5-Column Score Breakdown Table (ĐBP | Thi1 | Thi2 | Đ1 | Đ2)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildScoreCol('ĐBP', item.dbp),
                _buildDivider(),
                _buildScoreCol('Thi 1', item.thi1),
                _buildDivider(),
                _buildScoreCol('Thi 2', item.thi2),
                _buildDivider(),
                _buildScoreCol('Đ 1', item.d1 ?? (item.scoreOverall > 0 ? item.scoreOverall : null), isFinal: true),
                _buildDivider(),
                _buildScoreCol('Đ 2', item.d2, isFinal: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCol(String label, double? score, {bool isFinal = false}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: isFinal ? AppColors.primary : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            score != null ? score.toStringAsFixed(score % 1 == 0 ? 0 : 1) : '—',
            style: TextStyle(
              fontSize: 13,
              fontWeight: isFinal ? FontWeight.w900 : FontWeight.w800,
              color: isFinal
                  ? (score != null ? AppColors.primary : const Color(0xFF64748B))
                  : AppColors.textForeground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 24,
      color: const Color(0xFFE2E8F0),
    );
  }

  _BadgeStyle _getBadge(String letter) {
    final upper = letter.toUpperCase().trim();
    if (upper == 'A') {
      return const _BadgeStyle(Color(0xFFECFDF5), Color(0xFF059669), Color(0xFFA7F3D0), 'A');
    }
    if (upper == 'B') {
      return const _BadgeStyle(Color(0xFFEFF6FF), Color(0xFF2563EB), Color(0xFFBFDBFE), 'B');
    }
    if (upper == 'C') {
      return const _BadgeStyle(Color(0xFFFFFBEB), Color(0xFFD97706), Color(0xFFFDE68A), 'C');
    }
    if (upper == 'D') {
      return const _BadgeStyle(Color(0xFFFEF3C7), Color(0xFFB45309), Color(0xFFFDE68A), 'D');
    }
    if (upper == 'P') {
      return const _BadgeStyle(Color(0xFFF0FDF4), Color(0xFF16A34A), Color(0xFFBBF7D0), 'Đạt');
    }
    if (upper == 'F') {
      return const _BadgeStyle(Color(0xFFFEF2F2), Color(0xFFDC2626), Color(0xFFFECACA), 'F');
    }
    return const _BadgeStyle(Color(0xFFFEF2F2), Color(0xFFEF4444), Color(0xFFFECACA), 'Đang học');
  }
}

class _BadgeStyle {
  final Color bg;
  final Color text;
  final Color border;
  final String label;

  const _BadgeStyle(this.bg, this.text, this.border, this.label);
}
