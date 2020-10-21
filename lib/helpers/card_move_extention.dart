import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../widgets/playing_card.dart';
import '../providers/cards.dart' as c;

enum rotation {
  face,
  back,
}

enum angle {
  right,
  left,
  up,
  down,
}

class CardMoveExtension {
  CardMoveExtension(this.cards, this.rank, this.suit);

  bool isFace = false;
  final int rank;
  final int suit;
  final c.Cards cards;
  c.Card get thisCardElement {
    return cards.cards.firstWhere(
        (element) => element.suit.index == suit && element.rank.index == rank);
  }

  final positionStream = StreamController(
      onListen: () => print('position stream listened to'),
      onCancel: () => print('position stream cancelled'));
  final rotationStream = StreamController(
      onListen: () => print('rotation stream listened to'),
      onCancel: () => print('rotation stream cancelled'));

  // e is for end and s is for start

  Future<void> rotate(rotation sRotation, rotation eRotation, angle sAngle,
      angle eAngle, Duration duration, Axis axis) async {
    print('rotation was run: $sRotation, $eRotation');
    print(thisCardElement);
//    final thisCardIdx = cards.cards.indexOf(thisCardElement);
    final thisCardIdx = cards.cards.indexWhere((element) =>
        element.suit == thisCardElement.suit &&
        element.rank == thisCardElement.rank);
    final animationController = AnimationController(
      vsync: PlayingCardState(),
      duration: duration,
    );
    // define animations
    final Animation<double> rotationAnimation = Tween<double>(
            begin: sRotation == rotation.face ? 0 : pi,
            end: eRotation == rotation.face
                ? 2 * pi
                : sRotation == rotation.face
                    ? 0
                    : pi)
        .animate(
      CurvedAnimation(
        curve: Curves.linear,
        parent: animationController,
      ),
    );
    final Animation<double> angleAnimation = Tween<double>(
      begin: sAngle == angle.up
          ? 0
          : sAngle == angle.right
              ? pi * 1 / 2
              : sAngle == angle.down
                  ? pi
                  : pi * 3 / 2,
      end: eAngle == angle.up
          ? 0
          : eAngle == angle.right
              ? pi * 1 / 2
              : eAngle == angle.down
                  ? pi
                  : -pi * 1 / 2,
    ).animate(
      CurvedAnimation(
        curve: Curves.linear,
        parent: animationController,
      ),
    );
    // adds listeners to animations
    if (sAngle != null && eAngle != null) {
      angleAnimation.addListener(() {
        cards.cards[thisCardIdx].currentRotationZ = angleAnimation.value;
        rotationStream.add('rotation');
      });
    }
    print(sRotation == rotation.face ? 0 : pi);
    print(eRotation == rotation.face
        ? 2 * pi
        : sRotation == rotation.face
            ? 0
            : pi);
    if (sRotation != null && eRotation != null) {
      rotationAnimation.addListener(() {
        print('about to add in rotation');
        isFace = rotationAnimation.value < pi * 1 / 2 ||
            rotationAnimation.value > pi * 3 / 2;
        axis == Axis.horizontal
            ? cards.cards[thisCardIdx].currentRotationX =
                rotationAnimation.value
            : cards.cards[thisCardIdx].currentRotationY =
                rotationAnimation.value;
        print(axis == Axis.horizontal
            ? cards.cards[thisCardIdx].currentRotationX
            : cards.cards[thisCardIdx].currentRotationY);
        print(rotationAnimation.value);
        rotationStream.add('rotation');
      });
    }
    await animationController.forward().then((value) {
      rotationAnimation.removeListener(() {});
      angleAnimation.removeListener(() {});
    });
  }

  Future<void> move(Duration duration, c.Cards cards,
      {double eBottom,
      double eTop,
      double eRight,
      double eLeft,
      double sBottom,
      double sTop,
      double sRight,
      double sLeft}) async {
    final thisCard = thisCardElement;
    final thisCardIdx = cards.cards.indexWhere(
        (element) => element.suit.index == suit && element.rank.index == rank);
    // sets up animation controller and other stuff
    final animController = AnimationController(
      duration: duration,
      vsync: PlayingCardState(),
    );
    Map<int, Animation> anims = {};
    final curRight = sRight ?? thisCard.right;
    final curLeft = sLeft ?? thisCard.left;
    final curTop = sTop ?? thisCard.top;
    final curBottom = sBottom ?? thisCard.bottom;
    final oldBottom = curBottom;
    final oldRight = curRight;
    print([
      thisCard.bottom,
      thisCard.top,
      thisCard.right,
      thisCard.left,
      'old:',
      oldBottom,
      oldRight
    ]);
    print([cards.height, cards.width]);
    thisCard.bottom =
        eBottom != null ? curBottom ?? cards.height - curTop : null;
    thisCard.top = eTop != null ? curTop ?? cards.height - oldBottom : null;
    thisCard.right = eRight != null ? curRight ?? cards.width - curLeft : null;
    thisCard.left = eLeft != null ? curLeft ?? cards.width - oldRight : null;
    print([
      thisCard.bottom,
      thisCard.top,
      thisCard.right,
      thisCard.left,
      'old:',
      oldBottom,
      oldRight
    ]);
    final start = [
      thisCard.bottom,
      thisCard.top,
      thisCard.right,
      thisCard.left
    ];
    final end = [eBottom, eTop, eRight, eLeft];
    // sets up animations for things that aren't null
    for (var i = 0; i < 4; i++) {
      if (end[i] != null) {
        print(start[i]);
        print(end[i]);
        print('');
        final anim = Tween<double>(
          begin: start[i],
          end: end[i],
        ).animate(
            CurvedAnimation(curve: Curves.easeInOut, parent: animController));
        anims.putIfAbsent(i, () => anim);
      }
    }
    // sets the corresponding side to the new value of the animation every time
    // the animation updates
    anims.forEach((i, anim) {
      anim.addListener(() {
        final value = anims[i].value;
        if (i == 0) {
          cards.cards[thisCardIdx].bottom = value;
        } else if (i == 1) {
          cards.cards[thisCardIdx].top = value;
        } else if (i == 2) {
          cards.cards[thisCardIdx].right = value;
          print(
              'position closed: ${positionStream.isClosed}, rotation closed: ${rotationStream.isClosed}');
          if (!positionStream.isClosed) positionStream.add('moved');
        } else {
          cards.cards[thisCardIdx].left = value;
          print(
              'position closed: ${positionStream.isClosed}, rotation closed: ${rotationStream.isClosed}');
          if (!positionStream.isClosed) positionStream.add('moved');
        }
      });
    });
    print('after adding in move:  ${[
      thisCard.bottom,
      thisCard.top,
      thisCard.right,
      thisCard.left
    ]}');
    // runs the animation and waits for it to play before resolving
    await animController.forward().then(
      (value) {
        anims.forEach((i, anim) {
          anim.removeListener(() {});
        });
        print([thisCard.bottom, thisCard.top, thisCard.right, thisCard.left]);
//        cards.cardStream.add('finished moving cards.');
      },
    );
  }

  Future<void> moveAndTwist(Duration duration, c.Cards cards,
      {double eBottom,
      double eTop,
      double eRight,
      double eLeft,
      rotation sRotation,
      rotation eRotation,
      angle sAngle,
      angle eAngle,
      Axis axis,
      double sBottom,
      double sTop,
      double sRight,
      double sLeft}) async {
    print('move run');
    move(duration, cards,
        eTop: eTop,
        eBottom: eBottom,
        eRight: eRight,
        eLeft: eLeft,
        sBottom: sBottom,
        sTop: sTop,
        sRight: sRight,
        sLeft: sLeft);
    await rotate(sRotation, eRotation, sAngle, eAngle, duration, axis);
    print('after move and twist');
  }

  static Future<void> animateDistribute(
      c.Cards cards, BuildContext context) async {
    final size = MediaQuery.of(context).size;
    await Future.forEach(
        [...cards.p2Cards, ...cards.p1Cards, ...cards.p3Cards, ...cards.widows],
        (playingCard) async {
      print('about to distribute card');
      final thisCard = cards.cards.firstWhere((element) =>
          element.rank == playingCard.rank && element.suit == playingCard.suit);
      playingCard.cardMoveExtension.moveAndTwist(
        Duration(milliseconds: 500),
        cards,
        sTop: -(PlayingCard.multiplySizeHeight * size.height) - 50,
        sRight: size.width / 2,
        eTop: playingCard.top,
        eRight: playingCard.right,
        eLeft: playingCard.left,
        eBottom: playingCard.bottom,
        sRotation: rotation.back,
        eRotation:
            thisCard.place == c.places.player1 ? rotation.face : rotation.back,
        sAngle: angle.up,
        eAngle: thisCard.place == c.places.player1 ||
                thisCard.place == c.places.widow
            ? angle.up
            : thisCard.place == c.places.player2
                ? angle.right
                : angle.left,
        axis: Axis.horizontal,
      );

      await Future.delayed(Duration(milliseconds: 50));
    });
  }

  static Future<void> alignCards(
      List<Map<String, dynamic>> newCards, bool isP1, bool isP2, c.Cards cards,
      {rotation sRotation,
      rotation eRotation,
      angle sAngle,
      angle eAngle,
      Axis axis}) async {
    print('align cards was run');
    final alignCards = (isP1
        ? cards.p1Cards
        : isP2
            ? cards.p2Cards
            : cards.p3Cards);
    final length = alignCards.length;
    await Future.forEach(
        (isP1
            ? cards.p1Cards
            : isP2
                ? cards.p2Cards
                : cards.p3Cards), (element) async {
      final newCard = newCards.firstWhere(
          (e) => e['rank'] == element.rank && e['suit'] == element.suit);
      final idx = alignCards.indexWhere(
          (e) => e.rank == newCard['rank'] && e.suit == newCard['suit']);
      final move = () => element.cardMoveExtension.moveAndTwist(
            Duration(milliseconds: 200),
            cards,
            eBottom: newCard['bottom'],
            eTop: newCard['top'],
            eRight: newCard['right'],
            eLeft: newCard['left'],
            sAngle: sAngle,
            eAngle: eAngle,
            axis: axis,
            sRotation: sRotation,
            eRotation: eRotation,
          );
//      if (idx == length - 1) {
      await move();
//      } else {
//        move();
//      }
    });
  }
}
