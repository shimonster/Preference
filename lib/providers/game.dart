import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../SPMP.dart';
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

  Map<String, int> bid;
  String bidderId;
  int dealer = 0;
  bool isPlaying = false;
  String gameState = SPMP.notStarted;
  int gameId;
  int playerNumber;
  Map<String, Map<String, dynamic>> players;
  final Client client;

  c.Cards get cards {
    return c.Cards(gameId: gameId, playerNumber: playerNumber, client: client);
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

  Future<void> joinGame(int gId, String nickname) async {
    final uid = Uid().toString();
    client.startClient(gId, nickname, uid);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('currentGame', gId);
    await prefs.setInt('currentPlayer', 0);
    gameId = gId;
    playerNumber = 0;
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

  bool placeBid(int num, int suit, String bidId) {
    if (bid['suit'] > suit && bid['rank'] > num) {
      bid = {'suit': suit, 'rank': num};
      bidderId = bidId;
      players.forEach((key, value) {
        if (key == bidId) {
          players[bidId]['hasBid'] = true;
        } else {
          players[key]['hasBid'] = false;
        }
      });
      if (bidId == client.uid) {
        client.sendMessage(
            {'method': SPMP.bid, 'rank': num, 'suit': suit, 'uid': client.uid});
      }
      return true;
    }
    return false;
  }

  Future<void> leaveGame() async {
    client.sendMessage({'method': SPMP.playerLeave, 'uid': client.uid});
    final prefs = await SharedPreferences.getInstance();
//    await prefs.setInt('currentGame', null);
//    await prefs.setInt('currentPlayer', null);
    gameId = null;
    playerNumber = null;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
    leaveGame();
  }
}
