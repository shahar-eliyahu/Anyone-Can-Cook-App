import 'dart:convert';

import 'package:drift/drift.dart';

import '../core/db/database.dart';
import '../core/ids.dart';
import '../features/cooking/engine/action_dispatcher.dart';
import '../features/cooking/engine/events.dart';

class ActiveSessionExistsException implements Exception {
  const ActiveSessionExistsException(this.active);
  final SessionRow active;
}

abstract final class SessionStatus {
  static const inProgress = 'in_progress';
  static const completed = 'completed';
  static const abandoned = 'abandoned';
}

class HistoryEntry {
  const HistoryEntry(this.session, this.recipe);
  final SessionRow session;
  final RecipeRow recipe;
}

/// Cooking sessions and their append-only event logs.
class SessionRepository {
  SessionRepository(this._db, this._clock);

  final AppDatabase _db;
  final DateTime Function() _clock;

  DateTime _now() => _clock().toUtc();

  SimpleSelectStatement<$CookingSessionsTable, SessionRow> _activeQuery() =>
      _db.select(_db.cookingSessions)
        ..where((s) =>
            s.status.equals(SessionStatus.inProgress) & s.deletedAt.isNull())
        ..orderBy([(s) => OrderingTerm.desc(s.startedAt)])
        ..limit(1);

  Future<SessionRow?> activeSession() => _activeQuery().getSingleOrNull();

  Stream<SessionRow?> watchActiveSession() => _activeQuery().watchSingleOrNull();

  Future<SessionRow?> getSession(String id) =>
      (_db.select(_db.cookingSessions)
            ..where((s) => s.id.equals(id) & s.deletedAt.isNull()))
          .getSingleOrNull();

  Stream<SessionRow?> watchSession(String id) => (_db.select(_db.cookingSessions)
        ..where((s) => s.id.equals(id) & s.deletedAt.isNull()))
      .watchSingleOrNull();

  /// Starts a session and records `SessionStarted`. Only one session may be in
  /// progress at a time.
  Future<SessionRow> startSession({
    required String recipeId,
    required String planId,
  }) {
    return _db.transaction(() async {
      final active = await activeSession();
      if (active != null) throw ActiveSessionExistsException(active);
      final now = _truncate(_now());
      final id = newId();
      await _db.into(_db.cookingSessions).insert(CookingSessionsCompanion.insert(
            id: id,
            createdAt: now,
            updatedAt: now,
            recipeId: recipeId,
            planId: planId,
            status: SessionStatus.inProgress,
            startedAt: now,
          ));
      await appendEvent(id, SessionStarted(now));
      return (await getSession(id))!;
    });
  }

  Future<void> appendEvent(String sessionId, CookingEvent event) {
    return _db.transaction(() async {
      final maxSeq = _db.sessionEvents.seq.max();
      final last = await (_db.selectOnly(_db.sessionEvents)
            ..addColumns([maxSeq])
            ..where(_db.sessionEvents.sessionId.equals(sessionId)))
          .map((row) => row.read(maxSeq))
          .getSingle();
      final now = _now();
      await _db.into(_db.sessionEvents).insert(SessionEventsCompanion.insert(
            id: newId(),
            createdAt: now,
            updatedAt: now,
            sessionId: sessionId,
            seq: (last ?? 0) + 1,
            type: event.type,
            payloadJson: jsonEncode(event.toPayload()),
            payloadSchemaVersion: CookingEvent.payloadSchemaVersion,
            at: event.at,
          ));
      await (_db.update(_db.cookingSessions)..where((s) => s.id.equals(sessionId)))
          .write(CookingSessionsCompanion(updatedAt: Value(now)));
    });
  }

  Future<List<CookingEvent>> loadEvents(String sessionId) async {
    final rows = await (_db.select(_db.sessionEvents)
          ..where((e) => e.sessionId.equals(sessionId))
          ..orderBy([(e) => OrderingTerm.asc(e.seq)]))
        .get();
    return [
      for (final r in rows)
        CookingEvent.decode(
          r.type,
          jsonDecode(r.payloadJson) as Map<String, dynamic>,
          r.at,
        ),
    ];
  }

  CookingEventStore eventStoreFor(String sessionId) =>
      _SessionEventStore(this, sessionId);

  Future<void> complete(String sessionId, {String? notes}) =>
      _end(sessionId, SessionStatus.completed, notes: notes);

  Future<void> abandon(String sessionId) =>
      _end(sessionId, SessionStatus.abandoned);

  Future<void> _end(String sessionId, String status, {String? notes}) {
    final now = _now();
    return (_db.update(_db.cookingSessions)
          ..where((s) =>
              s.id.equals(sessionId) & s.status.equals(SessionStatus.inProgress)))
        .write(CookingSessionsCompanion(
      status: Value(status),
      endedAt: Value(now),
      notes: notes == null ? const Value.absent() : Value(notes),
      updatedAt: Value(now),
    ));
  }

  /// All sessions (newest first) with their recipes, excluding deleted ones.
  Stream<List<HistoryEntry>> watchHistory() {
    final query = _db.select(_db.cookingSessions).join([
      innerJoin(_db.recipes, _db.recipes.id.equalsExp(_db.cookingSessions.recipeId)),
    ])
      ..where(_db.cookingSessions.deletedAt.isNull() & _db.recipes.deletedAt.isNull())
      ..orderBy([OrderingTerm.desc(_db.cookingSessions.startedAt)]);
    return query.watch().map((rows) => [
          for (final row in rows)
            HistoryEntry(
              row.readTable(_db.cookingSessions),
              row.readTable(_db.recipes),
            ),
        ]);
  }

  static DateTime _truncate(DateTime t) {
    final ms = t.millisecondsSinceEpoch;
    return DateTime.fromMillisecondsSinceEpoch(ms - ms % 1000, isUtc: true);
  }
}

class _SessionEventStore implements CookingEventStore {
  _SessionEventStore(this._repo, this._sessionId);
  final SessionRepository _repo;
  final String _sessionId;

  @override
  Future<void> append(CookingEvent event) => _repo.appendEvent(_sessionId, event);
}
