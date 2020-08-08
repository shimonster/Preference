import 'dart:io';
import 'dart:convert';
import 'dart:math';

import '../SPMP.dart';

void main() {
  Server(1234).startServer();
}

class Server {
  Server(this.port) {
    cardsController = CardsManagement(sendMessage);
  }

  final int port;

  CardsManagement cardsController;
  GameManagement gameController;
  Map<String, WebSocket> clientSockets = {};

  void startServer() {
    print('server started');
    gameController = GameManagement(cardsController, sendMessage);
    HttpServer.bind('localhost', port).then(
      (server) {
        print('after threads');
        server.listen((request) {
          final uid = request.uri.pathSegments[0];
          final nickname = request.uri.pathSegments[1];
          WebSocketTransformer.upgrade(request).then((ws) {
            print('a client connected to ws');
            clientSockets.putIfAbsent(uid, () => ws);
            gameController.joinGame(uid, nickname);
            sendMessage(
                {'method': SPMP.playerJoin, 'players': gameController.players});
            if (ws.readyState == WebSocket.open) {
              ws.listen(
                (jsonEvent) {
                  final event =
                      Map<String, dynamic>.from(json.decode(jsonEvent));

                  if (event['method'] == SPMP.bid) {
                    if (gameController.placeBid(
                        event['rank'], event['suit'], event['uid'])) {
                      sendMessage({
                        'method': SPMP.bid,
                        'rank': event['rank'],
                        'suit': event['suit'],
                        'uid': event['uid'],
                      });
                    }
                  }
                  if (event['method'] == SPMP.place) {
                    cardsController.move(
                        event['rank'],
                        event['suit'],
                        gameController.players.keys
                            .toList()
                            .indexOf(event['uid']));
                    sendMessage({
                      'method': SPMP.place,
                      'rank': event['rank'],
                      'suit': event['suit'],
                      'uid': event['uid'],
                      'turn': cardsController.turn,
                    }, event['uid']);
                  }
                  if (event['method'] == SPMP.dispose) {
                    for (var i = 0; i < 2; i++) {
                      cardsController.move(
                          event['rank'][i], event['suit'][i], SPMP.disposed);
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
                  if (event['method'] == SPMP.acceptPlay) {
                    if (gameController.acceptPlay(event['uid'])) {
                      final cards = cardsController.randomize();
                      sendMessage({
                        'method': SPMP.startPlaying,
                        'cards': cards,
                        'players': gameController.players
                      });
                    }
                  }
                  if (event['method'] == SPMP.playerJoin) {
                    gameController.joinGame(event['uid'], event['nickname']);
                    sendMessage({
                      'method': SPMP.playerJoin,
                      'players': gameController.players
                    }, event['uid']);
                  }
                  if (event['method'] == SPMP.playerLeave) {
                    sendMessage({
                      'method': SPMP.playerLeave,
                      'players': gameController.players
                    });
                  }
                },
                onDone: () {
                  print('listening to seb socket finished');
                  clientSockets.remove(uid);
                  gameController.players.remove(uid);
                },
                onError: (error) {
                  print('client error listening to web socket: $error');
                  clientSockets.remove(uid);
                },
                cancelOnError: true,
              );
            }
          });
        });
      },
      onError: (error) => print('client error contacing web socker: $error'),
    );
  }

  void sendMessage(Map<String, dynamic> message, [String exclude]) {
    print('about to send server message: $message');
    clientSockets.forEach((key, value) {
      if (key != exclude) {
        value.add(json.encode(message));
      }
    });
  }
}

class CardsManagement {
  CardsManagement(this.sendMessage);

  final void Function(Map<String, dynamic> message, [String exclude])
      sendMessage;
  List<Map<String, int>> _cards;
  int turn = 0;
  int player1Cards = 0;
  int player2Cards = 0;
  int player3Cards = 0;
  int player1Tricks = 0;
  int player2Tricks = 0;
  int player3Tricks = 0;

  List<Map<String, int>> randomize() {
    List<Map<String, int>> addCard = [];
    for (var i = 0; i < 32; i++) {
      addCard.add({
        'rank': i % 8,
        'suit': (i / 8).floor(),
        'place': null,
      });
    }
    _cards = addCard;
    _cards.shuffle(Random());
    _cards.asMap().forEach((elemId, element) {
      _cards[elemId]['place'] = (elemId / 10).floor();
    });
    player1Cards = 10;
    player2Cards = 10;
    player3Cards = 10;
    return _cards;
  }

  void move(int rank, int suit, int place, [String uid]) {
    bool didPlace = false;
    _cards.firstWhere((element) =>
        element['rank'] == rank && element['suit'] == suit)['place'] = place;
    // placing a card
    if (place == SPMP.center1) {
      didPlace = true;
      player1Cards -= 1;
      turn = (turn + 1) % 3;
    } else if (place == SPMP.center2) {
      didPlace = true;
      player2Cards -= 1;
      turn = (turn + 1) % 3;
    } else if (place == SPMP.center3) {
      didPlace = true;
      player3Cards -= 1;
      turn = (turn + 1) % 3;
    }
    if (didPlace) {
      if (player1Cards == player2Cards && player2Cards == player3Cards) {
        sendMessage({
          'method': SPMP.trickCollected,
          'turn': turn,
          'uid': uid,
        });
      }
    }
    // collecting widow
    if (place == SPMP.player1) {
      player1Cards += 2;
    } else if (place == SPMP.player2) {
      player2Cards += 2;
    } else if (place == SPMP.player3) {
      player3Cards += 2;
    }
    // disposed cards
    if (place == SPMP.disposed) {
      player1Cards = 10;
      player2Cards = 10;
      player3Cards = 10;
    }
    // collected trick
    if (place == SPMP.trick1) {
      player1Tricks += 1;
    } else if (place == SPMP.trick2) {
      player2Tricks += 1;
    } else if (place == SPMP.trick3) {
      player3Tricks += 1;
    }
  }
}

class GameManagement {
  GameManagement(this.cardsController, this.sendMessage);

  final CardsManagement cardsController;
  final void Function(Map<String, dynamic>, [String]) sendMessage;
  Map<String, int> bid;
  String bidderId;
  Map<String, Map<String, dynamic>> players = {};
  int dealer = 0;
  bool isPlaying = false;
  String gameState = SPMP.notStarted;

  bool placeBid(int num, int suit, String uid) {
    if (bid != null) {
      if (bid['suit'] > suit && bid['rank'] > num) {
        bid = {'suit': suit, 'rank': num};
        bidderId = uid;
        players.forEach((key, value) {
          if (key == uid) {
            players[uid]['hasBid'] = true;
          } else {
            players[key]['hasBid'] = false;
          }
        });
        if (players.values.every((element) => element['hasBid'])) {
          gameState = SPMP.playing;
          List<Map<String, dynamic>> widow = cardsController._cards
              .where((element) => element['place'] == SPMP.widow)
              .toList();
          for (var i = 0; i < 2; i++) {
            cardsController.move(widow[i]['rank'], widow[i]['suit'],
                players.keys.toList().indexOf(uid), SPMP.collectWidow);
            sendMessage({'method': SPMP.collectWidow});
          }
        }
        return true;
      }
    }
    return false;
  }

  bool acceptPlay(String uid) {
    players[uid]['isPlaying'] = true;
    if (players.values.every((element) => element['isPlaying'])) {
      isPlaying = true;
      gameState = SPMP.bidding;
    }
    return isPlaying;
  }

  void joinGame(String uid, String nickname) {
    players.putIfAbsent(
        uid, () => {'nickname': nickname, 'isPlaying': false, 'hasBid': false});
  }
}
