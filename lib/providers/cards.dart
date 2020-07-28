import 'dart:math';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../widgets/playing_card.dart';

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
  Cards(this._cards,
      {this.token, this.uid, this.gameId, this.playerNumber, this.client}) {
    print('constructor');
    if (token != null && gameId != null) {
      dealer = 0;
      if (isDealer) {
        print('creating cards');
        List<Card> addCard = [];
        for (var i = 0; i < 32; i++) {
          print((i / 8).floor());
          addCard.add(
            Card(
              ranks.values[i % 8],
              suits.values[(i / 8).floor()],
              null,
            ),
          );
        }
        _cards = addCard;
        print(_cards);
        //places
//          assert(_cards
//                  .where((element) => element.place == places.player1)
//                  .length ==
//              10);
//          assert(_cards
//                  .where((element) => element.place == places.player2)
//                  .length ==
//              10);
//          assert(_cards
//                  .where((element) => element.place == places.player3)
//                  .length ==
//              10);
//          assert(
//              _cards.where((element) => element.place == places.widow).length ==
//                  2);
//          //suits
        assert(
            _cards.where((element) => element.suit == suits.suit1).length == 8);
        assert(
            _cards.where((element) => element.suit == suits.suit2).length == 8);
        assert(
            _cards.where((element) => element.suit == suits.suit3).length == 8);
        assert(
            _cards.where((element) => element.suit == suits.suit4).length == 8);
        //ranks
        assert(
            _cards.where((element) => element.number == ranks.rank07).length ==
                4);
        assert(
            _cards.where((element) => element.number == ranks.rank08).length ==
                4);
        assert(
            _cards.where((element) => element.number == ranks.rank09).length ==
                4);
        assert(
            _cards.where((element) => element.number == ranks.rank10).length ==
                4);
        assert(
            _cards.where((element) => element.number == ranks.rank11).length ==
                4);
        assert(
            _cards.where((element) => element.number == ranks.rank12).length ==
                4);
        assert(
            _cards.where((element) => element.number == ranks.rank13).length ==
                4);
        assert(
            _cards.where((element) => element.number == ranks.rank14).length ==
                4);
        randomize();
      }
    }
  }

  final String token;
  final String uid;
  final String gameId;
  final int playerNumber;
  final http.Client client;
  int dealer;
  double width;
  double height;
  static const project = 'https://preference-1cc9d.firebaseio.com';
  List<Card> _cards = [];

  List<Card> get cards {
    return [..._cards];
  }

  bool get isDealer {
    return dealer == playerNumber && dealer != null;
  }

  Future<void> setUpStream() async {
    print('stream');
    final response = await client.get(
      '$project/games/$gameId/cards.json?auth=$token',
      headers: {
        'Accept': 'text/event-stream',
      },
    );
    print('after stream');
    print(response.persistentConnection);
    print(json.decode(response.body));
  }

  Future<void> randomize() async {
    if (isDealer) {
      print('setting cards');
      _cards.shuffle(Random());
      _cards.forEach((element) {
        final elemId = _cards.indexOf(element);
        _cards[elemId].place = elemId >= 30
            ? places.widow
            : elemId >= 20
                ? places.player3
                : elemId >= 10 ? places.player2 : places.player1;
      });
      final response = await client.post(
        '$project/games/-$gameId/cards.json?auth=$token',
        body: json.encode(
          _cards.asMap().map(
                (i, e) => MapEntry(i.toString(), {
                  'rankI': e.place.index.toString(),
                  'suitI': e.suit.index.toString(),
                  'placeI': e.place.index.toString()
                }),
              ),
        ),
      );
      print(response.body);
    }
  }

  List<PlayingCard> _getLocationCards(
      places place, double bottom, double top, double right, double left) {
    var thisCards = [
      ..._cards.where((element) => element.place == place).toList()
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
