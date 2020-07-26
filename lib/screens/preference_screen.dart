import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cards.dart';
import '../providers/game.dart';

class PreferenceScreen extends StatefulWidget {
  static const routeName = '/PreferenceScreen';

  @override
  _PreferenceScreenState createState() => _PreferenceScreenState();
}

class _PreferenceScreenState extends State<PreferenceScreen> {
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    Provider.of<Cards>(context, listen: false).randomize();
  }

  @override
  Widget build(BuildContext context) {
    final cards = Provider.of<Cards>(context);
    cards.width = MediaQuery.of(context).size.width;
    cards.height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Color.fromRGBO(28, 91, 11, 1),
      body: Container(
        decoration: BoxDecoration(
          border: Border.all(width: 10),
        ),
        child: Stack(
          fit: StackFit.loose,
          children: [
            Center(
              child: Text(Provider.of<Game>(context).gameId),
            ),
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
        ),
      ),
    );
  }
}
