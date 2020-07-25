import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import './screens/preference_screen.dart';
import './widgets/auth_card.dart';
import './screens/auth_screen.dart';
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
        primaryColor: Color.fromRGBO(28, 91, 11, 1),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: ChangeNotifierProvider.value(
        value: Cards(),
        child: AuthScreen(),
      ),
      routes: {
        AuthCard.routeName: (ctx) => AuthCard(),
      },
    );
  }
}
