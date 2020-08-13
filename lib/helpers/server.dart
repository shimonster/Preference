import 'dart:io';
import 'dart:convert';
import 'dart:math';

import '../SPMP.dart';

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
        server.listen((request) {
          final uid = request.uri.pathSegments[0];
          final nickname = request.uri.pathSegments[1];
          WebSocketTransformer.upgrade(request).then((ws) {
            print('a client connected to ws');
            clientSockets.putIfAbsent(uid, () => ws);
            print('player joined');
            gameController.joinGame(uid, nickname);
            cardsController.joinGame(uid, nickname);
            sendMessage({
              'method': SPMP.playerJoin,
              'players': gameController.players,
            }, uid);
            if (ws.readyState == WebSocket.open) {
              ws.listen(
                (jsonEvent) {
                  final event =
                      Map<String, dynamic>.from(json.decode(jsonEvent));
                  print(event['method']);

                  if (event['method'] == SPMP.bid ||
                      event['method'] == SPMP.pass) {
                    print('player tried to place bid');
                    gameController.placeBid(
                        event['rank'], event['suit'], event['uid']);
                    sendMessage({
                      'method': event['suit'] == -1 ? SPMP.pass : SPMP.bid,
                      'rank': event['rank'],
                      'suit': event['suit'],
                      'uid': event['uid'],
                      'turn': gameController.biddingId,
                    }, event['uid']);
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
                        'biddingId': gameController.biddingId,
                      });
                    }
                  }
                  if (event['method'] == SPMP.playerJoin) {}
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
          });
        });
      },
      onError: (error) => print('client error contacing web socker: $error'),
    );
  }

  void sendMessage(Map<String, dynamic> message, [String exclude]) {
    print('about to send server message: $message');
    clientSockets.forEach((key, value) {
      if (message['method'] == SPMP.startPlaying) {
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
      if (key != exclude && message['method'] != SPMP.startPlaying) {
        value.add(json.encode(message));
      }
    });
  }
}

class CardsManagement {
  CardsManagement(this.sendMessage);

  final void Function(Map<String, dynamic> message, [String exclude])
      sendMessage;
  List<Map<String, dynamic>> _cards;
  Map<String, Map<String, dynamic>> players = {};
  String turn;
  int player1Cards = 0;
  int player2Cards = 0;
  int player3Cards = 0;
  int player1Tricks = 0;
  int player2Tricks = 0;
  int player3Tricks = 0;

  void joinGame(String uid, String nickname) {
    print('card join game');
    players.putIfAbsent(
        uid, () => {'nickname': nickname, 'isPlaying': false, 'hasBid': false});
  }

  List<Map<String, dynamic>> randomize() {
    List<Map<String, dynamic>> addCard = [];
    for (var i = 0; i < 32; i++) {
      addCard.add({
        'rank': i % 8,
        'suit': (i / 8).floor(),
        'uid': null,
      });
    }
    _cards = addCard;
    _cards.shuffle(Random());
    _cards.asMap().forEach((elemId, element) {
      if (elemId < 30) {
        _cards[elemId]['uid'] = players.keys.toList()[(elemId / 10).floor()];
      } else {
        _cards[elemId]['uid'] = SPMP.widow;
      }
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
      turn =
          players.keys.toList()[(players.keys.toList().indexOf(uid) + 1) % 3];
    } else if (place == SPMP.center2) {
      didPlace = true;
      player2Cards -= 1;
      turn =
          players.keys.toList()[(players.keys.toList().indexOf(uid) + 1) % 3];
    } else if (place == SPMP.center3) {
      didPlace = true;
      player3Cards -= 1;
      turn =
          players.keys.toList()[(players.keys.toList().indexOf(uid) + 1) % 3];
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
  String bidId;
  String biddingId;
  Map<String, Map<String, dynamic>> players = {};
  int dealer = 0;
  bool isPlaying = false;
  String gameState = SPMP.notStarted;

  void placeBid(int num, int suit, String uid) {
    print('place bid was run');
    if (num == -1) {
      print('plater passed');
      players[uid]['hasBid'] = true;
      biddingId =
          players.keys.toList()[(players.keys.toList().indexOf(uid) + 1) % 3];
    } else {
      final pBid = () {
        print('a bid was plaed');
        bid = {'suit': suit, 'rank': num};
        bidId = uid;
        biddingId =
            players.keys.toList()[(players.keys.toList().indexOf(uid) + 1) % 3];
        players.forEach((key, value) {
          if (key == uid) {
            players[uid]['hasBid'] = true;
          } else {
            players[key]['hasBid'] = false;
          }
        });
      };
      if (bid == null) {
        print('no bids so far');
        pBid();
      } else if (bid['suit'] > suit && bid['rank'] > num) {
        print('there was already a bid');
        pBid();
      }
    }
    print(players.values.toList().map((e) => e['hasBid']).toList());
    if (players.values.every((element) => element['hasBid'])) {
      print('every one bid');
      gameState = SPMP.discarding;
      List<Map<String, dynamic>> widow = cardsController._cards
          .where((element) => element['uid'] == SPMP.widow)
          .toList();
      for (var i = 0; i < 2; i++) {
        cardsController.move(widow[i]['rank'], widow[i]['suit'],
            players.keys.toList().indexOf(bidId), SPMP.collectWidow);
        sendMessage({'method': SPMP.collectWidow, 'uid': bidId});
      }
    }
  }

  bool acceptPlay(String uid) {
    players[uid]['isPlaying'] = true;
    if (players.values.every((element) => element['isPlaying'])) {
      isPlaying = true;
      gameState = SPMP.bidding;
      biddingId = players.keys.toList().first;
    }
    return isPlaying;
  }

  void joinGame(String uid, String nickname) {
    players.putIfAbsent(
        uid, () => {'nickname': nickname, 'isPlaying': false, 'hasBid': false});
  }
}
