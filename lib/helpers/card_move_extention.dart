import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../widgets/playing_card.dart';
import '../providers/cards.dart';

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
  // rotation
  double currentRotationX = 0;
  double currentRotationY = 0;
  double currentRotationZ = 0;
  bool isFace = false;

  // position
  double pCurrentRight;
  double pCurrentLeft;
  double pCurrentTop;
  double pCurrentBottom;
  final positionStream = StreamController.broadcast();
  final rotationStream = StreamController.broadcast();
  double width;
  double height;

  // e is for end and s is for start

  Future<void> rotate(rotation sRotation, rotation eRotation, angle sAngle,
      angle eAngle, Duration duration, Axis axis) async {
    print('rotation was run');
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
        currentRotationZ = angleAnimation.value;
        rotationStream.add('rotation');
      });
    }
    if (sRotation != null && eRotation != null) {
      rotationAnimation.addListener(() {
        isFace = rotationAnimation.value < pi * 1 / 2 ||
            rotationAnimation.value > pi * 3 / 2;
        axis == Axis.horizontal
            ? currentRotationX = rotationAnimation.value
            : currentRotationY = rotationAnimation.value;
        rotationStream.add('rotation');
      });
    }
    await animationController.forward().then((value) {
      rotationAnimation.removeListener(() {});
      angleAnimation.removeListener(() {});
    });
  }

  Future<void> move(Duration duration, Cards cards,
      {double eBottom,
      double eTop,
      double eRight,
      double eLeft,
      double sBottom,
      double sTop,
      double sRight,
      double sLeft}) async {
    // sets up animation controller and other stuff
    final animController = AnimationController(
      duration: duration,
      vsync: PlayingCardState(),
    );
    Map<int, Animation> anims = {};
    final oldBottom = pCurrentBottom;
    final oldRight = pCurrentRight;
    print([
      pCurrentBottom,
      pCurrentTop,
      pCurrentRight,
      pCurrentLeft,
      'old:',
      oldBottom,
      oldRight
    ]);
    final bool isCustomStart =
        [sBottom, sTop, sRight, sLeft].every((element) => element != null);
    final newBottom =
        eBottom != null ? pCurrentBottom ?? height - pCurrentTop : eBottom;
    final newTop = eTop != null ? pCurrentTop ?? height - oldBottom : eTop;
    final newRight =
        eRight != null ? pCurrentRight ?? height - pCurrentLeft : eRight;
    final newLeft = eLeft != null ? pCurrentLeft ?? height - oldRight : eLeft;
    if (isCustomStart) {
      sBottom = newBottom;
      sTop = newTop;
      sRight = newRight;
      sLeft = newLeft;
    } else {
      pCurrentBottom = newBottom;
      pCurrentTop = newTop;
      pCurrentRight = newRight;
      pCurrentLeft = newLeft;
    }
    print([
      pCurrentBottom,
      pCurrentTop,
      pCurrentRight,
      pCurrentLeft,
      'old:',
      oldBottom,
      oldRight
    ]);
    final start = isCustomStart
        ? [sBottom, sTop, sRight, sLeft]
        : [pCurrentBottom, pCurrentTop, pCurrentRight, pCurrentLeft];
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
        print('$i: $value');
        if (i == 0) {
          print('bottom');
          pCurrentBottom = value;
        } else if (i == 1) {
          print('top');
          pCurrentTop = value;
        } else if (i == 2) {
          print('right');
          pCurrentRight = value;
        } else {
          print('left');
          pCurrentLeft = value;
        }
        print('adding in move:  ${[
          pCurrentBottom,
          pCurrentTop,
          pCurrentRight,
          pCurrentLeft
        ]}');
        positionStream.add('moved');
      });
    });
    print('after adding in move:  ${[
      pCurrentBottom,
      pCurrentTop,
      pCurrentRight,
      pCurrentLeft
    ]}');
    // runs the animation and waits for it to play before resolving
    await animController.forward().then(
      (value) {
        anims.forEach((i, anim) {
          anim.removeListener(() {});
        });
        print([pCurrentBottom, pCurrentTop, pCurrentRight, pCurrentLeft]);
        cards.cardStream.add('finished moving cards.');
      },
    );
  }

  Future<void> moveAndTwist(Duration duration, Cards cards,
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
      Cards cards, BuildContext context) async {
    await Future.forEach(
        [...cards.p2Cards, ...cards.p1Cards, ...cards.p3Cards, ...cards.widows],
        (PlayingCard playingCard) async {
      print('about to distribute card');
      final thisCard = cards.cards.firstWhere((element) =>
          element.rank == playingCard.rank && element.suit == playingCard.suit);
      final isP1 = thisCard.place == places.player1;
      final isP2 = thisCard.place == places.player2;
      final isP3 = thisCard.place == places.player3;
      if (isP1) {
        playingCard.pCurrentBottom = 0;
        playingCard.pCurrentRight = 0;
      } else if (isP2) {
        playingCard.pCurrentLeft = 0;
        playingCard.pCurrentTop = 0;
      } else if (isP3) {
        playingCard.pCurrentRight = 0;
        playingCard.pCurrentTop = 0;
      } else {
        playingCard.pCurrentTop = 0;
        playingCard.pCurrentRight = 0;
      }
      print('after asigning values to positions');
      playingCard.moveAndTwist(
        Duration(milliseconds: 1000),
        cards,
        eTop: playingCard.top,
        eRight: playingCard.right,
        eLeft: playingCard.left,
        eBottom: playingCard.bottom,
        sRotation: rotation.back,
        eRotation:
            thisCard.place == places.player1 ? rotation.face : rotation.back,
        sAngle: angle.up,
        eAngle:
            thisCard.place == places.player1 || thisCard.place == places.widow
                ? angle.up
                : thisCard.place == places.player2
                    ? angle.right
                    : angle.left,
        axis: Axis.vertical,
      );

      await Future.delayed(Duration(milliseconds: 100));
    });
  }

  static Future<void> alignCards(
      List<Map<String, dynamic>> newCards, bool isP1, bool isP2, Cards cards,
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
      final move = () => element.moveAndTwist(
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
      if (idx == length - 1) {
        await move();
      } else {
        move();
      }
    });
    cards.cardStream.add('aligned widow player');
  }
}
