import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseHelper {
  // Weight logs table name
  static const weightLogsTable = 'weight_logs';
  // Insert a weight log (web: SharedPreferences, native: SQLite)
  Future<int> insertWeightLog(Map<String, Object?> values) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final listJson = prefs.getStringList('gp1_weight_logs') ?? <String>[];
      final list = listJson.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
      final newId = await _nextId();
      final map = Map<String, Object?>.from(values)..['id'] = newId;
      list.insert(0, map.cast<String, dynamic>());
      await prefs.setStringList('gp1_weight_logs', list.map((m) => jsonEncode(m)).toList());
      profileNotifier.value = profileNotifier.value + 1;
      return newId;
    }
    final db = await database;
    final id = await db.insert(weightLogsTable, values);
    profileNotifier.value = profileNotifier.value + 1;
    return id;
  }

  // Get weight logs (optionally for a specific day)
  Future<List<Map<String, Object?>>> getWeightLogs({DateTime? day}) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final listJson = prefs.getStringList('gp1_weight_logs') ?? <String>[];
      final list = listJson.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
      if (day == null) return List<Map<String, Object?>>.from(list);
      final start = DateTime(day.year, day.month, day.day).millisecondsSinceEpoch;
      final end = DateTime(day.year, day.month, day.day, 23, 59, 59).millisecondsSinceEpoch;
      return list.where((m) {
        final d = m['date'] as int? ?? 0;
        return d >= start && d <= end;
      }).map((m) => m.cast<String, Object?>()).toList();
    }
    final db = await database;
    if (day == null) return await db.query(weightLogsTable, orderBy: 'date DESC');
    final start = DateTime(day.year, day.month, day.day).millisecondsSinceEpoch;
    final end = DateTime(day.year, day.month, day.day, 23, 59, 59).millisecondsSinceEpoch;
    return await db.query(weightLogsTable, where: 'date BETWEEN ? AND ?', whereArgs: [start, end], orderBy: 'date DESC');
  }
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // Notifiers so UI can listen for data changes and refresh dynamically.
  // Increment the int value to notify listeners. Using simple int notifiers
  // avoids creating many StreamControllers and is easy to consume in widgets.
  final ValueNotifier<int> workoutsNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> caloriesNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> profileNotifier = ValueNotifier<int>(0);

  static const _dbName = 'group_project_1.db';
  static const _dbVersion = 1;

  static const profileTable = 'profile';
  static const workoutsTable = 'workouts';
  static const caloriesTable = 'calories';
  static const templatesTable = 'templates';

  Database? _db;

  // Helper to compare ids that may come from JSON (int, double, or string)
  bool _idEquals(dynamic a, int id) {
    if (a == null) return false;
    if (a is int) return a == id;
    if (a is num) return a.toInt() == id;
    if (a is String) {
      final parsed = int.tryParse(a);
      return parsed != null && parsed == id;
    }
    return false;
  }

  // Generate a compact, safe integer id for web storage to avoid JS numeric
  // precision issues. On web we keep a small auto-increment counter in
  // SharedPreferences under the key 'gp1_next_id'. On non-web platforms this
  // method returns a millisecond-based id as a fallback (though sqlite
  // autoincrement is typically used there).
  Future<int> _nextId() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final key = 'gp1_next_id';
      final next = prefs.getInt(key) ?? 1;
      await prefs.setInt(key, next + 1);
      return next;
    }
    return DateTime.now().millisecondsSinceEpoch;
  }

  // Public accessor for next id (convenience)
  Future<int> nextId() => _nextId();
  // No in-memory fallback needed any more; profile will be persisted via
  // SharedPreferences (web + mobile). SQLite is kept as a fallback/sync on
  // non-web platforms so existing DB consumers remain compatible.

  Future<Database> get database async {
    // SQLite is not available on web. Guard here to avoid calling
    // path_provider / sqflite APIs in a web runtime where they are not
    // implemented (causes MissingPluginException). All web callers
    // should use the SharedPreferences-backed branches in this class.
    if (kIsWeb) {
      throw UnsupportedError('SQLite is not available on the web. Use DatabaseHelper web methods backed by SharedPreferences.');
    }

    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      // Shouldn't reach here; callers must use web branches instead of sqlite.
      throw UnsupportedError('initDatabase called on web - sqlite is not supported in web builds.');
    }

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _dbName);
    return await openDatabase(path,
        version: _dbVersion, onCreate: _onCreate, onConfigure: _onConfigure);
  }

  FutureOr<void> _onConfigure(Database db) async {
    // enable foreign key support for cascade deletes
    await db.execute('PRAGMA foreign_keys = ON');
  }

  FutureOr<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $profileTable (
        id INTEGER PRIMARY KEY,
        name TEXT,
        age INTEGER,
        sex TEXT,
        weight REAL,
        height REAL,
        bmr REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE $weightLogsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        weight REAL NOT NULL,
        date INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $workoutsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        type TEXT NOT NULL,
        minutes INTEGER NOT NULL,
        reps INTEGER,
        calories INTEGER NOT NULL,
        notes TEXT,
        date INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $caloriesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        calories INTEGER NOT NULL,
        date INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $templatesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        type TEXT NOT NULL,
        minutes INTEGER NOT NULL,
        reps INTEGER,
        calories INTEGER NOT NULL,
        notes TEXT,
        time TEXT
      )
    ''');

    // Plans normalized schema: plans, plan_entries and plan_entry_templates
    await db.execute('''
      CREATE TABLE plans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE plan_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plan_id INTEGER NOT NULL,
        day_offset INTEGER NOT NULL,
        FOREIGN KEY(plan_id) REFERENCES plans(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE plan_entry_templates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entry_id INTEGER NOT NULL,
        template_id INTEGER NOT NULL,
        FOREIGN KEY(entry_id) REFERENCES plan_entries(id) ON DELETE CASCADE,
        FOREIGN KEY(template_id) REFERENCES $templatesTable(id) ON DELETE CASCADE
      )
    ''');
  }

  // Profile CRUD (single row expected)
  Future<void> upsertProfile(Map<String, Object?> values) async {
    // Persist profile to SharedPreferences (works on web + mobile).
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gp1_profile', jsonEncode(values));

  // notify listeners that profile changed
  profileNotifier.value = profileNotifier.value + 1;

    // Also write to sqlite when available (non-web). This keeps the sqlite
    // `profile` table in sync for parts of the app that may still inspect it.
    if (!kIsWeb) {
      final db = await database;
      final existing = await db.query(profileTable, where: 'id = ?', whereArgs: [1]);
      if (existing.isEmpty) {
        await db.insert(profileTable, {...values, 'id': 1});
      } else {
        await db.update(profileTable, values, where: 'id = ?', whereArgs: [1]);
      }
    }
  }

  Future<Map<String, Object?>?> getProfile() async {
    // Prefer SharedPreferences (quick and works on web). If nothing stored
    // there and sqlite is available, fall back to sqlite (helps for older
    // installs that only wrote to the DB).
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString('gp1_profile');
    if (s != null) {
      final decoded = jsonDecode(s) as Map<String, dynamic>;
      // Convert to Map<String, Object?> expected by callers.
      return decoded.map((k, v) => MapEntry(k, v as Object?));
    }

    if (kIsWeb) return null;

    final db = await database;
    final rows = await db.query(profileTable, where: 'id = ?', whereArgs: [1]);
    if (rows.isEmpty) return null;
    // Sync DB row into SharedPreferences for future fast reads
    final row = rows.first;
    await prefs.setString('gp1_profile', jsonEncode(row));
    return row;
  }

  Future<int> insertWorkout(Map<String, Object?> values) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final listJson = prefs.getStringList('gp1_workouts') ?? <String>[];
      final list = listJson.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
  final newId = await _nextId();
      final map = Map<String, Object?>.from(values)..['id'] = newId;
      list.insert(0, map.cast<String, dynamic>());
      await prefs.setStringList('gp1_workouts', list.map((m) => jsonEncode(m)).toList());
      // notify listeners that workouts changed
      workoutsNotifier.value = workoutsNotifier.value + 1;
      return newId;
    }

    final db = await database;
    final id = await db.insert(workoutsTable, values);
    workoutsNotifier.value = workoutsNotifier.value + 1;
    return id;
  }

  Future<int> updateWorkout(int id, Map<String, Object?> values) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final listJson = prefs.getStringList('gp1_workouts') ?? <String>[];
      final list = listJson.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
      var found = false;
      for (var i = 0; i < list.length; i++) {
        if (_idEquals(list[i]['id'], id)) {
          final merged = Map<String, Object?>.from(list[i])..addAll(values);
          list[i] = merged.cast<String, dynamic>();
          found = true;
          break;
        }
      }
      if (found) await prefs.setStringList('gp1_workouts', list.map((m) => jsonEncode(m)).toList());
      if (found) workoutsNotifier.value = workoutsNotifier.value + 1;
      return found ? 1 : 0;
    }

    final db = await database;
    final count = await db.update(workoutsTable, values, where: 'id = ?', whereArgs: [id]);
    if (count > 0) workoutsNotifier.value = workoutsNotifier.value + 1;
    return count;
  }

  Future<List<Map<String, Object?>>> getWorkouts({DateTime? day}) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final listJson = prefs.getStringList('gp1_workouts') ?? <String>[];
      final list = listJson.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
      if (day == null) return List<Map<String, Object?>>.from(list);
      final start = DateTime(day.year, day.month, day.day).millisecondsSinceEpoch;
      final end = DateTime(day.year, day.month, day.day, 23, 59, 59).millisecondsSinceEpoch;
      return list.where((m) {
        final d = m['date'] as int? ?? 0;
        return d >= start && d <= end;
      }).map((m) => m.cast<String, Object?>()).toList();
    }

    final db = await database;
    if (day == null) return await db.query(workoutsTable, orderBy: 'date DESC');
    final start = DateTime(day.year, day.month, day.day).millisecondsSinceEpoch;
    final end = DateTime(day.year, day.month, day.day, 23, 59, 59).millisecondsSinceEpoch;
    return await db.query(workoutsTable, where: 'date BETWEEN ? AND ?', whereArgs: [start, end], orderBy: 'date DESC');
  }

  Future<int> insertCalorie(Map<String, Object?> values) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final listJson = prefs.getStringList('gp1_calories') ?? <String>[];
      final list = listJson.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
      final newId = await _nextId();
      final map = Map<String, Object?>.from(values)..['id'] = newId;
      list.insert(0, map.cast<String, dynamic>());
      await prefs.setStringList('gp1_calories', list.map((m) => jsonEncode(m)).toList());
      // notify listeners that calories changed
      caloriesNotifier.value = caloriesNotifier.value + 1;
      return newId;
    }

    final db = await database;
    final id = await db.insert(caloriesTable, values);
    // notify listeners that calories changed
    caloriesNotifier.value = caloriesNotifier.value + 1;
    return id;
  }

  Future<List<Map<String, Object?>>> getCalories({DateTime? day}) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final listJson = prefs.getStringList('gp1_calories') ?? <String>[];
      final list = listJson.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
      if (day == null) return List<Map<String, Object?>>.from(list);
      final start = DateTime(day.year, day.month, day.day).millisecondsSinceEpoch;
      final end = DateTime(day.year, day.month, day.day, 23, 59, 59).millisecondsSinceEpoch;
      return list.where((m) {
        final d = m['date'] as int? ?? 0;
        return d >= start && d <= end;
      }).map((m) => m.cast<String, Object?>()).toList();
    }

    final db = await database;
    if (day == null) return await db.query(caloriesTable, orderBy: 'date DESC');
    final start = DateTime(day.year, day.month, day.day).millisecondsSinceEpoch;
    final end = DateTime(day.year, day.month, day.day, 23, 59, 59).millisecondsSinceEpoch;
    return await db.query(caloriesTable, where: 'date BETWEEN ? AND ?', whereArgs: [start, end], orderBy: 'date DESC');
  }

  Future<int> deleteCalorie(int id) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final listJson = prefs.getStringList('gp1_calories') ?? <String>[];
      final list = listJson.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
      final newList = list.where((m) => !_idEquals(m['id'], id)).toList();
      await prefs.setStringList('gp1_calories', newList.map((m) => jsonEncode(m)).toList());
      // notify listeners that calories changed
      caloriesNotifier.value = caloriesNotifier.value + 1;
      return list.length - newList.length;
    }

    final db = await database;
    final count = await db.delete(caloriesTable, where: 'id = ?', whereArgs: [id]);
    if (count > 0) caloriesNotifier.value = caloriesNotifier.value + 1;
    return count;
  }

  Future<int> updateCalorie(int id, Map<String, Object?> values) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final listJson = prefs.getStringList('gp1_calories') ?? <String>[];
      final list = listJson.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
      var found = false;
      for (var i = 0; i < list.length; i++) {
        if (_idEquals(list[i]['id'], id)) {
          final merged = Map<String, Object?>.from(list[i])..addAll(values);
          list[i] = merged.cast<String, dynamic>();
          found = true;
          break;
        }
      }
      if (found) await prefs.setStringList('gp1_calories', list.map((m) => jsonEncode(m)).toList());
      // notify listeners that calories changed
      if (found) caloriesNotifier.value = caloriesNotifier.value + 1;
      return found ? 1 : 0;
    }

    final db = await database;
    final count = await db.update(caloriesTable, values, where: 'id = ?', whereArgs: [id]);
    if (count > 0) caloriesNotifier.value = caloriesNotifier.value + 1;
    return count;
  }

  Future<int> deleteWorkout(int id) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final listJson = prefs.getStringList('gp1_workouts') ?? <String>[];
      final list = listJson.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
      final newList = list.where((m) => !_idEquals(m['id'], id)).toList();
      await prefs.setStringList('gp1_workouts', newList.map((m) => jsonEncode(m)).toList());
      // notify listeners that workouts changed
      workoutsNotifier.value = workoutsNotifier.value + 1;
      return list.length - newList.length;
    }

    final db = await database;
    final count = await db.delete(workoutsTable, where: 'id = ?', whereArgs: [id]);
    if (count > 0) workoutsNotifier.value = workoutsNotifier.value + 1;
    return count;
  }

  // Templates
  Future<int> insertTemplate(Map<String, Object?> values) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final listJson = prefs.getStringList('gp1_templates') ?? <String>[];
      final list = listJson.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
  final newId = await _nextId();
      final map = Map<String, Object?>.from(values)..['id'] = newId;
      list.insert(0, map.cast<String, dynamic>());
      await prefs.setStringList('gp1_templates', list.map((m) => jsonEncode(m)).toList());
      return newId;
    }

    final db = await database;
    return await db.insert(templatesTable, values);
  }

  Future<int> updateTemplate(int id, Map<String, Object?> values) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final listJson = prefs.getStringList('gp1_templates') ?? <String>[];
      final list = listJson.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
      var found = false;
      for (var i = 0; i < list.length; i++) {
        if (_idEquals(list[i]['id'], id)) {
          final merged = Map<String, Object?>.from(list[i])..addAll(values);
          list[i] = merged.cast<String, dynamic>();
          found = true;
          break;
        }
      }
      if (found) await prefs.setStringList('gp1_templates', list.map((m) => jsonEncode(m)).toList());
      return found ? 1 : 0;
    }

    final db = await database;
    return await db.update(templatesTable, values, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteTemplate(int id) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final listJson = prefs.getStringList('gp1_templates') ?? <String>[];
      final list = listJson.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
      final newList = list.where((m) => !_idEquals(m['id'], id)).toList();
      await prefs.setStringList('gp1_templates', newList.map((m) => jsonEncode(m)).toList());
      return list.length - newList.length;
    }

    final db = await database;
    return await db.delete(templatesTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, Object?>>> getTemplates() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final listJson = prefs.getStringList('gp1_templates') ?? <String>[];
      return listJson.map((s) => Map<String, Object?>.from(jsonDecode(s) as Map<String, dynamic>)).toList();
    }

    final db = await database;
    return await db.query(templatesTable, orderBy: 'id DESC');
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) await db.close();
    _db = null;
  }

  // Plans helpers (normalized)
  Future<int> insertPlan(Map<String, Object?> values) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final listJson = prefs.getStringList('gp1_plans') ?? <String>[];
      final list = listJson.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
  final newId = await _nextId();
      final map = Map<String, Object?>.from(values)..['id'] = newId;
      map['entries'] = <Map<String, Object?>>[]; // placeholder for entries
      list.insert(0, map.cast<String, dynamic>());
      await prefs.setStringList('gp1_plans', list.map((m) => jsonEncode(m)).toList());
      return newId;
    }

    final db = await database;
    return await db.insert('plans', values);
  }

  Future<int> updatePlan(int id, Map<String, Object?> values) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final listJson = prefs.getStringList('gp1_plans') ?? <String>[];
      final list = listJson.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
      var found = false;
      for (var i = 0; i < list.length; i++) {
        if (list[i]['id'] == id) {
          final merged = Map<String, Object?>.from(list[i])..addAll(values);
          list[i] = merged.cast<String, dynamic>();
          found = true;
          break;
        }
      }
      if (found) await prefs.setStringList('gp1_plans', list.map((m) => jsonEncode(m)).toList());
      return found ? 1 : 0;
    }

    final db = await database;
    return await db.update('plans', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deletePlan(int id) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final listJson = prefs.getStringList('gp1_plans') ?? <String>[];
      final list = listJson.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
      final newList = list.where((m) => m['id'] != id).toList();
      await prefs.setStringList('gp1_plans', newList.map((m) => jsonEncode(m)).toList());
      return list.length - newList.length;
    }

    final db = await database;
    // with foreign keys enabled, deleting the plan will cascade-delete entries/templates
    return await db.delete('plans', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, Object?>>> getPlans() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final listJson = prefs.getStringList('gp1_plans') ?? <String>[];
      // return as List<Map<String, Object?>> matching sqlite row shape
      return listJson.map((s) => Map<String, Object?>.from(jsonDecode(s) as Map<String, dynamic>)).toList();
    }

    final db = await database;
    return await db.query('plans', orderBy: 'id DESC');
  }

  Future<int> insertPlanEntry(Map<String, Object?> values) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final listJson = prefs.getStringList('gp1_plans') ?? <String>[];
      final list = listJson.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
      final planId = values['plan_id'] as int;
      final pIndex = list.indexWhere((p) => _idEquals(p['id'], planId));
      if (pIndex == -1) return 0; // plan not found
      final plan = list[pIndex];
      final entries = (plan['entries'] as List?) ?? [];
      final newEid = await _nextId();
      final e = {'id': newEid, 'plan_id': planId, 'day_offset': values['day_offset']};
      entries.add(e);
      plan['entries'] = entries;
      list[pIndex] = plan;
      await prefs.setStringList('gp1_plans', list.map((m) => jsonEncode(m)).toList());
      return newEid;
    }

    final db = await database;
    return await db.insert('plan_entries', values);
  }

  Future<int> insertPlanEntryTemplate(Map<String, Object?> values) async {
    if (kIsWeb) {
      // plan_entry_templates are stored inside the plans structure in prefs
      final prefs = await SharedPreferences.getInstance();
      final listJson = prefs.getStringList('gp1_plans') ?? <String>[];
      final list = listJson.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
      final entryId = values['entry_id'] as int;
      final templateId = values['template_id'] as int?;
      final templateObj = values['template'] as Map<String, Object?>?;

      for (final plan in list) {
        final entries = (plan['entries'] as List?) ?? [];
        for (final e in entries) {
          if (_idEquals(e['id'], entryId)) {
            final tlist = (e['templates'] as List?) ?? [];
            if (templateObj != null) {
              // embed the full template object into the entry (useful on web when we
              // don't want to persist to the global templates list)
              final assignedId = templateId ?? await _nextId();
              final toAdd = Map<String, Object?>.from(templateObj)..['id'] = assignedId;
              tlist.add(toAdd.cast<String, dynamic>());
              e['templates'] = tlist;
              await prefs.setStringList('gp1_plans', list.map((m) => jsonEncode(m)).toList());
              return assignedId;
            } else if (templateId != null) {
              tlist.add({'template_id': templateId});
              e['templates'] = tlist;
              await prefs.setStringList('gp1_plans', list.map((m) => jsonEncode(m)).toList());
              return templateId;
            }
          }
        }
      }
      return 0;
    }

    final db = await database;
    return await db.insert('plan_entry_templates', values);
  }

  // Returns a nested structure for each plan: {'plan': planRow, 'entries': [ {'entry': entryRow, 'templates': [templateRows...] }, ... ] }
  Future<List<Map<String, Object?>>> getFullPlans() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final listJson = prefs.getStringList('gp1_plans') ?? <String>[];
      final list = listJson.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
      final out = <Map<String, Object?>>[];
      for (final p in list) {
        final planRow = Map<String, Object?>.from(p);
        final entriesRaw = (p['entries'] as List?) ?? [];
        final entries = <Map<String, Object?>>[];
        for (final e in entriesRaw) {
          final entry = Map<String, Object?>.from(e as Map<String, dynamic>);
          final tmplMappings = (e['templates'] as List?) ?? [];
          final templates = <Map<String, Object?>>[];
          for (final m in tmplMappings) {
                // tmplMappings may either be a mapping with a template_id that references
                // gp1_templates, or it may be an embedded template object (when plans
                // were saved on web without persisting templates globally). Handle both.
                if (m.containsKey('template_id')) {
                  final tid = m['template_id'] as int?;
                  if (tid != null) {
                    // try to resolve template from gp1_templates
                    final tJson = prefs.getStringList('gp1_templates') ?? <String>[];
                    final tList = tJson.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
                    final found = tList.firstWhere((tt) => _idEquals(tt['id'], tid), orElse: () => {});
                    if (found.isNotEmpty) templates.add(Map<String, Object?>.from(found));
                  }
                } else if (m.containsKey('title')) {
                  // embedded template object previously stored in the plan entry
                  templates.add(Map<String, Object?>.from(m as Map<String, dynamic>));
                }
          }
          entries.add({'entry': entry, 'templates': templates});
        }
        out.add({'plan': planRow, 'entries': entries});
      }
      return out;
    }

    final db = await database;
    final plans = await db.query('plans', orderBy: 'id DESC');
    final result = <Map<String, Object?>>[];
    for (final p in plans) {
      final pid = p['id'] as int;
      final entries = await db.query('plan_entries', where: 'plan_id = ?', whereArgs: [pid], orderBy: 'day_offset ASC');
      final List<Map<String, Object?>> entriesWithTemplates = [];
      for (final e in entries) {
        final eid = e['id'] as int;
        final templateRows = await db.rawQuery('SELECT t.* FROM $templatesTable t JOIN plan_entry_templates pet ON t.id = pet.template_id WHERE pet.entry_id = ?', [eid]);
        entriesWithTemplates.add({'entry': e, 'templates': templateRows});
      }
      result.add({'plan': p, 'entries': entriesWithTemplates});
    }
    return result;
  }

  /// Update a plan and its entries/templates in a single transaction.
  /// The provided [planId] must already exist. The [plan] parameter should contain
  /// PlanEntry objects with optional `id` fields for existing entries; new entries
  /// may have `id == null`.
  Future<void> updatePlanWithEntries(int planId, Map<String, Object?> plan, List<Map<String, Object?>> entries) async {
    if (kIsWeb) {
      // Simplified web implementation: replace plan row and its entries stored in SharedPreferences.
      final prefs = await SharedPreferences.getInstance();
      final plansJson = prefs.getStringList('gp1_plans') ?? <String>[];
      final plans = plansJson.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
  final pIndex = plans.indexWhere((p) => _idEquals(p['id'], planId));
      if (pIndex == -1) return;

      // update plan meta
      final existingPlan = plans[pIndex];
      if (plan.containsKey('name')) existingPlan['name'] = plan['name'];
      if (plan.containsKey('description')) existingPlan['description'] = plan['description'];

      // load templates list for upserts
      final templatesJson = prefs.getStringList('gp1_templates') ?? <String>[];
      final templates = templatesJson.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();

      final newEntries = <Map<String, Object?>>[];
      for (final e in entries) {
  int entryId = e['id'] as int? ?? await _nextId();
        final dayOffset = e['day_offset'];
        final tmplList = <Map<String, Object?>>[];
        final providedTemplates = (e['templates'] as List<dynamic>? ?? []).cast<Map<String, Object?>>();
        for (final t in providedTemplates) {
          int tid = t['id'] as int? ?? 0;
          if (tid == 0) {
            // create new template
            tid = await _nextId();
            final newT = Map<String, Object?>.from(t)..['id'] = tid;
            templates.insert(0, (newT as Map).cast<String, dynamic>());
          } else {
            // update existing template if present
            final idx = templates.indexWhere((tt) => _idEquals(tt['id'], tid));
            if (idx != -1) {
              templates[idx] = (Map<String, Object?>.from(templates[idx])..addAll(t)).cast<String, dynamic>();
            }
          }
          tmplList.add({'template_id': tid});
        }
        newEntries.add({'id': entryId, 'plan_id': planId, 'day_offset': dayOffset, 'templates': tmplList});
      }

      existingPlan['entries'] = newEntries;
      plans[pIndex] = existingPlan;

      await prefs.setStringList('gp1_templates', templates.map((m) => jsonEncode(m)).toList());
      await prefs.setStringList('gp1_plans', plans.map((m) => jsonEncode(m)).toList());
      return;
    }

    final db = await database;
    await db.transaction((txn) async {
      // update plan row
      await txn.update('plans', plan, where: 'id = ?', whereArgs: [planId]);

      // load existing entries for diff
      final existingEntries = await txn.query('plan_entries', where: 'plan_id = ?', whereArgs: [planId]);
      final existingEntryIds = existingEntries.map((e) => e['id'] as int).toSet();

      final processedEntryIds = <int>{};

      for (final e in entries) {
        final entryId = e['id'] as int?;
        if (entryId == null) {
          // insert new entry
          final newEid = await txn.insert('plan_entries', {'plan_id': planId, 'day_offset': e['day_offset']});
          processedEntryIds.add(newEid);

          // attach templates
          final tmplList = e['templates'] as List<Map<String, Object?>>? ?? [];
          for (final t in tmplList) {
            int tid;
            if (t['id'] == null) {
              tid = await txn.insert(templatesTable, t);
            } else {
              tid = t['id'] as int;
              // ensure template row is up-to-date
              await txn.update(templatesTable, t, where: 'id = ?', whereArgs: [tid]);
            }
            await txn.insert('plan_entry_templates', {'entry_id': newEid, 'template_id': tid});
          }
        } else {
          // update existing entry day_offset
          await txn.update('plan_entries', {'day_offset': e['day_offset']}, where: 'id = ?', whereArgs: [entryId]);
          processedEntryIds.add(entryId);

          // diff templates for this entry
          final currentMappings = await txn.query('plan_entry_templates', where: 'entry_id = ?', whereArgs: [entryId]);
          final currentTemplateIds = currentMappings.map((m) => m['template_id'] as int).toSet();

          final tmplList = e['templates'] as List<Map<String, Object?>>? ?? [];
          final newTemplateIds = <int>{};
          for (final t in tmplList) {
            int tid;
            if (t['id'] == null) {
              tid = await txn.insert(templatesTable, t);
            } else {
              tid = t['id'] as int;
              await txn.update(templatesTable, t, where: 'id = ?', whereArgs: [tid]);
            }
            newTemplateIds.add(tid);
            if (!currentTemplateIds.contains(tid)) {
              await txn.insert('plan_entry_templates', {'entry_id': entryId, 'template_id': tid});
            }
          }

          // remove mappings that are no longer present
          for (final existingTid in currentTemplateIds.difference(newTemplateIds)) {
            await txn.delete('plan_entry_templates', where: 'entry_id = ? AND template_id = ?', whereArgs: [entryId, existingTid]);
          }
        }
      }

      // delete entries removed by user
      for (final existing in existingEntryIds.difference(processedEntryIds)) {
        await txn.delete('plan_entries', where: 'id = ?', whereArgs: [existing]);
      }
    });
  }
}
