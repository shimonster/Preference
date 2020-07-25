import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AuthCard extends StatefulWidget {
  static const routeName = '/AuthCard';
  @override
  _AuthCardState createState() => _AuthCardState();
}

class _AuthCardState extends State<AuthCard> {
  final controller = ScrollController();
  String email;
  String password;
  String nickName;

  int currentOption = 0;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width * 1 / 3;

    Widget _buildForm(bool isCreating) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: SizedBox(
          width: width - 16,
          child: Form(
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
                      nickName = input.trim();
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
                        nickName = input.trim();
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
                    onPressed: () {},
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
