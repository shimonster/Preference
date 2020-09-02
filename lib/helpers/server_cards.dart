import 'dart:math';

import './server.dart';

import '../SPMP.dart';

class CardsManagement {
  CardsManagement(this.sendMessage, this.server);

  final void Function(Map<String, dynamic> message, [String exclude])
      sendMessage;
  final Server server;
  List<Map<String, dynamic>> cards;
  String turn;
  int player1Cards = 0;
  int player2Cards = 0;
  int player3Cards = 0;
  int player1Tricks = 0;
  int player2Tricks = 0;
  int player3Tricks = 0;

  List<Map<String, dynamic>> randomize() {
    List<Map<String, dynamic>> addCard = [];
    for (var i = 0; i < 32; i++) {
      addCard.add({
        'rank': i % 8,
        'suit': (i / 8).floor(),
        'uid': null,
      });
    }
    cards = addCard;
    cards.shuffle(Random());
    cards.asMap().forEach((elemId, element) {
      if (elemId < 30) {
        cards[elemId]['uid'] =
            server.gameController.players.keys.toList()[(elemId / 10).floor()];
      } else {
        cards[elemId]['uid'] = SPMP.widow;
      }
    });
    player1Cards = 10;
    player2Cards = 10;
    player3Cards = 10;
    return cards;
  }

  void move(int rank, int suit, int place, [String uid]) {
    cards.firstWhere((element) =>
        element['rank'] == rank && element['suit'] == suit)['place'] = place;
    print(place);
    // placing a card
    placeCard(place, uid, suit, rank);
    // collecting widow
    collectWidow(place, uid);
    // disposed cards
    dispose(place);
  }

  void placeCard(int place, String uid, int suit, int rank) {
    // changes turn and sends message
    if (place >= 5 && place <= 7) {
      turn = server.gameController.players.keys.toList()[
          (server.gameController.players.keys.toList().indexOf(uid) + 1) % 3];
      sendMessage({
        'method': SPMP.place,
        'suit': suit,
        'rank': rank,
        'turn': turn,
      }, uid);
      // updates card amounts
      if (place == SPMP.center1) {
        player1Cards -= 1;
      } else if (place == SPMP.center2) {
        player2Cards -= 1;
      } else if (place == SPMP.center3) {
        player3Cards -= 1;
      }
      // someone collected trick
      collectTrick(place);
    }
  }

  void collectWidow(int place, String uid) {
    // if the new place is someones cards
    if (place < 3) {
      cards = cards
          .map((e) =>
              e..update('uid', (value) => value == SPMP.widow ? uid : value))
          .toList();
    }
    if (place == SPMP.player1) {
      player1Cards += 2;
    } else if (place == SPMP.player2) {
      player2Cards += 2;
    } else if (place == SPMP.player3) {
      player3Cards += 2;
    }
  }

  void dispose(int place) {
    if (place == SPMP.disposed) {
      player1Cards = 10;
      player2Cards = 10;
      player3Cards = 10;
    }
  }

  void collectTrick(int place) {
    if (player1Cards == player2Cards &&
        player2Cards == player3Cards &&
        server.gameController.gameState == SPMP.playing) {
      print('collect trick server');
      String collectUid;
      Map<String, dynamic> biggestCard;
      // finds cards that were placed
      final placed = cards.where((element) =>
          element['place'] == SPMP.center1 ||
          element['place'] == SPMP.center2 ||
          element['place'] == SPMP.center3);
      // determines the biggest card
      for (var i in placed) {
        print(i);
        if (biggestCard == null ||
            (i['rank'] > biggestCard['rank'] &&
                i['suit'] >= biggestCard['suit']) ||
            i['suit'] > biggestCard['suit']) {
          biggestCard = i;
          collectUid = cards.firstWhere((element) =>
              element['suit'] == biggestCard['suit'] &&
              element['rank'] == biggestCard['rank'])['uid'];
        }
      }
      final pIdx =
          server.gameController.players.keys.toList().indexOf(collectUid);
      print(pIdx);
      final isP1 = pIdx == 0;
      final isP2 = pIdx == 1;
      if (isP1) {
        player1Tricks += 1;
      } else if (isP2) {
        player2Tricks += 1;
      } else {
        player3Tricks += 1;
      }
      for (var i in placed) {
        move(i['rank'], i['suit'],
            isP1 ? SPMP.trick1 : isP2 ? SPMP.trick2 : SPMP.trick3);
      }
      sendMessage({
        'method': SPMP.trickCollected,
        'turn': turn,
        'uid': collectUid,
      });
      if (player1Cards == 0) {
        sendMessage({
          'method': SPMP.finishRound,
          'p1Tricks': player1Tricks,
          'p2Tricks': player2Tricks,
          'p3Tricks': player3Tricks,
        });
      }
    }
  }
}
