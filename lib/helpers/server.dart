import 'dart:io';
import 'dart:convert';

import '../SPMP.dart';
import './server_cards.dart';
import './server_game.dart';

void main() {
  Server(1234).startServer();
}

class Server {
  Server(this.port);

  final int port;

  CardsManagement cardsController;
  GameManagement gameController;
  Map<String, WebSocket> clientSockets = {};

  void startServer() {
    print('server started');
    cardsController = CardsManagement(sendMessage);
    gameController = GameManagement(cardsController, sendMessage);
    HttpServer.bind('localhost', port).then(
      (server) {
        print('after threads');
        server.listen(
          (request) {
            final uid = request.uri.pathSegments[0];
            final nickname = request.uri.pathSegments[1];
            WebSocketTransformer.upgrade(request).then(
              (ws) {
                // if a request is sent to server, a client joined
                print('a client connected to ws');
                clientSockets.putIfAbsent(uid, () => ws);
                print('player joined');
                gameController.joinGame(uid, nickname);
                cardsController.joinGame(uid, nickname);
                sendMessage({
                  'method': SPMP.playerJoin,
                  'players': gameController.players,
                }, uid);
                // when the web socket is open, we listen for additions
                if (ws.readyState == WebSocket.open) {
                  ws.listen(
                    (jsonEvent) {
                      final event =
                          Map<String, dynamic>.from(json.decode(jsonEvent));
                      print(event['method']);
// event handling based on event['method'] -------------- event handling based on event['method'] --------------
                      // bid bid bid bid bid bid bid bid bid bid bid bid bid bid
                      if (event['method'] == SPMP.bid ||
                          event['method'] == SPMP.pass) {
                        gameController.placeBid(
                            event['rank'], event['suit'], event['uid']);
                      }
                      // declare declare declare declare declare declare declare
                      if (event['method'] == SPMP.declare) {
                        gameController.declareGame(
                            event['rank'], event['suit']);
                      }
                      // place place place place place place place place place
                      if (event['method'] == SPMP.place) {
                        cardsController.move(
                            event['rank'],
                            event['suit'],
                            gameController.players.keys
                                .toList()
                                .indexOf(event['uid']));
                      }
                      // dispose dispose dispose dispose dispose dispose dispose
                      if (event['method'] == SPMP.dispose) {
                        for (var i = 0; i < 2; i++) {
                          cardsController.move(event['rank'][i],
                              event['suit'][i], SPMP.disposed);
                        }
                        sendMessage({
                          'method': SPMP.dispose,
                          'rank': event['rank'],
                          'suit': event['suit'],
                          'uid': event['uid']
                        }, event['uid']);
                        sendMessage({
                          'method': SPMP.finishBidding,
                        });
                      }
                      // accept-play accept-play accept-play accept-play accept-play
                      if (event['method'] == SPMP.acceptPlay) {
                        if (gameController.acceptPlay(event['uid'])) {
                          final cards = cardsController.randomize();
                          sendMessage({
                            'method': SPMP.startPlaying,
                            'cards': cards,
                            'biddingId': gameController.biddingId,
                          });
                        }
                      }
                      // player-leave player-leave player-leave player-leave
                      if (event['method'] == SPMP.playerLeave) {
                        sendMessage({
                          'method': SPMP.playerLeave,
                          'players': gameController.players
                        });
                      }
                    },
                    onDone: () {
                      print('listening to web socket finished');
                      clientSockets.remove(uid);
                      gameController.players.remove(uid);
                      cardsController.players.remove(uid);
                      if (gameController.players.isEmpty) {
                        server.close();
                      }
                    },
                    onError: (error) {
                      print('client error listening to web socket: $error');
                      clientSockets.remove(uid);
                    },
                    cancelOnError: true,
                  );
                }
              },
            );
          },
        );
      },
      onError: (error) => print('client error contacing web socker: $error'),
    );
  }

  void sendMessage(Map<String, dynamic> message, [String exclude]) {
    print('about to send server message: $message');
    clientSockets.forEach((key, value) {
      if (message['method'] == SPMP.startPlaying) {
        // if we are starting playing
        Map<String, Map<String, dynamic>> newPlayers = {
          ...gameController.players
        };
        while (newPlayers.keys.toList().first != key) {
          print(
              'list not sorted correctly: $key: ${newPlayers.keys.toList().first}');
          final entries = newPlayers.entries.toList();
          final first = entries[0];
          entries.add(first);
          entries.removeAt(0);
          newPlayers = entries.fold(
              {},
              (previousValue, element) =>
                  {...previousValue, element.key: element.value});
        }
        gameController.players = newPlayers;
        cardsController.players = newPlayers;
        value.add(json.encode({...message, 'players': newPlayers}));
      }
      // otherwise just send message
      if (key != exclude && message['method'] != SPMP.startPlaying) {
        value.add(json.encode(message));
      }
    });
  }
}
