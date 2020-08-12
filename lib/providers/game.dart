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
  String bidId;
  String biddingId;
  int dealer = 0;
  bool isPlaying = false;
  String gameState = SPMP.notStarted;
  int gameId;
  Map<String, Map<String, dynamic>> players;
  final Client client;
  c.Cards cards;

  Future<void> createGame(String nickname) async {
    final gId = 1234;
    final uid = Uid().toString();
    client.startClient(gId, nickname, uid);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('currentGame', gId);
    await prefs.setInt('currentPlayer', 0);
    gameId = gId;
    cards = c.Cards(gameId: gameId, client: client);
    notifyListeners();
  }

  Future<void> joinGame(int gId, String nickname) async {
    final uid = Uid().toString();
    client.startClient(gId, nickname, uid);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('currentGame', gId);
    await prefs.setInt('currentPlayer', 0);
    gameId = gId;
    cards = c.Cards(gameId: gameId, client: client);
    notifyListeners();
  }

  Future<void> getCurrentGame() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('currentGame')) {
      final id = prefs.getInt('currentGame');
      gameId = id;
    }
    print('prefs: $gameId');
  }

  bool placeBid(int num, int suit, String id) {
    print('placed bid: $id');
    if (bid == null) {
      bid = {'suit': suit, 'rank': num};
      bidId = id;
      players.forEach((key, value) {
        if (key == bidId) {
          players[bidId]['hasBid'] = true;
        } else {
          if (num != -1) {
            players[key]['hasBid'] = false;
          }
        }
      });
      if (id == client.uid) {
        client.sendMessage(
            {'method': SPMP.bid, 'rank': num, 'suit': suit, 'uid': client.uid});
      }
    } else if (bid['suit'] > suit && bid['rank'] > num) {
      bid = {'suit': suit, 'rank': num};
      bidId = id;
      players.forEach((key, value) {
        if (key == bidId) {
          players[bidId]['hasBid'] = true;
        } else {
          if (num != -1) {
            players[key]['hasBid'] = false;
          }
        }
      });
      if (id == client.uid) {
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
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
    leaveGame();
  }
}
