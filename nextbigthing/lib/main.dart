import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:nextbigthing/Game.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:bson/bson.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return MaterialApp(
      title: 'Coin Grid',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: Mine(),
    );
  }
}

Future<List<Map<String, dynamic>>> getProfiles() async {
  final db = await mongo.Db.create(
      'mongodb+srv://ronaldchomnou:Ronaldinho2910@cluster0.39ac5k2.mongodb.net/nextbigthing?retryWrites=true&w=majority&appName=Cluster0');
  await db.open();

  final collection = db.collection('MineBomb');
  final profiles = await collection.find().toList();

  db.close();

  return profiles.map((profile) {
    int wallet = (profile['wallet']).toInt();
    return {
      'name': profile['name'] as String,
      'wallet': wallet,
    };
  }).toList();
}

class Mine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Coin Grid',
          style: TextStyle(fontSize: 30),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: MainMenu(),
    );
  }
}

class MainMenu extends StatefulWidget {
  @override
  _MainMenuState createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  Future<List<Map<String, dynamic>>>? profileListFuture;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    profileListFuture = getProfiles();
  }

  void refreshProfiles() {
    setState(() {
      profileListFuture = getProfiles();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Select Profile"),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        key: ValueKey(profileListFuture),
        future: profileListFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            List<Map<String, dynamic>> profiles = snapshot.data ?? [];
            return ListView.builder(
              itemCount: profiles.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Icon(Icons.person),
                  title: Text(profiles[index]['name']),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StartGame(
                            profileName: profiles[index]['name'],
                            userWallet: profiles[index]['wallet'],
                          ),
                        ));
                  },
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProfileDialog(context),
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showAddProfileDialog(BuildContext context) {
    TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Create New Profile"),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(hintText: "Enter profile name"),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _addProfileToDb(nameController.text)
                    .then((_) => refreshProfiles());
              },
              child: Text('Enter'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addProfileToDb(String name) async {
    final db = await mongo.Db.create(
        'mongodb+srv://ronaldchomnou:Ronaldinho2910@cluster0.39ac5k2.mongodb.net/nextbigthing?retryWrites=true&w=majority&appName=Cluster0');
    await db.open();
    var collection = db.collection('MineBomb');
    await collection.insert({'name': name, 'wallet': 5000});
    db.close();
  }
}

class StartGame extends StatefulWidget {
  final String profileName;
  int userWallet;

  StartGame({required this.profileName, required this.userWallet});

  @override
  _StartGameState createState() => _StartGameState();
}

class _StartGameState extends State<StartGame> {
  int selectedMines = 1;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => Game(context, selectedMines),
      child: Scaffold(
        appBar: AppBar(
          title: Text("Game - ${widget.profileName}"),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: Consumer<Game>(
          builder: (context, game, child) => Column(
            children: [
              GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                ),
                itemCount: game.numberOfTiles,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => game.tapTile(index),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color:
                                game.isTileClicked[index] ? null : Colors.green,
                            border: Border.all(color: Colors.black),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: game.isTileClicked[index]
                              ? game.tilesWithMines[index]
                                  ? Icon(Icons.whatshot,
                                      size: 70, color: Colors.red)
                                  : Icon(Icons.monetization_on,
                                      size: 70, color: Colors.yellow)
                              : Container(),
                        ),
                      ],
                    ),
                  );
                },
              ),
              Align(
                alignment: Alignment.center,
                child: Container(
                  margin: EdgeInsets.all(2.0),
                  padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FutureBuilder<String>(
                        future: game.currentWalletFuture(widget.profileName),
                        builder: (BuildContext context,
                            AsyncSnapshot<String> snapshot) {
                          if (snapshot.data == null) {
                            return Text('Wallet: ',
                                style: TextStyle(fontSize: 20));
                          } else {
                            return Text('Wallet: \$${snapshot.data}',
                                style: TextStyle(fontSize: 20));
                          }
                        },
                      ),
                      SizedBox(width: 10),
                      Icon(Icons.add_card, color: Colors.blue),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 10),
              if (game.gameOver)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(game.userWon ? "You Win!" : "You Lost!",
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: game.userWon ? Colors.green : Colors.red)),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: game.gameStarted || game.gameOver
                        ? null
                        : () {
                            game.startGame();
                            setState(() {});
                          },
                    child: Text("Play"),
                  ),
                  SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () {
                      if (game.gameOver) {
                        print("GAME IS OFFICIALLY OVER");
                        game.endGame(widget.profileName, selectedMines);
                      }
                      game.resetGame();
                      setState(() {});
                    },
                    child: Text("Reset"),
                  ),
                  SizedBox(width: 20),
                  Text("Mines:"),
                  SizedBox(width: 20),
                  DropdownButton<int>(
                    value: selectedMines,
                    onChanged: game.gameStarted
                        ? null
                        : (int? newValue) {
                            if (newValue != null) {
                              setState(() {
                                selectedMines = newValue;
                              });
                              game.updateMines(selectedMines);
                            }
                          },
                    items: List.generate(29, (index) => index + 1)
                        .map<DropdownMenuItem<int>>((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text(value.toString()),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
