import 'dart:math';
import 'package:flutter/material.dart';

class MyClipPath extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ClipPath(
        clipper: MyClipper(MediaQuery.of(context).size),
        child: Container(
          color: Colors.green,
        ),
      ),
    );
  }
}

class MyClipper extends CustomClipper<Path> {
  MyClipper(this.containerSize);
  Size containerSize;
  @override
  Path getClip(Size size) {
    var path = Path();

    double x = containerSize.width / 2;
    double y = 0;
    double radian = 0;
    double step =
        min(containerSize.width, containerSize.height / cos(0.1 * pi)) /
            pow(2 * sin(.3 * pi), 2);
    path.moveTo(x, y);
    for (var i = 0; i < 10; i++) {
      if (i == 0) {
        radian = .6 * pi;
        print(50 * 4 * pow(sin(0.3 * pi), 2) * cos(0.1 * pi));
      } else if (i.isEven) {
        radian += 1.2 * pi;
      } else {
        radian += 0.4 * pi;
      }
      x += step * cos(radian);
      y += step * sin(radian);
      path.lineTo(x, y);
    }
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}
