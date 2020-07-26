import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Game extends ChangeNotifier {
  String gameId;
  int playerNumber;
  bool isDealer;

  var client = http.Client();
  String project = 'https://preference-1cc9d.firebaseio.com';

  Future<void> createGame(String nickname) async {
    final name = UniqueKey().toString();
//    final authResponse = await client.post(
//        'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=AIzaSyDpQioFovwZvuPZMzlkK6xoJFM1uj5EkAg');
//    print(json.decode(authResponse.body)['idToken']);
    final response = await client.get(
//      'https://preference-1cc9d.firebaseio.com/games.json?access_token=${json.decode(authResponse.body)['idToken']}',
      'https://preference-1cc9d.firebaseio.com/games.json',
//      body: json.encode({'Player1': nickname}),
    );
    print(response.body);
    gameId = name;
    playerNumber = 1;
    notifyListeners();
  }

  Future<void> joinGame(String name, String nickname) async {
    final gamesJson = await client.get('$project/games');
    final games = json.decode(gamesJson.body);
    final number = games[name].length + 1;
    await client.post(
      '$project/games/$name',
      body: json.encode({'Player $number': nickname}),
    );
    playerNumber = number;
    gameId = name;
    notifyListeners();
  }

  Future<void> leaveGame() async {
    await client.delete(
        'https://preference-1cc9d.firebaseio.com/games/$gameId/Player $playerNumber');
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
