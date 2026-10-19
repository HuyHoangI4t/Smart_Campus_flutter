import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_campus/app/app.dart';

void main() {
  testWidgets('SmartCampusApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SmartCampusApp(),
      ),
    );

    expect(find.byType(SmartCampusApp), findsOneWidget);
  });
}
