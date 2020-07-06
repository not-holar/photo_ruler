// import 'dart:collection';
import 'dart:math';

// import 'package:flutter/cupertino.dart';

class RulerArrow {
  final Point<double> start;
  final Point<double> end;

  final double length;

  RulerArrow(
    this.start,
    this.end,
  ) : length = start.distanceTo(end);
}

// class RulerList with ChangeNotifier {
//   List<RulerArrow> _items = [];

//   UnmodifiableListView<RulerArrow> get items => UnmodifiableListView(_items);
// }
