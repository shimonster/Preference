import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../widgets/playing_card.dart';
import '../providers/cards.dart' as c;
import '../SPMP.dart';

enum rotation {
  face,
  back,
}

enum angle {
  left,
  up,
  right,
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
    final thisCardIdx = cards.cards.indexWhere(
        (element) => element.suit.index == suit && element.rank.index == rank);
    // sets up animation controller and other stuff
    final animController = AnimationController(
      duration: duration,
      vsync: PlayingCardState(),
    );
    Map<int, Animation> anims = {};
    final curRight = sRight ?? thisCardElement.right;
    final curLeft = sLeft ?? thisCardElement.left;
    final curTop = sTop ?? thisCardElement.top;
    final curBottom = sBottom ?? thisCardElement.bottom;
    final oldBottom = curBottom;
    final oldRight = curRight;
    print([
      thisCardElement.bottom,
      thisCardElement.top,
      thisCardElement.right,
      thisCardElement.left,
      'old:',
      oldBottom,
      oldRight
    ]);
    print([cards.height, cards.width]);
    thisCardElement.bottom =
        eBottom != null ? curBottom ?? cards.height - curTop : null;
    thisCardElement.top =
        eTop != null ? curTop ?? cards.height - oldBottom : null;
    thisCardElement.right =
        eRight != null ? curRight ?? cards.width - curLeft : null;
    thisCardElement.left =
        eLeft != null ? curLeft ?? cards.width - oldRight : null;
    print([
      thisCardElement.bottom,
      thisCardElement.top,
      thisCardElement.right,
      thisCardElement.left,
      'old:',
      oldBottom,
      oldRight
    ]);
    final start = [
      thisCardElement.bottom,
      thisCardElement.top,
      thisCardElement.right,
      thisCardElement.left
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
      thisCardElement.bottom,
      thisCardElement.top,
      thisCardElement.right,
      thisCardElement.left
    ]}');
    // runs the animation and waits for it to play before resolving
    await animController.forward().then(
      (value) {
        anims.forEach((i, anim) {
          anim.removeListener(() {});
        });
//        print([
//          thisCardElement.bottom,
//          thisCardElement.top,
//          thisCardElement.right,
//          thisCardElement.left
//        ]);
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
    final newCards1 = cards.getLocationCards(SPMP.player1);
    final newCards2 = cards.getLocationCards(SPMP.player2);
    final newCards3 = cards.getLocationCards(SPMP.player3);
    final newCardsWidow = cards.getLocationCards(SPMP.widow);
    final allNewCards = [newCards1, newCards2, newCards3, newCardsWidow];
    for (var i = 0; i < 4; i++) {
      final isP1 = i == 0;
      final isP2 = i == 1;
      final isP3 = i == 2;
      final isWidow = i == 3;
      await alignCards(
        allNewCards[i],
        isP1,
        isP2,
        isWidow,
        cards,
        sAngle: isP2 || isP3 ? angle.up : null,
        eAngle: isP2
            ? angle.right
            : isP3
                ? angle.left
                : null,
        sRotation: isP1 ? rotation.back : null,
        eRotation: isP1 ? rotation.face : null,
      );
    }
//    await Future.forEach(cards.cards, (card) async {
//      print('about to distribute card');
//      card.cardMoveExtension.moveAndTwist(
//        Duration(milliseconds: 500),
//        cards,
//        sTop: -(PlayingCard.multiplySizeHeight * size.height) - 50,
//        sRight: size.width / 2,
//        eTop: card.top,
//        eRight: card.right,
//        eLeft: card.left,
//        eBottom: card.bottom,
//        sRotation: rotation.back,
//        eRotation:
//            card.place == c.places.player1 ? rotation.face : rotation.back,
//        sAngle: angle.up,
//        eAngle: card.place == c.places.player1 || card.place == c.places.widow
//            ? angle.up
//            : card.place == c.places.player2
//                ? angle.right
//                : angle.left,
//        axis: Axis.horizontal,
//      );
//
//      await Future.delayed(Duration(milliseconds: 500));
//    });
  }

  static Future<void> alignCards(List<Map<String, dynamic>> newCards, bool isP1,
      bool isP2, bool isWidow, c.Cards cards,
      {rotation sRotation,
      rotation eRotation,
      angle sAngle,
      angle eAngle,
      Axis axis}) async {
    print('align cards was run');
    final alignCards = cards.cards
        .where((element) =>
            element.place.index ==
            (isP1
                ? SPMP.player1
                : isP2
                    ? SPMP.player2
                    : isWidow
                        ? SPMP.widow
                        : SPMP.player3))
        .toList();
    await Future.forEach(alignCards, (c.Card element) async {
      final newCard = newCards.firstWhere(
          (e) => e['rank'] == element.rank && e['suit'] == element.suit);
      print((element.currentRotationZ / pi) + 1);
      final isAlreadyAngle =
          angle.values[((element.currentRotationZ / (pi / 2)) + 1).round()] ==
              eAngle;
      element.cardMoveExtension.moveAndTwist(
        Duration(milliseconds: 400),
        cards,
        eBottom: newCard['bottom'],
        eTop: newCard['top'],
        eRight: newCard['right'],
        eLeft: newCard['left'],
        sAngle: isAlreadyAngle ? null : sAngle,
        eAngle: isAlreadyAngle ? null : eAngle,
        axis: axis,
        sRotation: sRotation,
        eRotation: eRotation,
      );
      await Future.delayed(Duration(milliseconds: 100));
    });
  }
}
