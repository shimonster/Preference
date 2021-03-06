import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../SPMP.dart';
import './cards.dart' as c;
import './client.dart';

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
    cards = c.Cards(client: client);
    print('made cards');
    client.startClient(gId, nickname, uid);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('currentGame', gId);
    await prefs.setInt('currentPlayer', 0);
    gameId = gId;
    notifyListeners();
  }

  Map<String, dynamic> sortPlayers(String uid) {
    Map<String, Map<String, dynamic>> newPlayers = {...players};
    print('sort players was run');
    void sort() {
      if (newPlayers.keys.toList().first == uid) {
        return;
      }
      final entries = newPlayers.entries.toList();
      final first = entries[0];
      entries.add(first);
      entries.removeAt(0);
      newPlayers = entries.fold<Map<String, Map<String, dynamic>>>(
          {},
          (previousValue, element) =>
              {...previousValue, element.key: element.value});
      if (newPlayers.keys.toList().first != uid) {
        sort();
      }
    }

    sort();
    return newPlayers;
  }

  Future<void> getCurrentGame() async {
//    final prefs = await SharedPreferences.getInstance();
//    if (prefs.containsKey('currentGame')) {
//      final id = prefs.getInt('currentGame');
//      gameId = id;
//    }
//    print('prefs: $gameId');
  }

  void placeBid(int num, int suit, String id, [String turn]) {
    if (num == -1) {
      players[id]['hasBid'] = true;
      biddingId = turn ??
          players.keys.toList()[(players.keys.toList().indexOf(id) + 1) % 3];
    } else {
      final pBid = () {
        print('bid placed');
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
      if (bid == null ||
          (suit > bid['suit'] && num >= bid['rank']) ||
          num > bid['rank']) {
        print('already a bid');
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
    cards.componentStream.add('declared');
    if (bidId == client.uid) {
      cards.cards
          .where((element) => element.place == c.places.player1)
          .forEach((element) {
        element.positionStream.add('playing');
      });
    }
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

  void finishRound(BuildContext context, Map<String, int> playerTricks) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children:
              playerTricks.entries.map((value) => Text('$value')).toList(),
        ),
      ),
    ).then((value) {
      bidId = null;
      bid = null;
      isPlaying = false;
      cards.cardStream.add('about to start new round');
      client.sendMessage({'method': SPMP.acceptNewRound, 'uid': client.uid});
    });
  }

  Future<void> leaveGame() async {
    client.sendMessage({'method': SPMP.playerLeave, 'uid': client.uid});
    client.ws?.close();
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
