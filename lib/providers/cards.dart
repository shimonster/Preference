import 'dart:math';

import 'package:flutter/foundation.dart';

import '../widgets/playing_card.dart';

enum ranks {
  seven,
  eight,
  nin,
  ten,
  jack,
  queen,
  king,
  ace,
}

enum suits {
  heart,
  diamond,
  spade,
  club,
}

enum places {
  player1,
  player2,
  player3,
  widow,
  disposed,
  center1,
  center2,
  center3,
  trick1,
  trick2,
  trick3,
  tbd,
}

class Card {
  final ranks number;
  final suits suit;
  places place;

  Card(this.number, this.suit, this.place);
}

class Cards extends ChangeNotifier {
  Cards() {
    for (var i = 0; i < 32; i++) {
      _cards.add(
        Card(
          ranks.values[i % 8],
          suits.values[(i / 8).floor()],
          places.tbd,
        ),
      );
    }
  }

  List<Card> _cards = [];

  List<Card> get cards {
    return [..._cards];
  }

  void randomize() {
    _cards.shuffle(Random());
    _cards.forEach((element) {
      final elemId = _cards.indexOf(element);
      _cards[elemId].place = elemId > 30
          ? places.widow
          : elemId > 20
              ? places.player3
              : elemId > 10 ? places.player2 : places.player1;
    });
    print(_cards.map((e) => e.place).toList());
//    notifyListeners();
  }

  List<PlayingCard> get p1Cards {
    double i = -1;
    return _cards
        .where((element) => element.place == places.player1)
        .toList()
        .map((e) {
      i++;
      return PlayingCard(e.suit, e.number, bottom: 30, right: i * 20 + 10.5);
    }).toList();
  }

  List<PlayingCard> get p2Cards {
    double i = -1;
    return _cards
        .where((element) => element.place == places.player2)
        .toList()
        .map((e) {
      i++;
      return PlayingCard(e.suit, e.number, left: 30, top: i * 20 + 10.5);
    }).toList();
  }

  List<PlayingCard> get p3Cards {
    double i = -1;
    return _cards
        .where((element) => element.place == places.player3)
        .toList()
        .map((e) {
      i++;
      return PlayingCard(e.suit, e.number, right: 30, top: i * 20 + 10.5);
    }).toList();
  }

  List<PlayingCard> get widows {
    double i = -1;
    return _cards
        .where((element) => element.place == places.widow)
        .toList()
        .map((e) {
      i++;
      return PlayingCard(e.suit, e.number, top: 30, right: i * 20 + 10.5);
    }).toList();
  }
}
