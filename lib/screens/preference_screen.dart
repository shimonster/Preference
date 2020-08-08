// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import '../providers/cards.dart' as c;
import '../providers/game.dart';
import '../providers/client.dart';

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
  StreamSubscription stream;
  @override
  void initState() {
    super.initState();
    Provider.of<Client>(context, listen: false).game.getCurrentGame().then(
          (_) => setState(() {
            _isLoading = false;
          }),
        );
    sub = html.window.onPopState.listen((event) {
      if (!hasPopped) {
        setState(() {
          _isLoading = true;
        });
        hasPopped = true;
        print('event: ${event.type}');
        Navigator.of(context).pushReplacementNamed('/');
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    sub.cancel();
    stream.cancel();
    Provider.of<Client>(context, listen: false).game.leaveGame();
  }

  @override
  Widget build(BuildContext context) {
    final client = Provider.of<Client>(context, listen: false);
    final cards = client.game.cards;
    cards.width = html.window.innerHeight.toDouble();
    cards.height = html.window.innerWidth.toDouble();
    final _idController =
        TextEditingController(text: client.game.gameId.toString());
    return Scaffold(
      backgroundColor: Color.fromRGBO(28, 91, 11, 1),
      body: Container(
        decoration: BoxDecoration(
          border: Border.all(width: 10),
        ),
        child: StreamBuilder(
          stream: client.socketStream,
          builder: (context, snapshot) {
            return _isLoading
                ? Center(
                    child: CircularProgressIndicator(),
                  )
                : Stack(
                    fit: StackFit.loose,
                    children: [
                      if (_isPlaying) ...cards.p2Cards,
                      if (_isPlaying) ...cards.p1Cards,
                      if (_isPlaying) ...cards.p3Cards,
                      if (_isPlaying) ...cards.widows,
                      if (!_isPlaying)
                        Positioned(
                          bottom: 30,
                          child: RaisedButton(
                            onPressed: () {
                              setState(() {
                                print(cards.cards);
                                client.play();
                                _isPlaying = true;
                                cards.cards.forEach((element) {});
                              });
                            },
                            child: Text('start'),
                          ),
                        ),
                    ],
                  );
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      floatingActionButton: Container(
        margin: EdgeInsets.only(top: 15),
        height: _showInfo ? 50 : 35,
        width:
            _showInfo ? client.game.gameId.toString().length * 12.0 + 20 : 35,
        child: MouseRegion(
          cursor: MouseCursor.defer,
          onEnter: (_) {
            setState(() {
              _showInfo = true;
            });
          },
          onExit: (_) {
            setState(() {
              _showInfo = false;
            });
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
                      width: client.game.gameId.toString().length * 12.0,
                      child: TextField(
                        textAlign: TextAlign.center,
                        controller: _idController,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                        ),
                        onChanged: (_) {
                          _idController.text = client.game.gameId.toString();
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
