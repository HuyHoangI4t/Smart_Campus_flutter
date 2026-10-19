import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/gpa_calculator.dart';
import '../models/grade_model.dart';

class GradesState {
  final List<GradeItem> items;
  final String selectedSemester;
  final bool isLoading;
  final String? error;

  const GradesState({
    this.items = const [],
    this.selectedSemester = 'Tất cả',
    this.isLoading = false,
    this.error,
  });

  List<String> get availableSemesters {
    final sems = items.map((e) => e.semester).toSet().toList();
    return ['Tất cả', ...sems];
  }

  List<GradeItem> get filteredItems {
    if (selectedSemester == 'Tất cả') return items;
    return items.where((e) => e.semester == selectedSemester).toList();
  }

  double get averageScore10 {
    if (filteredItems.isEmpty) return 0.0;
    double total = 0;
    int credits = 0;
    for (final item in filteredItems) {
      total += item.scoreOverall * item.credits;
      credits += item.credits;
    }
    return credits > 0 ? total / credits : 0.0;
  }

  double get gpa4 {
    final list = filteredItems
        .map((e) => {'score': e.scoreOverall, 'credits': e.credits})
        .toList();
    return GpaCalculator.calculateGpa4(list);
  }

  int get totalCredits {
    return filteredItems.fold(0, (sum, item) => sum + item.credits);
  }

  GradesState copyWith({
    List<GradeItem>? items,
    String? selectedSemester,
    bool? isLoading,
    String? error,
  }) {
    return GradesState(
      items: items ?? this.items,
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
      final response = await _dio.get(ApiEndpoints.grades);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List list = response.data['data'] ?? [];
        final items = list.map((item) => GradeItem.fromJson(item)).toList();
        state = state.copyWith(items: items, isLoading: false);
      } else {
        _useFallbackMockData();
      }
    } catch (_) {
      _useFallbackMockData();
    }
  }

  void _useFallbackMockData() {
    final mockItems = [
      const GradeItem(
        id: 1,
        courseCode: '',
        courseName: 'An toàn thông tin',
        credits: 2,
        scoreOverall: 0.0,
        semester: 'HK1 (2026)',
        letter: 'X',
        hocPhi: 'Nợ: 1238000',
      ),
      const GradeItem(
        id: 2,
        courseCode: '',
        courseName: 'Quản trị mạng trên môi trường Windows',
        credits: 2,
        scoreOverall: 0.0,
        semester: 'HK1 (2026)',
        letter: 'X',
        hocPhi: 'Nợ: 1238000',
      ),
      const GradeItem(
        id: 3,
        courseCode: '',
        courseName: 'Thương mại điện tử',
        credits: 2,
        scoreOverall: 0.0,
        semester: 'HK1 (2026)',
        letter: 'X',
        hocPhi: 'Nợ: 1238000',
      ),
      const GradeItem(
        id: 4,
        courseCode: '',
        courseName: 'Những vấn đề hiện đại của CNTT',
        credits: 2,
        scoreOverall: 0.0,
        semester: 'HK1 (2026)',
        letter: 'X',
        hocPhi: 'Nợ: 1238000',
      ),
      const GradeItem(
        id: 5,
        courseCode: '',
        courseName: 'Cơ sở vật lý cho Tin học',
        credits: 2,
        scoreOverall: 6.9,
        dbp: 9.1,
        thi1: 5.5,
        d1: 6.9,
        semester: 'HK2 (2025)',
        letter: 'C',
        hocPhi: 'Nộp: 1100000',
      ),
      const GradeItem(
        id: 6,
        courseCode: '',
        courseName: 'Trí tuệ nhân tạo',
        credits: 2,
        scoreOverall: 9.0,
        dbp: 9.0,
        thi1: 9.0,
        d1: 9.0,
        semester: 'HK2 (2025)',
        letter: 'A',
        hocPhi: 'Nộp: 1100000',
      ),
      const GradeItem(
        id: 7,
        courseCode: '',
        courseName: 'Các quy trình phát triển phần mềm hiện đại',
        credits: 2,
        scoreOverall: 8.0,
        dbp: 8.0,
        thi1: 8.0,
        d1: 8.0,
        semester: 'HK2 (2025)',
        letter: 'B',
        hocPhi: 'Nộp: 1100000',
      ),
      const GradeItem(
        id: 8,
        courseCode: '',
        courseName: 'Nhập môn Hệ điều hành',
        credits: 2,
        scoreOverall: 8.5,
        dbp: 9.5,
        thi1: 8.0,
        d1: 8.5,
        semester: 'HK2 (2025)',
        letter: 'A',
        hocPhi: 'Nộp: 1100000',
      ),
    ];

    state = state.copyWith(items: mockItems, isLoading: false);
  }
}

final gradesProvider = NotifierProvider<GradesNotifier, GradesState>(GradesNotifier.new);

