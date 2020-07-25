import 'dart:math';

import 'package:flutter/material.dart';

class AuthCard extends StatefulWidget {
  static const routeName = '/AuthCard';
  @override
  _AuthCardState createState() => _AuthCardState();
}

class _AuthCardState extends State<AuthCard> {
  final controller = ScrollController();
  int currentOption;

  @override
  void initState() {
    super.initState();
    currentOption =
        (controller.offset / MediaQuery.of(context).size.width * 1 / 3).round();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          BottomNavigationBar(
            onTap: (i) => setState(() {
              controller.animateTo(
                  (MediaQuery.of(context).size.width * 1 / 3) * i,
                  duration: Duration(
                    milliseconds: 300,
                  ),
                  curve: Curves.easeOutExpo);
              currentOption = i;
            }),
            currentIndex: currentOption,
            items: [
              BottomNavigationBarItem(
                title: Text('Sign in'),
                icon: Icon(Icons.person),
              ),
              BottomNavigationBarItem(
                title: Text('Create an account'),
                icon: Icon(Icons.person_add),
              ),
              BottomNavigationBarItem(
                title: Text('Play anounomously'),
                icon: Icon(Icons.person_outline),
              ),
            ],
          ),
          SizedBox(
            height: 10,
          ),
          Container(
            width: MediaQuery.of(context).size.width * 1 / 3,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 2 / 3,
            ),
            child: SingleChildScrollView(
              physics: PageScrollPhysics(),
              controller: controller,
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 1 / 3,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Text('sign in'),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 1 / 3,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Text('create acount'),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 1 / 3,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Text('sign up'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
