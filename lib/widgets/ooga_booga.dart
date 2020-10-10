import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:test/test.dart';

import 'package:vector_math/vector_math_64.dart' as v;

class OogaBooga extends StatefulWidget {
  @override
  _OogaBoogaState createState() => _OogaBoogaState();
}

class _OogaBoogaState extends State<OogaBooga> with TickerProviderStateMixin {
  static const boxes = 10;
  static const double offset = 5;

  double mouseX = 0;
  double mouseY = 0;
  double xNum = 0;
  double yNum = 0;
  double mouseOriginX = 0;
  double mouseOriginY = 0;

  List<double> heightInterp = [];
  List<double> widthInterp = [];
  Animation<double> moveAnim;
  AnimationController moveAnimController;
  bool isInit = false;
  bool shouldDisplay = true;
  bool switchValue = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('did change dependencies');
    if (!isInit) {
      moveAnimController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 100),
      );
      moveAnim = Tween<double>(
        begin: 1,
        end: 0,
      ).animate(moveAnimController);
      isInit = true;
    }

    final size = MediaQuery.of(context).size;
    heightInterp = List.generate(boxes, (index) {
      final interp = (index + 1) / boxes;
      return lerpDouble(size.height * 0.15, size.height * 0.04, interp);
    });
    widthInterp = List.generate(boxes, (index) {
      final interp = (index + 1) / boxes;
      return lerpDouble(size.width * 0.15, size.width * 0.04, interp);
    });
    mouseOriginX = size.width - (offset + (widthInterp.first / 2));
    mouseOriginY = (offset + (heightInterp.first / 2));
    mouseX = mouseOriginX;
    mouseY = mouseOriginY;
  }

  @override
  Widget build(BuildContext context) {
    final animController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );
    final size = MediaQuery.of(context).size;

    void updatePosition(DragUpdateDetails details) {
      setState(() {
        mouseX += details.delta.dx;
        mouseY += details.delta.dy;
        xNum = (mouseX - mouseOriginX) / size.width;
        yNum = (mouseY - mouseOriginY) / size.height;
      });
      print('paned $xNum  $mouseX, $yNum  $mouseY');
    }

    void reset(DragEndDetails details) {
      print('pan ended');
      final xAnim = Tween<double>(
        begin: xNum,
        end: 0,
      ).animate(
          CurvedAnimation(curve: Curves.elasticOut, parent: animController));
      final yAnim = Tween<double>(
        begin: yNum,
        end: 0,
      ).animate(
          CurvedAnimation(curve: Curves.elasticOut, parent: animController));

      xAnim.addListener(() => setState(() {
            xNum = xAnim.value;
            mouseX = (xNum * size.width) + mouseOriginX;
          }));
      yAnim.addListener(() => setState(() {
            yNum = yAnim.value;
            mouseY = (yNum * size.height) + mouseOriginY;
          }));

      animController.forward().then((_) {
        yAnim.removeListener(() {});
        xAnim.removeListener(() {});
      });
    }

    Widget rotationContainer(double c, double width, double height) {
      final xMove = c * (mouseX - mouseOriginX) * 0.7;
      final yMove = c * (mouseY - mouseOriginY) * 0.7;
      final int moveAverage =
          ((sqrt(pow(xMove, 2)) + sqrt(pow(yMove, 2))) / 2).round();
      final int red = min(
          255,
          ((moveAverage / 1.5) + 100 - (50 * width / widthInterp.first))
              .round());
      final int green = 0;
      final int blue = max(0, 255 - (moveAverage / 1.5).round());

      return Positioned(
        left: xMove + (widthInterp.first / 2) - (width / 2),
        top: yMove + (heightInterp.first / 2) - (height / 2),
        child: Transform(
          origin: Offset(width / 2, height / 2),
          transform: Matrix4.rotationY(
              xNum > 0 ? min(pi / 3, xNum * 2 * c) : max(-pi / 3, xNum * 2 * c))
            ..rotateX(yNum > 0
                ? -min(pi / 3, yNum * 2 * c)
                : -max(-pi / 3, yNum * 2 * c)),
          child: Container(
            decoration: BoxDecoration(
              color: Color.fromRGBO(red, green, blue, 1),
              borderRadius: BorderRadius.circular(min(width, height) / 4),
            ),
            child: FittedBox(child: FlutterLogo()),
            width: width,
            height: height,
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: moveAnim,
      builder: (ctx, _) => Positioned(
        right: offset,
        top: offset - ((1 - moveAnim.value) * (heightInterp.first)),
        width: widthInterp.first,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            shouldDisplay
                ? Opacity(
                    opacity: moveAnim.value,
                    child: SizedBox(
                      height: heightInterp.first,
                      child: GestureDetector(
                        onPanUpdate: updatePosition,
                        onPanEnd: reset,
                        child: Stack(
                          overflow: Overflow.visible,
                          children: [
                            ...List.generate(boxes, (index) {
                              final c = ((index + 1) / boxes);
                              return rotationContainer(
                                  c, widthInterp[index], heightInterp[index]);
                            }),
                          ],
                        ),
                      ),
                    ),
                  )
                : SizedBox(
                    height: heightInterp.first,
                  ),
            Switch(
              value: switchValue,
              onChanged: (val) async {
                if (!val) {
                  setState(() => switchValue = false);
                  await moveAnimController.forward();
                  setState(() => shouldDisplay = false);
                } else {
                  setState(() {
                    shouldDisplay = true;
                    switchValue = true;
                  });
                  moveAnimController.reverse();
                }
              },
            )
          ],
        ),
      ),
    );
  }
}
