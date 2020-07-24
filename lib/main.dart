import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import './screens/preference_screen.dart';
import './providers/cards.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Preference',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: ChangeNotifierProvider.value(
        value: Cards(),
        child: PreferenceScreen(),
      ),
    );
  }
}
