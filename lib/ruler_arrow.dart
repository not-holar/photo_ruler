import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';

double angleBetween(Point<double> start, Point<double> end) {
  final relative = start - end;
  return atan2(relative.x, relative.y);
}

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
  final StateController<Line> line;

  bool unfinished;

  Ruler(
    Line _line, {
    this.unfinished = false,
  })  : line = StateController(_line),
        assert(_line != null),
        assert(unfinished != null);
}

/// An object that controls a list of [Ruler].

class RulerList extends StateNotifier<List<Ruler>> {
  RulerList([List<Ruler> initialRulers]) : super(initialRulers ?? []);

  void add(double x1, double y1, double x2, double y2) {
    final unfinished = (x2 == null) || (y2 == null);

    state = [
      ...state,
      Ruler(
        unfinished
            ? Line(Point(x1, y1), Point(x2, y2))
            : Line(Point(x1, y1), Point(x1, y1)),
        unfinished: unfinished,
      )
    ];
  }

  void remove(int index) {
    final newState = state;
    newState.removeAt(index);
    state = newState;
  }
}
