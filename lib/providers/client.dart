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
  Stream socketStream;

  void init() {
    game = Game(this);
  }

  void startClient(int portNumber, String nickname, String id) {
    port = portNumber;
    username = nickname;
    uid = id;
    socketStream = socketStreamController.stream;
    final address = 'ws://localhost:$port/$uid/$username';
    ws = WebSocket(address);
    if (ws.readyState != WebSocket.CLOSED ||
        ws.readyState != WebSocket.CLOSING) {
      print('socket open');
      ws.onMessage.listen(
        (jsonEvent) {
          final eventMap = json.decode(jsonEvent.data) as Map;
          final Map<String, dynamic> event =
              eventMap.map((key, value) => MapEntry(key, value));
          print('${DateTime.now()}, $event');
          if (event['method'] == SPMP.bid) {
            game.cards.turn = event['turn'];
            game.placeBid(event['rank'], event['suit'], event['uid']);
          }
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
          if (event['method'] == SPMP.dispose) {
            for (var i = 0; i < 2; i++) {
              game.cards.move(event['rank'][i], event['suit'][i], SPMP.disposed,
                  SPMP.dispose, false, event['uid']);
            }
          }
          if (event['method'] == SPMP.collectWidow) {
            for (var i = 0; i < 2; i++) {
              game.cards.move(
                  event['rank'][i],
                  event['suit'][i],
                  game.players.keys.toList().indexOf(event['uid']),
                  SPMP.dispose,
                  false,
                  event['uid']);
            }
          }
          if (event['method'] == SPMP.startPlaying) {
            game.isPlaying = true;
            game.gameState = SPMP.bidding;
            game.cards.setCards(List<Map>.from(event['cards'])
                .map<Card>((e) => Card(ranks.values[e['rank']],
                    suits.values[e['suit']], places.values[e['place']]))
                .toList());
          }
          if (event['method'] == SPMP.finishBidding) {
            game.gameState = SPMP.playing;
          }
          if (event['method'] == SPMP.playerJoin ||
              event['method'] == SPMP.playerLeave) {
            game.players =
                Map<String, Map<String, dynamic>>.from(event['players']);
          }
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
