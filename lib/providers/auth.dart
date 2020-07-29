import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Auth extends ChangeNotifier {
  String uid;
  String token;
  Timer timer;
  static const _apiKey = 'AIzaSyDpQioFovwZvuPZMzlkK6xoJFM1uj5EkAg';

  Future<void> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('token')) {
      token = prefs.getString('token');
    }
  }

  Future<Map> createAccount() async {
    print('start auth');
    http.Response authResponse = await http.post(
      'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$_apiKey',
      body: json.encode({"returnSecureToken": true}),
    );
    print('after sign int');
    Map<String, dynamic> body = json.decode(authResponse.body);
    uid = body['localId'];
    token = body['idToken'];
    print(body['expiresIn']);
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('token', token);
    timer = Timer.periodic(Duration(seconds: int.parse(body['expiresIn']) - 10),
        (_) async {
      print('timer');
      authResponse = await http.post(
        'https://securetoken.googleapis.com/v1/token?key=$_apiKey',
        body: json.encode({
          'grant_type': 'refresh_token',
          'refresh_token': body['refreshToken']
        }),
      );
      body = json.decode(authResponse.body);
      uid = body['localId'];
      token = body['idToken'];
    });
    print('finish auth');
    prefs.setString('token', token);
    return json.decode(authResponse.body);
  }

  Future<void> deleteAccount() async {
    await http.post(
      'https://identitytoolkit.googleapis.com/v1/accounts:delete?key=$_apiKey',
      body: json.encode({'idToken': token}),
    );
    uid = null;
    token = null;
    timer.cancel();
  }
}
