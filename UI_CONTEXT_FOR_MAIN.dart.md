# Card Organizer UI – Context for Building All Screens in main.dart

Copy everything below this line and send it to whoever is building the UI. They will implement all screens inside **main.dart** and connect them to the existing backend.

---

## 1. App overview

- **Card Organizer**: users see **suit folders** (Hearts, Spades, Diamonds, Clubs). Each folder has **13 cards**. Tapping a folder opens its cards; user can add, edit, and delete cards and delete folders (folder delete also deletes all its cards – cascade).
- All UI lives in **main.dart** (replace the current counter demo). Backend is already done; only wire it from the UI.

---

## 2. Backend (already built – just use it)

**Imports you need in main.dart:**

```dart
import 'package:flutter/material.dart';
import 'database/database_helper.dart';
import 'models/folder.dart';
import 'models/card_model.dart';
import 'repositories/folder_repository.dart';
import 'repositories/card_repository.dart';
```

**FolderRepository** (singleton-style usage: `FolderRepository()` and call methods):

| Method | Returns | Use for |
|--------|--------|---------|
| `getAllFolders()` | `Future<List<Folder>>` | Folders screen list |
| `getCardCount(int folderId)` | `Future<int>` | Card count per folder |
| `insertFolder(Folder folder)` | `Future<int>` | (Optional) add folder |
| `deleteFolder(int folderId)` | `Future<int>` | Delete folder (cascade deletes its cards) |

**CardRepository**:

| Method | Returns | Use for |
|--------|--------|---------|
| `getCardsByFolder(int folderId)` | `Future<List<CardModel>>` | Cards screen list |
| `insertCard(CardModel card)` | `Future<int>` | Add new card |
| `updateCard(CardModel card)` | `Future<int>` | Save edited card |
| `deleteCard(int cardId)` | `Future<int>` | Delete one card |

**Models:**

- **Folder**: `id` (int?), `folderName` (String), `timestamp` (String). Use `id` for navigation and delete.
- **CardModel**: `id` (int?), `cardName`, `suit`, `imageUrl`, `folderId` (int). All required except `id`. Use for form and list.

**Prepopulated data:** On first run the DB creates 4 folders (Hearts, Spades, Diamonds, Clubs) and 13 cards per folder (Ace through King). Card images use URLs like `https://deckofcardsapi.com/static/img/AS.png` (suit code + rank code, e.g. `0` for 10).

---

## 3. What to put in main.dart

- **MyApp**: Keep. Change `title` to something like `'Card Organizer'`, set `home` to your **Folders** screen (the first screen).
- **Screen 1 – Folders screen** (home): List or grid of folders. For each folder: show folder name, card count, delete button, and tap → open Cards screen for that folder.
- **Screen 2 – Cards screen**: Shows cards for one folder. Receives a `Folder` (or at least `folderId`). List/grid of cards (image, name, suit), edit/delete per card, FAB to add a new card → Add/Edit Card screen.
- **Screen 3 – Add/Edit Card screen**: Form: card name, suit dropdown, image URL (or fixed URL), folder (current folder or dropdown). Save → insert or update via repository, then pop and refresh the Cards screen. Cancel → pop.

All three screens can be **StatefulWidget**s in the same file. Use **setState** after any insert/update/delete so the list refreshes.

---

## 4. Navigation flow

- **App start** → Folders screen (list of folders from `FolderRepository().getAllFolders()`).
- **Tap a folder** → Navigate to Cards screen, pass the selected `Folder` (or `folder.id`). Cards screen loads cards with `CardRepository().getCardsByFolder(folder.id!)`.
- **Tap “Add card”** → Navigate to Add/Edit Card screen; pass `folderId` (and optionally `Folder` for display). On save, `insertCard`, pop, then Cards screen refreshes (setState + reload list).
- **Tap “Edit” on a card** → Navigate to Add/Edit Card screen with that `CardModel` (edit mode). On save, `updateCard`, pop, refresh Cards screen.
- **Delete folder** → Show confirmation dialog. On confirm: `deleteFolder(folder.id!)`, then refresh Folders list (setState).
- **Delete card** → Show confirmation dialog. On confirm: `deleteCard(card.id!)`, then refresh Cards list (setState).

Use `Navigator.push` / `Navigator.pop`. When returning from Add/Edit Card, refresh the Cards screen (e.g. reload list in `setState` or when the route pops).

---

## 5. Loading and refreshing data

- **Folders screen**: In `initState` or first build, call `FolderRepository().getAllFolders()` and `getCardCount(folderId)` per folder. Store result in state (e.g. `List<Folder> folders`, and optionally `Map<int, int> cardCounts`). Use **FutureBuilder** or a **setState** after `await` to show the list; show a loading indicator while waiting.
- **Cards screen**: Same idea: `CardRepository().getCardsByFolder(folderId)` → store `List<CardModel> cards` in state, show with FutureBuilder or setState.
- After any **insert/update/delete**, call `setState(() { ... })` and re-fetch the list (or re-run the same future and setState) so the UI updates.

---

## 6. Delete confirmation (required by spec)

- **Folder delete**: Message like “This folder and all its cards will be permanently deleted. This cannot be undone.” Confirm → `deleteFolder(id)`, then refresh.
- **Card delete**: “This card will be permanently deleted.” Confirm → `deleteCard(id)`, then refresh.
- Dialog must be **non-dismissible** (user must tap Cancel or Confirm). Use `AlertDialog` with `barrierDismissible: false` (or equivalent).

Example pattern:

```dart
showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (ctx) => AlertDialog(
    title: const Text('Delete folder?'),
    content: const Text(
      'This folder and all its cards will be permanently deleted. This cannot be undone.',
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(ctx),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () async {
          Navigator.pop(ctx);
          await FolderRepository().deleteFolder(folder.id!);
          if (mounted) setState(() {});
        },
        child: const Text('Delete'),
      ),
    ],
  ),
);
```

(Use the same pattern for card delete with `CardRepository().deleteCard(card.id!)`.)

---

## 7. Constants for forms (Add/Edit Card)

Suit and card name options (match DB prepopulation):

**Suits:** `Hearts`, `Spades`, `Diamonds`, `Clubs`

**Card names (ranks):** `Ace`, `2`, `3`, `4`, `5`, `6`, `7`, `8`, `9`, `10`, `Jack`, `Queen`, `King`

Image URL pattern for deckofcardsapi:  
`https://deckofcardsapi.com/static/img/{rankCode}{suitCode}.png`  
e.g. Ace Spades = `AS`, 10 Hearts = `0H`. Suit codes: H, S, D, C. Rank codes: A, 2–9, 0 (for 10), J, Q, K.

You can use a dropdown for suit and card name and build the URL from selection, or a simple text field for image URL.

---

## 8. Creating models in UI

- **New folder** (if you add that):  
  `Folder(folderName: 'Hearts', timestamp: DateTime.now().toIso8601String())`
- **New card**:  
  `CardModel(cardName: 'Ace', suit: 'Hearts', imageUrl: 'https://...', folderId: folderId)`
- **Edit card**: use `card.copyWith(cardName: newName, suit: newSuit, ...)` then `CardRepository().updateCard(updatedCard)`.

---

## 9. Image display

Cards have `imageUrl` (String). Use **Image.network(card.imageUrl)** for URLs. For loading/error use `Image.network(..., loadingBuilder: ..., errorBuilder: ...)` or a placeholder (e.g. Icon or “No image” text) in `errorBuilder`.

---

## 10. main() – keep as is

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;
  runApp(const MyApp());
}
```

Do not remove this; the DB must be initialized before the app runs.

---

## 11. Checklist for the person building the UI

- [ ] MyApp: title “Card Organizer”, home = Folders screen.
- [ ] Folders screen: load folders with `FolderRepository().getAllFolders()`, show card count with `getCardCount(folderId)`, tap → Cards screen, delete with confirmation.
- [ ] Cards screen: receive folder (or folderId), load cards with `CardRepository().getCardsByFolder(folderId)`, show image/name/suit, edit/delete per card, FAB → Add/Edit Card.
- [ ] Add/Edit Card screen: form (name, suit, image URL, folderId); save → insert or update via repository, pop and refresh; cancel → pop.
- [ ] Delete dialogs: non-dismissible, clear message, cascade warning for folder delete.
- [ ] After every mutation (add/edit/delete): setState and re-fetch so the list updates.
- [ ] Use `context.mounted` (or `mounted`) after async work before calling setState or Navigator.

That’s everything needed to build the full UI in main.dart and connect it to the existing backend.
