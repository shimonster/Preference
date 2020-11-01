import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../widgets/playing_card.dart';
import '../providers/cards.dart' as c;
import '../SPMP.dart';

enum rotation {
  face,
  back,
}

enum angle {
  left,
  up,
  right,
  down,
}

class CardMoveExtension {
  CardMoveExtension(this.cards, this.rank, this.suit);

  bool isFace = false;
  final int rank;
  final int suit;
  final c.Cards cards;
  c.Card get thisCardElement {
    return cards.cards.firstWhere(
        (element) => element.suit.index == suit && element.rank.index == rank);
  }

  // e is for end and s is for start

  Future<void> rotate(rotation sRotation, rotation eRotation, angle sAngle,
      angle eAngle, Duration duration, Axis axis) async {
    print('rotation was run: $sRotation, $eRotation');
    print(thisCardElement);
//    final thisCardIdx = cards.cards.indexOf(thisCardElement);
    final thisCardIdx = cards.cards.indexWhere((element) =>
        element.suit == thisCardElement.suit &&
        element.rank == thisCardElement.rank);
    final crd = cards.cards[thisCardIdx];
    final animationController = AnimationController(
      vsync: PlayingCardState(),
      duration: duration,
    );
    // define animations
    final Animation<double> rotationAnimation = Tween<double>(
            begin: sRotation == rotation.face ? 0 : pi,
            end: eRotation == rotation.face
                ? 2 * pi
                : sRotation == rotation.face
                    ? 0
                    : pi)
        .animate(
      CurvedAnimation(
        curve: Curves.linear,
        parent: animationController,
      ),
    );
    final Animation<double> angleAnimation = Tween<double>(
      begin: sAngle == angle.up
          ? 0
          : sAngle == angle.right
              ? pi * 1 / 2
              : sAngle == angle.down
                  ? pi
                  : pi * 3 / 2,
      end: eAngle == angle.up
          ? 0
          : eAngle == angle.right
              ? pi * 1 / 2
              : eAngle == angle.down
                  ? pi
                  : -pi * 1 / 2,
    ).animate(
      CurvedAnimation(
        curve: Curves.linear,
        parent: animationController,
      ),
    );
    // adds listeners to animations
    if (sAngle != null && eAngle != null) {
      angleAnimation.addListener(() {
        crd.currentRotationZ = angleAnimation.value;
        cards.cards[thisCardIdx].rotationStream.add('rotation');
      });
    }
    print(sRotation == rotation.face ? 0 : pi);
    print(eRotation == rotation.face
        ? 2 * pi
        : sRotation == rotation.face
            ? 0
            : pi);
    if (sRotation != null && eRotation != null) {
      rotationAnimation.addListener(() {
        print('about to add in rotation');
        isFace = rotationAnimation.value < pi * 1 / 2 ||
            rotationAnimation.value > pi * 3 / 2;
        axis == Axis.horizontal
            ? crd.currentRotationX = rotationAnimation.value
            : crd.currentRotationY = rotationAnimation.value;
        print(axis == Axis.horizontal
            ? crd.currentRotationX
            : crd.currentRotationY);
        print(rotationAnimation.value);
        cards.cards[thisCardIdx].rotationStream.add('rotation');
      });
    }
    await animationController.forward().then((value) {
      rotationAnimation.removeListener(() {});
      angleAnimation.removeListener(() {});
    });
  }

  Future<void> move(Duration duration, c.Cards cards,
      {double eBottom,
      double eTop,
      double eRight,
      double eLeft,
      double sBottom,
      double sTop,
      double sRight,
      double sLeft}) async {
    final thisCardIdx = cards.cards.indexWhere(
        (element) => element.suit.index == suit && element.rank.index == rank);
    final crd = cards.cards[thisCardIdx];
    // sets up animation controller and other stuff
    final animController = AnimationController(
      duration: duration,
      vsync: PlayingCardState(),
    );
    Map<int, Animation> anims = {};
    final curRight = sRight ?? crd.right;
    final curLeft = sLeft ?? crd.left;
    final curTop = sTop ?? crd.top;
    final curBottom = sBottom ?? crd.bottom;
    final oldBottom = curBottom;
    final oldRight = curRight;
    print([
      crd.bottom,
      crd.top,
      crd.right,
      crd.left,
      'old:',
      oldBottom,
      oldRight
    ]);
    print([cards.height, cards.width]);
    crd.bottom = eBottom != null
        ? curBottom ??
            cards.height -
                curTop -
                (cards.height * PlayingCard.multiplySizeHeight)
        : null;
    crd.top = eTop != null
        ? curTop ??
            cards.height -
                oldBottom -
                (cards.height * PlayingCard.multiplySizeHeight)
        : null;
    crd.right = eRight != null
        ? curRight ??
            cards.width -
                curLeft -
                (cards.width * PlayingCard.multiplySizeWidth)
        : null;
    crd.left = eLeft != null
        ? curLeft ??
            cards.width -
                oldRight -
                (cards.width * PlayingCard.multiplySizeWidth)
        : null;
    print([
      crd.bottom,
      crd.top,
      crd.right,
      crd.left,
      'old:',
      oldBottom,
      oldRight
    ]);
    final start = [crd.bottom, crd.top, crd.right, crd.left];
    final end = [eBottom, eTop, eRight, eLeft];
    // sets up animations for things that aren't null
    for (var i = 0; i < 4; i++) {
      if (end[i] != null) {
        print(start[i]);
        print(end[i]);
        print('');
        final anim = Tween<double>(
          begin: start[i],
          end: end[i],
        ).animate(
            CurvedAnimation(curve: Curves.easeInOut, parent: animController));
        anims.putIfAbsent(i, () => anim);
      }
    }
    // sets the corresponding side to the new value of the animation every time
    // the animation updates
    void addToStream() {
      print(
          'position closed: ${crd.positionStream.isClosed}, rotation closed: ${crd.rotationStream.isClosed}');
      if (!crd.positionStream.isClosed) crd.positionStream.add('moved');
    }

    anims.forEach((i, anim) {
      anim.addListener(() {
        final value = anims[i].value;
        if (i == 0) {
          crd.bottom = value;
        } else if (i == 1) {
          crd.top = value;
        } else if (i == 2) {
          crd.right = value;
          addToStream();
        } else {
          crd.left = value;
          addToStream();
        }
      });
    });
    print(
        'after adding in move:  ${[crd.bottom, crd.top, crd.right, crd.left]}');
    // runs the animation and waits for it to play before resolving
    await animController.forward().then(
      (value) {
        anims.forEach((i, anim) {
          anim.removeListener(() {});
        });
      },
    );
  }

  Future<void> moveAndTwist(Duration duration, c.Cards cards,
      {double eBottom,
      double eTop,
      double eRight,
      double eLeft,
      rotation sRotation,
      rotation eRotation,
      angle sAngle,
      angle eAngle,
      Axis axis,
      double sBottom,
      double sTop,
      double sRight,
      double sLeft}) async {
    print('move run');
    move(duration, cards,
        eTop: eTop,
        eBottom: eBottom,
        eRight: eRight,
        eLeft: eLeft,
        sBottom: sBottom,
        sTop: sTop,
        sRight: sRight,
        sLeft: sLeft);
    await rotate(sRotation, eRotation, sAngle, eAngle, duration, axis);
    print('after move and twist');
  }

  static Future<void> animateDistribute(c.Cards cards) async {
    final newCards1 = cards.getLocationCards(SPMP.player1);
    final newCards2 = cards.getLocationCards(SPMP.player2);
    final newCards3 = cards.getLocationCards(SPMP.player3);
    final newCardsWidow = cards.getLocationCards(SPMP.widow);
    final allNewCards = [newCards1, newCards2, newCards3, newCardsWidow];
    print(allNewCards);
    for (var i = 0; i < 4; i++) {
      final isP1 = i == 0;
      final isP2 = i == 1;
      final isP3 = i == 2;
      final isWidow = i == 3;
      bool isMine =
          isP1 && cards.client.game.players.keys.contains(cards.client.uid);
      await alignCards(
        allNewCards[i],
        isP1,
        isP2,
        isWidow,
        cards,
        sAngle: isP2 || isP3 ? angle.up : null,
        eAngle: isP2
            ? angle.right
            : isP3
                ? angle.left
                : null,
        sRotation: isMine ? rotation.back : null,
        eRotation: isMine ? rotation.face : null,
      );
    }
  }

  static Future<void> alignCards(List<Map<String, dynamic>> newCards, bool isP1,
      bool isP2, bool isWidow, c.Cards cards,
      {rotation sRotation,
      rotation eRotation,
      angle sAngle,
      angle eAngle,
      Axis axis}) async {
    print('align cards was run');
    final alignCards = cards.cards
        .where((element) =>
            element.place.index ==
            (isP1
                ? SPMP.player1
                : isP2
                    ? SPMP.player2
                    : isWidow
                        ? SPMP.widow
                        : SPMP.player3))
        .toList();
    await Future.forEach(alignCards, (c.Card element) async {
      print(newCards);
      print([element.rank.index, element.suit.index]);
      final newCard = newCards.firstWhere(
          (e) => e['rank'] == element.rank && e['suit'] == element.suit);
      print((element.currentRotationZ / (pi / 2)) + 1);
      final isAlreadyAngle =
          angle.values[((element.currentRotationZ / (pi / 2)) + 1).round()] ==
              eAngle;
      element.cardMoveExtension.moveAndTwist(
        Duration(milliseconds: 400),
        cards,
        eBottom: newCard['bottom'],
        eTop: newCard['top'],
        eRight: newCard['right'],
        eLeft: newCard['left'],
        sAngle: isAlreadyAngle ? null : sAngle,
        eAngle: isAlreadyAngle ? null : eAngle,
        axis: axis,
        sRotation: sRotation,
        eRotation: eRotation,
      );
      await Future.delayed(Duration(milliseconds: 100));
    });
  }
}
