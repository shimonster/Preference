// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:async';
import 'dart:math';

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
  centerWidow
}

class Card {
  final ranks rank;
  final suits suit;
  places place;
  double top = -500;
  double bottom;
  double right = -500;
  double left;
  double currentRotationX = 0;
  double currentRotationY = 0;
  double currentRotationZ = 0;

  Card(this.rank, this.suit, this.place);

  @override
  String toString() {
    return '$rank, $suit, $place';
  }

  @override
  int get hashCode => int.parse('$rank$suit');

  @override
  bool operator ==(Object other) {
    return hashCode == other.hashCode;
  }
}

class Cards extends ChangeNotifier {
  Cards({this.client}) {
    print('created new cards');
    disposeStream.done.then((value) => print('dispose stream done'));
  }

  String turn;
  final Client client;
  double width;
  double height;
  final cardStream = StreamController.broadcast();
  final disposeStream = StreamController.broadcast();

  List<Card> _cards = [];

  List<PlayingCard> placed = [];

  List<Card> get cards {
    return [..._cards];
  }

  List get p1Cards {
    return _createPlayerCards(SPMP.player1);
  }

  List get p2Cards {
    return _createPlayerCards(SPMP.player2);
  }

  List get p3Cards {
    return _createPlayerCards(SPMP.player3);
  }

  List get widows {
    return _createPlayerCards(SPMP.widow);
  }

  void setCards(List<Card> newCards) {
    _cards = newCards;
  }

  void move(List<int> rank, List<int> suit, int place, String method,
      bool shouldSend, String uid) {
    if (place == SPMP.disposed) {
      disposeCards(shouldSend ? null : rank, shouldSend ? null : suit);
    }
    // ===================================
    print(suit);
    print(rank);
    for (var i = 0; i < rank.length; i++) {
      final idx = _cards.indexWhere((element) =>
          element.rank.index == rank[i] && element.suit.index == suit[i]);
      print('idx of cards: $idx');
      _cards[idx].place = places.values[place];
      print('new place: ${_cards[idx].place}');
    }
    if (shouldSend) {
      client.sendMessage({
        'method': method,
        'rank': rank.length == 1 ? rank[0] : rank,
        'suit': suit.length == 1 ? suit[0] : suit,
        'uid': uid,
      });
    }
    // =======================================
    if (place == SPMP.trick1) {
      collectTrick(0);
    }
    if (place == SPMP.trick2) {
      collectTrick(1);
    }
    if (place == SPMP.trick3) {
      collectTrick(2);
    }
    if (method == SPMP.collectWidow) {
      collectWidow(place);
    }
    if (place == SPMP.disposing) {
      disposingCards(rank[0], suit[0]);
    }
    if (place == SPMP.disposed) {
      moveNotDisposed();
    }
  }

  void collectTrick(int pNum) async {
    print('trick collected');
    await Future.delayed(Duration(milliseconds: 500));
    final isP1 = pNum == 0;
    final isP2 = pNum == 1;
    for (var i in placed) {
      print('collected card: $i');
      await placed
          .firstWhere((element) => element.equals(i))
          .cardMoveExtension
          .move(
            Duration(milliseconds: 200),
            this,
            eTop: isP1 ? null : height / 2,
            eBottom: isP1 ? -200 : null,
            eRight: isP1
                ? width / 2
                : isP2
                    ? null
                    : -200,
            eLeft: isP2 ? -200 : null,
          );
    }
    print('after moved placed');
    placed = [];
    if (widows.isNotEmpty && client.game.bidId == null) {
      print('placing widow in middle');
      placeWidowInMiddle(widows[0].suit.index, widows[0].rank.index);
    }
  }

  Future<void> placeCard(int rank, int suit, [String nTurn]) async {
    final turnIdx = client.game.players.keys.toList().indexOf(turn);
    print(turnIdx);
    print(suit);
    print(rank);
    print(p1Cards.map((e) => [e.suit.index, e.rank.index]).toList());
    print(p2Cards.map((e) => [e.suit.index, e.rank.index]).toList());
    print(p3Cards.map((e) => [e.suit.index, e.rank.index]).toList());
    final isP1 = turnIdx == 0;
    final isP2 = turnIdx == 1;
    final card = (isP1
            ? p1Cards
            : isP2
                ? p2Cards
                : p3Cards)
        .firstWhere((element) =>
            element.rank.index == rank && element.suit.index == suit);
    print(card);
    card.cardMoveExtension.moveAndTwist(
      Duration(milliseconds: 200),
      this,
      eBottom: isP1 ? height * 7 / 12 : null,
      eTop: isP1 ? null : height / 3,
      eRight: isP2
          ? null
          : (width / 2) -
              (PlayingCard.multiplySizeWidth * width / (isP1 ? 2 : 1)),
      eLeft: isP2 ? width / 2 : null,
      sAngle: isP1
          ? null
          : isP2
              ? angle.right
              : angle.left,
      eAngle: isP1 ? null : angle.up,
      axis: isP1 ? null : Axis.vertical,
      sRotation: isP1 ? null : rotation.back,
      eRotation: isP1 ? null : rotation.face,
    );
    placed.add(card);
    (isP1
            ? p1Cards
            : isP2
                ? p2Cards
                : p3Cards)
        .removeWhere((element) => element.equals(card));
    // moves cards that were placed
    print(placed);
    print(turn);
    move([rank], [suit], turnIdx + 5, SPMP.place, turn == client.uid,
        client.uid);
    final newCards = _getLocationCards(turnIdx);
    // moves cards that haven't been collected to new place
    await CardMoveExtension.alignCards(newCards, isP1, isP2, this);
    // changes turn
    turn = nTurn ?? client.game.players.keys.toList()[(turnIdx + 1) % 3];
    // updates my cards if my turn
    if (turn == client.uid) {
      p1Cards.forEach(
          (element) => element.cardMoveExtension.rotationStream.add('my turn'));
    }
  }

  void disposingCards(int rank, int suit) {
    // TODO: position cards better
    final crdIdx = p1Cards.indexWhere(
        (element) => element.rank.index == rank && element.suit.index == suit);
    p1Cards[crdIdx].cardMoveExtension.move(
          Duration(milliseconds: 1),
          this,
          eTop: height / 2,
          eRight: (width / 2) -
              (100 *
                  _cards
                      .where((element) => element.place == places.disposing)
                      .length),
        );
    print([
      p1Cards[crdIdx].cardMoveExtension.bottom,
      p1Cards[crdIdx].cardMoveExtension.top,
      p1Cards[crdIdx].cardMoveExtension.right,
      p1Cards[crdIdx].cardMoveExtension.left,
    ]);
    disposeStream.add('disposing');
    print('after dispose add');
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
    } else {
      for (var i = 0; i < 2; i++) {
        disposing.add(cards.firstWhere(
            (e) => e.rank.index == rank[i] && e.suit.index == suit[i]));
      }
    }
    for (var i = 0; i < 2; i++) {
      print('loop was run');
      print(disposing.length);
      print(p3Cards);
      (isP1
              ? p1Cards
              : isP2
                  ? p2Cards
                  : p3Cards)
          .firstWhere((element) {
            if (rank == null) {
              return disposing
                  .any((e) => e.rank == element.rank && e.suit == element.suit);
            } else {
              return element.rank.index == rank[i] &&
                  element.suit.index == suit[i];
            }
          })
          .cardMoveExtension
          .move(Duration(milliseconds: 200), this,
              eTop: -100, eRight: width / 2)
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

  void moveNotDisposed() {
    final place = client.game.players.keys.toList().indexOf(client.game.bidId);
    final isP1 = place == 0;
    final isP2 = place == 1;
    print((isP1
            ? p1Cards
            : isP2
                ? p2Cards
                : p3Cards)
        .length);
    client.game.gameState = SPMP.declaring;
    final newCards = _getLocationCards(place);
    CardMoveExtension.alignCards(newCards, isP1, isP2, this);
    if (isP1) {
      flipOtherCards();
    }
  }

  void flipOtherCards() {
    for (var i = 0; i < 2; i++) {
      (i == 0 ? p2Cards : p3Cards).forEach((element) {
        element.cardMoveExtension.rotate(
            rotation.back,
            rotation.face,
            i == 0 ? angle.right : angle.left,
            angle.up,
            Duration(milliseconds: 200),
            Axis.vertical);
      });
    }
  }

  void placeWidowInMiddle(int suit, int rank) {
    print('placing widow in middle');
    final moveWidow = widows.firstWhere(
        (element) => element.suit.index == suit && element.rank.index == rank);
    move([rank], [suit], SPMP.centerWidow, SPMP.startCollecting, false,
        client.uid);
    placed.add(moveWidow);
    widows.remove(moveWidow);
    cardStream.add('added widow to placed');
    placed
        .firstWhere((element) =>
            element.suit.index == suit && element.rank.index == rank)
        .cardMoveExtension
        .moveAndTwist(
          Duration(milliseconds: 200),
          this,
          eTop: height / 2,
          eRight: (width / 2) - (width * PlayingCard.multiplySizeWidth / 2),
          sRotation: rotation.back,
          eRotation: rotation.face,
        );
  }

  void collectWidow(int place) {
    client.game.gameState = SPMP.discarding;
    final isP1 = place == 0;
    final isP2 = place == 1;
//    cardStream.add('after widw stuff');
//    (isP1
//            ? p1Cards
//            : isP2
//                ? p2Cards
//                : p3Cards)
//        .addAll(widows);
//    widows = [];
//    if (place == 0) {
//      p1Cards = sortCards(p1Cards);
//    } else if (place == 1) {
//      p2Cards = sortCards(p2Cards);
//    } else if (place == 2) {
//      p3Cards = sortCards(p3Cards);
//    }
    // moves cards
    final newCards = _getLocationCards(place);
    print(isP1);
    CardMoveExtension.alignCards(
      newCards,
      isP1,
      isP2,
      this,
      axis: isP1 ? Axis.vertical : null,
      sRotation: isP1 ? rotation.face : null,
      eRotation: isP1 ? rotation.back : null,
      sAngle: !isP1
          ? isP2
              ? angle.up
              : angle.up
          : null,
      eAngle: !isP1
          ? isP2
              ? angle.right
              : angle.left
          : null,
    );
  }

  List<T> sortCards<T>(List crds) {
    List<T> sortedCards = [];
    crds.sort((a, b) => a.suit.index > b.suit.index ? -1 : 1);
    for (var i = 0; i < 4; i++) {
      final List<T> list = crds
          .where((element) => element.suit == suits.values[i])
          .toList()
            ..sort((a, b) => a.rank.index > b.rank.index ? -1 : 1);
      sortedCards.addAll(list);
    }
    return sortedCards;
  }

  double findSideLocation(int amnt, int i, bool isVert, double unitLength) {
    final mLength = isVert ? height : width;
    final increment = min(width, height) / 18;
    final offset = i * increment;
    final start = (mLength - (((amnt - 1) * increment) + unitLength)) / 2;
    return start + offset;
  }

  List<Map<String, dynamic>> _getLocationCards(int place) {
    var thisCards = [
      ..._cards.where((element) => element.place.index == place).toList()
    ];
    int i = -1;
    thisCards = sortCards(thisCards);
    final l = thisCards.length;
    return thisCards.map((e) {
      i++;
      return {
        'suit': e.suit,
        'rank': e.rank,
        'top': place == 0
            ? null
            : place == 3
                ? 30
                : findSideLocation(
                    l, i, true, width * PlayingCard.multiplySizeHeight),
        'right': place == 0 || place == 3
            ? findSideLocation(
                l, i, false, width * PlayingCard.multiplySizeWidth)
            : place == 1
                ? null
                : 30,
        'bottom': place == 0 ? 30 : null,
        'left': place == 1 ? 30 : null,
      };
    }).toList();
  }

  List<PlayingCard> _createPlayerCards(int player) {
    final newCards = _getLocationCards(player);
    final newPlayingCards = newCards
        .map((e) => PlayingCard(e['suit'], e['rank'], this,
            top: e['top'],
            bottom: e['bottom'],
            right: e['right'],
            left: e['left']))
        .toList();
    return newPlayingCards;
  }
}
