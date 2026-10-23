import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'database.g.dart';

/// Columns shared by every table so cloud sync can be added later without a
/// rewrite: client-generated UUID ids, timestamps, soft-delete tombstones and an
/// owner that stays null until accounts exist.
mixin SyncColumns on Table {
  TextColumn get id => text()();
  TextColumn get ownerId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// The original (imported, AI-analyzed) recipe.
class Recipes extends Table with SyncColumns {
  TextColumn get title => text()();
  TextColumn get customTitle => text().nullable()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  TextColumn get sourceType => text()(); // text | image | url | sample
  TextColumn get sourceUrl => text().nullable()();
  TextColumn get sourceText => text().nullable()();
  TextColumn get sourceImagePath => text().nullable()();
  TextColumn get analysisJson => text().nullable()();
  IntColumn get analysisSchemaVersion => integer().nullable()();
  BoolColumn get planStale => boolean().withDefault(const Constant(false))();
}

/// Approved cooking plans, stored separately from the recipe and versioned.
class Plans extends Table with SyncColumns {
  TextColumn get recipeId => text().references(Recipes, #id)();
  TextColumn get planJson => text()();
  IntColumn get planSchemaVersion => integer()();
  TextColumn get status => text()(); // approved | superseded
  DateTimeColumn get approvedAt => dateTime().nullable()();
  TextColumn get basedOnPlanId => text().nullable()();
}

class CookingSessions extends Table with SyncColumns {
  TextColumn get recipeId => text().references(Recipes, #id)();
  TextColumn get planId => text().references(Plans, #id)();
  TextColumn get status => text()(); // in_progress | completed | abandoned
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
}

/// Append-only cooking event log; session state is rebuilt by replaying it.
class SessionEvents extends Table with SyncColumns {
  TextColumn get sessionId => text().references(CookingSessions, #id)();
  IntColumn get seq => integer()();
  TextColumn get type => text()();
  TextColumn get payloadJson => text()();
  IntColumn get payloadSchemaVersion => integer()();
  DateTimeColumn get at => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {sessionId, seq},
      ];
}

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(
  tables: [Recipes, Plans, CookingSessions, SessionEvents, AppSettings],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'anyone_can_cook'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // Add a step per schema version here when the schema changes.
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Opens the database (running migrations) and returns its schema version.
final databaseReadyProvider = FutureProvider<int>((ref) async {
  final db = ref.watch(databaseProvider);
  await db.customSelect('SELECT 1').get();
  return db.schemaVersion;
});
