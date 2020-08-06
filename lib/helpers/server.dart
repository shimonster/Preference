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

  final cardsController = CardsManagement();
  final gameController = GameManagement();
  Map<String, WebSocket> clientSockets = {};

  void startServer() {
    print('server started');
    HttpServer.bind('localhost', 1234).then(
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

                  if (event['method'] == SPMP.acceptPlay) {
                    if (gameController.acceptPlay(event['uid'])) {
                      final cards = cardsController.randomize();
                      sendMessage(
                          {'method': SPMP.startPlaying, 'cards': cards});
                    }
                  }
                  if (event['method'] == SPMP.bid) {
                    if (gameController.placeBid(
                        event['rank'], event['suit'], event['uid'])) {
                      sendMessage({
                        'method': SPMP.setBid,
                        'rank': event['rank'],
                        'suit': event['suit'],
                        'uid': event['uid'],
                      });
                    }
                  }
                  if (event['method'] == SPMP.place) {}
                },
                onDone: () {
                  print('listening to seb socket finished');
                  clientSockets.remove(uid);
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
    clientSockets.forEach((key, value) {
      if (key != exclude) {
        value.add(message);
      }
    });
  }
}

class CardsManagement {
  List<Map<String, int>> _cards;
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
    return _cards;
  }

  void move(int rank, int suit, int place) {
    _cards.firstWhere((element) =>
        element['rank'] == rank && element['suit'] == suit)['place'] = place;
  }
}

class GameManagement {
  Map<String, int> bid;
  String bidderId;
  Map<String, Map<String, dynamic>> players = {};
  int dealer = 0;
  bool isPlaying = false;

  bool placeBid(int num, int suit, String uid) {
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
      return true;
    }
    return false;
  }

  bool acceptPlay(String uid) {
    players[uid]['isPlaying'] = true;
    if (players.values.every((element) => element['isPlaying'])) {
      isPlaying = true;
    }
    return isPlaying;
  }

  void joinGame(String uid, String nickname) {
    players.putIfAbsent(
        uid, () => {'nickname': nickname, 'isPlaying': false, 'hasBid': false});
  }
}
