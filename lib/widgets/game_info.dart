import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import '../providers/client.dart';

class GameInfo extends StatefulWidget {
  @override
  _GameInfoState createState() => _GameInfoState();
}

class _GameInfoState extends State<GameInfo> {
  bool _showInfo = false;

  @override
  Widget build(BuildContext context) {
    final client = Provider.of<Client>(context);
    final _idController =
        TextEditingController(text: client.game.gameId.toString());
    return Container(
      margin: EdgeInsets.only(top: 15),
      height: _showInfo ? 50 : 35,
      width: _showInfo ? client.game.gameId.toString().length * 12.0 + 20 : 35,
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
    );
  }
}
