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

class StartGame extends StatelessWidget {
  final String profileName;

  StartGame({required this.profileName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Game - $profileName",
          style: TextStyle(fontSize: 30),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }
}
