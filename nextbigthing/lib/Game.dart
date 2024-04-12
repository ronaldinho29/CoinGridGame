import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class Game extends ChangeNotifier {
  final int numberOfTiles = 30;
  int numberOfMines;
  List<bool> tilesWithMines;
  List<bool> isTileClicked;
  bool gameOver = false;
  bool gameStarted = false;
  bool userWon = false;

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
  } else {
    // Count how many tiles are not mines and have not been clicked yet
    int remainingSafeTiles = 0;
    for (int i = 0; i < numberOfTiles; i++) {
      if (!tilesWithMines[i] && !isTileClicked[i]) {
        remainingSafeTiles++;
      }
    }

    if (remainingSafeTiles == 0) {  // Check if all non-mine tiles have been clicked
      gameOver = true;
      userWon = true;
      gameStarted = false;
    }
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
}
