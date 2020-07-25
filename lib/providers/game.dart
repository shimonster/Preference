import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Game extends ChangeNotifier {
  String gameId;
  int playerNumber;
  bool isDealer;
  final alphabet = 'abcdefghijklmnopqrstABCDEFGHIJKLMNOPQRST' * 2;

  var client = http.Client();
  String project = 'https://preference-1cc9d.firebaseio.com';

  Stream<String> get gameStream {
    return Stream.value(gameId);
  }

  Future<void> createGame(String nickname) async {
    final name = UniqueKey().toString();
    await http.post(
      '$project/games/$name',
      body: json.encode({'Player 1': nickname}),
    );
    gameId = name;
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
  }

  Future<void> leaveGame() async {
    await client.delete('$project/games/$gameId/Player $playerNumber');
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
