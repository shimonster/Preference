import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class Auth extends ChangeNotifier {
  String uid;
  String token;

  Future<Map> createAccount() async {
    final authResponse = await http.post(
      'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=AIzaSyDpQioFovwZvuPZMzlkK6xoJFM1uj5EkAg',
      body: json.encode({"returnSecureToken": true}),
    );
    uid = json.decode(authResponse.body)['localId'];
    token = json.decode(authResponse.body)['idToken'];
    notifyListeners();
    return json.decode(authResponse.body);
  }
}
