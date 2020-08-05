import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/preference_screen.dart';
import '../providers/game.dart';

class AuthCard extends StatefulWidget {
  static const routeName = '/AuthCard';
  @override
  _AuthCardState createState() => _AuthCardState();
}

class _AuthCardState extends State<AuthCard> {
  final controller = ScrollController();
  String _nickname;
  String _gameCode;
  var _isLoading = false;

  int currentOption = 0;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width * 1 / 3;

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
                      onSaved: (input) {
                        _gameCode = input.trim();
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
                    onPressed: () async {
                      if (form.currentState.validate()) {
                        form.currentState.save();
                        final game = Provider.of<Game>(context, listen: false);
                        setState(() {
                          _isLoading = true;
                        });
                        try {
                          if (isCreating) {
//                            await game.createGame(_nickname);
                          } else {
//                            await game.joinGame(_gameCode, _nickname);
                          }
                          setState(() {
                            _isLoading = false;
                          });
                          Navigator.of(context).pop();
                          Navigator.of(context).pushReplacementNamed(
                            PreferenceScreen.routeName,
                          );
                          showDialog(
                              context: context,
                              builder: (ctx) {
                                final _idController =
                                    TextEditingController(text: game.gameId);
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
                                      _idController.text = game.gameId;
                                    },
                                  ),
                                );
                              });
                        } catch (error) {
                          setState(() {
                            _isLoading = false;
                          });
                          throw error;
                        }
                      }
                    },
                  ),
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
                title: Text('Join game'),
                icon: Icon(Icons.input),
              ),
              BottomNavigationBarItem(
                title: Text('Create game'),
                icon: Icon(Icons.create),
              ),
            ],
          ),
          SizedBox(
            height: 10,
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
