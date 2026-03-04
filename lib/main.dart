import 'package:flutter/material.dart';
import 'database/database_helper.dart';
import 'models/folder.dart';
import 'models/card_model.dart';
import 'repositories/folder_repository.dart';
import 'repositories/card_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Card Organizer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FoldersScreen(),
    );
  }
}

class FoldersScreen extends StatefulWidget {
  @override
  _FoldersScreenState createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  List<Folder> folderList = [];
  Map<int, int> cardCounts = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadFolders();
  }

  void loadFolders() async {
    final result = await FolderRepository().getAllFolders();
    // get card count for each folder
    for (var f in result) {
      int count = await FolderRepository().getCardCount(f.id!);
      cardCounts[f.id!] = count;
    }
    setState(() {
      folderList = result;
      loading = false;
    });
  }

  void removeFolder(Folder folder) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Folder'),
          content: Text('This folder and all its cards will be permanently deleted. This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await FolderRepository().deleteFolder(folder.id!);
                loadFolders(); // refresh
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  String getFolderIcon(String name) {
    if (name == 'Hearts') return '♥️';
    if (name == 'Spades') return '♠️';
    if (name == 'Diamonds') return '♦️';
    if (name == 'Clubs') return '♣️';
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Card Folders')),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              padding: EdgeInsets.all(15),
              children: List.generate(folderList.length, (index) {
                return GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CardsScreen(
                          folderName: folderList[index].folderName,
                          folderId: folderList[index].id!,
                        ),
                      ),
                    );
                    loadFolders();
                  },
                  child: Card(
                    elevation: 3,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(getFolderIcon(folderList[index].folderName), style: TextStyle(fontSize: 40)),
                        SizedBox(height: 5),
                        Text(folderList[index].folderName, style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('${cardCounts[folderList[index].id] ?? 0} cards', style: TextStyle(color: Colors.grey)),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => removeFolder(folderList[index]),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
    );
  }
}

// Cards Screen
class CardsScreen extends StatefulWidget {
  final String folderName;
  final int folderId;

  CardsScreen({required this.folderName, required this.folderId});

  @override
  _CardsScreenState createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  List<CardModel> cards = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadCards();
  }

  void loadCards() async {
    final result = await CardRepository().getCardsByFolder(widget.folderId);
    setState(() {
      cards = result;
      loading = false;
    });
  }

  void deleteCard(CardModel card) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Card'),
          content: Text('This card will be permanently deleted.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await CardRepository().deleteCard(card.id!);
                loadCards(); // refresh list
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.folderName} Cards')),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: cards.length,
              itemBuilder: (context, i) {
                return Card(
                  margin: EdgeInsets.all(10),
                  child: ListTile(
                    leading: Container(
                      width: 50,
                      height: 70,
                      child: Image.network(
                        cards[i].imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.image_not_supported),
                      ),
                    ),
                    title: Text(cards[i].cardName),
                    subtitle: Text(cards[i].suit),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddEditCardScreen(
                                  card: cards[i],
                                  folderId: widget.folderId,
                                ),
                              ),
                            );
                            loadCards();
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteCard(cards[i]),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddEditCardScreen(
                folderId: widget.folderId,
              ),
            ),
          );
          loadCards();
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class AddEditCardScreen extends StatefulWidget {
  final CardModel? card;
  final int folderId;

  AddEditCardScreen({this.card, required this.folderId});

  @override
  _AddEditCardScreenState createState() => _AddEditCardScreenState();
}

class _AddEditCardScreenState extends State<AddEditCardScreen> {
  TextEditingController nameController = TextEditingController();
  String selectedSuit = 'Hearts';
  String selectedRank = 'Ace';
  bool saving = false;

  List<String> suits = ['Hearts', 'Spades', 'Diamonds', 'Clubs'];
  List<String> ranks = ['Ace', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'Jack', 'Queen', 'King'];

  @override
  void initState() {
    super.initState();
    if (widget.card != null) {
      selectedSuit = widget.card!.suit;
      selectedRank = widget.card!.cardName;
    }
  }

  // build the image url from suit and rank
  String getImageUrl() {
    Map<String, String> suitCode = {'Hearts': 'H', 'Spades': 'S', 'Diamonds': 'D', 'Clubs': 'C'};
    Map<String, String> rankCode = {
      'Ace': 'A', '2': '2', '3': '3', '4': '4', '5': '5',
      '6': '6', '7': '7', '8': '8', '9': '9', '10': '0',
      'Jack': 'J', 'Queen': 'Q', 'King': 'K'
    };
    return 'https://deckofcardsapi.com/static/img/${rankCode[selectedRank]}${suitCode[selectedSuit]}.png';
  }

  void saveCard() async {
    if (nameController.text.isEmpty && widget.card == null) {
      // just use the dropdown value, nameController isn't really needed
    }

    setState(() {
      saving = true;
    });

    String imgUrl = getImageUrl();

    if (widget.card == null) {
      await CardRepository().insertCard(CardModel(
        cardName: selectedRank,
        suit: selectedSuit,
        imageUrl: imgUrl,
        folderId: widget.folderId,
      ));
    } else {
      await CardRepository().updateCard(widget.card!.copyWith(
        cardName: selectedRank,
        suit: selectedSuit,
        imageUrl: imgUrl,
      ));
    }

    setState(() {
      saving = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Card saved')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.card == null ? 'Add Card' : 'Edit Card')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Card Name:'),
            SizedBox(height: 8),
            DropdownButton<String>(
              value: selectedRank,
              isExpanded: true,
              items: ranks.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (value) {
                setState(() {
                  selectedRank = value!;
                });
              },
            ),
            SizedBox(height: 16),
            Text('Suit:'),
            DropdownButton<String>(
              value: selectedSuit,
              isExpanded: true,
              items: suits.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (value) {
                setState(() {
                  selectedSuit = value!;
                });
              },
            ),
            SizedBox(height: 20),
            Container(
              width: 100,
              height: 140,
              color: Colors.grey[300],
              child: Image.network(
                getImageUrl(),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(Icons.image, size: 50),
              ),
            ),
            Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: saving ? null : saveCard,
                    child: saving
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
