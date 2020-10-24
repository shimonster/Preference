import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../screens/waiting_for_others_screen.dart';
import '../providers/client.dart';

class AuthCard extends StatefulWidget {
  static const routeName = '/AuthCard';
  @override
  _AuthCardState createState() => _AuthCardState();
}

class _AuthCardState extends State<AuthCard> {
  final controller = ScrollController();
  String _nickname;
  int _gameCode;
  var _isLoading = false;
  var _isError = false;

  int currentOption = 0;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width * 1 / 3;

    void showGameDialogue() {
      final client = Provider.of<Client>(context, listen: false);

      showDialog(
          context: context,
          builder: (ctx) {
            final _idController =
                TextEditingController(text: client.game.gameId.toString());
            return AlertDialog(
              title: Center(
                child: Text('This is your game code'),
              ),
              content: TextField(
                textAlign: TextAlign.center,
                controller: _idController,
                decoration: InputDecoration(
                  border: InputBorder.none,
                ),
                onChanged: (_) {
                  _idController.text = client.game.gameId.toString();
                },
              ),
            );
          });
    }

    void authenticate(GlobalKey<FormState> form, bool isCreating) async {
      if (form.currentState.validate()) {
        try {
          form.currentState.save();
          final client = Provider.of<Client>(context, listen: false);
          setState(() {
            _isLoading = true;
          });
          client.init();
          if (isCreating) {
            await client.game.createGame(_nickname);
          } else {
            await client.game.joinGame(_gameCode, _nickname);
          }
          final cards = client.game.cards;
          final size = MediaQuery.of(context).size;
          cards.height = size.height;
          cards.width = size.width;
          print(cards.width);
          print(cards.height);
          setState(() {
            _isLoading = false;
          });
          Navigator.of(context).pop();
          Navigator.of(context)
              .pushReplacementNamed(WaitingForOthersScreen.routeName);
          showGameDialogue();
        } catch (error) {
          setState(() {
            _isLoading = false;
            _isError = true;
          });
          throw error;
        }
      }
    }

    Widget _buildForm(bool isCreating) {
      final form = GlobalKey<FormState>();
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: SizedBox(
          width: width - 16,
          child: Form(
            key: form,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    height: 10,
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Nickname',
                      border: OutlineInputBorder(),
                    ),
                    onSaved: (input) {
                      _nickname = input.trim();
                    },
                    validator: (input) {
                      if (input.isEmpty) {
                        return 'Please enter a nickname';
                      }
                      return null;
                    },
                  ),
                  if (!isCreating)
                    SizedBox(
                      height: 10,
                    ),
                  if (!isCreating)
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Game code',
                        border: OutlineInputBorder(),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onSaved: (input) {
                        _gameCode = int.parse(input.trim());
                      },
                      validator: (input) {
                        if (input.isEmpty) {
                          return 'Please enter a nickname';
                        }
                        return null;
                      },
                    ),
                  SizedBox(
                    height: 10,
                  ),
                  RaisedButton(
                      child: Text('Play'),
                      onPressed: () {
                        authenticate(form, isCreating);
                      }),
                  SizedBox(
                    height: 10,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      child: Column(
        children: [
          if (_isLoading) LinearProgressIndicator(),
          if (!_isLoading)
            SizedBox(
              height: 10,
            ),
          BottomNavigationBar(
            onTap: (i) => setState(() {
              controller.animateTo((width) * i,
                  duration: Duration(
                    milliseconds: 300,
                  ),
                  curve: Curves.easeOutExpo);
            }),
            currentIndex: currentOption,
            type: BottomNavigationBarType.shifting,
            selectedItemColor: Theme.of(context).primaryColor,
            unselectedItemColor: Theme.of(context).primaryColor,
            items: [
              BottomNavigationBarItem(
                label: 'Join game',
                icon: Icon(Icons.input),
              ),
              BottomNavigationBarItem(
                label: 'Create game',
                icon: Icon(Icons.create),
              ),
            ],
          ),
          SizedBox(
            height: 10,
          ),
          if (_isError)
            Text(
              'Error getting into game.',
              style: TextStyle(
                color: Theme.of(context).errorColor,
                fontSize: 20,
              ),
            ),
          Container(
            width: width,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: SingleChildScrollView(
              physics: PageScrollPhysics(),
              controller: controller
                ..addListener(() {
                  setState(() {
                    currentOption = (controller.offset / (width)).round();
                  });
                }),
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildForm(false),
                  _buildForm(true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
