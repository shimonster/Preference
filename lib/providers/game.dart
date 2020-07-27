import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import './auth.dart';
import '../helpers/game_id.dart';

class Game extends ChangeNotifier {
  Game(this.auth);

  final Auth auth;
  String gameId;
  int playerNumber;
  bool isDealer;

  var client = http.Client();
  String project = 'https://preference-1cc9d.firebaseio.com';

  Future<void> createGame(String nickname) async {
    final authResponse = await auth.createAccount();
    final response = await client.post(
      '$project/games.json?auth=${authResponse['idToken']}',
      body: json.encode({
        'players': {
          '0': {'nickname': nickname, 'uid': authResponse['localId']}
        }
      }),
    );
    gameId = json.decode(response.body)['name'];
    playerNumber = 0;
    notifyListeners();
  }

  Future<void> joinGame(String name, String nickname) async {
    final authResponse = await auth.createAccount();
    final gameJson = await client
        .get('$project/games/$name.json?auth=${authResponse['idToken']}');
    final game = json.decode(gameJson.body);
    await client.patch(
      '$project/games/$name.json?auth=${authResponse['idToken']}',
      body: json.encode({
        'players': [
          ...game['players'],
          {'nickname': nickname, 'uid': authResponse['localId']}
        ]
      }),
    );
    playerNumber = game['players'].length;
    gameId = name;
    notifyListeners();
  }

  Future<void> leaveGame() async {
    await client.delete('$project/games/$gameId/$playerNumber.json');
    gameId = null;
    playerNumber = null;
    isDealer = null;
  }

  @override
  void dispose() {
    super.dispose();
    client.close();
  }
}
