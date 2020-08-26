import 'dart:math';

import '../SPMP.dart';

class CardsManagement {
  CardsManagement(this.sendMessage);

  final void Function(Map<String, dynamic> message, [String exclude])
      sendMessage;
  List<Map<String, dynamic>> cards;
  Map<String, Map<String, dynamic>> players = {};
  String turn;
  int player1Cards = 0;
  int player2Cards = 0;
  int player3Cards = 0;
  int player1Tricks = 0;
  int player2Tricks = 0;
  int player3Tricks = 0;

  void joinGame(String uid, String nickname) {
    print('card join game');
    players.putIfAbsent(
        uid, () => {'nickname': nickname, 'isPlaying': false, 'hasBid': false});
  }

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
        cards[elemId]['uid'] = players.keys.toList()[(elemId / 10).floor()];
      } else {
        cards[elemId]['uid'] = SPMP.widow;
      }
    });
    player1Cards = 10;
    player2Cards = 10;
    player3Cards = 10;
    return cards;
  }

  bool move(int rank, int suit, int place, [String uid]) {
    bool didPlace = false;
    bool didCollectTrick = false;
    cards.firstWhere((element) =>
        element['rank'] == rank && element['suit'] == suit)['place'] = place;
    print(place);
    // placing a card
    if (place == SPMP.center1) {
      didPlace = true;
      player1Cards -= 1;
      turn =
          players.keys.toList()[(players.keys.toList().indexOf(uid) + 1) % 3];
    } else if (place == SPMP.center2) {
      didPlace = true;
      player2Cards -= 1;
      turn =
          players.keys.toList()[(players.keys.toList().indexOf(uid) + 1) % 3];
    } else if (place == SPMP.center3) {
      didPlace = true;
      player3Cards -= 1;
      turn =
          players.keys.toList()[(players.keys.toList().indexOf(uid) + 1) % 3];
    }
    if (didPlace &&
        (player1Cards == player2Cards && player2Cards == player3Cards)) {
      didCollectTrick = true;
    }
    // collecting widow
    if (place == SPMP.player1) {
      player1Cards += 2;
    } else if (place == SPMP.player2) {
      player2Cards += 2;
    } else if (place == SPMP.player3) {
      player3Cards += 2;
    }
    // disposed cards
    if (place == SPMP.disposed) {
      player1Cards = 10;
      player2Cards = 10;
      player3Cards = 10;
    }
    // collected trick
    if (place == SPMP.trick1) {
      player1Tricks += 1;
    } else if (place == SPMP.trick2) {
      player2Tricks += 1;
    } else if (place == SPMP.trick3) {
      player3Tricks += 1;
    }
    return didCollectTrick;
  }
}
