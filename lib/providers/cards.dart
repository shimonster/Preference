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
  final widowStream = StreamController.broadcast();

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
    if (place == 0) {
      p1Cards.addAll(widows);
      widows = [];
      p1Cards = sortCards(p1Cards);
      print(p1Cards);
      widowStream.add('collected widow');
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
    } else if (place == 1) {
      p2Cards.addAll(widows);
      widows = [];
      widowStream.add('collected widow');
      for (var i = 0; i < 12; i++) {
        p2Cards[i].moveAndTwist(
          Duration(milliseconds: 200),
          eRight: newCards[i].right,
          eLeft: newCards[i].left,
          eTop: newCards[i].top,
          eBottom: newCards[i].bottom,
          sAngle: i < 10 ? null : angle.up,
          eAngle: i < 10 ? null : angle.right,
        );
      }
    } else {
      p3Cards.addAll(widows);
      widows = [];
      widowStream.add('collected widow');
      for (var i = 0; i < 12; i++) {
        p3Cards[i].moveAndTwist(
          Duration(milliseconds: 200),
          eRight: newCards[i].right,
          eLeft: newCards[i].left,
          eTop: newCards[i].top,
          eBottom: newCards[i].bottom,
          sAngle: angle.up,
          eAngle: angle.left,
        );
      }
    }
  }

  void move(List<int> rank, List<int> suit, int place, String method, bool isMe,
      String uid) {
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
        e.place,
        top: top == 0 ? findSideLocation(l, i, true) : top,
        bottom: bottom == 0 ? findSideLocation(l, i, true) : bottom,
        right: right == 0 ? findSideLocation(l, i, false) : right,
        left: left == 0 ? findSideLocation(l, i, false) : left,
      );
    }).toList();
  }
}
