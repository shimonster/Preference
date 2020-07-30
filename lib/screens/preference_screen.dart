// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../providers/cards.dart' as c;
import '../providers/auth.dart';
import '../providers/game.dart';

class PreferenceScreen extends StatefulWidget {
  static const routeName = '/preference';

  @override
  _PreferenceScreenState createState() => _PreferenceScreenState();
}

class _PreferenceScreenState extends State<PreferenceScreen> {
  bool _isPlaying = false;
  bool _showInfo = false;
  bool _isLoading = true;
  bool hasPopped = false;
  StreamSubscription sub;
  @override
  void initState() {
    super.initState();
    Provider.of<Game>(context, listen: false).getCurrentGame().then((_) async {
      await Provider.of<Auth>(context, listen: false).getToken();
    }).then(
      (_) => setState(() {
        _isLoading = false;
      }),
    );
    sub = html.window.onPopState.listen((event) async {
      if (!hasPopped) {
        setState(() {
          _isLoading = true;
        });
        hasPopped = true;
        print('event: ${event.type}');
        await Provider.of<Game>(context, listen: false).leaveGame();
        Navigator.of(context).pushReplacementNamed('/');
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    sub.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<Game>(context, listen: false);
    final cards = game.cards;
    cards.width = html.window.innerHeight.toDouble();
    cards.height = html.window.innerWidth.toDouble();
    final _idController = TextEditingController(text: game.gameId);
    return Scaffold(
      backgroundColor: Color.fromRGBO(28, 91, 11, 1),
      body: Container(
        decoration: BoxDecoration(
          border: Border.all(width: 10),
        ),
        child: StreamBuilder(
            stream: cards.setUpStream()
              ..listen((event) {
                print('from stream: $event');
              }),
            builder: (context, snapshot) {
              print(snapshot.data);
              return _isLoading
                  ? Center(
                      child: CircularProgressIndicator(),
                    )
                  : Stack(
                      fit: StackFit.loose,
                      children: [
                        Text(snapshot.hasData ? snapshot.data : 'none'),
//          if (_isPlaying) ...cards.p2Cards,
//          if (_isPlaying) ...cards.p1Cards,
//          if (_isPlaying) ...cards.p3Cards,
//          if (_isPlaying) ...cards.widows,
//          if (!_isPlaying)
//            RaisedButton(
//              onPressed: () {
//                setState(() {
//                  _isPlaying = true;
//                });
//              },
//              child: Text('start'),
//            ),
//        ]),
                      ],
                    );
            }),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      floatingActionButton: Container(
        margin: EdgeInsets.only(top: 15),
        height: _showInfo ? 50 : 35,
        width: _showInfo ? game.gameId.length * 12.0 + 20 : 35,
        child: MouseRegion(
          onEnter: (_) {
//            setState(() {
//              _showInfo = true;
//            });
            Provider.of<Game>(context, listen: false).cards.changeDealer();
          },
          onExit: (_) {
//            setState(() {
//              _showInfo = false;
//            });
          },
          child: Stack(
            overflow: Overflow.visible,
            clipBehavior: Clip.antiAlias,
            children: [
              Icon(Icons.info_outline),
              if (_showInfo)
                Positioned(
                  top: -5,
                  left: -5,
                  child: Card(
                    child: SizedBox(
                      height: 50,
                      width: game.gameId.length * 12.0,
                      child: TextField(
                        textAlign: TextAlign.center,
                        controller: _idController,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                        ),
                        onChanged: (_) {
                          _idController.text = game.gameId;
                        },
                      ),
                    ),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}
