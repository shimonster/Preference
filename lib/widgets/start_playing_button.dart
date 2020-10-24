import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/client.dart';

class StartPlayingButton extends StatelessWidget {
  const StartPlayingButton(this.setHasAccepted, this.ctx);

  final void Function(bool) setHasAccepted;
  final BuildContext ctx;

  @override
  Widget build(BuildContext context) {
    final client = Provider.of<Client>(context);
    return RaisedButton(
      onPressed: () async {
        client.play();
        setHasAccepted(true);
      },
      child: Text('start'),
    );
  }
}
