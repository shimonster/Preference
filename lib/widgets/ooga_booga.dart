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
  Animation<Offset> moveAnim;
  AnimationController moveAnimController;
  bool isInit = false;
  bool shouldDisplay = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('did change dependencies');
    if (!isInit) {
      moveAnimController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 100),
      );
      moveAnim = Tween<Offset>(
        begin: Offset(0, 0),
        end: Offset(0, -1.5),
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
      duration: Duration(milliseconds: 400),
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

      return Center(
        child: Transform(
          origin: Offset(width / 2, height / 2),
          transform: Matrix4.translation(v.Vector3(xMove, yMove, 0))
            ..rotateY(xNum > 0
                ? min(pi / 3, xNum * 2 * c)
                : max(-pi / 3, xNum * 2 * c))
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

//    return Column(
//      children: [
//        SizedBox(
//          height: 20,
//        ),
//        Slider(
//          activeColor: Colors.red,
//          inactiveColor: Colors.blue,
//          max: 100,
//          min: 0,
//          value: boxes,
//          divisions: 100,
//          label: boxes.round().toString(),
////          semanticFormatterCallback: (val) => val.round().toString(),
//          onChanged: (input) {
//            setState(() {
//              boxes = input;
//              heightInterp = List.generate(boxes.round(), (index) {
//                final interp = (index + 1) / boxes;
//                return lerpDouble(
//                    size.height * 0.2, size.height * 0.04, interp);
//              });
//              widthInterp = List.generate(boxes.round(), (index) {
//                final interp = (index + 1) / boxes;
//                return lerpDouble(size.width * 0.2, size.width * 0.04, interp);
//              });
//            });
//          },
//        ),
    return Positioned(
      right: offset,
      top: offset,
      child: Column(
        children: [
          if (shouldDisplay)
            SlideTransition(
              position: moveAnim,
              child: GestureDetector(
                onPanUpdate: updatePosition,
                onPanEnd: reset,
                child: Container(
                  width: widthInterp.first,
                  height: heightInterp.first,
                  child: Stack(
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
            ),
          Switch(
              value: shouldDisplay,
              onChanged: (val) {
                if (!val) {
                  setState(() => shouldDisplay = false);
                  moveAnimController.forward();
                } else {
                  setState(() => shouldDisplay = true);
                  moveAnimController.reverse();
                }
              })
        ],
      ),
    );
//            ],
//          ),
//        ),
//      ],
//    );
  }
}
