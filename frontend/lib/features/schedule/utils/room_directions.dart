import '../models/room_direction_model.dart';

/// Phân tích và tạo lộ trình hướng dẫn từng bước đến phòng học
/// (hoặc thông tin tham gia lớp trực tuyến)
/// Hỗ trợ các định dạng:
/// - Online: Google Meet, Zoom, MS Teams, Online, Trực tuyến
/// - Dạng 3 phần: 7.3.18 -> Nhà 7, Tầng 3, Phòng 18
/// - Dạng 2 phần: 6.12 -> Nhà 6, Phòng 12; 2.21 (CLC) -> Nhà 2, Phòng 21 (CLC)
/// - Các hội trường & khoa chuyên biệt: GĐ 400, GĐ 200, Thư viện, TT GDQP, Khoa Y Dược, v.v.
RoomDirectionInfo parseRoomDirections(String roomRaw, {String extraNote = ''}) {
  final room = roomRaw.trim();
  final upper = room.toUpperCase();
  final noteUpper = extraNote.toUpperCase();

  // 1. Kiểm tra lớp học trực tuyến / Online
  final isOnline = upper.contains('ONLINE') ||
      upper.contains('TRỰC TUYẾN') ||
      upper.contains('TRUC TUYEN') ||
      upper.contains('GOOGLE MEET') ||
      upper.contains('ZOOM') ||
      upper.contains('TEAMS') ||
      upper.startsWith('MEET') ||
      noteUpper.contains('ONLINE') ||
      noteUpper.contains('GOOGLE MEET') ||
      noteUpper.contains('ZOOM') ||
      noteUpper.contains('TEAMS') ||
      noteUpper.contains('PM:');

  if (isOnline) {
    final combined = '$room $extraNote'.trim();
    final meetMatch = RegExp(r'([a-z]{3}-[a-z]{4}-[a-z]{3})', caseSensitive: false).firstMatch(combined);
    String meetingCode = meetMatch != null ? meetMatch.group(1)!.toLowerCase() : '';
    if (meetingCode.isEmpty) {
      final codeMatch = RegExp(r'(?:mã|code|id)[:\s]+([^\s,;]+)', caseSensitive: false).firstMatch(combined);
      if (codeMatch != null) {
        meetingCode = codeMatch.group(1)!.trim();
      }
    }

    final urlMatch = RegExp(r'https?://[^\s]+', caseSensitive: false).firstMatch(combined);
    final meetingUrl = meetingCode.isNotEmpty && RegExp(r'^[a-z]{3}-[a-z]{4}-[a-z]{3}$', caseSensitive: false).hasMatch(meetingCode)
        ? 'https://meet.google.com/$meetingCode'
        : urlMatch?.group(0);

    return RoomDirectionInfo(
      room: room.isNotEmpty ? room : 'Online',
      building: 'Lớp học trực tuyến (Online)',
      buildingCode: 'Online',
      floor: 'Học từ xa',
      mapQuery: '',
      isOnline: true,
      meetingInfo: extraNote.isNotEmpty ? extraNote : (room != 'Online' ? room : null),
      meetingUrl: meetingUrl,
      meetingCode: meetingCode.isNotEmpty ? meetingCode : null,
      steps: const [], // Không cần chỉ đường đi bộ đối với lớp online
      tips: const [
        'Sử dụng tai nghe có mic để nghe giảng rõ ràng và hạn chế tiếng vọng từ không gian xung quanh.',
        'Đăng nhập đúng tài khoản email sinh viên (@dhtn.edu.vn) và đặt tên đầy đủ kèm MSSV để giảng viên dễ duyệt và điểm danh.',
        'Nên vào phòng sớm 5 phút để kiểm tra âm thanh, hình ảnh sẵn sàng trước khi bài học bắt đầu.',
      ],
    );
  }

  // Loại bỏ các tiền tố thường gặp để chuẩn hóa regex cho phòng trực tiếp
  final clean = upper
      .replaceFirst(RegExp(r'^(NHÀ\s*HỌC\s*SỐ|NHÀ\s*HỌC|NHÀ|PHÒNG|P\.)\s*', caseSensitive: false), '')
      .trim();

  String building = 'Khu giảng đường';
  String buildingCode = 'Giảng đường';
  String floor = '';
  String mapQuery = '';
  String roomDisplay = room.isNotEmpty ? room : 'Khu giảng đường';

  // 1. Dạng 3 phần: X.Y.Z (vd: 7.3.18 -> Nhà 7, Tầng 3, Phòng 18; 9.2.04 -> Nhà 9, Tầng 2, Phòng 04)
  final match3 = RegExp(r'^(\d+)\s*[\._]\s*(\d+)\s*[\._]\s*([0-9A-Z_-]+)(.*)', caseSensitive: false).firstMatch(clean);
  if (match3 != null) {
    final bNum = match3.group(1)!;
    final fNum = match3.group(2)!;
    final rNum = match3.group(3)!;
    final extra = match3.group(4)?.trim() ?? '';

    buildingCode = 'Nhà $bNum';
    building = _getBuildingFullName(bNum);
    floor = 'Tầng $fNum';
    roomDisplay = 'Phòng $rNum${extra.isNotEmpty ? ' $extra' : ''}';
    mapQuery = buildingCode;
  } else {
    // 2. Dạng 2 phần: X.Z (vd: 6.12 -> Nhà 6, Phòng 12; 2.21 (CLC) -> Nhà 2, Phòng 21 (CLC))
    final match2 = RegExp(r'^(\d+)\s*[\._]\s*([0-9A-Z_-]+)(.*)', caseSensitive: false).firstMatch(clean);
    if (match2 != null) {
      final bNum = match2.group(1)!;
      final rNum = match2.group(2)!;
      final extra = match2.group(3)?.trim() ?? '';

      buildingCode = 'Nhà $bNum';
      building = _getBuildingFullName(bNum);
      floor = '';
      roomDisplay = 'Phòng $rNum${extra.isNotEmpty ? ' $extra' : ''}';
      mapQuery = buildingCode;
    } else if (upper.contains('400')) {
      building = 'Giảng đường 400 chỗ';
      buildingCode = 'GĐ 400';
      mapQuery = 'Giảng đường 400 chỗ';
      roomDisplay = 'Hội trường lớn 400 chỗ';
    } else if (upper.contains('200')) {
      building = 'Giảng đường 200 chỗ';
      buildingCode = 'GĐ 200';
      mapQuery = 'Giảng đường 200 chỗ';
      roomDisplay = 'Hội trường vừa 200 chỗ';
    } else if (upper.contains('THƯ VIỆN') || upper.contains('THU VIEN')) {
      building = 'Thư viện Trung tâm';
      buildingCode = 'Thư viện';
      mapQuery = 'Thư viện Trung tâm';
      roomDisplay = 'Thư viện Trung tâm';
    } else if (upper.contains('QUỐC PHÒNG') || upper.contains('GDQP') || upper.contains('QP-AN')) {
      building = 'Trung tâm Giáo dục Quốc phòng và An ninh';
      buildingCode = 'TT GDQP';
      mapQuery = 'Trung tâm Giáo dục Quốc phòng và An ninh';
      roomDisplay = 'Trung tâm GDQP';
    } else if (upper.contains('Y DƯỢC') || upper.contains('Y DUOC')) {
      building = 'Nhà học số 5 - Khoa Y Dược';
      buildingCode = 'Nhà 5';
      mapQuery = 'Nhà học số 5';
      roomDisplay = room.isNotEmpty ? room : 'Khoa Y Dược';
    } else if (upper.contains('KINH TẾ') || upper.contains('KINH TE')) {
      building = 'Nhà học số 7 - Khoa Kinh tế';
      buildingCode = 'Nhà 7';
      mapQuery = 'Nhà học số 7';
      roomDisplay = room.isNotEmpty ? room : 'Khoa Kinh tế';
    } else if (upper.contains('SƯ PHẠM') || upper.contains('SU PHAM')) {
      building = 'Nhà học số 8 - Khoa Sư phạm';
      buildingCode = 'Nhà 8';
      mapQuery = 'Nhà học số 8';
      roomDisplay = room.isNotEmpty ? room : 'Khoa Sư phạm';
    } else if (upper.contains('CÔNG NGHỆ') || upper.contains('CNTT') || upper.contains('TỰ NHIÊN')) {
      building = 'Nhà học số 9 - Khoa KHTN & Công nghệ';
      buildingCode = 'Nhà 9';
      mapQuery = 'Nhà học số 9';
      roomDisplay = room.isNotEmpty ? room : 'Khoa CNTT';
    } else {
      final bMatch = RegExp(r'NHÀ\s*(\d+)', caseSensitive: false).firstMatch(upper);
      if (bMatch != null) {
        final bNum = bMatch.group(1)!;
        buildingCode = 'Nhà $bNum';
        building = _getBuildingFullName(bNum);
        mapQuery = buildingCode;
      }
    }
  }

  final steps = <DirectionStep>[
    DirectionStep(
      step: 1,
      title: 'Cổng trường',
      desc: 'Từ cổng đi thẳng qua trục đường trung tâm hướng về phía $buildingCode.',
      icon: 'compass',
    ),
    DirectionStep(
      step: 2,
      title: 'Vào sảnh chính $buildingCode',
      desc: 'Bước vào sảnh chính $buildingCode, có thể tra cứu sơ đồ phân phòng tại bảng thông báo sảnh.',
      icon: 'home',
    ),
  ];

  if (floor.isNotEmpty) {
    steps.add(
      DirectionStep(
        step: 3,
        title: 'Lên $floor',
        desc: 'Sử dụng thang bộ để di chuyển lên $floor.',
        icon: 'arrow-up-circle',
      ),
    );
    steps.add(
      DirectionStep(
        step: 4,
        title: 'Đến $roomDisplay',
        desc: 'Rẽ theo biển báo số phòng dọc hành lang $floor, $roomDisplay nằm ở vị trí tương ứng.',
        icon: 'map-pin',
      ),
    );
  } else {
    steps.add(
      DirectionStep(
        step: 3,
        title: 'Đến $roomDisplay',
        desc: 'Đi theo biển chỉ dẫn số phòng tại khu vực $buildingCode, $roomDisplay nằm ở vị trí tương ứng.',
        icon: 'map-pin',
      ),
    );
  }

  const tips = [
    'Nhà xe thường đông vào đầu ca học, bạn có thể thử nhà xe khác để nhanh hơn.',
    'Nên đến trước giờ vào lớp 5 - 10 phút để ổn định vị trí và điểm danh.',
  ];

  return RoomDirectionInfo(
    room: roomDisplay,
    building: building,
    buildingCode: buildingCode,
    floor: floor,
    mapQuery: mapQuery,
    steps: steps,
    tips: tips,
  );
}

String _getBuildingFullName(String bNum) {
  switch (bNum) {
    case '5':
      return 'Nhà học số 5 - Khoa Y Dược';
    case '7':
      return 'Nhà học số 7 - Khoa Kinh tế';
    case '8':
      return 'Nhà học số 8 - Khoa Sư phạm';
    case '9':
      return 'Nhà học số 9 - Khoa KHTN & Công nghệ';
    default:
      return 'Nhà học số $bNum';
  }
}
