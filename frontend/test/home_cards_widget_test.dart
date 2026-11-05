import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_campus/core/widgets/nav_header.dart';
import 'package:smart_campus/core/widgets/wireframe_widgets.dart';
import 'package:smart_campus/features/grades/providers/grades_provider.dart';
import 'package:smart_campus/features/home/widgets/home_gpa_card.dart';

class _MockLoadingGradesNotifier extends GradesNotifier {
  @override
  GradesState build() => const GradesState(isLoading: true);
}

class _MockLoadedGradesNotifier extends GradesNotifier {
  @override
  GradesState build() {
    return const GradesState(
      isLoading: false,
      summary: GradesSummary(
        gpa4: 3.52,
        gpa10: 8.35,
        totalCredits: 75,
        academicRank: 'Giỏi',
      ),
    );
  }
}

void main() {
  group('Home & Navigation Components Widget Tests', () {
    testWidgets('NavHeader renders title, subtitle and custom border radius', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NavHeader(
              title: 'Trang chủ',
              subtitle: 'Đại học Tây Nguyên',
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
          ),
        ),
      );

      // Verify title & subtitle are rendered
      expect(find.text('Trang chủ'), findsOneWidget);
      expect(find.text('Đại học Tây Nguyên'), findsOneWidget);
      expect(find.byType(NavHeader), findsOneWidget);
    });

    testWidgets('HomeGpaCard renders WireframeGpaCard when loading', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gradesProvider.overrideWith(() => _MockLoadingGradesNotifier()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: HomeGpaCard(),
              ),
            ),
          ),
        ),
      );

      // In initial loading state, wireframe shimmer is displayed
      expect(find.byType(WireframeGpaCard), findsOneWidget);
    });

    testWidgets('HomeGpaCard renders grade information when loaded', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gradesProvider.overrideWith(() => _MockLoadedGradesNotifier()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: HomeGpaCard(),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // HomeGpaCard displays header text and metrics
      expect(find.text('Kết quả học tập'), findsOneWidget);
      expect(find.text('Tích lũy toàn khóa đào tạo'), findsOneWidget);
      expect(find.text('3.52'), findsOneWidget);
      expect(find.text('8.35'), findsOneWidget);
      expect(find.text('Giỏi'), findsOneWidget);
    });
  });
}
