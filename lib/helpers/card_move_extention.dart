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
        rotationStream.add('rotation');
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
        rotationStream.add('rotation');
      });
    }
    await animationController.forward().then((value) {
      rotationAnimation.removeListener(() {});
      angleAnimation.removeListener(() {});
    });
  }

  Future<void> move(Duration duration,
      {double eBottom, double eTop, double eRight, double eLeft}) async {

    // sets up animation controller and other stuff
    final animController = AnimationController(
      duration: duration,
      vsync: PlayingCardState(),
    );
    Map<int, Animation> anims = {};
    final start = [currentBottom, currentTop, currentRight, currentLeft];
    final end = [eBottom, eTop, eRight, eLeft];
    print(start);
    // sets up animations for things that aren't null
    for (var i = 0; i < 4; i++) {
      if (end[i] != null) {
        print(start[i]);
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
        final value = anim.value;
        if (i == 0) {
          currentBottom = value;
        } else if (i == 1) {
          currentTop = value;
        } else if (i == 2) {
          currentRight = value;
        } else {
          currentLeft = value;
        }
      });
    });
    // adds listener to controller to update UI when new card position
    animController.addListener(() => positionStream.add('moved'));
    // runs the animation and waits for it to play before resolving
    await animController.forward().then(
      (value) {
        animController.removeListener(() {});
        anims.forEach((i, anim) {
          anim.removeListener(() {});
        });
      },
    );
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

  static void setPositionValues(int suit, int rank, Cards cards,
      {double right, double left, double top, double bottom}) {
    int findCardIdx(int idx) {
      return (idx == 0
              ? cards.p1Cards
              : idx == 1
                  ? cards.p2Cards
                  : idx == 2 ? cards.p3Cards : cards.widows)
          .indexWhere((element) =>
              element.rank.index == rank && element.suit.index == suit);
    }

    final p1Idx = findCardIdx(0);
    final p2Idx = findCardIdx(1);
    final p3Idx = findCardIdx(2);
    final widowIdx = findCardIdx(3);

    final idxs = [p1Idx, p2Idx, p3Idx, widowIdx];
    final i = idxs.firstWhere((element) => element != -1);
    final pIdx = idxs.firstWhere((element) => element != -1);
    final isP1 = pIdx == 0;
    final isP2 = pIdx == 1;
    final isP3 = pIdx == 2;
    (isP1
            ? cards.p1Cards
            : isP2 ? cards.p2Cards : isP3 ? cards.p3Cards : cards.widows)[i]
        .currentRight = right;
    (isP1
            ? cards.p1Cards
            : isP2 ? cards.p2Cards : isP3 ? cards.p3Cards : cards.widows)[i]
        .currentLeft = left;
    (isP1
            ? cards.p1Cards
            : isP2 ? cards.p2Cards : isP3 ? cards.p3Cards : cards.widows)[i]
        .currentTop = top;
    (isP1
            ? cards.p1Cards
            : isP2 ? cards.p2Cards : isP3 ? cards.p3Cards : cards.widows)[i]
        .currentBottom = bottom;
  }

  static Future<void> animateDistribute(
      Cards cards, BuildContext context) async {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
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
        playingCard.currentBottom = 0;
        playingCard.currentRight = 0;
      } else if (isP2) {
        playingCard.currentLeft = 0;
        playingCard.currentTop = 0;
      } else if (isP3) {
        playingCard.currentRight = 0;
        playingCard.currentTop = 0;
      } else {
        playingCard.currentTop = 0;
        playingCard.currentRight = 0;
      }
      print('after asigning values to positions');
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
