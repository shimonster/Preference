import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:preference/providers/cards.dart';
import 'package:provider/provider.dart';

import '../widgets/playing_card.dart';
import '../helpers/card_move_extention.dart';
import '../providers/cards.dart' show places;
import '../providers/client.dart';

class StartPlayingButton extends StatelessWidget {
  const StartPlayingButton(this.setIsPlaying, this.setHasAccepted);

  final void Function(bool) setIsPlaying;
  final void Function(bool) setHasAccepted;

  @override
  Widget build(BuildContext context) {
    final client = Provider.of<Client>(context);
    final cards = client.game.cards;
    return Positioned(
      bottom: 30,
      child: RaisedButton(
        onPressed: () async {
          client.play();
          setHasAccepted(true);
          client.startGameStream.stream.listen((_) async {
            setIsPlaying(true);
            await Future.delayed(Duration(milliseconds: 50));
            Future.forEach([
              ...cards.p2Cards,
              ...cards.p1Cards,
              ...cards.p3Cards,
              ...cards.widows
            ], (PlayingCard playingCard) async {
              playingCard.move(
                Duration(),
                eTop: -100,
                eRight: MediaQuery.of(context).size.width / 2,
              );
              playingCard.moveAndTwist(
                Duration(milliseconds: 1000),
                eTop: playingCard.top,
                eRight: playingCard.right,
                eLeft: playingCard.left,
                eBottom: playingCard.bottom,
                sRotation: rotation.back,
                eRotation: playingCard.place == places.player1
                    ? rotation.face
                    : rotation.back,
                sAngle: angle.up,
                eAngle: playingCard.place == places.player1 ||
                        playingCard.place == places.widow
                    ? angle.up
                    : playingCard.place == places.player2
                        ? angle.right
                        : angle.left,
                axis: Axis.vertical,
              );
              await Future.delayed(Duration(milliseconds: 100));
            });
            client.startGameStream.close();
          });
        },
        child: Text('start'),
      ),
    );
  }
}
