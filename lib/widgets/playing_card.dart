import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/card_move_extention.dart';
import '../providers/cards.dart' as c;
import '../providers/client.dart';
import '../SPMP.dart';

// ignore: must_be_immutable
class PlayingCard extends StatefulWidget {
  PlayingCard(this.suit, this.rank, this.cards,
      {this.top, this.bottom, this.right, this.left}) {
    cardMoveExtension = CardMoveExtension(cards, rank.index, suit.index);
  }

  final c.suits suit;
  final c.ranks rank;
  final double top;
  final double bottom;
  final double right;
  final double left;
  static const multiplySizeWidth = 0.06;
  static const multiplySizeHeight = 0.06 * 23 / 16;
  final c.Cards cards;
  CardMoveExtension cardMoveExtension;

  bool equals(PlayingCard other) {
    return other.rank == rank && other.suit == suit;
  }

  @override
  PlayingCardState createState() {
    return PlayingCardState();
  }
}

class PlayingCardState extends State<PlayingCard>
    with SingleTickerProviderStateMixin {
  bool _isInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      widget.cardMoveExtension.positionStream.done.then((value) => print(
          'position stream done: ${widget.suit.index}  ${widget.rank.index}'));
      widget.cardMoveExtension.rotationStream.done.then((value) => print(
          'ROTATION stream done: ${widget.suit.index}  ${widget.rank.index}'));
      _isInit = true;
    }
  }

  @override
  void dispose() {
    super.dispose();
    print('playing card dispose: ${widget.rank.index}  ${widget.suit.index}');
    widget.cardMoveExtension.positionStream.close();
    widget.cardMoveExtension.rotationStream.close();
  }

  // defines how the card will look
  Widget get card {
    final size = MediaQuery.of(context).size;
    final thisCard = widget.cardMoveExtension.thisCardElement;
    return Transform(
      transform: Matrix4.rotationY(thisCard.currentRotationY)
        ..rotateX(thisCard.currentRotationX)
        ..rotateZ(thisCard.currentRotationZ),
      alignment: Alignment.center,
      child: Container(
        width: size.width * PlayingCard.multiplySizeWidth,
        height: size.width * PlayingCard.multiplySizeHeight,
        decoration: BoxDecoration(
          color: widget.cardMoveExtension.isFace ? Colors.orange : Colors.blue,
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
    final size = MediaQuery.of(context).size;
    final thisCard = widget.cardMoveExtension.thisCardElement;
    // builds the card
    return StreamBuilder(
        stream: widget.cardMoveExtension.positionStream.stream,
        builder: (context, snapshot) {
          print('position builder was run:    ${[
            thisCard.bottom,
            thisCard.top,
            thisCard.right,
            thisCard.left
          ]}');
          return Positioned(
            right: thisCard.right,
            left: thisCard.left,
            bottom: thisCard.bottom,
            top: thisCard.top,
            child: StreamBuilder(
              stream: widget.cardMoveExtension.rotationStream.stream,
              builder: (context, snap) {
                print('rotation builder was run:    ${[
                  thisCard.bottom,
                  thisCard.top,
                  thisCard.right,
                  thisCard.left
                ]}');
                print('');
                final newCard = card;
                return thisCard.place == c.places.player1 &&
                        ((client.game.gameState == SPMP.playing &&
                                client.game.cards.turn == client.uid) ||
                            (client.game.gameState == SPMP.discarding &&
                                client.game.bidId == client.uid))
                    ? Draggable(
                        feedback: newCard,
                        childWhenDragging: Container(
                          width: size.width * PlayingCard.multiplySizeWidth,
                          height: size.width * PlayingCard.multiplySizeHeight,
                          color: Colors.black54,
                        ),
                        data: thisCard,
                        child: newCard,
                      )
                    : newCard;
              },
            ),
          );
        });
  }
}
