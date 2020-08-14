// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import '../widgets/bidding_buttons.dart';
import '../SPMP.dart';
import '../providers/client.dart';
import '../widgets/game_info.dart';
import '../widgets/start_playing_button.dart';

class PreferenceScreen extends StatefulWidget {
  static const routeName = '/preference';

  @override
  _PreferenceScreenState createState() => _PreferenceScreenState();
}

class _PreferenceScreenState extends State<PreferenceScreen> {
  bool _isPlaying = false;
  bool _hasAccepted = false;
  bool _isLoading = true;
  bool hasPopped = false;
  StreamSubscription sub;
  StreamSubscription stream;

  void setHasAccepted(bool val) {
    setState(() {
      _hasAccepted = val;
    });
  }

  void setIsPlaying(bool val) {
    _isPlaying = val;
  }

  @override
  void initState() {
    super.initState();
    Provider.of<Client>(context, listen: false).game.getCurrentGame().then(
          (_) => setState(() {
            _isLoading = false;
          }),
        );
    sub = html.window.onPopState.listen((event) {
      if (!hasPopped) {
        setState(() {
          _isLoading = true;
        });
        hasPopped = true;
        print('event: ${event.type}');
        Navigator.of(context).pushReplacementNamed('/');
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    sub.cancel();
    stream.cancel();
    Provider.of<Client>(context, listen: false).game.leaveGame();
  }

  @override
  Widget build(BuildContext context) {
    final client = Provider.of<Client>(context, listen: false);
    final cards = client.game.cards;
    return Scaffold(
      backgroundColor: Color.fromRGBO(28, 91, 11, 1),
      body: Container(
        decoration: BoxDecoration(
          border: Border.all(width: 10),
        ),
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(),
              )
            : StreamBuilder(
                stream: client.socketStream,
                builder: (context, snapshot) {
                  return Stack(
                    fit: StackFit.loose,
                    children: [
                      if (_isPlaying) ...cards.p2Cards,
                      if (_isPlaying) ...cards.p1Cards,
                      if (_isPlaying) ...cards.p3Cards,
                      if (_isPlaying) ...cards.widows,
                      if (client.game.gameState == SPMP.bidding)
                        StreamBuilder(
                          stream: client.bidStream.stream,
                          builder: (ctx, snap) => client.game.biddingId ==
                                  client.uid
                              ? Positioned(
                                  bottom:
                                      MediaQuery.of(context).size.height * 0.2,
                                  right:
                                      MediaQuery.of(context).size.width * 0.5 -
                                          50,
                                  child: BiddingButtons(),
                                )
                              : Container(),
                        ),
                      if (_hasAccepted && !_isPlaying)
                        Center(
                          child: Text(
                            'Get Ready!',
                            style: TextStyle(
                              fontSize: 30,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      if (_isPlaying)
                        Center(
                          child: Text(client.uid),
                        ),
                      if (!_hasAccepted)
                        StartPlayingButton(setIsPlaying, setHasAccepted),
                    ],
                  );
                }),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      floatingActionButton: GameInfo(),
    );
  }
}
