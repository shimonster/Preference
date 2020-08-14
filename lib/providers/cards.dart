// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/foundation.dart';

import '../widgets/playing_card.dart';
import '../providers/client.dart';
import '../SPMP.dart';

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
  Cards({this.gameId, this.client}) {
    print('created new cards');
  }

  String token;
  String uid;
  String turn;
  final Client client;
  final int gameId;
  int dealer;
  double width = html.window.innerWidth.toDouble();
  double height = html.window.innerHeight.toDouble();

  List<Card> _cards = [];
  List<PlayingCard> p1Cards = [];
  List<PlayingCard> p2Cards = [];
  List<PlayingCard> p3Cards = [];
  List<PlayingCard> widows = [];

  List<Card> get cards {
    return [..._cards];
  }

  void setCards(List<Card> newCards) {
    _cards = newCards;
    p1Cards = _getLocationCards(places.player1, 30, null, 0, null);
    p2Cards = _getLocationCards(places.player2, null, 0, null, 30);
    p3Cards = _getLocationCards(places.player3, null, 0, 30, null);
    widows = _getLocationCards(places.widow, null, 30, null, 0);
  }

  void move(
      int rank, int suit, int place, String method, bool isMe, String uid) {
    final idx = _cards.indexWhere((element) =>
        element.number.index == rank && element.suit.index == suit);
    print('idx of widow: $idx');
    _cards[idx].place = places.values[place];
    print('new place: ${_cards[idx].place}');
    if (isMe) {
      client.sendMessage({
        'method': method,
        'rank': rank,
        'suit': suit,
        'uid': uid,
      });
    }
    if (method == SPMP.collectWidow) {
      print('moving to player who collected widow');
      print(place);
      final newCards = _getLocationCards(
          places.values[place],
          place == 0 ? 30 : null,
          place == 0 ? null : 0,
          place == 0 ? 0 : place == 1 ? null : 30,
          place == 1 ? 30 : null);
      print('length of new cards: ${newCards.length}');
      if (place == 0) {
        p1Cards = newCards;
      } else if (place == 1) {
        p2Cards = newCards;
      } else {
        p3Cards = newCards;
      }
      print([p1Cards, p2Cards, p3Cards][place]);
      [p1Cards, p2Cards, p3Cards][place].forEach((element) {
        print('changed position: $rank, $suit');
        element.move(Duration(milliseconds: 200),
            eRight: element.right,
            eLeft: element.left,
            eTop: element.top,
            eBottom: element.bottom);
        element.positionStream.add('position');
      });
    }
  }

  List<PlayingCard> _getLocationCards(
      places place, double bottom, double top, double right, double left) {
    var thisCards = [
      ..._cards.where((element) => element.place == place).toList()
    ];
    print(
        'cards length from location cards: ${thisCards.length}, place: $place');
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
}
