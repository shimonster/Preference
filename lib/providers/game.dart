import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class Game extends ChangeNotifier {
  String gameId;
  String uid;
  bool isDealer;

  Future<void> startGame() async {}
}
