// ignore: avoid_web_libraries_in_flutter
import 'dart:html';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../SPMP.dart';

class Client extends ChangeNotifier {
  Client();

  String username;
  int port;
  String uid;
  WebSocket ws;

  void startClient(int portNumber, String nickname, String id) {
    port = portNumber;
    nickname = nickname;
    uid = id;
    print('client started');
    final address = 'ws://localhost:$port/$uid/$username';
    ws = WebSocket(address);
    print('client connected to ws');
    if (ws.readyState != WebSocket.CLOSED ||
        ws.readyState != WebSocket.CLOSING) {
      print('after threads');
      ws.onMessage.listen(
        (event) {
          print(
              '${DateTime.now()}, ${Map<String, String>.from(json.decode(event.data))}');
          print('after add');
          notifyListeners();
        },
        onDone: () => print('listening to seb socket finished'),
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
