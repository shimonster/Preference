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
    joinGame(1234, nickname);
  }

  Future<void> joinGame(int gId, String nickname) async {
    final uid = Uid().toString();
    client.startClient(gId, nickname, uid);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('currentGame', gId);
    await prefs.setInt('currentPlayer', 0);
    gameId = gId;
    cards = c.Cards(client: client);
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

  void placeBid(int num, int suit, String id, [String turn]) {
    if (num == -1) {
      players[id]['hasBid'] = true;
      biddingId = turn ??
          players.keys.toList()[(players.keys.toList().indexOf(id) + 1) % 3];
    } else {
      final pBid = () {
        bid = {'suit': suit, 'rank': num};
        bidId = id;
        biddingId =
            players.keys.toList()[(players.keys.toList().indexOf(id) + 1) % 3];
        players.forEach((key, value) {
          if (key == id) {
            players[id]['hasBid'] = true;
          } else {
            players[key]['hasBid'] = false;
          }
        });
      };
      if (bid == null) {
        pBid();
      } else if ((bid['suit'] > suit && bid['rank'] >= num) ||
          bid['rank'] > num) {
        pBid();
      }
    }
    if (id == client.uid) {
      client.sendMessage({
        'method': num == -1 ? SPMP.pass : SPMP.bid,
        'rank': num,
        'suit': suit,
        'uid': client.uid
      });
    }
    client.bidStream.add('player bid');
  }

  void declareGame(int rank, int suit, bool isMe) {
    bid = {'rank': rank, 'suit': suit};
    gameState = SPMP.playing;
    cards.cardStream.add('declared');
    cards.p1Cards.forEach((element) {
      element.positionStream.add('playing');
    });
    print('after add to card stream');
    print(bidId);
    cards.turn = bidId;
    if (isMe) {
      client.sendMessage({
        'method': SPMP.declare,
        'rank': rank,
        'suit': suit,
      });
    }
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
