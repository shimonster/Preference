import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/client.dart';
import '../SPMP.dart';
import './select_button.dart';

class BiddingButtons extends StatefulWidget {
  @override
  _BiddingButtonsState createState() => _BiddingButtonsState();
}

class _BiddingButtonsState extends State<BiddingButtons> {
  @override
  Widget build(BuildContext context) {
    final client = Provider.of<Client>(context, listen: false);
    return StreamBuilder(
      stream: client.bidStream.stream,
      builder: (ctx, snap) {
        return client.game.biddingId == client.uid &&
                client.game.gameState == SPMP.bidding
            ? Positioned(
                bottom: MediaQuery.of(context).size.height * 0.2,
                right: MediaQuery.of(context).size.width * 0.5 - 50,
                child: Row(
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
                    SelectButton((int suit, int rank) {
                      print('a bid button was pressed');
                      print('client uid: ${client.uid}');
                      client.game.placeBid(rank, suit, client.uid);
                    },
                        (int suit, int rank) =>
                            client.game.bid == null ||
                            (client.game.bid['suit'] == suit &&
                                rank > client.game.bid['rank']) ||
                            suit > client.game.bid['suit']),
                  ],
                ),
              )
            : Container();
      },
    );
  }
}
