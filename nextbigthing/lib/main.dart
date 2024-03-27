import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;


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
  List<bool> _isTitleVisible = List.generate(30, (index) => true);
  List<bool> _isBorderVisible = List.generate(30, (index) => true);
  List<bool> _isTileEnabled = List.generate(30, (index) => true);

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
      body: GridView.count(
        crossAxisCount: 5, // Changed to 5x6 grid
        children: List.generate(30, (index) {
          return GestureDetector(
            onTap: () {
              if (_isTileEnabled[index]) {
                setState(() {
                  if (_isTitleVisible[index]) {
                    _isTitleVisible[index] = false;
                  } else {
                    _isBorderVisible[index] = !_isBorderVisible[index];
                  }
                  _isTileEnabled[index] = false; // Disable the tile
                });
              }
            },
            child: Stack(
              children: [
                Visibility(
                  visible: _isBorderVisible[index],
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black), // Add black borders
                    ),
                  ),
                ),
                Visibility(
                  visible: _isTitleVisible[index],
                  child: Center(
                    child: Container(
                      width: 70, // Adjust the width of the green tile
                      height: 70, // Adjust the height of the green tile
                      decoration: BoxDecoration(
                        color: Colors.green, // Green color tile
                        borderRadius: BorderRadius.circular(5), // Rounded edges
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}