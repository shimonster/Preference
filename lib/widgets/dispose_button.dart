import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../SPMP.dart';
import '../providers/client.dart';
import '../providers/cards.dart' as c;

class DisposeButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Client client = Provider.of<Client>(context);
    final c.Cards cards = client.game.cards;
    return StreamBuilder(
      stream: client.game.cards.disposeStream.stream,
      builder: (context, snapshot) {
        return client.game.gameState == SPMP.discarding
            ? RaisedButton(
                child: Text('Dispose'),
                onPressed: client.game.cards.cards
                            .where((element) =>
                                element.place == c.places.disposing)
                            .length ==
                        2
                    ? () {
                        print('dispose cards was pressed');
                        final disposeCrds = cards.cards.where(
                            (element) => element.place == c.places.disposing);
                        client.game.cards.disposeCards(
                          disposeCrds.map((e) => e.rank.index).toList(),
                          disposeCrds.map((e) => e.suit.index).toList(),
                        );
                      }
                    : null,
              )
            : Container();
      },
    );
  }
}
