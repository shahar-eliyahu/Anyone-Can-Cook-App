import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/motion.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/components.dart';
import '../../data/providers.dart';
import '../../data/recipe_repository.dart';
import '../../data/settings_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../models/recipe_analysis.dart';
import 'drafts_card.dart';
import 'image_store.dart';
import 'import_errors.dart';
import 'import_service.dart';

/// Import a recipe from pasted text, a photo, or a link (docs/PLAN.md, Phase 2).
class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  /// 0 text, 1 photo, 2 link.
  int _tab = 0;
  final _text = TextEditingController();
  final _url = TextEditingController();
  String? _imagePath;
  Uint8List? _imageBytes;
  ImportStage? _stage;
  bool _slow = false;
  Timer? _slowTimer;
  String? _message;
  bool _info = false; // _message is a notice, not an error
  bool _canRetry = false;

  /// The photo saved with the pending input (kept when the user leaves).
  String? _pendingImage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _ensurePrivacyNotice();
      await _restorePending();
    });
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
    // A photo picked but never sent is not kept; one saved with a failed attempt is.
    if (_imagePath != null && _imagePath != _pendingImage) {
      unawaited(ref.read(imageStoreProvider).delete(_imagePath));
    }
    _text.dispose();
    _url.dispose();
    super.dispose();
  }

  bool get _busy => _stage != null;

  /// Shown once, before the first import: what is sent to the AI service.
  Future<void> _ensurePrivacyNotice() async {
    final settings = ref.read(settingsRepositoryProvider);
    if (await settings.get(SettingKeys.importPrivacyAccepted) == 'true' || !mounted) return;
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.privacyTitle),
        content: Text(l10n.privacyBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.privacyAccept)),
        ],
      ),
    );
    if (ok == true) {
      await settings.set(SettingKeys.importPrivacyAccepted, 'true');
    } else if (mounted) {
      context.pop();
    }
  }

  /// Brings back the input of an attempt that didn't go through (e.g. AI quota used up).
  Future<void> _restorePending() async {
    final pending = await ref.read(importServiceProvider).pendingInput();
    if (pending == null || !mounted) return;
    final image = pending.imagePath;
    // Sync read: the file is small, and this keeps widget tests deterministic.
    final bytes = image != null && File(image).existsSync() ? File(image).readAsBytesSync() : null;
    final l10n = AppLocalizations.of(context);
    setState(() {
      if (pending.text case final t?) {
        _text.text = t;
        _tab = 0;
      } else if (pending.url case final u?) {
        _url.text = u;
        _tab = 2;
      } else if (bytes != null) {
        _imagePath = _pendingImage = image;
        _imageBytes = bytes;
        _tab = 1;
      } else {
        return;
      }
      _message = l10n.importRestored;
      _info = true;
    });
  }

  Future<void> _pickPhoto({required bool camera}) async {
    final picked = await ref.read(photoPickerProvider)(camera: camera);
    if (picked == null) return;
    final images = ref.read(imageStoreProvider);
    final (path, bytes) = await images.saveCompressed(picked);
    await images.delete(_imagePath);
    if (!mounted) return;
    setState(() {
      _imagePath = path;
      _imageBytes = bytes;
      _message = null;
    });
  }

  Future<void> _removePhoto() async {
    if (_imagePath == _pendingImage) {
      await ref.read(importServiceProvider).clearPending();
      _pendingImage = null;
    }
    await ref.read(imageStoreProvider).delete(_imagePath);
    setState(() => _imagePath = _imageBytes = null);
  }

  ImportSource? get _source => switch (_tab) {
        0 when _text.text.trim().isNotEmpty => ImportSource.text(_text.text.trim()),
        1 when _imagePath != null => ImportSource.image(_imagePath!, _imageBytes!),
        2 when _url.text.trim().isNotEmpty => ImportSource.url(_url.text.trim()),
        _ => null,
      };

  Future<void> _analyze() async {
    final l10n = AppLocalizations.of(context);
    final source = _source;
    if (source == null) return;
    if (source.type == SourceType.url && Uri.tryParse(source.url!)?.hasScheme != true) {
      setState(() => _message = l10n.errInvalidUrl);
      return;
    }
    final service = ref.read(importServiceProvider);

    final duplicate = await service.findDuplicate(source);
    if (duplicate != null && mounted) {
      final again = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.importDuplicateTitle),
          content: Text(l10n.importDuplicateBody(duplicate.displayTitle)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
            TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.importAgain)),
            FilledButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.importOpenExisting)),
          ],
        ),
      );
      if (again == null || !mounted) return;
      if (!again) {
        if (duplicate.isDraft) {
          await openDraft(context, ref, duplicate.id, replace: true);
        } else {
          context.pushReplacement('/recipes/${duplicate.id}');
        }
        return;
      }
    }

    setState(() {
      _stage = ImportStage.reading;
      _message = null;
      _info = _canRetry = false;
      _slow = false;
    });
    _slowTimer = Timer(const Duration(seconds: 12), () {
      if (mounted) setState(() => _slow = true);
    });
    try {
      if (source.type == SourceType.image) _pendingImage = source.imagePath;
      final outcome = await service.analyze(source, onStage: (s) {
        if (mounted) setState(() => _stage = s);
      });
      _imagePath = _imageBytes = _pendingImage = null; // now owned by the draft (or already deleted)
      if (!mounted) return;
      switch (outcome) {
        case ImportNotRecipe(:final reasonHe):
          setState(() => _message = [l10n.importNotRecipe, ?reasonHe].join('\n'));
        case ImportNeedsAnswers(:final draftId):
          context.pushReplacement('/drafts/$draftId/clarify');
        case ImportPlanReady(:final draftId):
          context.pushReplacement('/recipes/$draftId');
        case ImportPlanFailed(:final draftId, :final error):
          // The recipe is saved; the draft's screen retries only the plan.
          context.pushReplacement('/drafts/$draftId/clarify', extra: error);
      }
    } catch (e) {
      // The input (and photo) stays, on screen and saved, for a retry; nothing is retried automatically.
      if (mounted) {
        setState(() {
          _message = importErrorText(l10n, e);
          _canRetry = isRetryable(e);
        });
      }
    } finally {
      _slowTimer?.cancel();
      if (mounted) setState(() => _stage = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AppScaffold(
      title: l10n.importTitle,
      bottomBar: _busy
          ? null
          : FilledButton.icon(
              onPressed: _source == null ? null : _analyze,
              icon: Icon(_canRetry ? Icons.refresh_rounded : Icons.menu_book_rounded),
              label: Text(_canRetry ? l10n.importRetry : l10n.importAnalyze),
            ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.page, Space.s, Space.page, Space.xl),
        children: [
          Text(l10n.importIntro, style: theme.textTheme.titleLarge),
          const SizedBox(height: Space.m),
          IgnorePointer(
            ignoring: _busy,
            child: SegmentedButton<int>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: 0, icon: const Icon(Icons.notes_rounded), label: Text(l10n.importTabText)),
                ButtonSegment(value: 1, icon: const Icon(Icons.photo_camera_outlined), label: Text(l10n.importTabPhoto)),
                ButtonSegment(value: 2, icon: const Icon(Icons.link_rounded), label: Text(l10n.importTabUrl)),
              ],
              selected: {_tab},
              onSelectionChanged: (v) => setState(() => _tab = v.first),
            ),
          ),
          const SizedBox(height: Space.l),
          AnimatedSwitcher(
            duration: Motion.of(context, Motion.medium),
            child: KeyedSubtree(key: ValueKey(_tab), child: _input(l10n, theme)),
          ),
          if (_busy) ...[
            const SizedBox(height: Space.l),
            StageLoader(
              stages: [l10n.importStageReading, l10n.importStagePlanning],
              current: _stage == ImportStage.planning ? 1 : 0,
              note: _slow ? '${l10n.importStageSlow} ${l10n.importLeaveNote}' : null,
              action: _slow
                  ? Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: OutlinedButton(onPressed: () => context.pop(), child: Text(l10n.importLeave)),
                    )
                  : null,
            ),
          ],
          if (_message case final m?) ...[
            const SizedBox(height: Space.m),
            NoteBanner(m, kind: _info ? NoteKind.info : NoteKind.warning),
          ],
        ],
      ),
    );
  }

  Widget _input(AppLocalizations l10n, ThemeData theme) => switch (_tab) {
        0 => TextField(
            controller: _text,
            enabled: !_busy,
            minLines: 8,
            maxLines: 16,
            maxLength: 20000,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(hintText: l10n.importTextHint, counterText: ''),
          ),
        1 => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: Space.m,
            children: [
              if (_imagePath != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(Radii.card),
                  child: Stack(
                    children: [
                      ColoredBox(
                        color: theme.colorScheme.surfaceContainer,
                        child: File(_imagePath!).existsSync()
                            ? Image.file(
                                File(_imagePath!),
                                height: 260,
                                fit: BoxFit.contain,
                                width: double.infinity,
                                errorBuilder: (_, _, _) => const SizedBox(height: 260, child: Icon(Icons.broken_image_outlined)),
                              )
                            : const SizedBox(height: 260, width: double.infinity, child: Center(child: Icon(Icons.image_outlined, size: 48))),
                      ),
                      if (!_busy)
                        PositionedDirectional(
                          top: Space.s,
                          end: Space.s,
                          child: IconButton.filledTonal(
                            tooltip: l10n.delete,
                            onPressed: _removePhoto,
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ),
                    ],
                  ),
                ),
              Row(
                spacing: Space.s,
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : () => _pickPhoto(camera: true),
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: Text(l10n.importTakePhoto),
                    ),
                  ),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : () => _pickPhoto(camera: false),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(l10n.importPickPhoto),
                    ),
                  ),
                ],
              ),
              Text(l10n.importPhotoNote, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        _ => TextField(
            controller: _url,
            enabled: !_busy,
            keyboardType: TextInputType.url,
            textDirection: TextDirection.ltr,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(hintText: l10n.importUrlHint, prefixIcon: const Icon(Icons.link_rounded)),
          ),
      };
}
