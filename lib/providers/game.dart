import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import './cards.dart' as c;
import 'client.dart';

class Uid extends UniqueKey {
  @override
  toString() {
    return shortHash(this);
  }
}

class Game extends ChangeNotifier {
  Game(this.client);

  int gameId;
  int playerNumber;
  final Client client;

  c.Cards get cards {
    return c.Cards(gameId: gameId, playerNumber: playerNumber);
  }

  Future<void> createGame(String nickname) async {
    final gId = 1234;
    final uid = Uid().toString();
    client.startClient(gId, nickname, uid);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('currentGame', gId);
    await prefs.setInt('currentPlayer', 0);
    gameId = gId;
    playerNumber = 0;
    notifyListeners();
  }

  Future<void> joinGame(String name, String nickname) async {
    notifyListeners();
  }

  Future<void> getCurrentGame() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('currentGame')) {
      final id = prefs.getInt('currentGame');
      final number = prefs.getInt('currentPlayer');
      gameId = id;
      playerNumber = number;
    }
    print('prefs: $gameId');
  }

  Future<void> leaveGame() async {}

  @override
  void dispose() {
    super.dispose();
    leaveGame();
  }
}
