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
  const StartPlayingButton(this.setHasAccepted, this.animateDistribution);

  final void Function(bool) setHasAccepted;
  final Future<void> Function() animateDistribution;

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
              await Future.delayed(Duration(milliseconds: 50));
              animateDistribution();
            });
          },
          child: Text('start'),
        ));
  }
}
