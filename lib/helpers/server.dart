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
    cardsController = CardsManagement(sendMessage, this);
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
                sendMessage(
                  {
                    'method': SPMP.playerJoin,
                    'players': gameController.players,
                    'uid': uid,
                  }, /*uid*/
                );
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
                        print(cardsController.turn);
                        cardsController.move(
                          event['rank'],
                          event['suit'],
                          gameController.players.keys
                                  .toList()
                                  .indexOf(cardsController.turn) +
                              5,
                          cardsController.turn,
                        );
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
                            'spectating': gameController.spectating,
                            'players': gameController.players,
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
                      // accept-new-game accept-new-game accept-new-game accept-new-game
                      if (event['method'] == SPMP.acceptNewRound) {
                        cardsController.acceptNewRound(event['uid']);
                      }
                    },
                    onDone: () {
                      print('listening to web socket finished');
                      clientSockets.remove(uid);
                      gameController.allPlayers.remove(uid);
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
    print(clientSockets);
    clientSockets.forEach((key, value) {
      if (key != exclude) {
        value.add(json.encode(message));
      }
    });
  }
}
