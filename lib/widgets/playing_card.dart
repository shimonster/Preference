import 'package:flutter/material.dart';

import '../helpers/card_move_extention.dart';
import '../providers/cards.dart';

class PlayingCard extends StatefulWidget {
  PlayingCard(this.suit, this.rank,
      {this.top, this.bottom, this.right, this.left});

  final suits suit;
  final ranks rank;
  final double top;
  final double bottom;
  final double right;
  final double left;
  final card = PlayingCardState();

  Future<void> rotateCard(
    rotation sRotation,
    rotation eRotation,
    angle sAngle,
    angle eAngle,
    Duration duration,
    Axis axis,
  ) async {
    await card.stateCardRotation(
        sRotation, eRotation, sAngle, eAngle, duration, axis);
  }

  Future<void> moveCard(Duration duration,
      {double eBottom, double eTop, double eRight, double eLeft}) async {
    card.stateCardMove(duration,
        eTop: eTop, eBottom: eBottom, eRight: eRight, eLeft: eLeft);
  }

  @override
  PlayingCardState createState() => card;
}

class PlayingCardState extends State<PlayingCard>
    with SingleTickerProviderStateMixin, CardMoveExtension {
  Future<void> stateCardRotation(
      sRotation, eRotation, sAngle, eAngle, duration, axis) async {
    await rotate(
        sRotation, eRotation, sAngle, eAngle, duration, axis, setState);
  }

  Future<void> stateCardMove(Duration duration,
      {double eBottom, double eTop, double eRight, double eLeft}) async {
    await move(duration, setState,
        eTop: eTop, eBottom: eBottom, eRight: eRight, eLeft: eLeft);
  }

  @override
  void initState() {
    super.initState();
    stateCardMove(Duration(milliseconds: 5000),
        eTop: widget.top,
        eRight: widget.right,
        eLeft: widget.left,
        eBottom: widget.bottom);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: moveDuration,
      curve: Curves.easeInOut,
      top: currentTop ?? 0,
      bottom: currentBottom,
      right: currentRight ?? 0,
      left: currentLeft,
      child: Transform(
        transform: Matrix4.rotationY(currentRotationY)
          ..rotateX(currentRotationX)
          ..rotateZ(currentRotationZ),
        alignment: Alignment.center,
        child: Container(
//          width: MediaQuery.of(context).size.width * 0.15,
//          height: MediaQuery.of(context).size.width * 0.15 * 23 / 16,
          width: 85,
          height: 115,
          decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.blue, Colors.orange])),
          child: Center(
            child: Text('${widget.rank}  ${widget.suit}'),
          ),
        ),
      ),
    );
  }
}
