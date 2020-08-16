import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/client.dart';

class StartPlayingButton extends StatelessWidget {
  const StartPlayingButton(this.setHasAccepted, this.animateDistribution);

  final void Function(bool) setHasAccepted;
  final Future<void> Function() animateDistribution;

  @override
  Widget build(BuildContext context) {
    final client = Provider.of<Client>(context);
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
