import 'package:flutter/material.dart';
import 'campus_walkways.dart';
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
  final LatLng? insidePoint;
  final LatLng? outsidePoint;

  const CampusGate({
    required this.id,
    required this.name,
    required this.shortName,
    required this.lat,
    required this.lng,
    this.insidePoint,
    this.outsidePoint,
  });

  LatLng get coordinate => LatLng(lat, lng);
  LatLng get insideCoordinate => insidePoint ?? coordinate;
  LatLng get outsideCoordinate => outsidePoint ?? coordinate;

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
      insidePoint: _parsePoint(json['insidePoint']),
      outsidePoint: _parsePoint(json['outsidePoint']),
    );
  }

  static LatLng? _parsePoint(dynamic val) {
    if (val is List && val.length >= 2 && val[0] is num && val[1] is num) {
      return LatLng((val[0] as num).toDouble(), (val[1] as num).toDouble());
    }
    return null;
  }
}

class CampusConstants {
  CampusConstants._();

  static const LatLng campusCenter = LatLng(12.6515, 108.0245);

  static const CampusGate defaultGate = CampusGate(
    id: 'front_gate',
    name: 'Cổng trước (Lê Duẩn)',
    shortName: 'Cổng trước',
    lat: 12.651536,
    lng: 108.023856,
    insidePoint: LatLng(12.65144, 108.02395),
    outsidePoint: LatLng(12.65154752, 108.02385583),
  );

  static const List<CampusGate> gates = [
    defaultGate,
    CampusGate(
      id: 'hospital_gate',
      name: 'Cổng Bệnh viện (Lê Duẩn)',
      shortName: 'Cổng BV (Lê Duẩn)',
      lat: 12.650645,
      lng: 108.022990,
      insidePoint: LatLng(12.65050, 108.02308),
      outsidePoint: LatLng(12.650645, 108.02285),
    ),
    CampusGate(
      id: 'back_gate',
      name: 'Cổng sau (Y Wang)',
      shortName: 'Cổng sau',
      lat: 12.648372,
      lng: 108.028044,
      insidePoint: LatLng(12.64850, 108.02798),
      outsidePoint: LatLng(12.64837195, 108.02804429),
    ),
  ];

  /// Tuyến đường trục giao thông chính bao quanh trường (Đường Lê Duẩn & Đường Y Wang)
  static const List<LatLng> perimeterLeDuan = [
    LatLng(12.64800, 108.02210),
    LatLng(12.64936, 108.02271),
    LatLng(12.650645, 108.022990), // Cổng Bệnh viện ĐH Tây Nguyên
    LatLng(12.651536, 108.023856), // Cổng chính (Lê Duẩn)
    LatLng(12.65267, 108.02494),
    LatLng(12.65386, 108.02579),
  ];

  static const List<LatLng> perimeterYWang = [
    LatLng(12.64650, 108.02650),
    LatLng(12.64748, 108.02705),
    LatLng(12.648372, 108.028044), // Cổng sau (Y Wang)
    LatLng(12.64950, 108.02925),
    LatLng(12.65013, 108.02963),
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

  static List<List<LatLng>> get defaultWalkways => campusDefaultWalkways;
}
