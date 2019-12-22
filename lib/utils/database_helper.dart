import 'package:flutter_learning/models/project.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_learning/models/task.dart';

class DatabaseHelper {
  static DatabaseHelper _databaseHelper;
  static Database _database;

  final String _db = "notes.db";

  final String _noteTable = "note_table";
  final String _priorityTable = "priority_table";
  static final String colId = "id";
  static final String colTitle = "title";
  static final String colDescription = "description";
  static final String colPriorityId = "priorityId";
  static final String colDate = "date";
  static final String colPriorityPosition = "position";
  static final String colPriorityTitle = "title";

  final String _noteTableOld = "_note_table_old";
  final String _priorityTableOld = "_priority_table_old";
  final String _colPriorityIdOld = "priority";

  DatabaseHelper._createInstance();

  factory DatabaseHelper() {
    if (_databaseHelper == null)
      _databaseHelper = DatabaseHelper._createInstance();

    return _databaseHelper;
  }

  Future<Database> get database async {
    if (_database == null) _database = await initializeDatabase();
    return _database;
  }

  Future<Database> initializeDatabase() async {
    Directory directory = await getApplicationDocumentsDirectory();
    String path = directory.path + _db;

    var notesDatabase = await openDatabase(path,
        version: 2, onCreate: _createDb, onUpgrade: _upgradeDb);
    return notesDatabase;
  }

  void _createDb(Database db, int newVersion) async {
    await _createPriorityTable(db);
    await _createNoteTable(db);
  }

  Future _createPriorityTable(Database db) async {
    await db.execute(_getCreatePriorityTableQuery());
  }

  String _getCreatePriorityTableQuery() {
    return "CREATE TABLE $_priorityTable("
        "$colPriorityId INTEGER PRIMARY KEY AUTOINCREMENT, "
        "$colPriorityPosition INTEGER , "
        "$colPriorityTitle TEXT)";
  }

  Future _createNoteTable(Database db) async {
    await db.execute(_getCreateNoteTableQuery());
  }

  String _getCreateNoteTableQuery() {
    return "CREATE TABLE $_noteTable("
        "$colId INTEGER PRIMARY KEY AUTOINCREMENT, "
        "$colTitle TEXT,"
        "$colDescription TEXT,"
        "$colPriorityId INTEGER,"
        "$colDate TEXT)";
  }

  void _upgradeDb(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < newVersion) {
      if (oldVersion == 1) {
        await db.execute(
            "ALTER TABLE $_noteTable RENAME TO $_noteTableOld;");
            await db.execute(_getCreateNoteTableQuery());
        await db.execute("INSERT INTO $_noteTable ($colId, $colTitle, $colDescription, $colPriorityId, $colDate) "
            "SELECT $colId, $colTitle, $colDescription, $_colPriorityIdOld, $colDate "
            "FROM $_noteTableOld;");
        await db.execute(_getCreatePriorityTableQuery());
        await db.execute("INSERT INTO $_priorityTable ($colPriorityPosition) "
            "SELECT $_colPriorityIdOld "
            "FROM $_noteTableOld;");

      } else if (oldVersion == 2) {
        await db.execute(
            "ALTER TABLE $_priorityTable RENAME TO $_priorityTableOld;");

        await db.execute("INSERT INTO $_priorityTable ($colPriorityPosition, $colPriorityTitle) "
            "SELECT $colPriorityId, $colPriorityTitle "
            "FROM $_priorityTableOld;");
      }

      await db.execute("DROP TABLE IF EXISTS $_noteTableOld");
      await db.execute("DROP TABLE IF EXISTS $_priorityTableOld");
    }
  }

  // Fetch Operation: Get all note objects from database
  Future<List<Map<String, dynamic>>> getNoteMapList() async {
    Database db = await this.database;

//    var result = await db.rawQuery("SELECT * FROM $noteTable order by $colPriority ASC");
    var result = await db.query(_noteTable, orderBy: "$colPriorityId ASC");

    return result;
  }

  // Insert Operation: Insert a Note object to database
  Future<int> insertNote(Task note) async {
    Database db = await this.database;
    var result = await db.insert(_noteTable, note.toMap());
    return result;
  }

  // Update Operation: Update a Note object and save it to database
  Future<int> updateNote(Task note) async {
    var db = await this.database;
    return await db.update(_noteTable, note.toMap(),
        where: "$colId = ?", whereArgs: [note.id]);
  }

  // Delete Operation: Delete a Note object from database
  Future<int> deleteNote(int id) async {
    var db = await this.database;
    return await db.rawDelete("DELETE FROM $_noteTable WHERE $colId = $id");
  }

  // Get number of Note objects in database
  Future<int> getNoteCount() async {
    Database db = await this.database;
    List<Map<String, dynamic>> x =
        await db.rawQuery("SELECT COUNT (*) from $_noteTable");
    return Sqflite.firstIntValue(x);
  }

  // Get the 'Map List' [ List<Map> ] and convert it to 'Note List' [ List<Note> ]
  Future<List<Task>> getTaskList() async {
    var noteMapList = await getNoteMapList(); // Get 'Map List' from database
    int count =
        noteMapList.length; // Count the number of map entries in db table

    List<Task> noteList = List<Task>();
    // For loop to create a 'Note List' from a 'Map List'
    for (int i = 0; i < count; i++) {
      noteList.add(Task.fromMapObject(noteMapList[i]));
    }

    return noteList;
  }

  // Fetch Operation: Get all priority objects from database
  Future<List<Map<String, dynamic>>> getPriorityMapList() async {
    Database db = await this.database;

//    var result = await db.rawQuery("SELECT * FROM $noteTable order by $colPriority ASC");
    var result = await db.query(_priorityTable, orderBy: "$colPriorityId ASC");

    return result;
  }

  // Insert Operation: Insert a Priority object to database
  Future<int> insertPriority(Project priority) async {
    Database db = await this.database;
    var result = await db.insert(_priorityTable, priority.toMap());
    return result;
  }

  // Update Operation: Update a Priority object and save it to database
  Future<int> updatePriority(Project priority) async {
    var db = await this.database;
    return await db.update(_priorityTable, priority.toMap(),
        where: "$colPriorityId = ?", whereArgs: [priority.priorityId]);
  }

  // Delete Operation: Delete a Priority object from database
  Future<int> deletePriority(int priorityId) async {
    var db = await this.database;
    return await db.rawDelete(
        "DELETE FROM $_priorityTable WHERE $colPriorityId = $priorityId");
  }

  // Get number of Priority objects in database
  Future<int> getPriorityCount() async {
    Database db = await this.database;
    List<Map<String, dynamic>> x =
        await db.rawQuery("SELECT COUNT (*) from $_priorityTable");
    return Sqflite.firstIntValue(x);
  }

  // Get the 'Map List' [ List<Map> ] and convert it to 'Priority List' [ List<Priority> ]
  Future<List<Project>> getPriorityList() async {
    var priorityMapList =
        await getPriorityMapList(); // Get 'Map List' from database
    int count =
        priorityMapList.length; // Count the number of map entries in db table

    List<Project> noteList = List<Project>();
    // For loop to create a 'Priority List' from a 'Map List'
    for (int i = 0; i < count; i++) {
      noteList.add(Project.fromMapObject(priorityMapList[i]));
    }

    return noteList;
  }
}
