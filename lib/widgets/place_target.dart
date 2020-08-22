import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cards.dart' as c;
import '../providers/client.dart';

class PlaceTarget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final client = Provider.of<Client>(context);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(),
      ),
      child: DragTarget<c.Card>(
        builder: (ctx, _, __) {
          print(_);
          print(__);
          return Container();
        },
        onAccept: (c.Card value) {
          client.game.cards.placeCard(value.rank.index, value.suit.index);
        },
      ),
    );
  }
}
