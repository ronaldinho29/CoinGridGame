import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'dart:math';

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

class StartGame extends StatefulWidget {
  final String profileName;

  StartGame({required this.profileName});

  @override
  _StartGameState createState() => _StartGameState();
}

class _StartGameState extends State<StartGame> {
  final int _numberOfTiles = 30;
  late int _tileWithRedX;
  List<bool> _isTileClicked;
  List<bool> _isBorderVisible = List.generate(30, (index) => true);

  _StartGameState() : _isTileClicked = List.generate(30, (index) => false) {
    // Randomly assign one tile to contain a red X mark
    _tileWithRedX = Random().nextInt(30);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Game - ${widget.profileName}",
          style: TextStyle(fontSize: 30),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          GridView.count(
            crossAxisCount: 5,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            children: List.generate(_numberOfTiles, (index) {
              return GestureDetector(
                onTap: () {
                  if (!_isTileClicked[index]) {
                    setState(() {
                      _isTileClicked[index] = true; // Mark tile as clicked
                    });
                  }
                },
                child: Stack(
                  children: [
                    Visibility(
                      visible: _isBorderVisible[index],
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black),
                        ),
                      ),
                    ),
                    Visibility(
                      visible: !_isTileClicked[index],
                      child: Center(
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    ),
                    // Conditionally show the red X mark if this tile is the one and has been clicked
                    if (_isTileClicked[index] && index == _tileWithRedX)
                      Center(
                        child:
                            Icon(Icons.whatshot, size: 70, color: Colors.red),
                      ),
                  ],
                ),
              );
            }),
          ),
          Align(
            alignment: Alignment.center,
            child: Container(
              margin: EdgeInsets.all(
                  2.0), // Adds margin around the wallet container
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
        ],
      ),
    );
  }
}
