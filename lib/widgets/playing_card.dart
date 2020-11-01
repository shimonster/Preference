import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/card_move_extention.dart';
import '../providers/cards.dart' as c;
import '../providers/client.dart';
import '../SPMP.dart';

// ignore: must_be_immutable
class PlayingCard extends StatefulWidget {
  PlayingCard(this.suit, this.rank, this.cards, key) : super(key: key);

  final c.suits suit;
  final c.ranks rank;
  static const multiplySizeWidth = 0.06;
  static const multiplySizeHeight = 0.06 * 23 / 16;
  final c.Cards cards;

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
  c.Card thisCard;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      thisCard = Provider.of<Client>(context, listen: false)
          .game
          .cards
          .cards
          .firstWhere((element) =>
              element.hashCode ==
              int.parse('${widget.rank.index}${widget.suit.index}'));
      thisCard.positionStream.done.then((value) => print(
          'position stream done: ${widget.suit.index}  ${widget.rank.index}'));
      thisCard.rotationStream.done.then((value) => print(
          'ROTATION stream done: ${widget.suit.index}  ${widget.rank.index}'));
      _isInit = true;
    }
  }

  @override
  void dispose() {
    super.dispose();
    print('playing card dispose: ${widget.rank.index}  ${widget.suit.index}');
    thisCard.positionStream.close();
//    thisCard.positionStream.sink.close();
    thisCard.rotationStream.close();
  }

  // defines how the card will look
  Widget get card {
    final size = MediaQuery.of(context).size;
    return Transform(
      transform: Matrix4.rotationY(thisCard.currentRotationY)
        ..rotateX(thisCard.currentRotationX)
        ..rotateZ(thisCard.currentRotationZ),
      alignment: Alignment.center,
      child: Container(
        width: size.width * PlayingCard.multiplySizeWidth,
        height: size.width * PlayingCard.multiplySizeHeight,
        decoration: BoxDecoration(
          color:
              thisCard.cardMoveExtension.isFace ? Colors.orange : Colors.blue,
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
    // builds the card
    return StreamBuilder(
        stream: thisCard.positionStream.stream,
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
              stream: thisCard.rotationStream.stream,
              builder: (context, snap) {
                print('rotation builder was run:    ${[
                  thisCard.bottom,
                  thisCard.top,
                  thisCard.right,
                  thisCard.left
                ]}');
                print('');
                final newCard = card;
                final placed = client.game.cards.placed;
                final firstSuit = placed.isNotEmpty
                    ? client.game.cards.cards
                        .firstWhere((element) => element.isFirstPlaced)
                        .suit
                    : null;
                return thisCard.place == c.places.player1 &&
                        ((client.game.gameState == SPMP.playing &&
                                client.game.cards.turn == client.uid) ||
                            (client.game.gameState == SPMP.discarding &&
                                client.game.bidId == client.uid))
                    ? client.game.gameState == SPMP.discarding ||
                            placed.isEmpty ||
                            firstSuit == widget.suit ||
                            client.game.bid['suit'] == widget.suit.index ||
                            client.game.cards.p1Cards
                                .every((element) => element.suit != firstSuit)
                        ? Draggable(
                            feedback: newCard,
                            childWhenDragging: Container(
                              width: size.width * PlayingCard.multiplySizeWidth,
                              height:
                                  size.width * PlayingCard.multiplySizeHeight,
                              color: Colors.black54,
                            ),
                            data: thisCard,
                            child: newCard,
                          )
                        : Stack(
                            children: [
                              newCard,
                              Container(
                                color: Colors.black54,
                                width:
                                    PlayingCard.multiplySizeWidth * size.width,
                                height:
                                    PlayingCard.multiplySizeHeight * size.width,
                              ),
                            ],
                          )
                    : newCard;
              },
            ),
          );
        });
  }
}
