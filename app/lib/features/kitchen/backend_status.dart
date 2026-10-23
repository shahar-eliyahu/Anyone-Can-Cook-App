import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/db/database.dart';
import '../../l10n/app_localizations.dart';

final healthProvider = FutureProvider<HealthStatus>(
  (ref) => ref.watch(apiClientProvider).getHealth(),
  retry: (retryCount, error) => null, // the user retries explicitly
);

/// Shows backend and local database status on the home screen.
class BackendStatusCard extends ConsumerStatefulWidget {
  const BackendStatusCard({super.key});

  static const wakingUpAfter = Duration(seconds: 5);

  @override
  ConsumerState<BackendStatusCard> createState() => _BackendStatusCardState();
}

class _BackendStatusCardState extends ConsumerState<BackendStatusCard> {
  Timer? _wakeTimer;
  bool _slow = false;

  @override
  void initState() {
    super.initState();
    _startWakeTimer();
  }

  void _startWakeTimer() {
    _wakeTimer?.cancel();
    _slow = false;
    _wakeTimer = Timer(BackendStatusCard.wakingUpAfter, () {
      if (mounted) setState(() => _slow = true);
    });
  }

  void _retry() {
    setState(_startWakeTimer);
    ref.invalidate(healthProvider);
  }

  @override
  void dispose() {
    _wakeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final health = ref.watch(healthProvider);
    final dbVersion = ref.watch(databaseReadyProvider);

    final Widget backendLine = switch (health) {
      AsyncData(:final value) => Text(
          '${l10n.backendOk} · ${_aiModeLabel(l10n, value.aiProvider)}',
        ),
      AsyncError() => Row(
          children: [
            Expanded(child: Text(l10n.backendOffline)),
            TextButton(onPressed: _retry, child: Text(l10n.retry)),
          ],
        ),
      _ => Row(
          children: [
            const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(_slow ? l10n.backendWakingUp : l10n.backendConnecting),
            ),
          ],
        ),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            backendLine,
            if (dbVersion case AsyncData(:final value)) ...[
              const SizedBox(height: 8),
              Text(l10n.databaseReady(value)),
            ],
          ],
        ),
      ),
    );
  }

  String _aiModeLabel(AppLocalizations l10n, String provider) => switch (provider) {
        'mock' => l10n.aiModeDemo,
        '' => l10n.aiModeUnknown,
        _ => l10n.aiModeLive,
      };
}
