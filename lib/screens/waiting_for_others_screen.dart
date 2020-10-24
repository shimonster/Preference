import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import './preference_screen.dart';
import '../widgets/start_playing_button.dart';
import '../providers/client.dart';

class WaitingForOthersScreen extends StatefulWidget {
  static const routeName = '/WaitingForOthers';

  @override
  _WaitingForOthersScreenState createState() => _WaitingForOthersScreenState();
}

class _WaitingForOthersScreenState extends State<WaitingForOthersScreen> {
  bool _hasAccepted = false;
  StreamSubscription sub;

  @override
  Widget build(BuildContext context) {
    final client = Provider.of<Client>(context, listen: false);

    void setHasAccepted(bool val) {
      print('accepted');
      setState(() {
        _hasAccepted = val;
      });
      sub = client.game.cards.componentStream.stream.listen((event) {
        if (event == 'start') {
          print('about to go to preference screen');
          Navigator.of(context)
              .pushReplacementNamed(PreferenceScreen.routeName);
          sub.cancel();
        }
      });
    }

    return Scaffold(
      body: Center(
        child: !_hasAccepted
            ? StartPlayingButton(setHasAccepted, context)
            : _hasAccepted && !client.game.isPlaying
                ? Center(
                    child: Text(
                      'Get Ready!',
                      style: TextStyle(
                        fontSize: 30,
                        color: Colors.white,
                      ),
                    ),
                  )
                : Container(),
      ),
    );
  }
}
