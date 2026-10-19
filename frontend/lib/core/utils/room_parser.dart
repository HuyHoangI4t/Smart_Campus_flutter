class ParsedCampusRoom {
  final String raw;
  final String buildingCode;
  final String floor;
  final String roomNumber;
  final String fullDisplay;
  final String routeGuide;

  const ParsedCampusRoom({
    required this.raw,
    required this.buildingCode,
    required this.floor,
    required this.roomNumber,
    required this.fullDisplay,
    required this.routeGuide,
  });

  static ParsedCampusRoom empty() => const ParsedCampusRoom(
        raw: '',
        buildingCode: '',
        floor: '',
        roomNumber: '',
        fullDisplay: '',
        routeGuide: '',
      );
}

class CampusRoomParser {
  CampusRoomParser._();

  static ParsedCampusRoom parse(String roomRaw) {
    final raw = roomRaw.trim();
    if (raw.isEmpty) return ParsedCampusRoom.empty();

    // Chuẩn hóa loại bỏ các tiền tố
    final clean = raw.replaceAll(RegExp(r'^(?:Phòng|PHÒNG|PHONG|P\.|P)\s*', caseSensitive: false), '').trim();

    // 1. Dạng 3 phần: <Nhà>.<Tầng>.<Phòng> (ví dụ: 8.3.4, 7.3.18, 5.1.2)
    final match3 = RegExp(r'^(\d+)\s*\.\s*(\d+)\s*\.\s*([0-9A-Za-z_-]+)').firstMatch(clean);
    if (match3 != null) {
      final bNum = match3.group(1)!;
      final fNum = match3.group(2)!;
      final rNum = match3.group(3)!;
      final bCode = 'Nhà học số $bNum';
      final fText = 'Tầng $fNum';
      final rText = 'Phòng $rNum';

      return ParsedCampusRoom(
        raw: raw,
        buildingCode: bCode,
        floor: fText,
        roomNumber: rText,
        fullDisplay: '$bCode • $fText • $rText',
        routeGuide: 'Cổng trường ➔ Sảnh $bCode ➔ Lên $fText ➔ $rText',
      );
    }

    // 2. Dạng 2 phần: <Nhà>.<Phòng> (ví dụ: 2.20, 6.01)
    final match2 = RegExp(r'^(\d+)\s*\.\s*([0-9A-Za-z_-]+)').firstMatch(clean);
    if (match2 != null) {
      final bNum = match2.group(1)!;
      final rNum = match2.group(2)!;
      final bCode = 'Nhà học số $bNum';
      String fText = 'Tầng 1';

      if (rNum.length >= 2) {
        final firstChar = rNum[0];
        final floorNum = int.tryParse(firstChar);
        if (floorNum != null && floorNum > 0) {
          fText = 'Tầng $floorNum';
        }
      }

      return ParsedCampusRoom(
        raw: raw,
        buildingCode: bCode,
        floor: fText,
        roomNumber: 'Phòng $rNum',
        fullDisplay: '$bCode • $fText • Phòng $rNum',
        routeGuide: 'Cổng trường ➔ Sảnh $bCode ➔ $fText ➔ Phòng $rNum',
      );
    }

    return ParsedCampusRoom(
      raw: raw,
      buildingCode: 'Khuôn viên',
      floor: '',
      roomNumber: raw,
      fullDisplay: raw,
      routeGuide: 'Di chuyển theo biển chỉ dẫn tới $raw',
    );
  }
}

