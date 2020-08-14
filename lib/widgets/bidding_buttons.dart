import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/client.dart';

class BiddingButtons extends StatefulWidget {
  @override
  _BiddingButtonsState createState() => _BiddingButtonsState();
}

class _BiddingButtonsState extends State<BiddingButtons> {
  static const suits = ['S', 'C', 'D', 'H', 'N'];
  @override
  Widget build(BuildContext context) {
    final client = Provider.of<Client>(context, listen: false);
    return Row(
      children: [
        FlatButton(
          child: Text('Pass'),
          onPressed: () {
            print('onPressed of pass button');
            client.game.placeBid(-1, -1, client.uid);
          },
        ),
        SizedBox(
          width: 10,
        ),
        FlatButton(
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
                            onPressed: client.game.bid != null
                                ? client.game.bid['suit'] <= i
                                    ? client.game.bid['suit'] <= i
                                        ? () {
                                            print('a bid button was pressed');
                                            print('client uid: ${client.uid}');
                                            client.game
                                                .placeBid(index, i, client.uid);
                                          }
                                        : null
                                    : null
                                : () {
                                    print('a bid button was pressed');
                                    print('client uid: ${client.uid}');
                                    client.game.placeBid(index, i, client.uid);
                                  },
                          ),
                        ),
                      ),
                    ),
                  ).toList(),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
