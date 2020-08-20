import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../SPMP.dart';
import '../providers/client.dart';
import '../providers/cards.dart' as c;

class DisposeTarget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final client = Provider.of<Client>(context, listen: false);
    final cards = client.game.cards;
    return Center(
      child: DragTarget<c.Card>(
        builder: (ctx, items, __) {
          return Container(
            height: 100,
            width: 100,
            color: Colors.grey,
          );
        },
        onAccept: (data) {
          print('accepted data');
          cards.move([data.rank.index], [data.suit.index], SPMP.disposing,
              SPMP.dispose, false, client.uid);
        },
        onWillAccept: (value) {
          if (cards.cards
                  .where((element) => element.place == c.places.disposing)
                  .length >=
              2) {
            return false;
          } else {
            return true;
          }
        },
      ),
    );
  }
}
