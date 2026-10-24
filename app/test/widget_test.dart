import 'dart:async';

import 'package:anyone_can_cook/core/api_client.dart';
import 'package:anyone_can_cook/features/kitchen/backend_status.dart';
import 'package:anyone_can_cook/features/kitchen/kitchen_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_harness.dart';

void main() {
  testApp('home shows the Hebrew app name, RTL layout and demo-mode status', (tester, h) async {
    await tester.pumpWidget(h.build());
    await tester.pumpAndSettle();

    expect(find.text('לבשל כל אחד יכול'), findsOneWidget);
    expect(find.text('המטבח שלי'), findsOneWidget);
    expect(find.text('המשך בישול'), findsOneWidget);
    expect(find.text('אין בישול פעיל כרגע'), findsOneWidget);
    for (final tile in ['המתכונים שלי', 'מועדפים', 'היסטוריית בישול', 'הגדרות']) {
      expect(find.text(tile), findsOneWidget);
    }
    expect(find.text('השרת מחובר ✓ · מצב הדגמה (ללא בינה מלאכותית)'), findsOneWidget);
    expect(find.text('מסד הנתונים מוכן (גרסה 2)'), findsOneWidget); // schema v2 (Phase 2)

    final context = tester.element(find.byType(KitchenScreen));
    expect(Directionality.of(context), TextDirection.rtl);
  });

  testApp('shows live AI mode without English provider names', (tester, h) async {
    await tester.pumpWidget(h.build(
      health: () async => const HealthStatus(status: 'ok', version: '0.1.0', aiProvider: 'gemini'),
    ));
    await tester.pumpAndSettle();
    expect(find.text('השרת מחובר ✓ · בינה מלאכותית מחוברת'), findsOneWidget);
    expect(find.textContaining('gemini'), findsNothing);
  });

  testApp('offline backend shows retry and never blocks the app', (tester, h) async {
    var calls = 0;
    await tester.pumpWidget(h.build(health: () async {
      calls++;
      throw Exception('offline');
    }));
    await tester.pumpAndSettle();

    expect(find.text('אין חיבור לשרת'), findsOneWidget);
    await tester.tap(find.text('נסו שוב'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    // Navigation still works while offline.
    await tester.tap(find.text('המתכונים שלי'));
    await tester.pumpAndSettle();
    expect(find.text('אין מתכונים עדיין'), findsOneWidget);
  });

  testApp('shows a waking-up message while the backend is slow', (tester, h) async {
    final never = Completer<HealthStatus>();
    await tester.pumpWidget(h.build(health: () => never.future));
    await tester.pump();
    expect(find.text('מתחבר לשרת…'), findsOneWidget);
    await tester.pump(BackendStatusCard.wakingUpAfter + const Duration(seconds: 1));
    expect(find.text('השרת מתעורר… זה יכול לקחת עד דקה'), findsOneWidget);
  });
}
