import '../SPMP.dart';
import './server_cards.dart';

class GameManagement {
  GameManagement(this.cardsController, this.sendMessage);

  final CardsManagement cardsController;
  final void Function(Map<String, dynamic>, [String]) sendMessage;
  Map<String, int> bid;
  String bidId;
  String biddingId;
  Map<String, Map<String, dynamic>> players = {};
  int dealer = 0;
  bool isPlaying = false;
  String gameState = SPMP.notStarted;

  void placeBid(int num, int suit, String uid) {
    print('place bid was run');
    if (num == -1) {
      // player passed
      print('plater passed');
      players[uid]['hasBid'] = true;
      biddingId =
          players.keys.toList()[(players.keys.toList().indexOf(uid) + 1) % 3];
      sendMessage({
        'method': SPMP.pass,
        'rank': num,
        'suit': suit,
        'uid': uid,
        'turn': biddingId,
      }, uid);
    } else {
      // player placed bid :)
      final pBid = () {
        print('a bid was plaed');
        bid = {'suit': suit, 'rank': num};
        bidId = uid;
        biddingId =
            players.keys.toList()[(players.keys.toList().indexOf(uid) + 1) % 3];
        players.forEach((key, value) {
          if (key == uid) {
            players[uid]['hasBid'] = true;
          } else {
            players[key]['hasBid'] = false;
          }
        });
        sendMessage({
          'method': SPMP.bid,
          'rank': num,
          'suit': suit,
          'uid': uid,
          'turn': biddingId,
        }, uid);
      };
      if (bid == null) {
        print('no bids so far');
        pBid();
      } else if ((bid['suit'] > suit && bid['rank'] >= num) ||
          bid['rank'] > num) {
        print('there was already a bid');
        pBid();
      }
    }

    print(players.values.toList().map((e) => e['hasBid']).toList());
    // if everyone pid or passed
    if (players.values.every((element) => element['hasBid'])) {
      print('every one bid');
      gameState = SPMP.discarding;
      List<Map<String, dynamic>> widow = cardsController.cards
          .where((element) => element['uid'] == SPMP.widow)
          .toList();
      for (var i = 0; i < 2; i++) {
        cardsController.move(widow[i]['rank'], widow[i]['suit'],
            players.keys.toList().indexOf(bidId), SPMP.collectWidow);
      }
      sendMessage({'method': SPMP.collectWidow, 'uid': bidId});
    }
  }

  void declareGame(int rank, int suit) {
    bid = {'rank': rank, 'suit': suit};
    gameState = SPMP.playing;
    cardsController.turn = bidId;
    sendMessage({
      'method': SPMP.declare,
      'rank': rank,
      'suit': suit,
    });
  }

  bool acceptPlay(String uid) {
    players[uid]['isPlaying'] = true;
    if (players.values.every((element) => element['isPlaying'])) {
      isPlaying = true;
      gameState = SPMP.bidding;
      biddingId = players.keys.toList().first;
    }
    return isPlaying;
  }

  void joinGame(String uid, String nickname) {
    players.putIfAbsent(
        uid, () => {'nickname': nickname, 'isPlaying': false, 'hasBid': false});
  }
}
