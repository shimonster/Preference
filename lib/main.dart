import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import './screens/preference_screen.dart';
import './widgets/auth_card.dart';
import './screens/auth_screen.dart';
import './providers/client.dart';
import './screens/waiting_for_others_screen.dart';

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
        ChangeNotifierProvider.value(value: Client()),
      ],
      builder: (ctx, _) {
        return MaterialApp(
          title: 'Preference',
          theme: ThemeData(
            primaryColorDark: Color.fromRGBO(0, 74, 7, 1),
            primaryColor: Color.fromRGBO(28, 91, 11, 1),
            primaryColorLight: Color.fromRGBO(56, 214, 45, 1),
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          home: AuthScreen(),
          routes: {
            AuthCard.routeName: (ctx) => AuthCard(),
            PreferenceScreen.routeName: (ctx) => PreferenceScreen(),
            WaitingForOthersScreen.routeName: (ctx) => WaitingForOthersScreen(),
          },
        );
      },
    );
  }
}
