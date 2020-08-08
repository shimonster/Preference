import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../widgets/playing_card.dart';
import '../SPMP.dart';
import '../providers/client.dart';

enum ranks {
  rank07,
  rank08,
  rank09,
  rank10,
  rank11,
  rank12,
  rank13,
  rank14,
}

enum suits {
  suit1,
  suit2,
  suit3,
  suit4,
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
}

class Card {
  final ranks number;
  final suits suit;
  places place;

  Card(this.number, this.suit, this.place);
}

class Cards extends ChangeNotifier {
  Cards({this.gameId, this.playerNumber, this.client});

  String token;
  String uid;
  int turn;
  final Client client;
  final int gameId;
  final int playerNumber;
  int dealer;
  double width;
  double height;
  List<Card> privateCards = [];

  List<Card> get cards {
    return [...privateCards];
  }

  bool get isDealer {
    return dealer == playerNumber && dealer != null;
  }

//  Map<String, Map<String, String>> randomize() {
//    dealer = 0;
//    List<Card> addCard = [];
//    for (var i = 0; i < 32; i++) {
//      addCard.add(
//        Card(
//          ranks.values[i % 8],
//          suits.values[(i / 8).floor()],
//          null,
//        ),
//      );
//    }
//    _cards = addCard;
//    _cards.shuffle(Random());
//    _cards.forEach((element) {
//      final elemId = _cards.indexOf(element);
//      _cards[elemId].place = elemId >= 30
//          ? places.widow
//          : elemId >= 20
//              ? places.player3
//              : elemId >= 10 ? places.player2 : places.player1;
//    });
//    final newCards = _cards.asMap().map(
//          (i, e) => MapEntry(i.toString(), {
//            'rankI': e.number.index.toString(),
//            'suitI': e.suit.index.toString(),
//            'placeI': e.place.index.toString()
//          }),
//        );
//    print(newCards);
//    return newCards;
//  }

  void move(
      int rank, int suit, int place, String method, bool isMe, String uid) {
    privateCards
        .firstWhere((element) =>
            element.number.index == rank && element.suit.index == suit)
        .place = places.values[place];
    if (isMe) {
      client.sendMessage({
        'method': method,
        'rank': rank,
        'suit': suit,
        'uid': uid,
      });
    }
  }

  //
  //
  //
  //
  //
  //
  //
  //
  //
  //
  //
  //
  //
  //
  //
  //

  List<PlayingCard> _getLocationCards(
      places place, double bottom, double top, double right, double left) {
    var thisCards = [
      ...privateCards.where((element) => element.place == place).toList()
    ];
    final double increment = 50;
    double i = -1;
    final List<Card> sortedCards = [];
    if (place == places.player1) {
      thisCards.sort((a, b) {
        if (int.parse(a.suit.toString()[10]) >
            int.parse(b.suit.toString()[10])) {
          return -1;
        } else {
          return 1;
        }
      });
      for (var i = 0; i < 4; i++) {
        final int start =
            thisCards.indexWhere((element) => element.suit == suits.values[i]);
        final int end = thisCards
            .lastIndexWhere((element) => element.suit == suits.values[i]);
        final List<Card> list =
            start == -1 ? [] : thisCards.sublist(start, end + 1)
              ..sort((a, b) {
                if (int.parse(
                        '${a.number.toString()[10]}${a.number.toString().length > 11 ? a.number.toString()[11] : ''}') >
                    int.parse(
                        '${b.number.toString()[10]}${b.number.toString().length > 11 ? b.number.toString()[11] : ''}')) {
                  return -1;
                } else {
                  return 1;
                }
              });
        sortedCards.addAll(list);
      }
      thisCards = sortedCards;
    }
    return thisCards.map((e) {
      i++;
      return PlayingCard(
        e.suit,
        e.number,
        e.place,
        top: top == 0
            ? ((height / 2) -
                    (((thisCards.length * increment) +
                            width * PlayingCardState().multiplySizeHeight) /
                        2)) +
                (i * increment)
            : top,
        bottom: bottom == 0
            ? ((height / 2) -
                    (((thisCards.length * increment) +
                            width * PlayingCardState().multiplySizeHeight) /
                        2)) +
                (i * increment)
            : bottom,
        right: right == 0
            ? ((width / 2) -
                    (((thisCards.length * increment) +
                            width * PlayingCardState().multiplySizeWidth) /
                        2)) +
                (i * increment)
            : right,
        left: left == 0
            ? ((width / 2) -
                    (((thisCards.length * increment) +
                            width * PlayingCardState().multiplySizeWidth) /
                        2)) +
                (i * increment)
            : left,
      );
    }).toList();
  }

  List<PlayingCard> get p1Cards {
    return _getLocationCards(places.player1, 30, null, 0, null);
  }

  List<PlayingCard> get p2Cards {
    return _getLocationCards(places.player2, null, 0, null, 30);
  }

  List<PlayingCard> get p3Cards {
    return _getLocationCards(places.player3, null, 0, 30, null);
  }

  List<PlayingCard> get widows {
    return _getLocationCards(places.widow, null, 30, null, 0);
  }
}
