import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Finder button(String label) => find.widgetWithText(FilledButton, label);

Future<void> tapButton(WidgetTester tester, String label) async {
  // A SnackBar from the previous action can cover buttons near the bottom.
  tester.state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger)).removeCurrentSnackBar();
  await tester.pumpAndSettle();
  await expectSeen(tester, button(label));
  final finder = button(label).first;
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Expects [finder] somewhere in the screen's lazy list: scrolls to the top,
/// then down until it is built (off-screen list items are not built).
Future<void> expectSeen(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    final list = find.byType(Scrollable).first;
    await tester.drag(list, const Offset(0, 10000));
    await tester.pumpAndSettle();
    for (var i = 0; i < 30 && finder.evaluate().isEmpty; i++) {
      await tester.drag(list, const Offset(0, -300));
      await tester.pumpAndSettle();
    }
  }
  expect(finder, findsWidgets);
}
