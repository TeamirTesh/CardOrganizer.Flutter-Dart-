class CardModel {
  final int? id;
  final String cardName; // "Ace", "2", ..., "King"
  final String suit;     // "Hearts", "Spades", "Diamonds", "Clubs"
  final String imageUrl; // https://deckofcardsapi.com/static/img/AS.png
  final int folderId;

  CardModel({
    this.id,
    required this.cardName,
    required this.suit,
    required this.imageUrl,
    required this.folderId,
  });

  CardModel copyWith({
    int? id,
    String? cardName,
    String? suit,
    String? imageUrl,
    int? folderId,
  }) {
    return CardModel(
      id: id ?? this.id,
      cardName: cardName ?? this.cardName,
      suit: suit ?? this.suit,
      imageUrl: imageUrl ?? this.imageUrl,
      folderId: folderId ?? this.folderId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'card_name': cardName,
      'suit': suit,
      'image_url': imageUrl,
      'folder_id': folderId,
    };
  }

  factory CardModel.fromMap(Map<String, dynamic> map) {
    return CardModel(
      id: map['id'] as int?,
      cardName: map['card_name'] as String,
      suit: map['suit'] as String,
      imageUrl: map['image_url'] as String,
      folderId: map['folder_id'] as int,
    );
  }
}
