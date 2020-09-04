import '../SPMP.dart';
import './server_cards.dart';

class GameManagement {
  GameManagement(this.cardsController, this.sendMessage);

  final CardsManagement cardsController;
  final void Function(Map<String, dynamic>, [String]) sendMessage;
  Map<String, int> bid;
  String bidId;
  String biddingId;
  Map<String, Map<String, dynamic>> get players {
    return allPlayers == null
        ? null
        : allPlayers.entries.toList().fold(
            {},
            (previousValue, element) => previousValue.keys.toList().length < 3
                ? {...previousValue, element.key: element.value}
                : previousValue);
  }

  Map<String, Map<String, dynamic>> allPlayers = {};
  int dealer = 0;
  bool isPlaying = false;
  String gameState = SPMP.notStarted;

  void collectWidow() {
    print(players.values.toList().map((e) => e['hasBid']).toList());
    // if everyone bid or passed
    if (players.values.every((element) => element['hasBid'])) {
      print('every one bid');
      gameState = SPMP.discarding;
      List<Map<String, dynamic>> widow = cardsController.cards
          .where((element) => element['uid'] == SPMP.widow)
          .toList();
      for (var i = 0; i < 2; i++) {
        cardsController.move(widow[i]['rank'], widow[i]['suit'],
            players.keys.toList().indexOf(bidId), bidId);
      }
      sendMessage({'method': SPMP.collectWidow, 'uid': bidId});
    }
  }

  void pBid(String uid, int suit, int num) {
    print('a bid was plaed');
    bid = {'suit': suit, 'rank': num};
    bidId = uid;
    biddingId =
        players.keys.toList()[(players.keys.toList().indexOf(uid) + 1) % 3];
    players.forEach((key, value) {
      allPlayers[key]['hasBid'] = key == uid;
    });
  }

  void placeBid(int num, int suit, String uid) {
    print('place bid was run');
    void sendBidMessage() {
      sendMessage({
        'method': num == -1 ? SPMP.pass : SPMP.bid,
        'rank': num,
        'suit': suit,
        'uid': uid,
        'turn': biddingId,
      }, uid);
    }

    if (bid != null) {
      print(
          '${bid == null} || (${bid['suit'] > suit} && ${bid['rank'] >= num}) ||'
          '${bid['rank'] > num}');
    }

    if (num == -1) {
      print('player passed');
      allPlayers[uid]['hasBid'] = true;
      biddingId =
          players.keys.toList()[(players.keys.toList().indexOf(uid) + 1) % 3];
      sendBidMessage();
    } else if (bid == null ||
        (suit > bid['suit'] && num >= bid['rank']) ||
        num > bid['rank']) {
      print('a valid bid was placed');
      pBid(uid, suit, num);
      sendBidMessage();
    }
    collectWidow();
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
    allPlayers[uid]['isPlaying'] = true;
    if (players.values.every((element) => element['isPlaying'])) {
      isPlaying = true;
      gameState = SPMP.bidding;
      biddingId = players.keys.toList().first;
    }
    return isPlaying;
  }

  void joinGame(String uid, String nickname) {
    allPlayers.putIfAbsent(
        uid,
        () => {
              'nickname': nickname,
              'isPlaying': false,
              'hasBid': false,
              'hasAcceptedNewGame': false
            });
  }
}
