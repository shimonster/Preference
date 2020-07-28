import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import './auth.dart';

class Game extends ChangeNotifier {
  Game(this.auth);

  final Auth auth;
  String gameId;
  int playerNumber;

  var client = http.Client();
  static const project = 'https://preference-1cc9d.firebaseio.com';

  Future<void> createGame(String nickname) async {
    final authResponse = await auth.createAccount();
    final response = await client.post(
      '$project/games.json?auth=${authResponse['idToken']}',
      body: json.encode({
        'dealer': 0,
        'players': {
          '0': {'nickname': nickname, 'uid': authResponse['localId']}
        }
      }),
    );
    final String id = json.decode(response.body)['name'].replaceFirst('-', '');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentGame', id);
    await prefs.setInt('currentPlayer', 0);
    gameId = id;
    playerNumber = 0;
    notifyListeners();
  }

  Future<void> joinGame(String name, String nickname) async {
    final authResponse = await auth.createAccount();
    final gameRoute =
        '$project/games/$name.json?auth=${authResponse['idToken']}';
    final gameJson = await client.get(gameRoute);
    final game = json.decode(gameJson.body);
    await client.patch(
      gameRoute,
      body: json.encode({
        'players': [
          ...game['players'],
          {'nickname': nickname, 'uid': authResponse['localId']}
        ]
      }),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentGame', name);
    await prefs.setInt('currentPlayer', game['players'].length);
    playerNumber = game['players'].length;
    gameId = name;
    notifyListeners();
  }

  Future<void> getCurrentGame() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('currentGame')) {
      final id = prefs.getString('currentGame');
      final number = prefs.getInt('currentPlayer');
      gameId = id;
      playerNumber = number;
    }
    print('prefs: $gameId');
  }

  Future<void> leaveGame() async {
    gameId = null;
    playerNumber = null;
    final players = json.decode((await client
            .get('$project/games/$gameId/players.json?auth=${auth.token}'))
        .body);
    await client.delete(
        '$project/games/$gameId${players.length != 1 ? '/players/$playerNumber' : ''}.json?auth=${auth.token}');
    await auth.deleteAccount();
  }

  @override
  void dispose() {
    super.dispose();
    leaveGame();
    client.close();
  }
}
