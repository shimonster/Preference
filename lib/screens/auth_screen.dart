import 'package:flutter/material.dart';

import '../widgets/auth_card.dart';

class AuthScreen extends StatefulWidget {
  static const routeName = '/AuthScreen';

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Theme.of(context).primaryColor,
        child: Center(
          child: RaisedButton.icon(
            icon: Icon(Icons.style),
            label: Text('Start'),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => /*AuthCard()*/ SimpleDialog(
                  children: [AuthCard()],
                  contentPadding: EdgeInsets.all(0),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
