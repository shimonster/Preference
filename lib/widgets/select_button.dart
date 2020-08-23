import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/client.dart';

class SelectButton extends StatelessWidget {
  SelectButton(this.pressHandler, this.condition);

  final void Function(int suit, int rank) pressHandler;
  final bool Function(int suit, int rank) condition;
  static const suits = ['S', 'C', 'D', 'H', 'N'];

  @override
  Widget build(BuildContext context) {
    final client = Provider.of<Client>(context);

    return FlatButton(
      child: Text('Bid'),
      onPressed: () {
        print('onPressed of bid button');
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                5,
                (i) => Row(
                  children: List.generate(
                    5,
                    (index) => SizedBox(
                      width: 50,
                      height: 50,
                      child: RaisedButton(
                        child: Text('${suits[index]} ${i + 1}'),
                        onPressed: client.game.bid == null ||
                                (client.game.bid['suit'] <= index &&
                                    (client.game.bid['suit'] > index ||
                                        client.game.bid['rank'] <= i))
                            ? () => pressHandler(index, i)
                            : null,
                      ),
                    ),
                  ),
                ),
              ).toList(),
            ),
          ),
        );
      },
    );
  }
}
