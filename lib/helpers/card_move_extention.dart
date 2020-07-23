import 'dart:math';

import 'package:flutter/material.dart';

import '../widgets/playing_card.dart';

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

  // position
  double currentRight;
  double currentLeft;
  double currentTop;
  double currentBottom;
  Duration moveDuration = Duration(milliseconds: 5000);

  // e is for end and s is for start

  Future<void> rotate(
      rotation sRotation,
      rotation eRotation,
      angle sAngle,
      angle eAngle,
      Duration duration,
      Axis axis,
      void Function(void Function()) setState) async {
    final animationController = AnimationController(
      vsync: PlayingCardState(),
      duration: duration,
    );
    final Animation<double> rotationAnimation = Tween<double>(
            begin: sRotation == rotation.face ? 0 : pi,
            end: eRotation == rotation.face
                ? 2 * pi
                : sRotation == rotation.face ? pi : 3 * pi)
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
              : eAngle == angle.down ? pi : pi * 3 / 2,
    ).animate(
      CurvedAnimation(
        curve: Curves.linear,
        parent: animationController,
      ),
    );
    angleAnimation.addListener(() {
      setState(() {
        currentRotationZ = angleAnimation.value;
      });
    });
    rotationAnimation.addListener(() {
      setState(() {
        axis == Axis.horizontal
            ? currentRotationX = rotationAnimation.value
            : currentRotationY = rotationAnimation.value;
      });
    });
    await animationController.forward().then((value) {
      rotationAnimation.removeListener(() {});
      angleAnimation.removeListener(() {});
    });
  }

  Future<void> move(Duration duration, void Function(void Function()) setState,
      {double eBottom, double eTop, double eRight, double eLeft}) async {
    setState(() {
      moveDuration = duration;
      currentTop = eTop;
      currentBottom = eBottom;
      currentRight = eRight;
      currentLeft = eLeft;
    });
    await Future.delayed(duration);
  }

  Future<void> moveAndTwist(
      {double sBottom,
      double sTop,
      double sRight,
      double sLeft,
      double eBottom,
      double eTop,
      double eRight,
      double eLeft,
      rotation startR,
      rotation eRotation,
      angle sAngle,
      angle eAngle}) async {}
}
