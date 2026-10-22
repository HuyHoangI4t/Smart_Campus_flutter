import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/gpa_calculator.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/grade_model.dart';

class GradesSummary {
  final int totalCredits;
  final int accumulatedCredits;
  final int inProgressCredits;
  final int unlearnedCredits;
  final double gpa10;
  final double gpa4;
  final String academicRank;
  final int totalCourses;
  final int passedCourses;
  final int inProgressCourses;
  final int failedCourses;

  const GradesSummary({
    this.totalCredits = 0,
    this.accumulatedCredits = 0,
    this.inProgressCredits = 0,
    this.unlearnedCredits = 0,
    this.gpa10 = 0.0,
    this.gpa4 = 0.0,
    this.academicRank = '',
    this.totalCourses = 0,
    this.passedCourses = 0,
    this.inProgressCourses = 0,
    this.failedCourses = 0,
  });

  factory GradesSummary.fromJson(Map<String, dynamic> json) {
    final g10 = (json['gpa10'] is num)
        ? (json['gpa10'] as num).toDouble()
        : double.tryParse(json['gpa10']?.toString() ?? '0.0') ?? 0.0;
    final g4 = (json['gpa4'] is num)
        ? (json['gpa4'] as num).toDouble()
        : double.tryParse(json['gpa4']?.toString() ?? '0.0') ?? 0.0;

    final rankObj = json['academicRank'];
    final rank = rankObj is Map
        ? (rankObj['label']?.toString() ?? '')
        : (rankObj?.toString() ?? '');

    return GradesSummary(
      totalCredits: (json['totalCredits'] as num?)?.toInt() ?? 0,
      accumulatedCredits: (json['accumulatedCredits'] as num?)?.toInt() ?? 0,
      inProgressCredits: (json['inProgressCredits'] as num?)?.toInt() ?? 0,
      unlearnedCredits: (json['unlearnedCredits'] as num?)?.toInt() ??
          (json['remainingCredits'] as num?)?.toInt() ??
          0,
      gpa10: g10,
      gpa4: g4,
      academicRank: rank,
      totalCourses: (json['totalCourses'] as num?)?.toInt() ?? 0,
      passedCourses: (json['passedCourses'] as num?)?.toInt() ?? 0,
      inProgressCourses: (json['inProgressCourses'] as num?)?.toInt() ?? 0,
      failedCourses: (json['failedCourses'] as num?)?.toInt() ?? 0,
    );
  }
}

class GradesState {
  final List<GradeItem> items;
  final GradesSummary summary;
  final Map<String, dynamic> semesterStats;
  final List<String> semesters;
  final String selectedSemester;
  final bool isLoading;
  final String? error;

  const GradesState({
    this.items = const [],
    this.summary = const GradesSummary(),
    this.semesterStats = const {},
    this.semesters = const ['Tất cả'],
    this.selectedSemester = 'Tất cả',
    this.isLoading = false,
    this.error,
  });

  List<String> get availableSemesters {
    if (semesters.isNotEmpty && semesters.length > 1) {
      return semesters;
    }
    final sems = items.map((e) => e.semester).toSet().toList();
    return ['Tất cả', ...sems];
  }

  List<GradeItem> get filteredItems {
    if (selectedSemester == 'Tất cả') return items;
    return items.where((e) => e.semester == selectedSemester).toList();
  }

  double get averageScore10 {
    if (selectedSemester == 'Tất cả') {
      return summary.gpa10;
    }
    final sem = semesterStats[selectedSemester];
    if (sem != null && sem['gpa10'] != null) {
      return double.tryParse(sem['gpa10'].toString()) ?? 0.0;
    }
    if (filteredItems.isEmpty) return 0.0;
    double total = 0;
    int credits = 0;
    for (final item in filteredItems) {
      if (item.scoreOverall >= 4.0 && item.letter != 'P' && item.letter != 'X') {
        total += item.scoreOverall * item.credits;
        credits += item.credits;
      }
    }
    return credits > 0 ? total / credits : 0.0;
  }

  double get gpa4 {
    if (selectedSemester == 'Tất cả') {
      return summary.gpa4;
    }
    final sem = semesterStats[selectedSemester];
    if (sem != null && sem['gpa4'] != null) {
      return double.tryParse(sem['gpa4'].toString()) ?? 0.0;
    }
    final list = filteredItems
        .where((e) => e.letter != 'X' && e.letter != 'P')
        .map((e) => {'score': e.scoreOverall, 'credits': e.credits})
        .toList();
    return GpaCalculator.calculateGpa4(list);
  }

  int get accumulatedCredits {
    if (selectedSemester == 'Tất cả') {
      return summary.accumulatedCredits;
    }
    final sem = semesterStats[selectedSemester];
    if (sem != null && sem['accumulatedCredits'] != null) {
      return (sem['accumulatedCredits'] as num).toInt();
    }
    return filteredItems
        .where((e) => e.letter != 'X' && e.letter != 'F')
        .fold(0, (sum, item) => sum + item.credits);
  }

  int get inProgressCredits {
    if (selectedSemester == 'Tất cả') {
      return summary.inProgressCredits;
    }
    final sem = semesterStats[selectedSemester];
    if (sem != null && sem['inProgressCredits'] != null) {
      return (sem['inProgressCredits'] as num).toInt();
    }
    return filteredItems
        .where((e) => e.letter == 'X')
        .fold(0, (sum, item) => sum + item.credits);
  }

  int get unlearnedCredits => inProgressCredits;

  int get totalCredits {
    if (selectedSemester == 'Tất cả') {
      return summary.accumulatedCredits > 0 ? summary.accumulatedCredits : summary.totalCredits;
    }
    return accumulatedCredits;
  }

  String get academicRank {
    if (selectedSemester == 'Tất cả') {
      return summary.academicRank;
    }
    final sem = semesterStats[selectedSemester];
    if (sem != null && sem['academicRank'] != null) {
      final r = sem['academicRank'];
      return r is Map ? (r['label'] ?? 'Khá') : r.toString();
    }
    return summary.academicRank;
  }

  GradesState copyWith({
    List<GradeItem>? items,
    GradesSummary? summary,
    Map<String, dynamic>? semesterStats,
    List<String>? semesters,
    String? selectedSemester,
    bool? isLoading,
    String? error,
  }) {
    return GradesState(
      items: items ?? this.items,
      summary: summary ?? this.summary,
      semesterStats: semesterStats ?? this.semesterStats,
      semesters: semesters ?? this.semesters,
      selectedSemester: selectedSemester ?? this.selectedSemester,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class GradesNotifier extends Notifier<GradesState> {
  Dio get _dio => ref.read(dioProvider);

  @override
  GradesState build() {
    Future.microtask(() => fetchGrades());
    return const GradesState(isLoading: true);
  }

  void selectSemester(String semester) {
    state = state.copyWith(selectedSemester: semester);
  }

  Future<void> fetchGrades() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = ref.read(authProvider).user;
      final mssv = (user != null && !user.isGuest) ? user.studentId : null;
      final response = await _dio.get(
        ApiEndpoints.grades,
        queryParameters: mssv != null ? {'mssv': mssv} : null,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List list = response.data['data'] ?? [];
        final items = list.map((item) => GradeItem.fromJson(item)).toList();

        GradesSummary summary = state.summary;
        if (response.data['summary'] is Map<String, dynamic>) {
          summary = GradesSummary.fromJson(response.data['summary'] as Map<String, dynamic>);
        }

        Map<String, dynamic> semStats = {};
        if (response.data['semesterStats'] is Map<String, dynamic>) {
          semStats = response.data['semesterStats'] as Map<String, dynamic>;
        }

        List<String> semesters = state.semesters;
        if (response.data['semesters'] is List) {
          semesters = (response.data['semesters'] as List).map((e) => e.toString()).toList();
        }

        state = state.copyWith(
          items: items,
          summary: summary,
          semesterStats: semStats,
          semesters: semesters,
          isLoading: false,
        );
      } else {
        state = state.copyWith(items: const [], isLoading: false);
      }
    } catch (_) {
      state = state.copyWith(items: const [], isLoading: false);
    }
  }

}

final gradesProvider = NotifierProvider<GradesNotifier, GradesState>(GradesNotifier.new);

