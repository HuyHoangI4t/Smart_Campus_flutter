class GpaConversion {
  final double score10;
  final double score4;
  final String letterGrade;
  final String classification;

  const GpaConversion({
    required this.score10,
    required this.score4,
    required this.letterGrade,
    required this.classification,
  });
}

class GpaCalculator {
  GpaCalculator._();

  /// Quy đổi điểm từ thang 10 sang thang 4 và điểm chữ theo quy chế tín chỉ
  static GpaConversion convert(double score10) {
    if (score10 >= 8.5) {
      return GpaConversion(
        score10: score10,
        score4: 4.0,
        letterGrade: 'A',
        classification: 'Giỏi',
      );
    } else if (score10 >= 7.0) {
      return GpaConversion(
        score10: score10,
        score4: 3.0,
        letterGrade: 'B',
        classification: 'Khá',
      );
    } else if (score10 >= 5.5) {
      return GpaConversion(
        score10: score10,
        score4: 2.0,
        letterGrade: 'C',
        classification: 'Trung bình',
      );
    } else if (score10 >= 4.0) {
      return GpaConversion(
        score10: score10,
        score4: 1.0,
        letterGrade: 'D',
        classification: 'Yếu',
      );
    } else {
      return GpaConversion(
        score10: score10,
        score4: 0.0,
        letterGrade: 'F',
        classification: 'Kém (Học lại)',
      );
    }
  }

  /// Tính điểm trung bình tích lũy GPA hệ 4 từ danh sách môn học
  static double calculateGpa4(List<Map<String, dynamic>> courses) {
    double totalWeightedScore = 0.0;
    int totalCredits = 0;

    for (final course in courses) {
      final double score = (course['score'] as num?)?.toDouble() ?? 0.0;
      final int credits = (course['credits'] as num?)?.toInt() ?? 0;

      if (credits > 0) {
        final conv = convert(score);
        totalWeightedScore += conv.score4 * credits;
        totalCredits += credits;
      }
    }

    if (totalCredits == 0) return 0.0;
    return totalWeightedScore / totalCredits;
  }
}

