// ignore: avoid_web_libraries_in_flutter
import 'dart:html';
import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../SPMP.dart';
import './game.dart';

class Client extends ChangeNotifier {
  String username;
  int port;
  String uid;
  WebSocket ws;
  Game game;
  final socketStreamController = StreamController.broadcast();
  Stream socketStream;

  void startClient(int portNumber, String nickname, String id) {
    game = Game(this);
    port = portNumber;
    nickname = nickname;
    uid = id;
    socketStream = socketStreamController.stream;
    print('client started');
    final address = 'ws://localhost:$port/$uid/$username';
    ws = WebSocket(address);
    print('client connected to ws');
    if (ws.readyState != WebSocket.CLOSED ||
        ws.readyState != WebSocket.CLOSING) {
      print('after threads');
      ws.onMessage.listen(
        (jsonEvent) {
          final event = Map<String, dynamic>.from(json.decode(jsonEvent.data));
          print('${DateTime.now()}, $event');
          if (event['method'] == SPMP.bid) {
            game.placeBid(event['rank'], event['suit'], event['uid']);
          }
          if (event['method'] == SPMP.place) {
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
          }
          if (event['method'] == SPMP.finishBidding) {
            game.gameState = SPMP.playing;
          }
          if (event['method'] == SPMP.playerJoin ||
              event['method'] == SPMP.playerLeave) {
            game.players = event['players'];
          }
          if (event['method'] == SPMP.trickCollected) {
            for (var i = 0; i < 3; i++) {
              game.cards.move(
                  event['rank'][i],
                  event['suit'][i],
                  game.players.keys.toList().indexOf(event['uid']) + 9,
                  event['method'],
                  event['uid'] == uid,
                  event['uid']);
            }
          }
          socketStreamController.add(event);
        },
        onDone: () => socketStreamController.close(),
        onError: (error) =>
            print('client error listening to web socket: $error'),
        cancelOnError: true,
      );
    }
  }

  void sendMessage(Map<String, dynamic> message) {
    print('sending message from client');
    ws.send(json.encode(message));
    notifyListeners();
  }

  void placeCard(int suit, int rank) {
    sendMessage({
      'method': SPMP.place,
      'suit': suit,
      'rank': rank,
      'uid': uid,
    });
  }

  void placeBid(int amount, int suit) {
    sendMessage({
      'method': SPMP.bid,
      'suit': suit,
      'amount': amount,
      'uid': uid,
    });
  }

  void play() {
    sendMessage({
      'method': SPMP.acceptPlay,
      'uid': uid,
    });
  }
}
