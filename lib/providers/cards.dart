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
  Card(this.rank, this.suit, this.place, this.cards) {
    cardMoveExtension = CardMoveExtension(cards, rank.index, suit.index);
    top = -cards.height * PlayingCard.multiplySizeHeight;
    right =
        (cards.width / 2) - (cards.width * PlayingCard.multiplySizeWidth / 2);
  }

  final Cards cards;
  final ranks rank;
  final suits suit;
  CardMoveExtension cardMoveExtension;
  places place;
  double top;
  double bottom;
  double right;
  double left;
  double currentRotationX = 0;
  double currentRotationY = 0;
  double currentRotationZ = 0;

  bool isFirstPlaced = false;

  final positionStream = StreamController(
      onListen: () => print('position stream listened to'),
      onCancel: () => print('position stream cancelled'));
  final rotationStream = StreamController(
      onListen: () => print('rotation stream listened to'),
      onCancel: () => print('rotation stream cancelled'));

  @override
  String toString() {
    return '*$rank, $suit, $place*';
  }

  @override
  int get hashCode => int.parse('${rank.index}${suit.index}');

  @override
  bool operator ==(Object other) {
    return hashCode == other.hashCode;
  }
}

// ============================================================================

class Cards extends ChangeNotifier {
  Cards({this.client}) {
    print('created new cards');
    disposeStream.done.then((value) => print('dispose stream done'));
  }

  String turn;
  final Client client;
  double width;
  double height;
  final componentStream = StreamController.broadcast();
  final cardStream = StreamController.broadcast();
  final disposeStream = StreamController.broadcast();

  List<Card> _cards = [];

  List<Card> get cards {
    return [..._cards];
  }

  List get placed {
    final crds = _cards
        .where((element) =>
            element.place == places.center1 ||
            element.place == places.center2 ||
            element.place == places.center3)
        .toList();
    return List.generate(
        crds.length,
        (i) => PlayingCard(crds[i].suit, crds[i].rank, this,
            ValueKey('${crds[i].rank}${crds[i].suit}')));
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

  Future<void> move(List<int> rank, List<int> suit, int place, String method,
      bool shouldSend, String uid, bool shouldAddToStream) async {
    print(suit);
    print(rank);
    for (var i = 0; i < rank.length; i++) {
      final idx = _cards.indexWhere((element) =>
          element.rank.index == rank[i] && element.suit.index == suit[i]);
      print('idx of cards: $idx');
      _cards[idx].place = places.values[place];
      print('new place: ${_cards[idx].place}');
    }
    if (shouldAddToStream) {
      cardStream.add(method);
    }
    if (shouldSend) {
      client.sendMessage({
        'method': method,
        'rank': rank.length == 1 ? rank[0] : rank,
        'suit': suit.length == 1 ? suit[0] : suit,
        'uid': uid,
      });
    }
  }

  void collectTrick(String uid) async {
    print('trick collected');
    await Future.delayed(Duration(milliseconds: 1000));
    final pNum = client.game.players.keys.toList().indexOf(uid);
    final isP1 = pNum == 0;
    final isP2 = pNum == 1;
    print('placed from trick: $placed');
    for (PlayingCard i in placed) {
      print('collected card: $i');
      _cards
          .firstWhere((element) =>
              element.hashCode == int.parse('${i.rank.index}${i.suit.index}'))
          .cardMoveExtension
          .move(
            Duration(milliseconds: 400),
            this,
            eTop: isP1 ? height : height / 2,
            eRight: isP1
                ? width / 2
                : isP2
                    ? width
                    : -width * PlayingCard.multiplySizeWidth,
          )
          .then((_) {
        _cards.firstWhere((element) => element.isFirstPlaced).isFirstPlaced =
            false;
        move(
          [i.rank.index],
          [i.suit.index],
          client.game.players.keys.toList().indexOf(uid) + 8,
          SPMP.trickCollected,
          false,
          uid,
          true,
        );
      });
      await Future.delayed(Duration(milliseconds: 100));
    }

    print('after moved placed');
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
    final card = _cards.firstWhere(
        (element) => element.rank.index == rank && element.suit.index == suit);
    print(card);
    final middle = (width / 2) - (PlayingCard.multiplySizeWidth * width / 2);
    card.cardMoveExtension.moveAndTwist(
      Duration(milliseconds: 200),
      this,
      eTop: height / (isP1 ? 2.5 : 3),
      eRight: middle *
          (isP1
              ? 1
              : isP2
                  ? 1.075
                  : 0.925),
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
    // changes place cards that were placed
    print(placed);
    print(turn);
    move([rank], [suit], turnIdx + 5, SPMP.place, turn == client.uid,
        client.uid, true);
    if (placed.length == 1) {
      print('made first');
      _cards[_cards.indexOf(card)].isFirstPlaced = true;
    }
    print(_cards.map((e) => e.place).toList());
    print(sortCards<Card>(_cards
        .where((element) =>
            element.place == places.center1 ||
            element.place == places.center2 ||
            element.place == places.center3)
        .toList()));
    print(placed);
    // moves cards that haven't been collected to new place
    final newCards = getLocationCards(turnIdx);
    await CardMoveExtension.alignCards(newCards, isP1, isP2, false, this);
    // changes turn
    turn = nTurn ?? client.game.players.keys.toList()[(turnIdx + 1) % 3];
    componentStream.add('turn change');
    // updates my cards if my turn
    if (turn == client.uid) {
      _cards
          .where((element) => element.place == places.player1)
          .forEach((element) => element.rotationStream.add('my turn'));
    }
  }

  void disposingCards(int rank, int suit) {
    // TODO: position cards better
    move([rank], [suit], SPMP.disposing, 'N/A', false, client.uid, false);
    final crdIdx = cards.indexWhere(
        (element) => element.rank.index == rank && element.suit.index == suit);
    final middle = (width / 2) - (PlayingCard.multiplySizeWidth * width / 2);
    cards[crdIdx].cardMoveExtension.move(
          Duration(milliseconds: 1),
          this,
          eTop: height / 2,
          eRight: middle *
              (cards
                          .where((element) => element.place == places.disposing)
                          .length ==
                      1
                  ? 1.075
                  : 0.925),
        );
    print([
      cards[crdIdx].bottom,
      cards[crdIdx].top,
      cards[crdIdx].right,
      cards[crdIdx].left,
    ]);
    disposeStream.add('disposing');
    print('after dispose add');
  }

  Future<void> disposeCards(List<int> rank, List<int> suit) async {
    print('disposed cards was run');
//    client.game.gameState = SPMP.declaring;
//    cardStream.add('changed game state to declaring');
    if (client.game.bidId == client.uid) {
      client.sendMessage({
        'method': SPMP.dispose,
        'rank': rank,
        'suit': suit,
        'uid': client.uid,
      });
    }
    // finds cards that were disposed in _cards list
    List<Card> disposing = [];
    print(_cards.map((e) => e.place).toList());
    for (var i = 0; i < 2; i++) {
      disposing.add(_cards.firstWhere(
          (e) => e.rank.index == rank[i] && e.suit.index == suit[i]));
    }
    // moves cards what were disposed
    for (var i = 0; i < 2; i++) {
      print('loop was run: ${[rank[i], suit[i]]}');
      print(int.parse('${rank[i]}${suit[i]}'));
      _cards
          .firstWhere((element) {
            print('${element.hashCode}, ${element.place}');
            return element.suit.index == suit[i] &&
                element.rank.index == rank[i];
          })
          .cardMoveExtension
          .move(Duration(milliseconds: 200), this,
              eTop: -500, eRight: width / 2)
          .then((value) {
            if (i == 1) {
              print('in if statement');
              for (var ind = 0; ind < 2; ind++) {
                print([rank[ind], suit[ind]]);
                print('loop to remove');
                _cards.removeWhere((element) =>
                    element.rank.index == rank[ind] &&
                    element.suit.index == suit[ind]);
              }
              cardStream.add('deleted disposed');
              print(_cards.length);
              print('after deleting cards');
              moveNotDisposed();
            }
          });
      print('i value: $i');
    }
  }

  Future<void> moveNotDisposed() async {
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
    final newCards = getLocationCards(place);
    print(newCards);
    await CardMoveExtension.alignCards(newCards, isP1, isP2, false, this);
    if (isP1) {
      flipOtherCards();
    }
  }

  void flipOtherCards() {
    // finds other players cards
    final otherCards = _cards
        .where((element) =>
            element.place == places.player2 || element.place == places.player3)
        .toList();
    print(
        otherCards.map((e) => [e.rank.index, e.suit.index, e.place]).toList());
    // flips other players cards
    otherCards.forEach((element) {
      element.cardMoveExtension.rotate(
          rotation.back,
          rotation.face,
          element.place == places.player2 ? angle.right : angle.left,
          angle.up,
          Duration(milliseconds: 200),
          Axis.vertical);
    });
  }

  void placeWidowInMiddle(int suit, int rank) {
    print('placing widow in middle');
    move([rank], [suit], SPMP.centerWidow, SPMP.startCollecting, false,
        client.uid, true);
    final moveWidow = widows.firstWhere(
        (element) => element.suit.index == suit && element.rank.index == rank);
    moveWidow.cardMoveExtension.moveAndTwist(
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
    componentStream.add('disposing');
    final isP1 = place == 0;
    final isP2 = place == 1;
    final widowCards = cards.where((element) => element.place == places.widow);
    // moves cards
    move(
        widowCards.map((e) => e.rank.index).toList(),
        widowCards.map((e) => e.suit.index).toList(),
        isP1
            ? SPMP.player1
            : isP2
                ? SPMP.player2
                : SPMP.player3,
        SPMP.collectWidow,
        isP1,
        client.game.players.keys.toList()[place],
        true);
    final newCards = getLocationCards(place);
    print(isP1);
    CardMoveExtension.alignCards(
      newCards,
      isP1,
      isP2,
      false,
      this,
      axis: isP1 ? Axis.vertical : null,
      sRotation: isP1 ? rotation.face : null,
      eRotation: isP1 ? rotation.back : null,
      sAngle: !isP1 ? angle.up : null,
      eAngle: !isP1
          ? isP2
              ? angle.right
              : angle.left
          : null,
    );
  }

  List<T> sortCards<T>(List ogCrds) {
    List<T> sortedCards = [];
    final crds = ogCrds..sort((a, b) => a.suit.index > b.suit.index ? -1 : 1);
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

  List<Map<String, dynamic>> getLocationCards(int place) {
    var thisCards =
        _cards.where((element) => element.place.index == place).toList();
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
    final sortedCards = sortCards<Card>(
        _cards.where((element) => element.place.index == player).toList());
    final newPlayingCards = sortedCards
        .map((e) =>
            PlayingCard(e.suit, e.rank, this, ValueKey('${e.rank}${e.suit}')))
        .toList();
    return newPlayingCards;
  }

  void setCards(List<Card> newCards) {
    _cards.sort((a, b) => a.place.index > b.place.index ? 1 : -1);
    _cards = newCards;
  }
}
