import '../../../core/utils/gpa_calculator.dart';

class GradeItem {
  final int id;
  final String courseCode;
  final String courseName;
  final int credits;
  final double scoreOverall;
  final double? scoreAttendance;
  final double? scoreMidterm;
  final double? scorePractical;
  final double? scoreFinal;
  final String semester;

  // Thành phần chi tiết theo chuẩn Đại học Tây Nguyên (07_schedule & 12_grades_detail)
  final double? dbp;
  final double? thi1;
  final double? thi2;
  final double? d1;
  final double? d2;
  final String letter;
  final String? hocPhi;

  const GradeItem({
    required this.id,
    required this.courseCode,
    required this.courseName,
    required this.credits,
    required this.scoreOverall,
    this.scoreAttendance,
    this.scoreMidterm,
    this.scorePractical,
    this.scoreFinal,
    this.semester = 'HK1 (2026)',
    this.dbp,
    this.thi1,
    this.thi2,
    this.d1,
    this.d2,
    this.letter = 'X',
    this.hocPhi,
  });

  factory GradeItem.fromJson(Map<String, dynamic> json) {
    final score = (json['score_overall'] ?? json['score'] ?? json['diem_hp'] ?? 0.0) is num
        ? (json['score_overall'] ?? json['score'] ?? json['diem_hp'] ?? 0.0).toDouble()
        : double.tryParse((json['score_overall'] ?? json['score'] ?? json['diem_hp'] ?? '0').toString()) ?? 0.0;

    return GradeItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      courseCode: json['course_code'] ?? json['courseCode'] ?? json['code'] ?? '',
      courseName: json['course_name'] ?? json['courseName'] ?? json['ten_hp'] ?? json['name'] ?? '',
      credits: (json['credits'] as num?)?.toInt() ?? (json['so_tin_chi'] as num?)?.toInt() ?? 2,
      scoreOverall: score,
      scoreAttendance: (json['score_attendance'] as num?)?.toDouble(),
      scoreMidterm: (json['score_midterm'] as num?)?.toDouble(),
      scorePractical: (json['score_practical'] as num?)?.toDouble(),
      scoreFinal: (json['score_final'] as num?)?.toDouble(),
      semester: json['semester'] ?? json['hoc_ky'] ?? 'HK1 (2026)',
      dbp: (json['dbp'] ?? json['diem_dbp'] as num?)?.toDouble(),
      thi1: (json['thi1'] ?? json['diem_thi1'] as num?)?.toDouble(),
      thi2: (json['thi2'] ?? json['diem_thi2'] as num?)?.toDouble(),
      d1: (json['d1'] ?? json['diem_1'] as num?)?.toDouble(),
      d2: (json['d2'] ?? json['diem_2'] as num?)?.toDouble(),
      letter: json['letter'] ?? json['diem_chu'] ?? (score >= 8.5 ? 'A' : score >= 7.0 ? 'B' : score >= 5.5 ? 'C' : score >= 4.0 ? 'D' : (score > 0 ? 'F' : 'X')),
      hocPhi: json['hoc_phi'] ?? json['hocPhi'],
    );
  }

  GpaConversion get conversion => GpaCalculator.convert(scoreOverall);

  String get subjectName => courseName;
  double get score10 => scoreOverall;
  String get status => letter == 'X' || scoreOverall == 0
      ? 'Đang học'
      : (scoreOverall >= 4.0 ? 'Đạt' : 'Học lại');
}
