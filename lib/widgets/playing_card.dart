import 'package:flutter/material.dart';

import '../helpers/card_move_extention.dart';
import '../providers/cards.dart';

class PlayingCard extends StatefulWidget {
  PlayingCard(this.suit, this.rank, this.place,
      {this.top, this.bottom, this.right, this.left});

  final suits suit;
  final ranks rank;
  final places place;
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

  Future<void> stateCardMoveAndRotate(Duration duration,
      {double eBottom,
      double eTop,
      double eRight,
      double eLeft,
      rotation sRotation,
      rotation eRotation,
      angle sAngle,
      angle eAngle,
      Axis axis}) async {
    moveAndTwist(duration, setState,
        eTop: eTop,
        eRight: eRight,
        eLeft: eLeft,
        eBottom: eBottom,
        sAngle: sAngle,
        eAngle: eAngle,
        sRotation: sRotation,
        eRotation: eRotation,
        axis: axis);
  }

  bool _isInit = false;
  double multiplySizeWidth = 0.1;
  double multiplySizeHeight = 0.1 * 23 / 16;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      stateCardMove(
        Duration(milliseconds: 0),
        eBottom: widget.place != places.player1
            ? null
            : -(MediaQuery.of(context).size.width * multiplySizeHeight) - 50,
        eTop: widget.place == places.player1
            ? null
            : -(MediaQuery.of(context).size.width * multiplySizeHeight) - 50,
        eRight: MediaQuery.of(context).size.width / 2,
      ).then(
        (value) => stateCardMoveAndRotate(
          Duration(milliseconds: 3000),
          eTop: widget.top,
          eRight: widget.right,
          eLeft: widget.left,
          eBottom: widget.bottom,
          sRotation: rotation.back,
          eRotation:
              widget.place == places.player1 ? rotation.face : rotation.back,
          sAngle: widget.place == places.player1 || widget.place == places.widow
              ? null
              : angle.up,
          eAngle: widget.place == places.player1 || widget.place == places.widow
              ? null
              : widget.place == places.player2 ? angle.right : angle.left,
          axis: Axis.vertical,
        ),
      );
    }
    _isInit = true;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: moveDuration,
      curve: Curves.easeInOut,
      top: currentTop,
      bottom: currentBottom,
      right: currentRight,
      left: currentLeft,
      child: Transform(
        transform: Matrix4.rotationY(currentRotationY)
          ..rotateX(currentRotationX)
          ..rotateZ(currentRotationZ),
        alignment: Alignment.center,
        child: Container(
          width: MediaQuery.of(context).size.width * multiplySizeWidth,
          height: MediaQuery.of(context).size.width * multiplySizeHeight,
          decoration: BoxDecoration(
//            gradient: LinearGradient(colors: [Colors.blue, Colors.orange]),
            color: isFace ? Colors.orange : Colors.blue,
            border: Border.all(width: 5),
          ),
          child: Center(
            child: Text('${widget.suit}   ${widget.rank}'),
          ),
        ),
      ),
    );
  }
}
