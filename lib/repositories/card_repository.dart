import '../database/database_helper.dart';
import '../models/card_model.dart';

class CardRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<CardModel>> getCardsByFolder(int folderId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'cards',
      where: 'folder_id = ?',
      whereArgs: [folderId],
      orderBy: 'id ASC',
    );
    return rows.map((m) => CardModel.fromMap(m)).toList();
  }

  Future<int> insertCard(CardModel card) async {
    final db = await _dbHelper.database;
    return db.insert('cards', card.toMap());
  }

  Future<int> updateCard(CardModel card) async {
    final db = await _dbHelper.database;
    return db.update(
      'cards',
      card.toMap(),
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  Future<int> deleteCard(int cardId) async {
    final db = await _dbHelper.database;
    return db.delete('cards', where: 'id = ?', whereArgs: [cardId]);
  }
}
