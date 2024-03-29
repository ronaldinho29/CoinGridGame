import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:nextbigthing/Game.dart';
import 'dart:math';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mine Game',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: Mine(),
    );
  }
}

Future<List<String>> getProfileNames() async {
  final db = await mongo.Db.create(
      'mongodb+srv://ronaldchomnou:Ronaldinho2910@cluster0.39ac5k2.mongodb.net/nextbigthing?retryWrites=true&w=majority&appName=Cluster0');
  await db.open();

  final collection = db.collection('MineBomb');
  final profiles = await collection.find().toList();

  db.close();

  return profiles.map((profile) => profile['name'] as String).toList();
}

class Mine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Mine Game',
          style: TextStyle(fontSize: 30),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: MainMenu(),
    );
  }
}

class MainMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Select Profile"),
        ),
        body: FutureBuilder<List<String>>(
          future: getProfileNames(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(),
              );
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              List<String> names = snapshot.data ?? [];
              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: names.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: Icon(Icons.person),
                          title: Text(names[index]),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    StartGame(profileName: names[index]),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            }
          },
        ));
  }
}

class StartGame extends StatelessWidget {
  final String profileName;

  StartGame({required this.profileName});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => Game(),
      child: Scaffold(
        appBar: AppBar(
          title: Text("Game - $profileName"),
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
                              ? index == game.tileWithRedX
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
                      Text('\$1000.00', style: TextStyle(fontSize: 20)),
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
                        : () => game.startGame(),
                    child: Text("Play"),
                  ),
                  SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () => game.resetGame(),
                    child: Text("Reset"),
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
