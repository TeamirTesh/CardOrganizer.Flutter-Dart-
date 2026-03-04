import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/folder.dart';

class FolderRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<Folder>> getAllFolders() async {
    final db = await _dbHelper.database;
    final rows = await db.query('folders', orderBy: 'id ASC');
    return rows.map((m) => Folder.fromMap(m)).toList();
  }

  Future<int> insertFolder(Folder folder) async {
    final db = await _dbHelper.database;
    return db.insert('folders', folder.toMap());
  }

  Future<int> deleteFolder(int folderId) async {
    final db = await _dbHelper.database;
    return db.delete('folders', where: 'id = ?', whereArgs: [folderId]);
  }

  Future<int> getCardCount(int folderId) async {
    final db = await _dbHelper.database;
    final res = await db.rawQuery(
      'SELECT COUNT(*) AS cnt FROM cards WHERE folder_id = ?',
      [folderId],
    );
    return Sqflite.firstIntValue(res) ?? 0;
  }
}
