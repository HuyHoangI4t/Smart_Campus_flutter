import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class CampusLocationItem {
  final int id;
  final String name;
  final String category;
  final String building;
  final String floor;
  final String description;
  final double lat;
  final double lng;
  final IconData icon;
  final Color color;

  const CampusLocationItem({
    required this.id,
    required this.name,
    required this.category,
    required this.building,
    required this.floor,
    required this.description,
    required this.lat,
    required this.lng,
    required this.icon,
    required this.color,
  });

  LatLng get coordinate => LatLng(lat, lng);

  factory CampusLocationItem.fromJson(Map<String, dynamic> json) {
    return CampusLocationItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Tất cả',
      building: json['building']?.toString() ?? '',
      floor: json['floor']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      lat: (json['lat'] is num)
          ? (json['lat'] as num).toDouble()
          : double.tryParse(json['lat']?.toString() ?? '0') ?? 0.0,
      lng: (json['lng'] is num)
          ? (json['lng'] as num).toDouble()
          : double.tryParse(json['lng']?.toString() ?? '0') ?? 0.0,
      icon: _parseIcon(json['icon']?.toString()),
      color: _parseColor(json['color']?.toString()),
    );
  }

  static IconData _parseIcon(String? iconName) {
    switch (iconName?.toLowerCase()) {
      case 'briefcase':
        return Icons.business_center_outlined;
      case 'book-open':
        return Icons.menu_book_outlined;
      case 'cpu':
        return Icons.biotech_outlined;
      case 'activity':
        return Icons.local_hospital_outlined;
      case 'layers':
        return Icons.account_balance_outlined;
      case 'award':
        return Icons.school_outlined;
      case 'book':
        return Icons.local_library_outlined;
      case 'home':
        return Icons.apartment_outlined;
      case 'coffee':
        return Icons.local_cafe_outlined;
      case 'droplet':
        return Icons.wc_outlined;
      default:
        return Icons.place_outlined;
    }
  }

  static Color _parseColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return const Color(0xFF132F73);
    final clean = hexString.replaceAll('#', '');
    if (clean.length == 6) {
      return Color(int.tryParse('FF$clean', radix: 16) ?? 0xFF132F73);
    } else if (clean.length == 8) {
      return Color(int.tryParse(clean, radix: 16) ?? 0xFF132F73);
    }
    return const Color(0xFF132F73);
  }
}

class CampusGate {
  final String id;
  final String name;
  final String shortName;
  final double lat;
  final double lng;

  const CampusGate({
    required this.id,
    required this.name,
    required this.shortName,
    required this.lat,
    required this.lng,
  });

  LatLng get coordinate => LatLng(lat, lng);

  factory CampusGate.fromJson(Map<String, dynamic> json) {
    return CampusGate(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      shortName: json['shortName']?.toString() ??
          json['short_name']?.toString() ??
          json['name']?.toString() ??
          '',
      lat: (json['lat'] is num)
          ? (json['lat'] as num).toDouble()
          : double.tryParse(json['lat']?.toString() ?? '0') ?? 0.0,
      lng: (json['lng'] is num)
          ? (json['lng'] as num).toDouble()
          : double.tryParse(json['lng']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class CampusConstants {
  CampusConstants._();

  static const LatLng campusCenter = LatLng(12.6515, 108.0245);

  static const CampusGate defaultGate = CampusGate(
    id: 'front_gate',
    name: 'Cổng trước (Lê Duẩn)',
    shortName: '(Lê Duẩn)',
    lat: 12.651536,
    lng: 108.023856,
  );

  static const List<CampusGate> gates = [
    defaultGate,
    CampusGate(
      id: 'back_gate',
      name: 'Cổng sau (Y Wang)',
      shortName: '(Y Wang)',
      lat: 12.648372,
      lng: 108.028044,
    ),
    CampusGate(
      id: 'hospital_gate',
      name: 'Cổng Bệnh viện (Yersin)',
      shortName: 'Bệnh viện',
      lat: 12.650645,
      lng: 108.022990,
    ),
  ];

  static const List<CampusLocationItem> campusLocations = [
    CampusLocationItem(
      id: 1,
      name: 'Tòa nhà Điều hành (Khu Hiệu bộ)',
      category: 'Hành chính',
      building: 'Tòa Hiệu Bộ',
      floor: 'Tầng 1 - 7',
      description: 'Trung tâm hành chính và các phòng ban hiệu bộ trường Đại học Tây Nguyên',
      lat: 12.65099693,
      lng: 108.02452788,
      icon: Icons.business_center_outlined,
      color: Color(0xFF10B981),
    ),
    CampusLocationItem(
      id: 2,
      name: 'Nhà học số 2 - Khoa Ngoại ngữ - Khoa Lý luận chính trị',
      category: 'Giảng đường',
      building: 'Nhà học số 2',
      floor: 'Tầng 1 - 2',
      description: 'Khu vực giảng đường ngoại ngữ và lý luận chính trị.',
      lat: 12.65079877,
      lng: 108.02465772,
      icon: Icons.menu_book,
      color: Color(0xFF8B5CF6),
    ),
    CampusLocationItem(
      id: 3,
      name: 'Phòng thí nghiệm Khoa Y Dược',
      category: 'Phòng thí nghiệm',
      building: 'Phòng TN Y Dược',
      floor: '',
      description: 'Phòng thí nghiệm thực hành chuyên ngành Y - Dược.',
      lat: 12.65054504,
      lng: 108.02483976,
      icon: Icons.memory,
      color: Color(0xFF06B6D4),
    ),
    CampusLocationItem(
      id: 4,
      name: 'Bệnh viện Trường Đại học Tây Nguyên',
      category: 'Y tế',
      building: 'Bệnh viện ĐH Tây Nguyên',
      floor: 'Nhiều tầng',
      description: 'Bệnh viện thực hành đa khoa và Trung tâm xét nghiệm y khoa chuyên sâu.',
      lat: 12.65041159,
      lng: 108.0230479,
      icon: Icons.local_hospital,
      color: Color(0xFFEF4444),
    ),
    CampusLocationItem(
      id: 5,
      name: 'Nhà học số 5 - Khoa Y Dược',
      category: 'Giảng đường',
      building: 'Nhà học số 5',
      floor: 'Tầng 1 - 4',
      description: 'Giảng đường chính đào tạo khối ngành Y Đa khoa, Điều dưỡng, Dược học.',
      lat: 12.64991685,
      lng: 108.02399454,
      icon: Icons.menu_book,
      color: Color(0xFF6366F1),
    ),
    CampusLocationItem(
      id: 6,
      name: 'Nhà học số 6',
      category: 'Giảng đường',
      building: 'Nhà học số 6',
      floor: '',
      description: 'Khu giảng đường học tập chung của các khoa.',
      lat: 12.65029684,
      lng: 108.02549959,
      icon: Icons.menu_book,
      color: Color(0xFF06B6D4),
    ),
    CampusLocationItem(
      id: 7,
      name: 'Nhà học số 7 - Khoa Kinh tế - Trung tâm Ngoại ngữ Tin học',
      category: 'Giảng đường',
      building: 'Nhà học số 7',
      floor: 'Tầng 1 - 4',
      description: 'Khu giảng đường Khoa Kinh tế, Trung tâm NN-TH.',
      lat: 12.65219714,
      lng: 108.02494019,
      icon: Icons.menu_book,
      color: Color(0xFFF97316),
    ),
    CampusLocationItem(
      id: 8,
      name: 'Nhà học số 8 - Khoa Sư phạm',
      category: 'Giảng đường',
      building: 'Nhà học số 8',
      floor: 'Tầng 1 - 4',
      description: 'Giảng đường chính của Khoa Sư phạm.',
      lat: 12.65279834,
      lng: 108.02540642,
      icon: Icons.menu_book,
      color: Color(0xFF3B82F6),
    ),
    CampusLocationItem(
      id: 9,
      name: 'Nhà học số 9 - Khoa Khoa học Tự nhiên và Công nghệ',
      category: 'Giảng đường',
      building: 'Nhà học số 9',
      floor: 'Tầng 1 - 4',
      description: 'Khoa CNTT, Toán, Vật lý, Hóa học...',
      lat: 12.65332602,
      lng: 108.02583055,
      icon: Icons.menu_book,
      color: Color(0xFF1E3A8A),
    ),
    CampusLocationItem(
      id: 10,
      name: 'Giảng đường 400 chỗ',
      category: 'Hội trường',
      building: 'Hội trường lớn',
      floor: 'Tầng 1',
      description: 'Hội trường lớn tổ chức sự kiện, hội thảo và các lớp đại cương đông sinh viên.',
      lat: 12.65198863,
      lng: 108.02531958,
      icon: Icons.military_tech,
      color: Color(0xFFF59E0B),
    ),
    CampusLocationItem(
      id: 11,
      name: 'Giảng đường 200 chỗ',
      category: 'Hội trường',
      building: 'Hội trường vừa',
      floor: '',
      description: 'Hội trường tổ chức chuyên đề, bảo vệ khóa luận và sinh hoạt lớp.',
      lat: 12.65260175,
      lng: 108.02584499,
      icon: Icons.military_tech,
      color: Color(0xFFF59E0B),
    ),
    CampusLocationItem(
      id: 12,
      name: 'Viện Công nghệ Sinh học & Môi trường',
      category: 'Nghiên cứu',
      building: 'Viện CNSH & MT',
      floor: 'Tầng 1 - 3',
      description: 'Nghiên cứu công nghệ sinh học và tài nguyên môi trường Tây Nguyên.',
      lat: 12.65317106,
      lng: 108.02651524,
      icon: Icons.memory,
      color: Color(0xFF10B981),
    ),
    CampusLocationItem(
      id: 13,
      name: 'Thư viện Trung tâm',
      category: 'Học tập',
      building: 'Tòa Thư viện',
      floor: 'Tầng 1 - 2',
      description: 'Thư viện tài liệu học tập, phòng tự học và tra cứu thông tin.',
      lat: 12.65143272,
      lng: 108.02536728,
      icon: Icons.menu_book,
      color: Color(0xFFF59E0B),
    ),
    CampusLocationItem(
      id: 14,
      name: 'Ký túc xá số 2',
      category: 'Ký túc xá',
      building: 'KTX 2',
      floor: 'Tầng 1 - 4',
      description: 'Khu nội trú ký túc xá sinh viên số 2.',
      lat: 12.64987752,
      lng: 108.02716015,
      icon: Icons.home_outlined,
      color: Color(0xFF8B5CF6),
    ),
    CampusLocationItem(
      id: 15,
      name: 'Trung tâm Ứng dụng và Tư vấn Kỹ thuật Nông Lâm nghiệp',
      category: 'Nghiên cứu',
      building: 'TT Ứng dụng Nông Lâm',
      floor: 'Tầng 1 - 2',
      description: 'Nghiên cứu nông lâm nghiệp, chuyển giao kỹ thuật công nghệ.',
      lat: 12.65182639,
      lng: 108.02749163,
      icon: Icons.apartment,
      color: Color(0xFF10B981),
    ),
    CampusLocationItem(
      id: 16,
      name: 'Khu đất ứng dụng và tư vấn kỹ thuật nông lâm nghiệp',
      category: 'Thực nghiệm',
      building: 'Khu thực nghiệm',
      floor: '',
      description: 'Khu vườn thực vật và đất thí nghiệm thực hành nông nghiệp.',
      lat: 12.6499721,
      lng: 108.02816422,
      icon: Icons.military_tech,
      color: Color(0xFF10B981),
    ),
    CampusLocationItem(
      id: 17,
      name: 'Trường Mầm non Thực hành 11-11',
      category: 'Tiện ích',
      building: 'Mầm non 11-11',
      floor: 'Tầng 1 - 2',
      description: 'Trường mầm non trực thuộc phục vụ thực hành sư phạm và con em cán bộ.',
      lat: 12.65120158,
      lng: 108.02801497,
      icon: Icons.military_tech,
      color: Color(0xFFEC4899),
    ),
    CampusLocationItem(
      id: 18,
      name: 'Trường THPT Thực hành Cao Nguyên',
      category: 'Giảng đường',
      building: 'THPT Thực hành',
      floor: 'Tầng 1 - 4',
      description: 'Trường THPT Thực hành Cao Nguyên trực thuộc Đại học Tây Nguyên.',
      lat: 12.65019949,
      lng: 108.02919879,
      icon: Icons.menu_book,
      color: Color(0xFF3B82F6),
    ),
    CampusLocationItem(
      id: 19,
      name: 'Trung tâm Giáo dục Quốc phòng và An ninh Trường ĐH Tây Nguyên',
      category: 'Giảng đường',
      building: 'TT GDQP-AN',
      floor: 'Tầng 1 - 4',
      description: 'Trung tâm GDQP-AN đào tạo kiến thức QP-AN cho sinh viên toàn vùng Tây Nguyên.',
      lat: 12.64828877,
      lng: 108.02723233,
      icon: Icons.menu_book,
      color: Color(0xFFEF4444),
    ),
    CampusLocationItem(
      id: 20,
      name: 'Thao trường quân sự',
      category: 'Tiện ích',
      building: 'Thao trường',
      floor: 'Bãi tập',
      description: 'Bãi tập bắn súng, chiến thuật và thao trường huấn luyện quân sự ngoài trời.',
      lat: 12.64954745,
      lng: 108.02747023,
      icon: Icons.military_tech,
      color: Color(0xFFF59E0B),
    ),
    CampusLocationItem(
      id: 21,
      name: 'Khu thể thao',
      category: 'Thể thao',
      building: 'Sân vận động',
      floor: 'Mặt sân',
      description: 'Sân vận động, sân bóng đá, đường chạy điền kinh phục vụ rèn luyện thể chất.',
      lat: 12.64917237,
      lng: 108.02630782,
      icon: Icons.fitness_center,
      color: Color(0xFF06B6D4),
    ),
    CampusLocationItem(
      id: 22,
      name: 'Nhà thi đấu thể thao',
      category: 'Thể thao',
      building: 'Nhà thi đấu',
      floor: '',
      description: 'Nhà thi đấu đa năng trong nhà cho cầu lông, bóng chuyền, bóng rổ.',
      lat: 12.64917513,
      lng: 108.02581528,
      icon: Icons.fitness_center,
      color: Color(0xFF3B82F6),
    ),
    CampusLocationItem(
      id: 23,
      name: 'Hồ bơi',
      category: 'Thể thao',
      building: 'Khu hồ bơi',
      floor: 'Bể bơi',
      description: 'Bể bơi tiêu chuẩn phục vụ học phần bơi lội và thể thao dưới nước.',
      lat: 12.64930933,
      lng: 108.02508591,
      icon: Icons.fitness_center,
      color: Color(0xFF06B6D4),
    ),
    CampusLocationItem(
      id: 24,
      name: 'Toà nhà Thí nghiệm Khoa Nông nghiệp',
      category: 'Phòng thí nghiệm',
      building: 'Khu TN Nông nghiệp',
      floor: 'Tầng 1 - 4',
      description: 'Khu phòng thí nghiệm chuyên ngành Nông - Lâm - Thủy sản.',
      lat: 12.65128786,
      lng: 108.02688494,
      icon: Icons.memory,
      color: Color(0xFF06B6D4),
    ),
    CampusLocationItem(
      id: 25,
      name: 'Ký túc xá Lào - Campuchia',
      category: 'Ký túc xá',
      building: 'KTX Lưu học sinh',
      floor: 'Tầng 1 - 4',
      description: 'Ký túc xá dành cho lưu học sinh quốc tế Lào và Campuchia.',
      lat: 12.65095505,
      lng: 108.027262,
      icon: Icons.home_outlined,
      color: Color(0xFF8B5CF6),
    ),
    CampusLocationItem(
      id: 26,
      name: 'Ký túc xá số 1',
      category: 'Ký túc xá',
      building: 'KTX 1',
      floor: 'Tầng 1 - 4',
      description: 'Khu ký túc xá sinh viên số 1.',
      lat: 12.65031896,
      lng: 108.02666604,
      icon: Icons.home_outlined,
      color: Color(0xFF8B5CF6),
    ),
    CampusLocationItem(
      id: 27,
      name: 'Ký túc xá số 3',
      category: 'Ký túc xá',
      building: 'KTX 3',
      floor: 'Tầng 1 - 4',
      description: 'Khu ký túc xá sinh viên số 3.',
      lat: 12.6491545,
      lng: 108.02799588,
      icon: Icons.home_outlined,
      color: Color(0xFF8B5CF6),
    ),
    CampusLocationItem(
      id: 28,
      name: 'Ký túc xá số 4',
      category: 'Ký túc xá',
      building: 'KTX 4',
      floor: 'Tầng 1 - 4',
      description: 'Khu ký túc xá sinh viên số 4.',
      lat: 12.64888412,
      lng: 108.02826763,
      icon: Icons.home_outlined,
      color: Color(0xFF8B5CF6),
    ),
    CampusLocationItem(
      id: 29,
      name: 'Nhà khách',
      category: 'Tiện ích',
      building: 'Nhà khách TNU',
      floor: 'Tầng 1 - 4',
      description: 'Nhà khách đón tiếp chuyên gia, giảng viên thỉnh giảng và đối tác.',
      lat: 12.6506929,
      lng: 108.02645132,
      icon: Icons.place,
      color: Color(0xFF64748B),
    ),
    CampusLocationItem(
      id: 30,
      name: 'Sân quần vợt',
      category: 'Thể thao',
      building: 'Sân Tennis',
      floor: 'Mặt sân',
      description: 'Cụm sân quần vợt / pickleball phục vụ thể thao cán bộ và sinh viên.',
      lat: 12.65090752,
      lng: 108.02617253,
      icon: Icons.fitness_center,
      color: Color(0xFF06B6D4),
    ),
    CampusLocationItem(
      id: 31,
      name: 'Căn tin - Đảo sinh viên',
      category: 'Tiện ích',
      building: 'Căng tin trung tâm',
      floor: '',
      description: 'Khu ẩm thực, ăn trưa, giải khát và không gian sinh hoạt chung ngoài trời.',
      lat: 12.652164,
      lng: 108.02635759,
      icon: Icons.coffee,
      color: Color(0xFFF97316),
    ),
    CampusLocationItem(
      id: 32,
      name: 'Phòng trưng bày',
      category: 'Học tập',
      building: 'Nhà Truyền thống',
      floor: '',
      description: 'Nhà truyền thống và phòng trưng bày lịch sử hình thành, phát triển nhà trường.',
      lat: 12.65160888,
      lng: 108.02402675,
      icon: Icons.menu_book,
      color: Color(0xFFEC4899),
    ),
    CampusLocationItem(
      id: 33,
      name: 'Nhà bảo vệ (Cổng chính Lê Duẩn)',
      category: 'Hành chính',
      building: 'Cổng chính',
      floor: '',
      description: 'Phòng kiểm soát ra vào, cổng chính số 567 Lê Duẩn.',
      lat: 12.65144341,
      lng: 108.02382916,
      icon: Icons.business_center_outlined,
      color: Color(0xFF10B981),
    ),
    CampusLocationItem(
      id: 34,
      name: 'Trung tâm Kỹ năng Sư phạm',
      category: 'Học tập',
      building: 'TT Kỹ năng Sư phạm',
      floor: 'Tầng 1 - 4',
      description: 'Trung tâm rèn luyện kỹ năng nghề nghiệp và nghiệp vụ sư phạm.',
      lat: 12.65056583,
      lng: 108.02892942,
      icon: Icons.menu_book,
      color: Color(0xFF3B82F6),
    ),
    CampusLocationItem(
      id: 35,
      name: 'Gara ô tô',
      category: 'Tiện ích',
      building: 'Gara ô tô trường',
      floor: '',
      description: 'Bãi đỗ xe ô tô và nhà để xe cán bộ, khách công tác.',
      lat: 12.65107564,
      lng: 108.02378504,
      icon: Icons.apartment,
      color: Color(0xFF64748B),
    ),
    CampusLocationItem(
      id: 36,
      name: 'Văn phòng Công đoàn trường',
      category: 'Hành chính',
      building: 'Khu Đoàn thể',
      floor: '',
      description: 'Trụ sở Ban Chấp hành Công đoàn Trường Đại học Tây Nguyên.',
      lat: 12.65074771,
      lng: 108.02339404,
      icon: Icons.business_center_outlined,
      color: Color(0xFF10B981),
    ),
    CampusLocationItem(
      id: 37,
      name: 'Văn phòng Đoàn Thanh niên - Hội Sinh viên',
      category: 'Hành chính',
      building: 'Khu Đoàn thể',
      floor: '',
      description: 'Trụ sở Đoàn TNCS Hồ Chí Minh & Hội Sinh viên Trường Đại học Tây Nguyên.',
      lat: 12.65054867,
      lng: 108.02358106,
      icon: Icons.business_center_outlined,
      color: Color(0xFF10B981),
    ),
    CampusLocationItem(
      id: 43,
      name: 'WC',
      category: 'WC',
      building: 'WC',
      floor: 'Tầng 1',
      description: 'Nhà vệ sinh nhà 6',
      lat: 12.65005177,
      lng: 108.02507489,
      icon: Icons.water_drop_outlined,
      color: Color(0xFF06b6d4),
    ),
    CampusLocationItem(
      id: 44,
      name: 'WC',
      category: 'WC',
      building: 'Nhà 6',
      floor: 'Tầng 1',
      description: 'Nhà vệ sinh nhà 6',
      lat: 12.6498268,
      lng: 108.02530036,
      icon: Icons.water_drop_outlined,
      color: Color(0xFF06b6d4),
    ),
    CampusLocationItem(
      id: 45,
      name: 'WC',
      category: 'WC',
      building: 'Nhà 2, Nhà 3',
      floor: 'Tầng 1',
      description: 'Nhà vệ sinh nhà 2, nhà 3',
      lat: 12.65044239,
      lng: 108.02490875,
      icon: Icons.water_drop_outlined,
      color: Color(0xFF06b6d4),
    ),
  ];

  static const List<LatLng> campusBoundary = [
    LatLng(12.64936184489708, 108.023709984411),
    LatLng(12.64939692098337, 108.0238593195032),
    LatLng(12.64922366673725, 108.0240207114143),
    LatLng(12.64914996044008, 108.0240744632604),
    LatLng(12.64910731131839, 108.024143411979),
    LatLng(12.64905641908621, 108.0243138201567),
    LatLng(12.64897030232368, 108.024311073955),
    LatLng(12.64846679989001, 108.0241911062746),
    LatLng(12.64835017475937, 108.0247583489782),
    LatLng(12.64825912642829, 108.0252039642648),
    LatLng(12.64879024169141, 108.0253483229021),
    LatLng(12.6487228183857, 108.0255963896767),
    LatLng(12.64881339164961, 108.025958958011),
    LatLng(12.6480975797379, 108.026419767791),
    LatLng(12.64746230619225, 108.0270818650112),
    LatLng(12.64783491871413, 108.0274820029304),
    LatLng(12.64817683713212, 108.0278523418964),
    LatLng(12.64834014924507, 108.0280072175512),
    LatLng(12.64837815224221, 108.0280034990301),
    LatLng(12.64843362651117, 108.0280736004634),
    LatLng(12.648424127415, 108.0281079564623),
    LatLng(12.64851185632938, 108.0282133043701),
    LatLng(12.64887356697684, 108.0285996439882),
    LatLng(12.64924557138193, 108.0290044662777),
    LatLng(12.64940948705378, 108.0291786420854),
    LatLng(12.64957989265152, 108.0293607651568),
    LatLng(12.6497233278739, 108.0295277768443),
    LatLng(12.64979058097085, 108.0295986717908),
    LatLng(12.6498738024417, 108.0296363735788),
    LatLng(12.65004690533162, 108.029681693164),
    LatLng(12.65012590824586, 108.0296826255635),
    LatLng(12.6502227605403, 108.029608578842),
    LatLng(12.65037273737863, 108.0294754334155),
    LatLng(12.65068472907029, 108.0291690340094),
    LatLng(12.65130925932491, 108.0285346899524),
    LatLng(12.65253281247356, 108.0273262157134),
    LatLng(12.65326595038413, 108.0266371644356),
    LatLng(12.65351972219521, 108.0263648962711),
    LatLng(12.6536705590384, 108.026217818969),
    LatLng(12.65381199629214, 108.0260589411716),
    LatLng(12.65367438187265, 108.025658267053),
    LatLng(12.65316607382772, 108.0252839823841),
    LatLng(12.65288132324158, 108.0250658838366),
    LatLng(12.65241666236353, 108.024653847315),
    LatLng(12.65209761057217, 108.024331765829),
    LatLng(12.65178083015148, 108.0239849309481),
    LatLng(12.65163902006585, 108.023884193641),
    LatLng(12.65155443502066, 108.0238907083279),
    LatLng(12.65150095363651, 108.0238432594696),
    LatLng(12.65152219056682, 108.0237942110838),
    LatLng(12.65095951369571, 108.023257667042),
    LatLng(12.65066664206127, 108.0229636143608),
    LatLng(12.6504510945065, 108.0227472291479),
    LatLng(12.65042001012422, 108.0227337420068),
    LatLng(12.65038955548521, 108.0227619676594),
    LatLng(12.65010276714285, 108.0230426974618),
    LatLng(12.64980850157077, 108.0233338952721),
    LatLng(12.64951862228554, 108.0236355295628),
    LatLng(12.64936184489708, 108.023709984411),
  ];

  static final List<List<LatLng>> defaultWalkways = [
    [
      const LatLng(12.6515362, 108.023856),
      const LatLng(12.6514434, 108.0239459),
      const LatLng(12.651938, 108.024481),
      const LatLng(12.6520387, 108.0245708),
      const LatLng(12.6525581, 108.0250454),
      const LatLng(12.6531195, 108.0254384),
    ],
    [
      const LatLng(12.6532045, 108.0258286),
      const LatLng(12.6529665, 108.0256356),
      const LatLng(12.6531195, 108.0254384),
    ],
    [
      const LatLng(12.6526537, 108.0253834),
      const LatLng(12.6524379, 108.0251984),
      const LatLng(12.6525581, 108.0250454),
    ],
    [
      const LatLng(12.652087, 108.0249596),
      const LatLng(12.6518699, 108.0247759),
      const LatLng(12.6520387, 108.0245708),
    ],
    [
      const LatLng(12.651938, 108.024481),
      const LatLng(12.6517587, 108.0246768),
      const LatLng(12.6518699, 108.0247759),
    ],
    [
      const LatLng(12.6531457, 108.0259776),
      const LatLng(12.6529795, 108.0260004),
      const LatLng(12.65302, 108.0263476),
      const LatLng(12.6529258, 108.0264428),
    ],
    [
      const LatLng(12.6529795, 108.0260004),
      const LatLng(12.6524771, 108.0260594),
      const LatLng(12.6528303, 108.0263195),
      const LatLng(12.6529258, 108.0264428),
    ],
    [
      const LatLng(12.6521657, 108.0263355),
      const LatLng(12.6523109, 108.0260701),
      const LatLng(12.6524771, 108.0260594),
    ],
    [
      const LatLng(12.6523109, 108.0260701),
      const LatLng(12.6523083, 108.0258703),
      const LatLng(12.6520938, 108.0257135),
      const LatLng(12.6521069, 108.0253301),
      const LatLng(12.6519356, 108.0251344),
      const LatLng(12.652087, 108.0249596),
      const LatLng(12.6519356, 108.0251344),
    ],
    [
      const LatLng(12.6519356, 108.0251344),
      const LatLng(12.6517708, 108.0252456),
      const LatLng(12.6517629, 108.0256733),
      const LatLng(12.6519735, 108.0256693),
      const LatLng(12.6520938, 108.0257135),
    ],
    [
      const LatLng(12.6521015, 108.0255619),
      const LatLng(12.6523147, 108.0255538),
      const LatLng(12.6526658, 108.0255688),
    ],
    [
      const LatLng(12.6523083, 108.0258703),
      const LatLng(12.6523147, 108.0255538),
      const LatLng(12.6523148, 108.0250979),
    ],
    [
      const LatLng(12.6529258, 108.0264428),
      const LatLng(12.6528918, 108.0266254),
      const LatLng(12.6528487, 108.0267903),
      const LatLng(12.652782, 108.0269244),
      const LatLng(12.6526773, 108.0270263),
      const LatLng(12.6525544, 108.0271322),
      const LatLng(12.6524354, 108.0272247),
    ],
    [
      const LatLng(12.6514368, 108.0249797),
      const LatLng(12.6516043, 108.0248135),
      const LatLng(12.6519356, 108.0251344),
      const LatLng(12.6516043, 108.0248135),
      const LatLng(12.651285, 108.0251394),
      const LatLng(12.6513896, 108.025256),
      const LatLng(12.6514525, 108.0251421),
      const LatLng(12.6515977, 108.0251755),
      const LatLng(12.6517708, 108.0252456),
      const LatLng(12.6514368, 108.0249797),
    ],
    [
      const LatLng(12.6517587, 108.0246768),
      const LatLng(12.6516043, 108.0248135),
      const LatLng(12.6506647, 108.023931),
      const LatLng(12.6506176, 108.0237795),
      const LatLng(12.6507734, 108.0236146),
      const LatLng(12.6509316, 108.0234523),
      const LatLng(12.6514434, 108.0239459),
    ],
    [
      const LatLng(12.651156, 108.024383),
      const LatLng(12.651938, 108.024481),
    ],
    [
      const LatLng(12.6514434, 108.0239459),
      const LatLng(12.6514071, 108.0241015),
      const LatLng(12.651156, 108.024383),
    ],
    [
      const LatLng(12.6510435, 108.0242838),
      const LatLng(12.6513155, 108.0239835),
      const LatLng(12.6514434, 108.0239459),
    ],
    [
      const LatLng(12.6514434, 108.0239459),
      const LatLng(12.6506176, 108.0237795),
      const LatLng(12.6503263, 108.0238764),
      const LatLng(12.6501589, 108.0237262),
      const LatLng(12.6499758, 108.0239032),
      const LatLng(12.6500098, 108.024064),
      const LatLng(12.6502295, 108.0243214),
      const LatLng(12.6504676, 108.0240533),
      const LatLng(12.6503263, 108.0238764),
    ],
    [
      const LatLng(12.651285, 108.0251394),
      const LatLng(12.6511715, 108.0249275),
      const LatLng(12.6509492, 108.0247157),
      const LatLng(12.6507059, 108.0244583),
      const LatLng(12.6504731, 108.0241982),
      const LatLng(12.6504676, 108.0240533),
      const LatLng(12.6506647, 108.023931),
    ],
    [
      const LatLng(12.6509492, 108.0247157),
      const LatLng(12.6507843, 108.02489),
      const LatLng(12.6505227, 108.0246165),
      const LatLng(12.6503474, 108.0244154),
    ],
    [
      const LatLng(12.6507059, 108.0244583),
      const LatLng(12.6505227, 108.0246165),
    ],
    [
      const LatLng(12.6509763, 108.0254586),
      const LatLng(12.65084, 108.025417),
      const LatLng(12.6505652, 108.0251501),
      const LatLng(12.6502631, 108.0248296),
      const LatLng(12.6499896, 108.0245157),
      const LatLng(12.6496324, 108.024155),
    ],
    [
      const LatLng(12.6508112, 108.0255832),
      const LatLng(12.650471, 108.025244),
      const LatLng(12.6501767, 108.0249235),
      const LatLng(12.6498901, 108.0246123),
      const LatLng(12.6495315, 108.0242368),
    ],
    [
      const LatLng(12.6499896, 108.0245157),
      const LatLng(12.6498901, 108.0246123),
    ],
    [
      const LatLng(12.6502631, 108.0248296),
      const LatLng(12.6501767, 108.0249235),
    ],
    [
      const LatLng(12.6508375, 108.0277948),
      const LatLng(12.6500484, 108.0286316),
      const LatLng(12.6498731, 108.0288179),
    ],
    [
      const LatLng(12.6500484, 108.0286316),
      const LatLng(12.6494752, 108.0280401),
      const LatLng(12.6489193, 108.0274609),
    ],
    [
      const LatLng(12.6503474, 108.0244154),
      const LatLng(12.6502295, 108.0243214),
      const LatLng(12.6499896, 108.0245157),
    ],
    [
      const LatLng(12.6505227, 108.0246165),
      const LatLng(12.6503263, 108.0246755),
      const LatLng(12.6502631, 108.0248296),
    ],
    [
      const LatLng(12.6507843, 108.02489),
      const LatLng(12.6507292, 108.0250215),
      const LatLng(12.6505652, 108.0251501),
    ],
    [
      const LatLng(12.6507452, 108.0263539),
      const LatLng(12.6504549, 108.026008),
      const LatLng(12.6506746, 108.0257801),
      const LatLng(12.650277, 108.0254905),
    ],
    [
      const LatLng(12.6498579, 108.0269739),
      const LatLng(12.6497533, 108.0268694),
      const LatLng(12.6499809, 108.0266897),
      const LatLng(12.6498893, 108.0265879),
      const LatLng(12.6504549, 108.026008),
    ],
    [
      const LatLng(12.6498893, 108.0265879),
      const LatLng(12.6497635, 108.02647),
      const LatLng(12.6498498, 108.0261965),
      const LatLng(12.6497347, 108.0259418),
      const LatLng(12.6494862, 108.0258399),
      const LatLng(12.6492168, 108.0259177),
      const LatLng(12.6493214, 108.0262796),
      const LatLng(12.6491331, 108.0263252),
    ],
    [
      const LatLng(12.6494862, 108.0258399),
      const LatLng(12.6493868, 108.0252313),
    ],
    [
      const LatLng(12.6498893, 108.0265879),
      const LatLng(12.6490517, 108.027395),
      const LatLng(12.6489193, 108.0274609),
      const LatLng(12.6486436, 108.0278187),
      const LatLng(12.6489287, 108.0280385),
    ],
    [
      const LatLng(12.6486436, 108.0278187),
      const LatLng(12.6484419, 108.0280148),
    ],
    [
      const LatLng(12.6494752, 108.0280401),
      const LatLng(12.6492561, 108.0282882),
      const LatLng(12.6489287, 108.0280385),
    ],
    [
      const LatLng(12.6494752, 108.0280401),
      const LatLng(12.6504154, 108.0271243),
      const LatLng(12.6499809, 108.0266897),
    ],
    [
      const LatLng(12.6504154, 108.0271243),
      const LatLng(12.6508471, 108.0266764),
      const LatLng(12.6511349, 108.0270116),
      const LatLng(12.6510302, 108.0271161),
    ],
    [
      const LatLng(12.6508471, 108.0266764),
      const LatLng(12.6512653, 108.0262498),
    ],
    [
      const LatLng(12.6520116, 108.0263384),
      const LatLng(12.6516245, 108.026703),
    ],
    [
      const LatLng(12.6521657, 108.0263355),
      const LatLng(12.6520116, 108.0263384),
    ],
    [
      const LatLng(12.650277, 108.0254905),
      const LatLng(12.6500123, 108.0251475),
      const LatLng(12.6498841, 108.0252708),
    ],
    [
      const LatLng(12.6500177, 108.0235303),
      const LatLng(12.6501929, 108.023356),
      const LatLng(12.6503708, 108.0232059),
      const LatLng(12.6505173, 108.0233158),
      const LatLng(12.650703, 108.0232514),
      const LatLng(12.6504781, 108.0234634),
      const LatLng(12.650363, 108.023576),
      const LatLng(12.6501589, 108.0237262),
    ],
    [
      const LatLng(12.650363, 108.023576),
      const LatLng(12.6501929, 108.023356),
    ],
    [
      const LatLng(12.6513626, 108.0247562),
      const LatLng(12.6511715, 108.0249275),
      const LatLng(12.6513626, 108.0247562),
    ],
    [
      const LatLng(12.6525586, 108.0257324),
      const LatLng(12.6526658, 108.0255688),
      const LatLng(12.6526537, 108.0253834),
    ],
    [
      const LatLng(12.6531457, 108.0259776),
      const LatLng(12.6532045, 108.0258286),
    ],
    [
      const LatLng(12.6529795, 108.0260004),
      const LatLng(12.6529665, 108.0256356),
    ],
    [
      const LatLng(12.6535609, 108.0261856),
      const LatLng(12.6534982, 108.0257432),
      const LatLng(12.6531195, 108.0254384),
    ],
    [
      const LatLng(12.649282, 108.027178),
      const LatLng(12.6494023, 108.0273255),
    ],
    [
      const LatLng(12.6506746, 108.0257801),
      const LatLng(12.6508112, 108.0255832),
      const LatLng(12.6509763, 108.0254586),
      const LatLng(12.6508265, 108.0257275),
      const LatLng(12.6509971, 108.0259482),
      const LatLng(12.651111, 108.0260566),
      const LatLng(12.6512653, 108.0262498),
      const LatLng(12.6513726, 108.026384),
      const LatLng(12.6514917, 108.0265302),
      const LatLng(12.6516245, 108.026703),
      const LatLng(12.6517495, 108.0268398),
      const LatLng(12.6515375, 108.0270532),
      const LatLng(12.6513726, 108.0272208),
      const LatLng(12.6512627, 108.0273509),
      const LatLng(12.6510979, 108.0275279),
      const LatLng(12.6509617, 108.0276688),
      const LatLng(12.6508375, 108.0277948),
    ],
    [
      const LatLng(12.6527571, 108.026026),
      const LatLng(12.6528303, 108.0263195),
    ],
    [
      const LatLng(12.6529977, 108.0261829),
      const LatLng(12.6527989, 108.0261923),
    ],
    [
      const LatLng(12.6527571, 108.026026),
      const LatLng(12.65271, 108.0258102),
      const LatLng(12.6526658, 108.0255688),
    ],
    [
      const LatLng(12.6529665, 108.0256356),
      const LatLng(12.6528985, 108.0254882),
      const LatLng(12.6528945, 108.0252778),
    ],
    [
      const LatLng(12.651569, 108.0245763),
      const LatLng(12.6514683, 108.0246835),
    ],
    [
      const LatLng(12.6514302, 108.0244166),
      const LatLng(12.6513072, 108.0245292),
    ],
    [
      const LatLng(12.6508432, 108.024099),
      const LatLng(12.6506025, 108.0243456),
    ],
    [
      const LatLng(12.6509187, 108.024348),
      const LatLng(12.6508432, 108.024099),
    ],
    [
      const LatLng(12.6524771, 108.0260594),
      const LatLng(12.6523083, 108.0258703),
    ],
    [
      const LatLng(12.6524379, 108.0251984),
      const LatLng(12.6523148, 108.0250979),
      const LatLng(12.6523148, 108.0248231),
    ],
    [
      const LatLng(12.6510435, 108.0242838),
      const LatLng(12.6509187, 108.024348),
      const LatLng(12.6510913, 108.024533),
      const LatLng(12.6513626, 108.0247562),
      const LatLng(12.6513072, 108.0245292),
      const LatLng(12.6510913, 108.024533),
      const LatLng(12.651156, 108.024383),
    ],
    [
      const LatLng(12.6507707, 108.0234777),
      const LatLng(12.6507734, 108.0236146),
      const LatLng(12.6506189, 108.0236091),
    ],
    [
      const LatLng(12.6500534, 108.0247922),
      const LatLng(12.6498598, 108.0249786),
      const LatLng(12.6496781, 108.0250884),
      const LatLng(12.6495386, 108.0251262),
      const LatLng(12.6493868, 108.0252313),
    ],
    [
      const LatLng(12.6498731, 108.0288179),
      const LatLng(12.6494896, 108.0291973),
    ],
    [
      const LatLng(12.6492561, 108.0282882),
      const LatLng(12.6489299, 108.0285966),
    ],
    [
      const LatLng(12.6513726, 108.0272208),
      const LatLng(12.6511349, 108.0270116),
    ],
    [
      const LatLng(12.6523097, 108.0274705),
      const LatLng(12.6520753, 108.0272153),
      const LatLng(12.6517286, 108.0274996),
      const LatLng(12.6519968, 108.0277571),
    ],
    [
      const LatLng(12.6520753, 108.0272153),
      const LatLng(12.6519131, 108.0270519),
      const LatLng(12.6517495, 108.0268398),
    ],
    [
      const LatLng(12.6508112, 108.0255832),
      const LatLng(12.6508265, 108.0257275),
      const LatLng(12.6506746, 108.0257801),
    ],
    [
      const LatLng(12.651637, 108.0241511),
      const LatLng(12.6514302, 108.0244166),
    ],
    [
      const LatLng(12.651637, 108.0241511),
      const LatLng(12.6517587, 108.0246768),
      const LatLng(12.651569, 108.0245763),
      const LatLng(12.651637, 108.0241511),
    ],
    [
      const LatLng(12.6498598, 108.0249786),
      const LatLng(12.6497217, 108.0247696),
    ],
    [
      const LatLng(12.6509763, 108.0254586),
      const LatLng(12.6510585, 108.025181),
      const LatLng(12.6507843, 108.02489),
    ],
    [
      const LatLng(12.651285, 108.0251394),
      const LatLng(12.6510585, 108.025181),
    ],
    [
      const LatLng(12.6531732, 108.0261586),
      const LatLng(12.6529977, 108.0261829),
    ],
    [
      const LatLng(12.6490517, 108.027395),
      const LatLng(12.6488261, 108.0272033),
      const LatLng(12.6482662, 108.0265945),
    ],
    [
      const LatLng(12.6492168, 108.0259177),
      const LatLng(12.6488054, 108.0260636),
      const LatLng(12.6485985, 108.0261426),
      const LatLng(12.6484964, 108.0262458),
      const LatLng(12.6484428, 108.0263732),
      const LatLng(12.6484363, 108.0265515),
      const LatLng(12.6485436, 108.0267245),
      const LatLng(12.648749, 108.0268157),
      const LatLng(12.6489597, 108.0267594),
      const LatLng(12.6491861, 108.0266816),
      const LatLng(12.6494177, 108.0266119),
      const LatLng(12.6496035, 108.0265676),
      const LatLng(12.6497635, 108.02647),
    ],
    [
      const LatLng(12.6488054, 108.0260636),
      const LatLng(12.6488524, 108.025904),
      const LatLng(12.648787, 108.0256157),
      const LatLng(12.6488995, 108.0254117),
      const LatLng(12.6491141, 108.0253648),
      const LatLng(12.6493868, 108.0252313),
    ],
    [
      const LatLng(12.6501074, 108.0290834),
      const LatLng(12.6503283, 108.0288529),
    ],
    [
      const LatLng(12.6508375, 108.0277948),
      const LatLng(12.6511371, 108.0279472),
    ],
    [
      const LatLng(12.6505889, 108.0261626),
      const LatLng(12.6507393, 108.0260004),
      const LatLng(12.6508557, 108.0261399),
    ],
    [
      const LatLng(12.650277, 108.0254905),
      const LatLng(12.6501373, 108.0255135),
      const LatLng(12.6498841, 108.0252708),
    ],
    [
      const LatLng(12.6513687, 108.0266548),
      const LatLng(12.6512828, 108.0268894),
    ],
    [
      const LatLng(12.6505, 108.02308),
      const LatLng(12.6503708, 108.0232059),
    ],
    [
      const LatLng(12.652087, 108.0249596),
      const LatLng(12.6521069, 108.0253301),
    ],
    [
      const LatLng(12.6498901, 108.0246123),
      const LatLng(12.6497217, 108.0247696),
      const LatLng(12.6495199, 108.0247532),
      const LatLng(12.6493117, 108.024835),
      const LatLng(12.6490264, 108.0249356),
      const LatLng(12.6489113, 108.0249946),
      const LatLng(12.6489191, 108.0251769),
      const LatLng(12.6488995, 108.0254117),
    ],
    [
      const LatLng(12.6495199, 108.0247532),
      const LatLng(12.6495386, 108.0251262),
    ],
    [
      const LatLng(12.6505652, 108.0251501),
      const LatLng(12.650471, 108.025244),
    ],
    [
      const LatLng(12.6509763, 108.0254586),
      const LatLng(12.6506746, 108.0257801),
    ],
    [
      const LatLng(12.6501074, 108.0290834),
      const LatLng(12.6498731, 108.0288179),
    ],
    [
      const LatLng(12.6515765, 108.0276754),
      const LatLng(12.6517286, 108.0274996),
    ],
    [
      const LatLng(12.6507734, 108.0236146),
      const LatLng(12.651121, 108.02375),
      const LatLng(12.6514434, 108.0239459),
    ],
    [
      const LatLng(12.6491609, 108.0257551),
      const LatLng(12.6492168, 108.0259177),
    ],
    [
      const LatLng(12.6493544, 108.0250834),
      const LatLng(12.6493868, 108.0252313),
    ],
    [
      const LatLng(12.6506176, 108.0237795),
      const LatLng(12.650363, 108.023576),
    ],
    [
      const LatLng(12.650471, 108.025244),
      const LatLng(12.650277, 108.0254905),
    ],
    [
      const LatLng(12.6501767, 108.0249235),
      const LatLng(12.6500123, 108.0251475),
    ],
    [
      const LatLng(12.6511608, 108.0238899),
      const LatLng(12.6508432, 108.024099),
    ],
    [
      const LatLng(12.6511608, 108.0238899),
      const LatLng(12.6510435, 108.0242838),
    ],
    [
      const LatLng(12.6489193, 108.0274609),
      const LatLng(12.64879, 108.0273898),
    ],
    [
      const LatLng(12.6517587, 108.0246768),
      const LatLng(12.6515986, 108.0244337),
      const LatLng(12.6515173, 108.0243116),
    ],
    [
      const LatLng(12.6509763, 108.0254586),
      const LatLng(12.6510946, 108.0256529),
      const LatLng(12.6513024, 108.0258839),
      const LatLng(12.6514564, 108.02578),
      const LatLng(12.6516265, 108.0257428),
      const LatLng(12.6517629, 108.0256733),
    ],
    [
      const LatLng(12.6513024, 108.0258839),
      const LatLng(12.651111, 108.0260566),
    ],
    [
      const LatLng(12.651285, 108.0251394),
      const LatLng(12.6509763, 108.0254586),
    ],
    [
      const LatLng(12.6507734, 108.0236146),
      const LatLng(12.6505173, 108.0233158),
    ],
    [
      const LatLng(12.6505173, 108.0233158),
      const LatLng(12.6504781, 108.0234634),
      const LatLng(12.6501929, 108.023356),
    ],
    [
      const LatLng(12.65302, 108.0263476),
      const LatLng(12.6530595, 108.0264701),
      const LatLng(12.6529258, 108.0264428),
    ],
    [
      const LatLng(12.6531732, 108.0261586),
      const LatLng(12.6531457, 108.0259776),
    ],
    [
      const LatLng(12.649533, 108.0274614),
      const LatLng(12.6494023, 108.0273255),
    ],
    [
      const LatLng(12.6490825, 108.0279829),
      const LatLng(12.6488558, 108.0282481),
      const LatLng(12.6489287, 108.0280385),
      const LatLng(12.6490825, 108.0279829),
    ],
    [
      const LatLng(12.6513687, 108.0266548),
      const LatLng(12.6514917, 108.0265302),
    ],
    [
      const LatLng(12.6505652, 108.0251501),
      const LatLng(12.6504623, 108.0249378),
    ],
    [
      const LatLng(12.6507843, 108.02489),
      const LatLng(12.6505652, 108.0251501),
      const LatLng(12.6507292, 108.0250215),
      const LatLng(12.6508733, 108.0249985),
    ],
    [
      const LatLng(12.650703, 108.0232514),
      const LatLng(12.6509316, 108.0234523),
    ],
    [
      const LatLng(12.651569, 108.0245763),
      const LatLng(12.6514302, 108.0244166),
    ],
    [
      const LatLng(12.6514564, 108.02578),
      const LatLng(12.6510946, 108.0256529),
    ],
    [
      const LatLng(12.6510913, 108.024533),
      const LatLng(12.6509711, 108.0245864),
    ],
  ];
}
