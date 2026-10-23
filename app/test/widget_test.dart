import 'dart:async';

import 'package:anyone_can_cook/app.dart';
import 'package:anyone_can_cook/core/api_client.dart';
import 'package:anyone_can_cook/core/db/database.dart';
import 'package:anyone_can_cook/features/kitchen/backend_status.dart';
import 'package:anyone_can_cook/features/kitchen/kitchen_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget appWith({required Future<HealthStatus> Function() health}) {
  return ProviderScope(
    retry: (retryCount, error) => null,
    overrides: [
      healthProvider.overrideWith((ref) => health()),
      databaseReadyProvider.overrideWith((ref) async => 1),
    ],
    child: const App(),
  );
}

void main() {
  testWidgets('shows the Hebrew app name, RTL layout and demo-mode status',
      (tester) async {
    await tester.pumpWidget(appWith(
      health: () async =>
          const HealthStatus(status: 'ok', version: '0.1.0', aiProvider: 'mock'),
    ));
    await tester.pumpAndSettle();

    expect(find.text('לבשל כל אחד יכול'), findsOneWidget);
    expect(find.text('המטבח שלי'), findsOneWidget);
    expect(find.text('המשך בישול'), findsOneWidget);
    expect(find.text('המתכונים שלי'), findsOneWidget);
    expect(find.text('מועדפים'), findsOneWidget);
    expect(find.text('היסטוריית בישול'), findsOneWidget);
    expect(find.text('הגדרות'), findsOneWidget);
    expect(find.text('השרת מחובר ✓ · מצב הדגמה (ללא בינה מלאכותית)'), findsOneWidget);
    expect(find.text('מסד הנתונים מוכן (גרסה 1)'), findsOneWidget);

    final context = tester.element(find.byType(KitchenScreen));
    expect(Directionality.of(context), TextDirection.rtl);
  });

  testWidgets('shows live AI mode for a real provider', (tester) async {
    await tester.pumpWidget(appWith(
      health: () async =>
          const HealthStatus(status: 'ok', version: '0.1.0', aiProvider: 'gemini'),
    ));
    await tester.pumpAndSettle();

    expect(find.text('השרת מחובר ✓ · בינה מלאכותית מחוברת'), findsOneWidget);
    expect(find.textContaining('gemini'), findsNothing);
  });

  testWidgets('shows an offline message with retry when the backend fails',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(appWith(health: () async {
      calls++;
      throw Exception('offline');
    }));
    await tester.pumpAndSettle();

    expect(find.text('אין חיבור לשרת'), findsOneWidget);
    await tester.tap(find.text('נסו שוב'));
    await tester.pumpAndSettle();
    expect(calls, 2);
  });

  testWidgets('shows a waking-up message while the backend is slow',
      (tester) async {
    final never = Completer<HealthStatus>();
    await tester.pumpWidget(appWith(health: () => never.future));
    await tester.pump();

    expect(find.text('מתחבר לשרת…'), findsOneWidget);
    await tester.pump(BackendStatusCard.wakingUpAfter + const Duration(seconds: 1));
    expect(find.text('השרת מתעורר… זה יכול לקחת עד דקה'), findsOneWidget);
  });
}
