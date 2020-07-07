import 'dart:collection';
import 'dart:math';

import 'package:flutter/foundation.dart';

class Line {
  final Point<double> start;
  final Point<double> end;

  final double length;
  final double angle;

  Line(
    this.start,
    this.end,
  )   : length = start.distanceTo(end),
        angle = angleBetween(start, end);

  @override
  String toString() {
    return 'Line: start$start, end$end';
  }
}

class Ruler {
  final ValueNotifier<Line> line;

  bool unfinished;

  Ruler(
    Line _line, {
    this.unfinished = false,
  })  : line = ValueNotifier(_line),
        assert(_line != null),
        assert(unfinished != null);
}

double angleBetween(Point<double> start, Point<double> end) {
  final relative = start - end;
  return atan2(relative.x, relative.y);
}

class RulerList with ChangeNotifier {
  final List<Ruler> _items = [];

  UnmodifiableListView<Ruler> get items => UnmodifiableListView(_items);

  Ruler add(Ruler value) {
    final result = value;
    _items.add(result);
    notifyListeners();
    return result;
  }

  void remove(int index) {
    _items.removeAt(index);
    notifyListeners();
  }
}
