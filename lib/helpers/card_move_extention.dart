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
  bool isFace = false;

  // position
  double currentRight;
  double currentLeft;
  double currentTop;
  double currentBottom;
  Duration moveDuration;

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
              : eAngle == angle.down ? pi : pi * 3 / 2,
    ).animate(
      CurvedAnimation(
        curve: Curves.linear,
        parent: animationController,
      ),
    );
    if (sAngle != null && eAngle != null) {
      angleAnimation.addListener(() {
        setState(() {
          currentRotationZ = angleAnimation.value;
        });
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
        setState(() {
          axis == Axis.horizontal
              ? currentRotationX = rotationAnimation.value
              : currentRotationY = rotationAnimation.value;
        });
      });
    }
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
      Duration duration, void Function(void Function()) setState,
      {double eBottom,
      double eTop,
      double eRight,
      double eLeft,
      rotation sRotation,
      rotation eRotation,
      angle sAngle,
      angle eAngle,
      Axis axis}) async {
    move(duration, setState,
        eTop: eTop, eBottom: eBottom, eRight: eRight, eLeft: eLeft);
    rotate(sRotation, eRotation, sAngle, eAngle, duration, axis, setState);
    await Future.delayed(duration);
  }
}
