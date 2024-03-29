import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class Game extends ChangeNotifier {
  final int numberOfTiles = 30;
  int tileWithRedX;
  List<bool> isTileClicked;
  bool gameOver = false;
  bool gameStarted = false;
  bool userWon = false;

  Game()
      : tileWithRedX = Random().nextInt(30),
        isTileClicked = List.generate(30, (index) => false);

  void startGame() {
    gameStarted = true;
    notifyListeners();
  }

  void resetGame() {
    tileWithRedX = Random().nextInt(30);
    isTileClicked = List.generate(30, (index) => false);
    gameOver = false;
    gameStarted = false;
    userWon = false;
    notifyListeners();
  }

  void tapTile(int index) {
    if (!gameStarted || gameOver || isTileClicked[index]) return;

    HapticFeedback.lightImpact();

    isTileClicked[index] = true;
    if (index == tileWithRedX) {
      HapticFeedback.heavyImpact();
      gameOver = true;
      userWon = false;
      gameStarted = false;
    } else {
      bool lastSafeTileClicked = isTileClicked.where((t) => !t).length == 1 &&
          !isTileClicked[tileWithRedX];
      if (lastSafeTileClicked) {
        userWon = true;
        gameOver = true;
        gameStarted = false;
      }
    }
    notifyListeners();
  }
}
