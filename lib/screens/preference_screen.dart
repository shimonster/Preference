import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
            ...cards.p2Cards,
            ...cards.p1Cards,
            ...cards.p3Cards,
            ...cards.widows,
          ],
        ),
      ),
    );
  }
}
