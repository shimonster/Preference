import 'dart:math';

import 'package:flutter/material.dart';

class Card extends StatefulWidget {
  @override
  _CardState createState() => _CardState();
}

enum rotationX {
  face,
  back,
}

enum rotationY {
  face,
  back,
}

enum angle {
  right,
  left,
  up,
  down,
}

class _CardState extends State<Card> with SingleTickerProviderStateMixin {
  double currentRotationX;
  double currentRotationY;
  double currentRotationZ;

  // e is for end and s is for start

  Future<void> twist(rotation sRotation, rotation eRotation, angle sAngle,
      angle eAngle, Duration duration, Axis axis) async {
    final animationController = AnimationController(
      vsync: this,
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
      currentRotationZ = angleAnimation.value;
    });
    rotationAnimation.addListener(() {});
  }

  Future<void> moveAndTwist(
      {double sBottom,
      double sTop,
      double sRight,
      double sLeft,
      rotation startR,
      double eBottom,
      double eTop,
      double eRight,
      double eLeft,
      rotation eRotation,
      angle sAngle,
      angle eAngle}) async {}

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.15,
        height: MediaQuery.of(context).size.width * 0.15 * 23 / 16,
        child: Text('this is the container'),
      ),
    );
  }
}
