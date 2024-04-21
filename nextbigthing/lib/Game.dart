import 'dart:math';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:flutter/material.dart'; // Import the material package for using dialogs

class Game extends ChangeNotifier {
  final BuildContext context; // Add a context field
  final int numberOfTiles = 30;
  int numberOfMines;
  List<bool> tilesWithMines;
  List<bool> isTileClicked;
  bool gameOver = false;
  bool gameStarted = false;
  bool userWon = false;
  bool redemptionWon = false;
  String databaseUri =
      'mongodb+srv://ronaldchomnou:Ronaldinho2910@cluster0.39ac5k2.mongodb.net/nextbigthing?retryWrites=true&w=majority&appName=Cluster0';

  Game(this.context, this.numberOfMines)
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
      _showMineHitDialog(); // Show the dialog when a mine is hit
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

 void _showMineHitDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(child: Text("Mine Hit!")),
          content: Text("Do you want to play a redemption game?"),
          actions: <Widget>[
            TextButton(
              child: Text("Yes"),
              onPressed: () {
                Navigator.of(context).pop();
                _showQuestionDialog();
              },
            ),
            TextButton(
              child: Text("No"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }



  final List<Map<String, String>> questionsAndAnswers = [
    {'question': 'What is 5 + 5?', 'answer': '10'},
    {'question': 'What is the capital of France?', 'answer': 'Paris'},
    {'question': 'What is 7 * 6?', 'answer': '42'},
    {
      'question': 'What is the color of the Statue of Liberty?',
      'answer': 'Green'
    },
    {'question': 'Who is the best CS professor at UMD?', 'answer': 'Marsh'},
    {'question': 'How many tiles are there in this game?', 'answer': '30'},
    {'question': 'What color is the sun?', 'answer': 'Yellow'},
    {
      'question': 'What year did the Covid-19 pandemic start?',
      'answer': '2020'
    },
    {'question': 'What has keys but can\'t open locks?', 'answer': 'Piano'},
    {'question': 'What has a ring but no fingers?', 'answer': 'Phone'},
  ];
  //Redemption Game
  void _showQuestionDialog() async {
    TextEditingController textEditingController = TextEditingController();

    var random = Random();
    var selectedQA =
        questionsAndAnswers[random.nextInt(questionsAndAnswers.length)];

    void closeDialog() { 
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    }

        await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Scaffold(
        resizeToAvoidBottomInset: false,
        body: AlertDialog(
          title: Center(child: Text("Enter Your Answer")),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(selectedQA['question']!),
                TextField(controller: textEditingController),
                SizedBox(height: 20),
                CountdownTimerDisplay(
                    initialTime: 5, onTimerComplete: closeDialog),
              ],
            ),
          ),
          actions: <Widget>[
            Center(
              child: TextButton(
                child: Text("Submit"),
                onPressed: () {
                  if (textEditingController.text.trim().toLowerCase() ==
                      selectedQA['answer']!.toLowerCase()) {
                    closeDialog();
                    resetGame();
                  } else {
                    closeDialog();
                  }
                },
              ),
            ),
          ],
        ),
      );
      },
    );
  }
}

//Timer
class CountdownTimerDisplay extends StatefulWidget {
  final int initialTime;
  final VoidCallback onTimerComplete;

  CountdownTimerDisplay(
      {Key? key, required this.initialTime, required this.onTimerComplete})
      : super(key: key);

  @override
  _CountdownTimerDisplayState createState() => _CountdownTimerDisplayState();
}

class _CountdownTimerDisplayState extends State<CountdownTimerDisplay> {
  late int remainingTime;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    remainingTime = widget.initialTime;
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (remainingTime > 0) {
        setState(() {
          remainingTime--;
        });
      } else {
        timer.cancel();
        widget.onTimerComplete();
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text('Time left: $remainingTime seconds');
  }
}
