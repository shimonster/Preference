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
import '../providers/cards.dart';
import '../widgets/playing_card.dart';
import '../helpers/card_move_extention.dart';

class PreferenceScreen extends StatefulWidget {
  static const routeName = '/preference';

  @override
  _PreferenceScreenState createState() => _PreferenceScreenState();
}

class _PreferenceScreenState extends State<PreferenceScreen> {
  bool _hasAccepted = false;
  bool _isLoading = true;
  bool hasPopped = false;
  StreamSubscription sub;
  StreamSubscription stream;

  void setHasAccepted(bool val) {
    print('accepted');
    setState(() {
      _hasAccepted = val;
    });
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

    Future<void> animateDistribute() async {
      await Future.forEach([
        ...cards.p2Cards,
        ...cards.p1Cards,
        ...cards.p3Cards,
        ...cards.widows
      ], (PlayingCard playingCard) async {
        playingCard.move(
          Duration(),
          eTop: -100,
          eRight: MediaQuery.of(context).size.width / 2,
        );
        playingCard.moveAndTwist(
          Duration(milliseconds: 1000),
          eTop: playingCard.top,
          eRight: playingCard.right,
          eLeft: playingCard.left,
          eBottom: playingCard.bottom,
          sRotation: rotation.back,
          eRotation: playingCard.place == places.player1
              ? rotation.face
              : rotation.back,
          sAngle: angle.up,
          eAngle: playingCard.place == places.player1 ||
                  playingCard.place == places.widow
              ? angle.up
              : playingCard.place == places.player2 ? angle.right : angle.left,
          axis: Axis.vertical,
        );
        await Future.delayed(Duration(milliseconds: 100));
      });
    }

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
                stream: client.socketStreamController.stream,
                builder: (context, snapshot) {
                  print(client.game.gameState);
                  return Stack(
                    fit: StackFit.loose,
                    children: [
                      if (client.game.isPlaying) ...cards.p2Cards,
                      if (client.game.isPlaying) ...cards.p1Cards,
                      if (client.game.isPlaying) ...cards.p3Cards,
                      if (client.game.isPlaying) ...cards.widows,
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
                      if (_hasAccepted && !client.game.isPlaying)
                        Center(
                          child: Text(
                            'Get Ready!',
                            style: TextStyle(
                              fontSize: 30,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      if (client.game.isPlaying)
                        Center(
                          child: Text(client.uid),
                        ),
                      if (!_hasAccepted)
                        StartPlayingButton(setHasAccepted, animateDistribute),
                    ],
                  );
                }),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      floatingActionButton: GameInfo(),
    );
  }
}
