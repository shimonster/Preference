// ignore: avoid_web_libraries_in_flutter
import 'dart:html';
import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';
//import 'package:flutter/material.dart' as m;

import '../SPMP.dart';
import './game.dart';
import './cards.dart';

class Client extends ChangeNotifier {
  String username;
  int port;
  String uid;
  WebSocket ws;
  Game game;
  final socketStreamController = StreamController.broadcast();
  final startGameStream = StreamController.broadcast();
  final bidStream = StreamController.broadcast();

  void init() {
    game = Game(this);
  }

  void startClient(int portNumber, String nickname, String id) {
    port = portNumber;
    username = nickname;
    uid = id;
    socketStreamController.onListen = () => print('stream listened to');
    final address = 'ws://localhost:$port/$uid/$username';
    // connects to web socket
    ws = WebSocket(address);
    // if web socket is open, listen
    if (ws.readyState != WebSocket.CLOSED ||
        ws.readyState != WebSocket.CLOSING) {
      print('socket open');
      ws.onMessage.listen(
        (jsonEvent) {
          final eventMap = json.decode(jsonEvent.data) as Map;
          final Map<String, dynamic> event =
              eventMap.map((key, value) => MapEntry(key, value));
          print('${DateTime.now()}, $event');
// event handling based on event['method'] -------------- event handling based on event['method'] --------------
          // bid bid bid bid bid bid bid bid bid bid bid bid bid bid bid bid bid
          if (event['method'] == SPMP.bid || event['method'] == SPMP.pass) {
            game.biddingId = event['turn'];
            game.placeBid(event['rank'], event['suit'], event['uid']);
            bidStream.add(event);
          }
          // place place place place place place place place place place place
          if (event['method'] == SPMP.place) {
            game.cards.turn = event['turn'];
            game.cards.move(
                event['rank'],
                event['suit'],
                game.players.keys.toList().indexOf(event['uid']),
                SPMP.place,
                false,
                event['uid']);
          }
          // dispose dispose dispose dispose dispose dispose dispose dispose
          if (event['method'] == SPMP.dispose) {
            for (var i = 0; i < 2; i++) {
              game.cards.move(event['rank'][i], event['suit'][i], SPMP.disposed,
                  SPMP.dispose, false, event['uid']);
            }
          }
          // collect-widow collect-widow collect-widow collect-widow collect-widow
          if (event['method'] == SPMP.collectWidow) {
            game.gameState = SPMP.discarding;
            final widow = game.cards.cards
                .where((element) => element.place == places.widow)
                .toList();
            for (var i = 0; i < 2; i++) {
              print('about to change position of cards');
              game.cards.move(
                  widow[i].number.index,
                  widow[i].suit.index,
                  game.players.keys.toList().indexOf(event['uid']),
                  SPMP.collectWidow,
                  false,
                  event['uid']);
            }
          }
          // start-playing start-playing start-playing start-playing start-playing
          if (event['method'] == SPMP.startPlaying) {
            game.isPlaying = true;
            game.biddingId = event['biddingId'];
            game.gameState = SPMP.bidding;
            startGameStream.add(true);
            game.players =
                Map<String, Map<String, dynamic>>.from(event['players']);
            game.cards.setCards(List<Map>.from(event['cards'])
                .map<Card>((e) => Card(
                    ranks.values[e['rank']],
                    suits.values[e['suit']],
                    e['uid'] == SPMP.widow
                        ? places.widow
                        : places.values[
                            game.players.keys.toList().indexOf(e['uid'])]))
                .toList());
            print(game.players);
          }
          // finish-bidding finish-bidding finish-bidding finish-bidding finish-bidding
          if (event['method'] == SPMP.finishBidding) {
            game.gameState = SPMP.playing;
          }
          // player-leave/player-join player-leave/player-join player-leave/player-join
          if (event['method'] == SPMP.playerJoin ||
              event['method'] == SPMP.playerLeave) {
            game.players =
                Map<String, Map<String, dynamic>>.from(event['players']);
          }
          // trick-collected trick-collected trick-collected trick-collected
          if (event['method'] == SPMP.trickCollected) {
            for (var i = 0; i < 3; i++) {
              game.cards.move(
                  event['rank'][i],
                  event['suit'][i],
                  game.players.keys.toList().indexOf(event['uid']) + 9,
                  event['method'],
                  false,
                  event['uid']);
            }
          }
          socketStreamController.add(event);
        },
        onDone: () {
          sendMessage({'method': SPMP.playerLeave, 'uid': uid});
          socketStreamController.close();
        },
        onError: (error) =>
            print('client error listening to web socket: $error'),
        cancelOnError: true,
      );
    }
  }

  void sendMessage(Map<String, dynamic> message) {
    print('sending message from client');
    socketStreamController.add(message);
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
