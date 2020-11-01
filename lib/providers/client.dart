// ignore: avoid_web_libraries_in_flutter
import 'dart:html';
import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as m;

import '../SPMP.dart';
import './game.dart';
import './cards.dart';
import '../helpers/card_move_extention.dart';

class Client extends ChangeNotifier {
  String username;
  int port;
  String uid;
  WebSocket ws;
  Game game;
  m.BuildContext context;
  final bidStream = StreamController.broadcast();
  bool isSpectating = false;

  void init() {
    game = Game(this);
  }

  void startClient(int portNumber, String nickname, String id) {
    port = portNumber;
    username = nickname;
    uid = id;
    final address = 'ws://localhost:$port/$uid/$username';
    // connects to web socket
    ws = WebSocket(address);
    // if web socket is open, listen
    print('socket open');
    ws.onMessage.listen(
      (jsonEvent) {
        final eventMap = json.decode(jsonEvent.data) as Map;
        final Map<String, dynamic> event =
            eventMap.map((key, value) => MapEntry(key, value));
        print('RECEIVED MESSAGE, $event');

        /// event handling based on [event['method']] -------------- event handling based on event['method'] --------------
        // bid bid bid bid bid bid bid bid bid bid bid bid bid bid bid bid bid
        if (event['method'] == SPMP.bid || event['method'] == SPMP.pass) {
          game.biddingId = event['turn'];
          game.placeBid(
              event['rank'], event['suit'], event['uid'], event['turn']);
        }
        // declare declare declare declare declare declare declare
        if (event['method'] == SPMP.declare) {
          game.declareGame(event['rank'], event['suit'], false);
        }
        // place place place place place place place place place place place
        if (event['method'] == SPMP.place) {
          game.cards.placeCard(event['rank'], event['suit'], event['turn']);
        }
        // dispose dispose dispose dispose dispose dispose dispose dispose
        if (event['method'] == SPMP.dispose) {
          game.cards.disposeCards(
              List<int>.from(event['rank']), List<int>.from(event['suit']));
        }
        // collect-widow collect-widow collect-widow collect-widow collect-widow
        if (event['method'] == SPMP.collectWidow) {
          game.gameState = SPMP.discarding;
//          final widow = game.cards.cards
//              .where((element) => element.place == places.widow)
//              .toList();
          game.cards
              .collectWidow(game.players.keys.toList().indexOf(event['uid']));
        }
        // start-playing start-playing start-playing start-playing start-playing
        if (event['method'] == SPMP.startPlaying) {
          game.players = Map<String, Map<String, dynamic>>.from(
              event['players'] ?? game.players);
          if (game.players.containsKey(uid)) {
            game.players = game.sortPlayers(uid);
          }
          game.cards.setCards(
            List<Map>.from(event['cards'])
                .map<Card>(
                  (e) => Card(
                      ranks.values[e['rank']],
                      suits.values[e['suit']],
                      e['uid'] == SPMP.widow
                          ? places.widow
                          : places.values[
                              game.players.keys.toList().indexOf(e['uid'])],
                      game.cards),
                )
                .toList(),
          );
          game.isPlaying = true;
          game.biddingId = event['biddingId'];
          game.gameState = SPMP.bidding;
          game.cards.componentStream.add('start');
          game.cards.cardStream.add('about to distribute new cards');
          CardMoveExtension.animateDistribute(game.cards);
          print(game.players);
        }
        // finish-bidding finish-bidding finish-bidding finish-bidding finish-bidding
        if (event['method'] == SPMP.finishBidding) {
//          game.gameState = SPMP.declaring;
//          game.cards.cardStream.add('game state is declaring');
        }
        // player-leave/player-join player-leave/player-join player-leave/player-join
        if (event['method'] == SPMP.playerJoin ||
            event['method'] == SPMP.playerLeave) {
          game.players =
              Map<String, Map<String, dynamic>>.from(event['players']);
        }
        // trick-collected trick-collected trick-collected trick-collected
        if (event['method'] == SPMP.trickCollected) {
          game.cards.collectTrick(event['uid']);
        }
        // finish-round finish-round finish-round finish-round finish-round
        if (event['method'] == SPMP.finishRound) {
          game.finishRound(
              context, Map<String, int>.from(event['playerTricks']));
        }
        // start-collecting start-collecting start-collecting start-collecting
        if (event['method'] == SPMP.startCollecting) {
          game.gameState = SPMP.playing;
          game.cards.turn = event['turn'];
          game.cards
              .placeWidowInMiddle(event['widow suit'], event['widow rank']);
          game.cards.componentStream.add('collecting widow');
        }
      },
      onDone: () {
        sendMessage({'method': SPMP.playerLeave, 'uid': uid});
        print('client done');
        bidStream.close();
        game.cards.disposeStream.close();
        game.cards.cardStream.close();
        game.cards.componentStream.close();
      },
      onError: (error) => print('client error listening to web socket: $error'),
      cancelOnError: true,
    );
  }

  void sendMessage(Map<String, dynamic> message) {
    print('sending message from client');
    ws.send(json.encode(message));
    notifyListeners();
  }

  void play() {
    sendMessage({
      'method': SPMP.acceptPlay,
      'uid': uid,
    });
  }
}
