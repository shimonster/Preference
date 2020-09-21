import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/card_move_extention.dart';
import '../providers/cards.dart' as c;
import '../providers/client.dart';
import '../SPMP.dart';

// ignore: must_be_immutable
class PlayingCard extends StatefulWidget with CardMoveExtension {
  PlayingCard(this.suit, this.rank,
      {this.top, this.bottom, this.right, this.left});

  final c.suits suit;
  final c.ranks rank;
  final double top;
  final double bottom;
  final double right;
  final double left;
  static const multiplySizeWidth = 0.06;
  static const multiplySizeHeight = 0.06 * 23 / 16;

  bool equals(PlayingCard other) {
    return other.rank == rank && other.suit == suit;
  }

  @override
  PlayingCardState createState() => PlayingCardState();
}

class PlayingCardState extends State<PlayingCard>
    with SingleTickerProviderStateMixin {
  c.Card get thisCard {
    final card = Provider.of<Client>(context, listen: false)
        .game
        .cards
        .cards
        .firstWhere((element) =>
            element.rank == widget.rank && element.suit == widget.suit);
    return card;
  }

  @override
  void initState() {
    super.initState();
    widget.positionStream.stream.listen((event) {
      print('position stream: ${widget.suit.index}  ${widget.rank.index}');
      setState(() {});
    });
//    widget.rotationStream.stream.listen((event) {
//      print('position stream');
//    });
    widget.positionStream.done.then((value) => print(
        'position stream done: ${widget.suit.index}  ${widget.rank.index}'));
    widget.rotationStream.done.then((value) => print(
        'ROTATION stream done: ${widget.suit.index}  ${widget.rank.index}'));
  }

  @override
  void dispose() {
    super.dispose();
    widget.positionStream.close();
    widget.rotationStream.close();
  }

  // defines how the card will look
  Widget get card {
    final width = MediaQuery.of(context).size.width;
    return Transform(
      transform: Matrix4.rotationY(widget.currentRotationY)
        ..rotateX(widget.currentRotationX)
        ..rotateZ(widget.currentRotationZ),
      alignment: Alignment.center,
      child: Container(
        width: width * PlayingCard.multiplySizeWidth,
        height: width * PlayingCard.multiplySizeHeight,
        decoration: BoxDecoration(
          color: widget.isFace ? Colors.orange : Colors.blue,
          border: Border.all(width: 5),
        ),
        child: Center(
          child:
              Text('${thisCard.suit}   ${thisCard.rank}    ${thisCard.place}'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final client = Provider.of<Client>(context, listen: false);
    final width = MediaQuery.of(context).size.width;
    final newCard = card;
    // builds the card
    return Positioned(
      right: widget.currentRight,
      left: widget.currentLeft,
      bottom: widget.currentBottom,
      top: widget.currentTop,
      child: StreamBuilder(
        stream: widget.rotationStream.stream,
        builder: (context, snap) {
          print('rotation builder was run: $thisCard  ${[
            widget.currentBottom,
            widget.currentTop,
            widget.currentRight,
            widget.currentLeft
          ]}');
          return thisCard.place == c.places.player1 &&
                  ((client.game.gameState == SPMP.playing &&
                          client.game.cards.turn == client.uid) ||
                      (client.game.gameState == SPMP.discarding &&
                          client.game.bidId == client.uid))
              ? Draggable(
                  feedback: newCard,
                  childWhenDragging: Container(
                    width: width * PlayingCard.multiplySizeWidth,
                    height: width * PlayingCard.multiplySizeHeight,
                    color: Colors.black54,
                  ),
                  data: thisCard,
                  child: newCard,
                )
              : newCard;
        },
      ),
    );
  }
}
