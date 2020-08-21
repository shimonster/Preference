// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../widgets/playing_card.dart';
import '../providers/client.dart';
import '../SPMP.dart';
import '../helpers/card_move_extention.dart';

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
  disposing,
}

class Card {
  final ranks rank;
  final suits suit;
  places place;

  Card(this.rank, this.suit, this.place);
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
  final cardStream = StreamController.broadcast();
  final disposeStream = StreamController.broadcast();

  List<Card> _cards = [];
  List<PlayingCard> p1Cards = [];
  List<PlayingCard> p2Cards = [];
  List<PlayingCard> p3Cards = [];
  List<PlayingCard> widows = [];

  List<Card> get cards {
    return [..._cards];
  }

  void move(List<int> rank, List<int> suit, int place, String method, bool isMe,
      String uid) {
    if (place == SPMP.disposed) {
      disposeCards(isMe ? null : rank, isMe ? null : suit);
    }
    for (var i = 0; i < rank.length; i++) {
      final idx = _cards.indexWhere((element) =>
          element.rank.index == rank[i] && element.suit.index == suit[i]);
      print('idx of cards: $idx');
      _cards[idx].place = places.values[place];
      print('new place: ${_cards[idx].place}');
    }
    if (isMe) {
      client.sendMessage({
        'method': method,
        'rank': rank,
        'suit': suit,
        'uid': uid,
      });
    }
    if (method == SPMP.collectWidow) {
      collectWidow(place);
    }
    if (place == SPMP.disposing) {
      disposingCards(rank[0], suit[0]);
    }
    if (place == SPMP.disposed) {
      moveDisposed();
    }
  }

  void disposingCards(int rank, int suit) {
    // TODO: position cards better
    final crdIdx = p1Cards.indexWhere(
        (element) => element.rank.index == rank && element.suit.index == suit);
    p1Cards[crdIdx].move(
      Duration(milliseconds: 100),
      eBottom: height / 2,
      eRight: (width / 2) -
          (100 *
              _cards
                  .where((element) => element.place == places.disposing)
                  .length),
    );
    disposeStream.add('disposing');
  }

  void disposeCards([List<int> rank, List<int> suit]) {
    print('disposed cards was run');
    List<Card> disposing = [];
    final place = client.game.players.keys.toList().indexOf(client.game.bidId);
    print(place);
    final isP1 = place == 0;
    final isP2 = place == 1;
    print(_cards.map((e) => e.place).toList());
    if (rank == null) {
      disposing = _cards.where((e) => e.place == places.disposing).toList();
    }
    for (var i = 0; i < 2; i++) {
      print('loop was run');
      (isP1 ? p1Cards : isP2 ? p2Cards : p3Cards)
          .firstWhere((element) {
            if (rank == null) {
              print(disposing.length);
              return disposing
                  .any((e) => e.rank == element.rank && e.suit == element.suit);
            } else {
              disposing.add(cards.firstWhere(
                  (e) => e.rank.index == rank[i] && e.suit.index == suit[i]));
              return element.rank.index == rank[i] &&
                  element.suit.index == suit[i];
            }
          })
          .move(
            Duration(milliseconds: 100),
            eBottom: isP1 ? 200 : null,
            eTop: isP1 ? null : 200,
            eRight: isP2 ? null : 200,
            eLeft: isP2 ? 200 : null,
          )
          .then((value) => cardStream.add('after disposal'));
    }
    print(disposing);
    if (rank == null) {
      p1Cards.removeWhere((element) => disposing
          .any((e) => e.rank == element.rank && e.suit == element.suit));
    } else {
      for (var i = 0; i < 2; i++) {
        (isP2 ? p2Cards : p3Cards).removeWhere((element) =>
            element.rank.index == rank[i] && element.suit.index == suit[i]);
      }
    }
  }

  void moveDisposed() {
    final place = client.game.players.keys.toList().indexOf(client.game.bidId);
    final isP1 = place == 0;
    final isP2 = place == 1;
    print((isP1 ? p1Cards : isP2 ? p2Cards : p3Cards).length);
    final newCards = _getLocationCards(
        places.values[place],
        place == 0 ? 30 : null,
        place == 0 ? null : 0,
        place == 0 ? 0 : place == 1 ? null : 30,
        place == 1 ? 30 : null);
    for (var i = 0; i < 10; i++) {
      (isP1 ? p1Cards : isP2 ? p2Cards : p3Cards)[i].move(
        Duration(milliseconds: 200),
        eRight: newCards[i].right,
        eLeft: newCards[i].left,
        eTop: newCards[i].top,
        eBottom: newCards[i].bottom,
      );
    }
    client.game.gameState = SPMP.declaring;
    cardStream.add('diposed');
  }

  void setCards(List<Card> newCards) {
    _cards = newCards;
    p1Cards = _getLocationCards(places.player1, 30, null, 0, null);
    p2Cards = _getLocationCards(places.player2, null, 0, null, 30);
    p3Cards = _getLocationCards(places.player3, null, 0, 30, null);
    widows = _getLocationCards(places.widow, null, 30, 0, null);
  }

  List<T> sortCards<T>(List crds) {
    List<T> sortedCards = [];
    crds.sort((a, b) =>
        int.parse(a.suit.toString()[10]) > int.parse(b.suit.toString()[10])
            ? -1
            : 1);
    for (var i = 0; i < 4; i++) {
      final List<T> list = crds
          .where((element) => element.suit == suits.values[i])
          .toList()
            ..sort((a, b) => a.rank.index > b.rank.index ? -1 : 1);
      sortedCards.addAll(list);
    }
    return sortedCards;
  }

  void moveWidowToPlayer(List<PlayingCard> newCards) {
    for (var i = 0; i < 12; i++) {
      p1Cards[i].moveAndTwist(
        Duration(milliseconds: 200),
        eRight: newCards[i].right,
        eLeft: newCards[i].left,
        eTop: newCards[i].top,
        eBottom: newCards[i].bottom,
        axis: Axis.vertical,
        sRotation: rotation.back,
        eRotation: rotation.face,
      );
    }
  }

  void collectWidow(int place) {
    client.game.gameState = SPMP.discarding;
    final newCards = _getLocationCards(
        places.values[place],
        place == 0 ? 30 : null,
        place == 0 ? null : 0,
        place == 0 ? 0 : place == 1 ? null : 30,
        place == 1 ? 30 : null);
    print('length of new cards: ${newCards.length}');
    final isP1 = place == 0;
    final isP2 = place == 1;
    (isP1 ? p1Cards : isP2 ? p2Cards : p3Cards).addAll(widows);
    widows = [];
    cardStream.add('collected widow');
    if (place == 0) {
      p1Cards = sortCards(p1Cards);
    }
    for (var i = 0; i < 12; i++) {
      (isP1 ? p1Cards : isP2 ? p2Cards : p3Cards)[i].moveAndTwist(
        Duration(milliseconds: 200),
        eRight: newCards[i].right,
        eLeft: newCards[i].left,
        eTop: newCards[i].top,
        eBottom: newCards[i].bottom,
        axis: isP1 ? i >= 10 ? Axis.vertical : null : null,
        sRotation: isP1 ? rotation.back : null,
        eRotation: isP1 ? rotation.face : null,
        sAngle: i >= 10 && !isP1 ? angle.up : null,
        eAngle: i >= 10 && !isP1 ? isP2 ? angle.right : angle.left : null,
      );
    }
  }

  double findSideLocation(int amnt, int i, bool isVert) {
    final increment = 50;
    final offset = i * increment;
    final mLength = isVert ? height : width;
    return ((mLength - (amnt * increment)) / 2) + offset;
  }

  List<PlayingCard> _getLocationCards(
      places place, double bottom, double top, double right, double left) {
    var thisCards = [
      ..._cards.where((element) => element.place == place).toList()
    ];
    int i = -1;
    thisCards = sortCards(thisCards);
    final l = thisCards.length;
    return thisCards.map((e) {
      i++;
      return PlayingCard(
        e.suit,
        e.rank,
        top: top == 0 ? findSideLocation(l, i, true) : top,
        bottom: bottom == 0 ? findSideLocation(l, i, true) : bottom,
        right: right == 0 ? findSideLocation(l, i, false) : right,
        left: left == 0 ? findSideLocation(l, i, false) : left,
      );
    }).toList();
  }
}
