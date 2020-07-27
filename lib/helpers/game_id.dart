import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class GameId extends UniqueKey {
  @override
  toString() {
    return shortHash(this);
  }
}
