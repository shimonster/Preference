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
  Map<String, int> playerTricks;

  List<Map<String, dynamic>> randomize() {
    playerTricks =
        server.gameController.players.map((key, value) => MapEntry(key, 0));
    playerTricks = server.gameController.allPlayers.entries.fold(
        {}, (previousValue, element) => {...previousValue, element.key: 0});
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
      print('widow collected');
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

  String findBiggestCard(
      List<Map<String, dynamic>> placed, bool isCollectingWidow) {
    String collectUid;
    Map<String, dynamic> biggestCard;
    final trump = server.gameController.bid['suit'];
    // determines the biggest card
    void makeBiggest(Map<String, dynamic> i) {
      print('new biggest card');
      biggestCard = i;
      collectUid = cards.firstWhere((element) =>
          (element['suit'] == biggestCard['suit']) &&
          (element['rank'] == biggestCard['rank']))['uid'];
    }

    for (var i in placed) {
      print(i);
      bool condish() =>
          (i['rank'] > biggestCard['rank'] ||
              (biggestCard['suit'] != trump && i['suit'] == trump)) &&
          (i['suit'] == biggestCard['suit'] || i['suit'] == trump);
      if (biggestCard == null) {
        makeBiggest(i);
      } else if (isCollectingWidow ? !condish() : condish()) {
        makeBiggest(i);
      }
    }
    return collectUid;
  }

  void moveCollectedTrick(bool isCollectingWidow, String collectUid,
      List<Map<String, dynamic>> placed) {
    final pIdx =
        server.gameController.players.keys.toList().indexOf(collectUid);
    print(collectUid);
    print(playerTricks);
    final isP1 = pIdx == 0;
    final isP2 = pIdx == 1;
    playerTricks[collectUid] += 1;
    for (var i in placed) {
      move(
          i['rank'],
          i['suit'],
          isP1
              ? SPMP.trick1
              : isP2
                  ? SPMP.trick2
                  : SPMP.trick3);
    }
//    if (isCollectingWidow) {
//      final widow = cards.firstWhere((element) => element['uid'] == SPMP.widow);
//      move(widow['rank'], widow['suit'],
//          isP1 ? SPMP.player1 : isP2 ? SPMP.player2 : SPMP.player3);
//    }
  }

  void collectTrick(int place) {
    print(player1Cards);
    print(player2Cards);
    print(player3Cards);
    if (player1Cards == player2Cards &&
        player2Cards == player3Cards &&
        (server.gameController.gameState == SPMP.playing ||
            server.gameController.gameState == SPMP.collectingWidow)) {
      final isCollectingWidow =
          server.gameController.gameState == SPMP.collectingWidow;
      final placed = cards
          .where((element) =>
              element['place'] == SPMP.center1 ||
              element['place'] == SPMP.center2 ||
              element['place'] == SPMP.center3 ||
              element['place'] == SPMP.centerWidow)
          .toList();
      final collectUid = findBiggestCard(placed, isCollectingWidow);
      Map<String, dynamic> widow;
      if (isCollectingWidow) {
        widow = cards.firstWhere((element) => element['uid'] == SPMP.widow);
      }
      moveCollectedTrick(isCollectingWidow, collectUid, placed);
      sendMessage({
        'method': SPMP.trickCollected,
        'turn': turn,
        'uid': collectUid,
        'widow rank': isCollectingWidow ? widow['rank'] : null,
        'widow suit': isCollectingWidow ? widow['suit'] : null,
      });
      endGame();
    }
  }

  void endGame() {
    if (player1Cards == 0) {
      final last = server.gameController.allPlayers.entries.last;
      server.gameController.allPlayers
          .removeWhere((key, value) => key == last.key);
      server.gameController.allPlayers = {
        last.key: last.value,
        ...server.gameController.allPlayers
      };
      sendMessage({
        'method': SPMP.finishRound,
        'playerTricks': playerTricks,
      });
    }
  }

  void acceptNewRound(String uid) {
    server.gameController.allPlayers[uid]['hasAcceptedNewGame'] = true;
    if (server.gameController.players.values
        .toList()
        .every((element) => element['hasAcceptedNewGame'])) {
      server.gameController.allPlayers =
          server.gameController.allPlayers.map((key, value) {
        final newVal = value;
        newVal['hasAcceptedNewGame'] = false;
        newVal['hasBid'] = false;
        return MapEntry(key, newVal);
      });
      server.gameController.bidId = null;
      server.gameController.bid = null;
      final entries = server.gameController.allPlayers.entries.toList();
      entries.add(entries[0]);
      entries.removeAt(0);
      final newCards = randomize();
      sendMessage({
        'method': SPMP.startPlaying,
        'cards': newCards,
        'biddingId': server.gameController.biddingId,
        'players': server.gameController.players,
      });
    }
  }
}
