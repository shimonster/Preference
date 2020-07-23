import 'package:flutter/material.dart';
import 'package:preference/helpers/card_move_extention.dart';
import 'package:provider/provider.dart';

import '../widgets/playing_card.dart';
import '../providers/cards.dart';

class PreferenceScreen extends StatefulWidget {
  @override
  _PreferenceScreenState createState() => _PreferenceScreenState();
}

class _PreferenceScreenState extends State<PreferenceScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<Cards>(context, listen: false).randomize();
  }

  @override
  Widget build(BuildContext context) {
    final cards = Provider.of<Cards>(context);
    return Scaffold(
      backgroundColor: Color.fromRGBO(28, 91, 11, 1),
      body: Stack(
        children: [
          Positioned(
            right: 30,
            child: SizedBox(
              width: 700,
              height: 2000,
              child: Stack(children: cards.p2Cards),
            ),
          ),
          Positioned(
            bottom: 30,
            child: SizedBox(
              width: 2000,
              height: 700,
              child: Stack(children: cards.p1Cards),
            ),
          ),
          Positioned(
            right: 30,
            child: SizedBox(
              width: 700,
              height: 2000,
              child: Stack(children: cards.p3Cards),
            ),
          ),
          Positioned(
            top: 30,
            child: SizedBox(
              width: 10000,
              height: 2000,
              child: Stack(children: cards.widows),
            ),
          ),
        ],
      ),
    );
  }
}
