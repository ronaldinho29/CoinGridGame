import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;

class Game extends ChangeNotifier {
  final int numberOfTiles = 30;
  int numberOfMines;
  List<bool> tilesWithMines;
  List<bool> isTileClicked;
  bool gameOver = false;
  bool gameStarted = false;
  bool userWon = false;
  String databaseUri =
      'mongodb+srv://ronaldchomnou:Ronaldinho2910@cluster0.39ac5k2.mongodb.net/nextbigthing?retryWrites=true&w=majority&appName=Cluster0';

  Game(this.numberOfMines)
      : tilesWithMines = List<bool>.filled(30, false),
        isTileClicked = List<bool>.filled(30, false) {
    _placeMines();
  }

  void _placeMines() {
    var rng = Random();
    tilesWithMines.fillRange(0, tilesWithMines.length, false);
    int placedMines = 0;
    while (placedMines < numberOfMines) {
      int index = rng.nextInt(numberOfTiles);
      if (!tilesWithMines[index]) {
        tilesWithMines[index] = true;
        placedMines++;
      }
    }
  }

  void startGame() {
    gameStarted = true;
    notifyListeners();
  }

  void resetGame() {
    _placeMines(); // Re-place the mines
    isTileClicked.fillRange(0, numberOfTiles, false);
    gameOver = false;
    gameStarted = false;
    userWon = false;
    notifyListeners();
  }

  void tapTile(int index) {
    if (!gameStarted || gameOver || isTileClicked[index]) return;

    HapticFeedback.lightImpact();

    isTileClicked[index] = true;
    if (tilesWithMines[index]) {
      HapticFeedback.heavyImpact();
      gameOver = true;
      userWon = false;
      gameStarted = false;
      // Directly trigger endGame without waiting for an external call
    } else {
      int remainingSafeTiles = 0;
      for (int i = 0; i < numberOfTiles; i++) {
        if (!tilesWithMines[i] && !isTileClicked[i]) {
          remainingSafeTiles++;
        }
      }
      if (remainingSafeTiles == 0) {
        gameOver = true;
        userWon = true;
        gameStarted = false;
      }
    }
    notifyListeners();
  }

  // Now endGame accepts userName and change explicitly for external calls
  void endGame(String userName, int selectedMines) {
    updateWallet(userName, selectedMines);
  }

  Future<void> updateWallet(String userName, int selectedMines) async {
    int walletChange;
    if (userWon) {
      walletChange = pow(selectedMines, 2) as int;
    } else {
      walletChange = -pow(selectedMines, 2) as int;
    }

    final db = await mongo.Db.create(databaseUri);
    try {
      await db.open();
      var collection = db.collection('MineBomb');
      await collection.updateOne(mongo.where.eq('name', userName),
          mongo.modify.inc('wallet', walletChange));
    } catch (e) {
      print('Error updating wallet: $e');
    } finally {
      await db.close();
    }
    notifyListeners();
  }

  void updateMines(int newMines) {
    numberOfMines = newMines;
    _placeMines(); // Re-place the mines with the new number
    isTileClicked.fillRange(0, numberOfTiles, false); // Reset clicks
    gameOver = false;
    gameStarted = false;
    userWon = false;
    notifyListeners();
  }

  Future<String> currentWalletFuture(String profileName) async {
    final db = await mongo.Db.create(databaseUri);
    try {
      await db.open();
      var collection = db.collection('MineBomb');
      var result =
          await collection.findOne(mongo.where.eq('name', profileName));
      if (result != null && result.containsKey('wallet')) {
        return result['wallet']
            .toString(); // Ensure the wallet field is converted to a string
      } else {
        throw Exception("Wallet not found for user $profileName");
      }
    } catch (e) {
      print('Error fetching wallet: $e');
      throw Exception(
          "Failed to fetch wallet: $e"); // Re-throw the exception to be handled by caller
    } finally {
      await db.close();
    }
  }
}
