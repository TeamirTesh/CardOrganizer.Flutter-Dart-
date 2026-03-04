import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'card_organizer.db';
  static const _dbVersion = 1;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createTables(db);
        await _prepopulate(db);
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE folders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        folder_name TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        card_name TEXT NOT NULL,
        suit TEXT NOT NULL,
        image_url TEXT NOT NULL,
        folder_id INTEGER NOT NULL,
        FOREIGN KEY(folder_id) REFERENCES folders(id) ON DELETE CASCADE
      )
    ''');
  }

  String _now() => DateTime.now().toIso8601String();

  Future<void> _prepopulate(Database db) async {
    final suits = [
      {'name': 'Hearts', 'code': 'H'},
      {'name': 'Spades', 'code': 'S'},
      {'name': 'Diamonds', 'code': 'D'},
      {'name': 'Clubs', 'code': 'C'},
    ];

    final ranks = [
      {'name': 'Ace', 'code': 'A'},
      {'name': '2', 'code': '2'},
      {'name': '3', 'code': '3'},
      {'name': '4', 'code': '4'},
      {'name': '5', 'code': '5'},
      {'name': '6', 'code': '6'},
      {'name': '7', 'code': '7'},
      {'name': '8', 'code': '8'},
      {'name': '9', 'code': '9'},
      {'name': '10', 'code': '0'}, // IMPORTANT: API uses 0 for 10
      {'name': 'Jack', 'code': 'J'},
      {'name': 'Queen', 'code': 'Q'},
      {'name': 'King', 'code': 'K'},
    ];

    for (final suit in suits) {
      final folderId = await db.insert('folders', {
        'folder_name': suit['name'],
        'timestamp': _now(),
      });

      for (final rank in ranks) {
        final code = '${rank['code']}${suit['code']}';
        final url = 'https://deckofcardsapi.com/static/img/$code.png';

        await db.insert('cards', {
          'card_name': rank['name'],
          'suit': suit['name'],
          'image_url': url,
          'folder_id': folderId,
        });
      }
    }
  }
}
