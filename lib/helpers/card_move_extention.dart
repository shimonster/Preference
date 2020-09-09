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
  double currentRight;
  double currentLeft;
  double currentTop;
  double currentBottom;
  Duration moveDuration;
  final positionStream = StreamController.broadcast();
  final rotationStream = StreamController.broadcast();

  // e is for end and s is for start

  Future<void> rotate(rotation sRotation, rotation eRotation, angle sAngle,
      angle eAngle, Duration duration, Axis axis) async {
    final animationController = AnimationController(
      vsync: PlayingCardState(),
      duration: duration,
    );
    final Animation<double> rotationAnimation = Tween<double>(
            begin: sRotation == rotation.face ? 0 : pi,
            end: eRotation == rotation.face
                ? 2 * pi
                : sRotation == rotation.face ? 0 : pi)
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
              : sAngle == angle.down ? pi : pi * 3 / 2,
      end: eAngle == angle.up
          ? 0
          : eAngle == angle.right
              ? pi * 1 / 2
              : eAngle == angle.down ? pi : -pi * 1 / 2,
    ).animate(
      CurvedAnimation(
        curve: Curves.linear,
        parent: animationController,
      ),
    );
    if (sAngle != null && eAngle != null) {
      angleAnimation.addListener(() {
        currentRotationZ = angleAnimation.value;
        try {
          rotationStream.add('rotation');
        } catch (error) {}
      });
    }
    if (sRotation != null && eRotation != null) {
      rotationAnimation.addListener(() {
        if (rotationAnimation.value < pi * 1 / 2 ||
            rotationAnimation.value > pi * 3 / 2) {
          isFace = true;
        } else {
          isFace = false;
        }
        axis == Axis.horizontal
            ? currentRotationX = rotationAnimation.value
            : currentRotationY = rotationAnimation.value;
        try {
          rotationStream.add('rotation');
        } catch (error) {}
      });
    }
    await animationController.forward().then((value) {
      rotationAnimation.removeListener(() {});
      angleAnimation.removeListener(() {});
    });
  }

  Future<void> move(Duration duration,
      {double eBottom, double eTop, double eRight, double eLeft}) async {
    print('move card was run: $isFace');
    moveDuration = duration;
    currentTop = eTop;
    currentBottom = eBottom;
    currentRight = eRight;
    currentLeft = eLeft;
    try {
      positionStream.add('position');
    } catch (error) {}
    print('after move add to position stream');
    await Future.delayed(duration);
    print('after move card future');
  }

  Future<void> moveAndTwist(Duration duration,
      {double eBottom,
      double eTop,
      double eRight,
      double eLeft,
      rotation sRotation,
      rotation eRotation,
      angle sAngle,
      angle eAngle,
      Axis axis}) async {
    moveDuration = duration;
    move(duration, eTop: eTop, eBottom: eBottom, eRight: eRight, eLeft: eLeft);
    rotate(sRotation, eRotation, sAngle, eAngle, duration, axis);
    await Future.delayed(duration);
  }

  static Future<void> animateDistribute(
      Cards cards, BuildContext context) async {
    await Future.forEach(
        [...cards.p2Cards, ...cards.p1Cards, ...cards.p3Cards, ...cards.widows],
        (PlayingCard playingCard) async {
      final thisCard = cards.cards.firstWhere((element) =>
          element.rank == playingCard.rank && element.suit == playingCard.suit);
      playingCard.move(
        Duration(),
        eTop: -100,
        eRight: MediaQuery.of(context).size.width / 2,
      );
      playingCard.moveAndTwist(
        Duration(milliseconds: 1000),
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
                : thisCard.place == places.player2 ? angle.right : angle.left,
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
    (isP1 ? cards.p1Cards : isP2 ? cards.p2Cards : cards.p3Cards)
        .forEach((element) {
      final newCard = newCards.firstWhere(
          (e) => e['rank'] == element.rank && e['suit'] == element.suit);
      element.moveAndTwist(
        Duration(milliseconds: 200),
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
    });
    await Future.delayed(Duration(milliseconds: 200));
  }
}
