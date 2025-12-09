
import 'package:flutter/cupertino.dart';

double width(BuildContext context) {
  return MediaQuery.of(context).size.width;
}

double height(BuildContext context) {
  return MediaQuery.of(context).size.height;
}

class TubeLight {
  final String id;
  final String name;
  String control;
  bool isOn;

  TubeLight({required this.id, required this.name, this.isOn = false, this.control = 'S'});
}
