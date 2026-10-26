import 'package:anyone_can_cook/core/widgets/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/app_harness.dart';

/// Short messages at the bottom go away by themselves (real-device bug: "המתכון נמחק" stayed on
/// screen, because Flutter keeps a snack bar with an action until it is tapped). Undo stays
/// reachable while the message is shown, and with a screen reader the message waits for the user.
void main() {
  const deleted = 'המתכון נמחק';
  const undo = 'בטל';

  Future<String> deleteSample(WidgetTester tester, AppHarness h) async {
    final id = await h.seedSample();
    await tester.pumpWidget(h.build(initialLocation: '/recipes/$id'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('פעולות למתכון'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('מחיקת המתכון'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('מחיקה'));
    await tester.pump(); // the deletion
    await tester.pump(const Duration(milliseconds: 500)); // back home, the message slides in
    return id;
  }

  Future<bool> isDeleted(AppHarness h, String id) async =>
      (await (h.db.select(h.db.recipes)..where((r) => r.id.equals(id))).getSingle()).deletedAt != null;

  testApp('the deletion message offers undo, then disappears by itself after about 5 seconds', (tester, h) async {
    final id = await deleteSample(tester, h);
    expect(find.text(deleted), findsOneWidget);
    expect(find.widgetWithText(SnackBarAction, undo), findsOneWidget);
    expect(find.text('מה מבשלים היום?'), findsOneWidget); // on home
    expect(await isDeleted(h, id), isTrue);

    await tester.pump(const Duration(seconds: 4));
    expect(find.text(deleted), findsOneWidget); // still there, undo still possible
    await tester.pump(const Duration(seconds: 1, milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.text(deleted), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
    expect(await isDeleted(h, id), isTrue); // nothing undone by the timeout
  });

  testApp('undo while the message is shown restores the recipe and closes the message', (tester, h) async {
    final id = await deleteSample(tester, h);
    await tester.pump(const Duration(seconds: 3));
    await tester.tap(find.widgetWithText(SnackBarAction, undo));
    await tester.pumpAndSettle();
    expect(await isDeleted(h, id), isFalse);
    expect(find.text(deleted), findsNothing);
    expect(find.text('עוף בתנור עם תפוחי אדמה ואורז'), findsWidgets); // back in the list
  });

  testApp('with a screen reader, the message with undo waits for the user (accessibility)', (tester, h) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(accessibleNavigation: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final id = await deleteSample(tester, h);
    await tester.pump(const Duration(seconds: 20));
    expect(find.text(deleted), findsOneWidget);
    await tester.tap(find.widgetWithText(SnackBarAction, undo));
    await tester.pumpAndSettle();
    expect(await isDeleted(h, id), isFalse);
    expect(find.text(deleted), findsNothing);
  });

  testApp('leaving the screen does not leave the message stuck', (tester, h) async {
    await deleteSample(tester, h);
    GoRouter.of(tester.element(find.text('מה מבשלים היום?'))).push('/recipes');
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('repeated messages replace each other instead of piling up, and every one times out', (tester) async {
    late ScaffoldMessengerState messenger;
    await tester.pumpWidget(MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: Builder(builder: (context) {
          messenger = ScaffoldMessenger.of(context);
          return const SizedBox.expand();
        })),
      ),
    ));
    for (var i = 1; i <= 5; i++) {
      messenger.showMessage('הודעה $i');
      await tester.pump(const Duration(milliseconds: 300));
    }
    await tester.pumpAndSettle();
    expect(find.text('הודעה 5'), findsOneWidget);
    expect(find.text('הודעה 1'), findsNothing);
    // One default duration later, nothing is left (no queue of earlier messages behind it).
    await tester.pump(const Duration(seconds: 4, milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);

    // A message with an action times out too when no screen reader is on.
    messenger.showMessage('עם פעולה', action: SnackBarAction(label: undo, onPressed: () {}), duration: const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(tester.widget<SnackBar>(find.byType(SnackBar)).persist, isFalse);
    await tester.pump(const Duration(seconds: 5, milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
  });
}
