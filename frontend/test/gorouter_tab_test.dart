import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('GoRouter StatefulShellRoute context.go changes currentIndex', (tester) async {
    int currentIdx = -1;

    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            currentIdx = navigationShell.currentIndex;
            return Scaffold(
              body: navigationShell,
              bottomNavigationBar: Text('CURRENT_INDEX_$currentIdx'),
            );
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  builder: (context, state) => Builder(
                    builder: (ctx) => ElevatedButton(
                      onPressed: () => ctx.go('/schedule'),
                      child: const Text('GO_TO_SCHEDULE'),
                    ),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/schedule',
                  builder: (context, state) => const Text('SCHEDULE_SCREEN'),
                ),
              ],
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    expect(find.text('CURRENT_INDEX_0'), findsOneWidget);

    await tester.tap(find.text('GO_TO_SCHEDULE'));
    await tester.pumpAndSettle();

    expect(find.text('SCHEDULE_SCREEN'), findsOneWidget);
    expect(find.text('CURRENT_INDEX_1'), findsOneWidget);
  });
}

