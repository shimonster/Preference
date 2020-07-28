import 'dart:convert';

import 'package:test/test.dart';
import 'package:http/http.dart' as http;

import '../lib/providers/game.dart';
import '../lib/providers/auth.dart';
import '../lib/providers/cards.dart';

void main() async {
  await http.delete('https://preference-1cc9d.firebaseio.com/games.json');
  group('games', () {
    final Auth createAuth = Auth();
    final Game createGame = Game(createAuth);
    test('create', () async {
      await createGame.createGame('player 1');

      expect(
        json.decode((await http
                .get('https://preference-1cc9d.firebaseio.com/games.json'))
            .body),
        {
          createGame.gameId: {
            'players': [
              {'nickname': 'player 1', 'uid': createAuth.uid}
            ]
          }
        },
      );

      expect(createGame.playerNumber, 0);
    });

    test('join', () async {
      final Auth auth = Auth();
      final Game game = Game(auth);
      await game.joinGame(createGame.gameId, 'player 2');

      expect(
        json.decode((await http
                .get('https://preference-1cc9d.firebaseio.com/games.json'))
            .body),
        {
          createGame.gameId: {
            'players': [
              {'nickname': 'player 1', 'uid': createAuth.uid},
              {'nickname': 'player 2', 'uid': auth.uid},
            ]
          }
        },
      );

      expect(game.playerNumber, 1);
    });
  });
}
