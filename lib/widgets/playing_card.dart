import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/card_move_extention.dart';
import '../providers/cards.dart';
import '../providers/client.dart';
import '../SPMP.dart';

// ignore: must_be_immutable
class PlayingCard extends StatefulWidget with CardMoveExtension {
  PlayingCard(this.suit, this.rank, this.place,
      {this.top, this.bottom, this.right, this.left});

  final suits suit;
  final ranks rank;
  final places place;
  final double top;
  final double bottom;
  final double right;
  final double left;

  @override
  PlayingCardState createState() => PlayingCardState();
}

class PlayingCardState extends State<PlayingCard>
    with SingleTickerProviderStateMixin {
  double multiplySizeWidth = 0.06;
  double multiplySizeHeight = 0.06 * 23 / 16;
  bool isInit = false;
  void Function(void Function()) setCardState;

  @override
  void dispose() {
    super.dispose();
    widget.positionStream.close();
  }

  @override
  Widget build(BuildContext context) {
    print('build of a card was run: ${widget.currentTop}');
    final client = Provider.of<Client>(context, listen: false);
    return StreamBuilder(
      stream: widget.positionStream.stream,
      builder: (context, snapshot) {
        print('position builder was run');
        return AnimatedPositioned(
          duration: Duration(seconds: 1),
          curve: Curves.easeInOut,
          top: widget.currentTop,
          bottom: widget.currentBottom,
          right: widget.currentRight,
          left: widget.currentLeft,
          child: StreamBuilder(
            stream: widget.rotationStream.stream,
            builder: (context, snap) {
              print('rotation builder was run');
              final card = Transform(
                transform: Matrix4.rotationY(widget.currentRotationY)
                  ..rotateX(widget.currentRotationX)
                  ..rotateZ(widget.currentRotationZ),
                alignment: Alignment.center,
                child: Container(
                  width: MediaQuery.of(context).size.width * multiplySizeWidth,
                  height:
                      MediaQuery.of(context).size.width * multiplySizeHeight,
                  decoration: BoxDecoration(
                    color: widget.isFace ? Colors.orange : Colors.blue,
                    border: Border.all(width: 5),
                  ),
                  child: Center(
                    child: Text('${widget.suit}   ${widget.rank}'),
                  ),
                ),
              );
              return widget.place == places.player1 &&
                      (client.game.gameState == SPMP.playing ||
                          client.game.gameState == SPMP.discarding) &&
                      (client.game.cards.turn == client.uid ||
                          client.game.biddingId == client.uid)
                  ? Draggable(
                      feedback: card,
                      childWhenDragging: Container(),
                      child: card,
                    )
                  : card;
            },
          ),
        );
      },
    );
  }
}
