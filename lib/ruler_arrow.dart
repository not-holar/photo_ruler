import 'dart:collection';
import 'dart:math';

import 'package:flutter/foundation.dart';

class RulerArrow {
  final Point<double> start;
  final Point<double> end;

  final double length;
  final double angle;

  RulerArrow(
    this.start,
    this.end,
  )   : length = start.distanceTo(end),
        angle = angleBetween(start, end);

  @override
  String toString() {
    return 'Ruler Arrow: start$start, end$end';
  }
}

double angleBetween(Point<double> start, Point<double> end) {
  final relative = start - end;
  return atan2(relative.x, relative.y);
}

class RulerList with ChangeNotifier {
  final List<ValueNotifier<RulerArrow>> _items = [];

  UnmodifiableListView<ValueNotifier<RulerArrow>> get items =>
      UnmodifiableListView(_items);

  ValueNotifier<RulerArrow> add(RulerArrow value) {
    final result = ValueNotifier(value);
    _items.add(result);
    notifyListeners();
    return result;
  }

  void remove(int index) {
    _items.removeAt(index);
    notifyListeners();
  }
}
