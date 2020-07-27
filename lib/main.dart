import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/game.dart';
import './screens/preference_screen.dart';
import './widgets/auth_card.dart';
import './screens/auth_screen.dart';
import './providers/cards.dart';
import './providers/auth.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: Auth(),
        ),
        ChangeNotifierProxyProvider<Auth, Cards>(
          create: (ctx) => Cards([]),
          update: (ctx, auth, prev) => Cards(prev.cards, auth.token, auth.uid),
        ),
        ChangeNotifierProvider(
          create: (ctx) => Game(Provider.of<Auth>(ctx, listen: false)),
        )
      ],
      child: MaterialApp(
        title: 'Preference',
        theme: ThemeData(
          primaryColorDark: Color.fromRGBO(0, 74, 7, 1),
          primaryColor: Color.fromRGBO(28, 91, 11, 1),
          primaryColorLight: Color.fromRGBO(56, 214, 45, 1),
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: Consumer<Game>(
          builder: (ctx, game, _) =>
              game.gameId == null ? AuthScreen() : PreferenceScreen(),
        ),
        routes: {
          AuthCard.routeName: (ctx) => AuthCard(),
          PreferenceScreen.routeName: (ctx) => PreferenceScreen(),
        },
      ),
    );
  }
}
