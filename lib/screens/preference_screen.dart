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
import '../widgets/dispose_target.dart';
import '../widgets/dispose_button.dart';
import '../widgets/select_button.dart';
import '../widgets/place_target.dart';
import '../widgets/ooga_booga.dart';

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

  void setHasAccepted(bool val) {
    print('accepted');
    setState(() {
      _hasAccepted = val;
    });
  }

  @override
  void initState() {
    super.initState();
    Provider.of<Client>(context, listen: false).context = context;
    Provider.of<Client>(context, listen: false).game.getCurrentGame().then(
          (_) => setState(() {
            _isLoading = false;
          }),
        );
    sub = html.window.onPopState.listen((event) {
      if (!hasPopped && event.type == 'popstate') {
        Provider.of<Client>(context, listen: false).game.leaveGame();
        sub.cancel();
        setState(() {
          _isLoading = true;
        });
        hasPopped = true;
        Provider.of<Client>(context, listen: false)
            .game
            .cards
            .cardStream
            .close();
        print('event: ${event.type}');
        Navigator.of(context).pushReplacementNamed('/');
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    print('preference dispose');
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
                stream: client.startGameStream.stream,
                builder: (context, snapshot) {
                  print(client.game.gameState);
                  return StreamBuilder(
                    stream: client.game.cards.cardStream.stream,
                    builder: (context, snapshot) {
                      print(
                          'preference screen about to build stack: p1: ${cards.p1Cards}, p2: ${cards.p2Cards}, p3: ${cards.p3Cards}, cards: ${cards.cards.map((e) => e.place).toList()}');
                      return Stack(
                        fit: StackFit.loose,
                        children: [
                          // other stuff
                          if (client.game.bidId == client.uid &&
                              client.game.gameState == SPMP.discarding)
                            DisposeTarget(),
                          // ---------------------------------
                          if (client.game.bidId == client.uid &&
                              client.game.gameState == SPMP.declaring)
                            SelectButton((int suit, int rank) {
                              print('onpressse d handler');
                              client.game.declareGame(suit, rank, true);
                            },
                                (int suit, int rank) =>
                                    !((client.game.bid['suit'] > suit &&
                                            client.game.bid['rank'] >= rank) ||
                                        client.game.bid['rank'] > rank)),
                          // ---------------------------------
                          if (client.game.bidId == client.uid) DisposeButton(),
                          // ---------------------------------
                          if (client.game.gameState == SPMP.playing)
                            if (client.game.cards.turn == client.uid)
                              Text('my turn!')
                            else
                              Text(client.game.cards.turn),
                          if ((client.game.gameState == SPMP.playing ||
                                  client.game.gameState ==
                                      SPMP.collectingWidow) &&
                              client.game.cards.turn == client.uid)
                            Center(child: PlaceTarget()),
                          // ---------------------------------
                          if (client.game.gameState == SPMP.bidding)
                            BiddingButtons(),
                          // ---------------------------------
                          if (!_hasAccepted)
                            StartPlayingButton(setHasAccepted, context),
                          // ---------------------------------
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
                          // ---------------------------------
                          if (client.game.isPlaying) ...cards.p2Cards,
                          if (client.game.isPlaying) ...cards.p1Cards,
                          if (client.game.isPlaying) ...cards.p3Cards,
                          if (client.game.isPlaying &&
                              client.game.gameState != SPMP.discarding)
                            ...cards.widows,
                          if (client.game.gameState == SPMP.playing)
                            ...cards.placed,
                          // ---------------------------------
                          OogaBooga(),
                          // ---------------------------------
                          if (client.game.isPlaying)
                            Center(
                              child: Text(client.uid),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      floatingActionButton: GameInfo(),
    );
  }
}
