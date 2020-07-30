import 'dart:math';
import 'dart:ui';

import 'package:filepicker_windows/filepicker_windows.dart';
// import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:number_inc_dec/number_inc_dec.dart';
// import 'package:provider/provider.dart';

import 'photo.dart';
import 'ruler_arrow.dart';

void main() {
  // if (bool.fromEnvironment('dart.vm.product')) {
  //   debugPrint = (String message, {int wrapWidth}) {};
  // }

  runApp(
    ProviderScope(
      child: App(),
    ),
  );
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        splashFactory: InkRipple.splashFactory,
        highlightColor: Colors.transparent,
        brightness: Brightness.dark,
        primarySwatch: Colors.grey,
        backgroundColor: Colors.grey.shade900,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        // canvasColor: const Color(0xff121212),
        canvasColor: Color.lerp(
          Colors.black87,
          Colors.grey.shade900,
          .7,
        ),
      ),
      home: Home(),
    );
  }
}

final photoProvider = StateProvider<Photo>((ref) => null);

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      body: Consumer((context, read) {
        final photo = read(photoProvider).state;

        if (photo == null) {
          return Center(
            child: RaisedButton.icon(
              onPressed: () async {
                final picker = FilePicker();
                picker.title = 'Select an image';
                picker.filterSpecification = {'All Files (*.*)': '*.*'};

                final file = picker.getFile();

                if (file == null) return;

                photoProvider.read(context).state = await Photo.fromList(
                  await file.readAsBytes(),
                );
              },
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 20,
              ),
              icon: const Icon(Icons.photo),
              label: const Text(
                "Open Image",
                textScaleFactor: 1.2,
              ),
            ),
          );
        }

        const padding = EdgeInsets.all(20.0);

        final _editorKey = GlobalKey();

        final transformationController = TransformationController();

        return Column(children: [
          Expanded(
            child: InteractiveViewer(
              maxScale: 100,
              minScale: 0.0001,
              transformationController: transformationController,
              child: Center(
                child: Padding(
                  padding: padding,
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.zero,
                    elevation: 12,
                    child: AspectRatio(
                      aspectRatio: photo.size.aspectRatio,
                      child: RulerEditor(
                        key: _editorKey,
                        photo: photo,
                        transformationController: transformationController,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: const EditorPanel(),
            ),
          ),
        ]);
      }),
    );
  }
}

final rulerListProvider = StateNotifierProvider((ref) => RulerList());
final selectedRulerProvider = StateProvider<int>((ref) => null);

final unselectedProvider = Computed(
  (read) => read(selectedRulerProvider).state == null,
);

final sizingScale = StateProvider((ref) => 1.0);

class EditorPanel extends StatelessWidget {
  const EditorPanel({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).canvasColor,
      elevation: 20,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 32,
          vertical: 12,
        ),
        child: Consumer((context, read) {
          final disabled = read(unselectedProvider);

          return AnimatedOpacity(
            opacity: disabled ? .3 : 1,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeInOut,
            child: IgnorePointer(
              ignoring: disabled,
              child: Row(children: [
                IconButton(
                  onPressed: () {
                    selectedRulerProvider.read(context).state = null;
                  },
                  icon: const Icon(Icons.close),
                ),
                Expanded(
                  child: Consumer((context, read) {
                    if (disabled) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          EditorPointInputPlaceholder(),
                          SizedBox(width: 5),
                          EditorPointInputPlaceholder(),
                          SizedBox(
                            height: 40,
                            child: VerticalDivider(width: 40),
                          ),
                          EditorPointInputPlaceholder(),
                          SizedBox(width: 5),
                          EditorPointInputPlaceholder(),
                        ],
                      );
                    }

                    final rulers = read(rulerListProvider.state);
                    final selectedRuler = read(selectedRulerProvider);

                    return ValueListenableBuilder(
                      valueListenable: rulers[selectedRuler.state].line,
                      builder: (context, Line line, child) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 120,
                              child: EditorPointInput(
                                key: ValueKey(selectedRuler.state),
                                onChange: (value) {
                                  rulers[selectedRuler.state].line.value = Line(
                                    Point(value, line.start.y),
                                    line.end,
                                  );
                                },
                                initialValue: line.start.x,
                              ),
                            ),
                            const SizedBox(width: 5),
                            SizedBox(
                              width: 120,
                              child: EditorPointInput(
                                key: ValueKey(selectedRuler.state),
                                onChange: (value) {
                                  rulers[selectedRuler.state].line.value = Line(
                                    Point(line.start.x, value),
                                    line.end,
                                  );
                                },
                                initialValue: line.start.y,
                              ),
                            ),
                            const SizedBox(
                              height: 40,
                              child: VerticalDivider(width: 40),
                            ),
                            SizedBox(
                              width: 120,
                              child: EditorPointInput(
                                key: ValueKey(selectedRuler.state),
                                onChange: (value) {
                                  rulers[selectedRuler.state].line.value = Line(
                                    line.start,
                                    Point(value, line.end.y),
                                  );
                                },
                                initialValue: line.end.x,
                              ),
                            ),
                            const SizedBox(width: 5),
                            SizedBox(
                              width: 120,
                              child: EditorPointInput(
                                key: ValueKey(selectedRuler.state),
                                onChange: (value) {
                                  rulers[selectedRuler.state].line.value = Line(
                                    line.start,
                                    Point(line.end.x, value),
                                  );
                                },
                                initialValue: line.end.y,
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  }),
                ),
                IconButton(
                  onPressed: () {
                    final sel = selectedRulerProvider.read(context);
                    rulerListProvider.read(context).remove(sel.state);
                    sel.state = null;
                  },
                  icon: const Icon(Icons.delete_outline),
                ),
              ]),
            ),
          );
        }),
      ),
    );
  }
}

class EditorPointInputPlaceholder extends StatelessWidget {
  const EditorPointInputPlaceholder({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black26,
        border: const Border(),
        borderRadius: BorderRadius.circular(10),
      ),
      width: 120,
      height: 40,
    );
  }
}

class EditorPointInput extends StatefulWidget {
  final void Function(double value) onChange;
  final double initialValue;

  const EditorPointInput({
    Key key,
    @required this.onChange,
    @required this.initialValue,
  }) : super(key: key);

  @override
  _EditorPointInputState createState() => _EditorPointInputState();
}

class _EditorPointInputState extends State<EditorPointInput> {
  final TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return NumberInputWithIncrementDecrement(
      controller: controller,
      min: double.negativeInfinity,
      isInt: false,
      widgetContainerDecoration: BoxDecoration(
        color: Colors.black26,
        border: const Border(),
        borderRadius: BorderRadius.circular(10),
      ),
      numberFieldDecoration: const InputDecoration(
        isDense: true,
        border: InputBorder.none,
        fillColor: Colors.black12,
      ),
      incIconDecoration: const BoxDecoration(
        border: Border(
          right: BorderSide(width: 8, color: Colors.transparent),
          top: BorderSide(width: 4, color: Colors.transparent),
        ),
      ),
      decIconDecoration: const BoxDecoration(
        border: Border(
          right: BorderSide(width: 8, color: Colors.transparent),
          bottom: BorderSide(width: 4, color: Colors.transparent),
        ),
      ),
      incIcon: Icons.keyboard_arrow_up,
      decIcon: Icons.keyboard_arrow_down,
      incIconSize: 16,
      decIconSize: 16,
      initialValue: widget.initialValue,
    );
  }

  @override
  void initState() {
    if (widget.onChange != null) {
      controller.addListener(() {
        widget.onChange(double.tryParse(controller.text));
      });
    }

    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

class EditorController {
  /// Cursor position in terms of Photo size
  Point<double> get cursorPosition => Point(
        cursorPositionCanvas.x / renderScale,
        cursorPositionCanvas.y / renderScale,
      );

  /// Cursor position in terms of Canvas size
  Point<double> cursorPositionCanvas = const Point(0, 0);

  /// Scaling from Image size to Canvas size
  double renderScale = 1.0;

  /// Whether the user is currently placing a ruler
  bool currentlyPlacingRuler = false;

  double hitBoxScale = 1.0;
}

class RulerEditor extends StatefulWidget {
  final Photo photo;
  final TransformationController transformationController;

  const RulerEditor({
    Key key,
    this.photo,
    this.transformationController,
  }) : super(key: key);

  @override
  _RulerEditorState createState() => _RulerEditorState();
}

class _RulerEditorState extends State<RulerEditor> {
  final controller = EditorController();

  Ruler rulerBeingPlaced;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.memory(
          widget.photo.bytes,
          filterQuality: FilterQuality.high,
        ),
        GestureDetector(
          onDoubleTap: () {
            if (controller.currentlyPlacingRuler) return;

            controller.currentlyPlacingRuler = true;
            final position = controller.cursorPosition;

            rulerBeingPlaced = rulerListProvider
                .read(context)
                .add(position.x, position.y, null, null);

            selectedRulerProvider.read(context).state =
                rulerListProvider.state.read(context).indexOf(rulerBeingPlaced);
          },
          onTap: () {
            if (controller.currentlyPlacingRuler) {
              controller.currentlyPlacingRuler = false;
              final position = controller.cursorPosition;
              rulerBeingPlaced.line.value = Line(
                rulerBeingPlaced.line.value.start,
                position,
              );
              rulerBeingPlaced.unfinished = false;
            } else {
              selectedRulerProvider.read(context).state = null;
            }
          },
          child: CustomPaint(
            painter: EditorUtilityPainter(
              controller: controller,
              imageSize: widget.photo.size,
              transformationController: widget.transformationController,
            ),
          ),
        ),
        Consumer((context, read) {
          final scale = read(sizingScale).state;

          return Stack(
            fit: StackFit.expand,
            children: read(rulerListProvider.state)
                .asMap()
                .entries
                .map(
                  (arrow) => arrowBuilder(arrow.key, arrow.value, scale),
                )
                .toList(),
          );
        }),
      ],
    );
  }

  Widget arrowBuilder(
    int index,
    Ruler ruler,
    double scale,
  ) {
    return GestureDetector(
      key: ValueKey(ruler),
      onTap: () => selectedRulerProvider.read(context).state = index,
      child: ValueListenableBuilder<Line>(
        valueListenable: ruler.line,
        builder: (context, line, child) {
          return Consumer((context, read) {
            return CustomPaint(
              key: ValueKey(ruler),
              painter: ArrowPainter(
                controller: controller,
                line: line,
                scale: scale,
                imageSize: widget.photo.size,
                selected: read(selectedRulerProvider).state == index,
              ),
            );
          });
        },
      ),
    );
  }
}

/// Rotates a [Point] around (0, 0)
Point<double> rotatePoint(Point<double> point, num radians) {
  return Point(
    point.x * cos(radians) - point.y * sin(radians),
    point.x * sin(radians) + point.y * cos(radians),
  );
}

/// Rotates a [Rect] around (0, 0)
List<Point<double>> rotateRect(Rect rect, num radians) {
  return [rect.topLeft, rect.topRight, rect.bottomRight, rect.bottomLeft]
      .map((point) => Point(point.dx, point.dy))
      .map((point) => rotatePoint(point, radians))
      .toList();
}

Path pathFromPoints(List<Point<double>> points) {
  final path = Path()..moveTo(points[0].x, points[0].y);

  for (final point in points.reversed) {
    path.lineTo(point.x, point.y);
  }

  return path;
}

class EditorUtilityPainter extends CustomPainter {
  final EditorController controller;
  final Size imageSize;
  final TransformationController transformationController;

  EditorUtilityPainter({
    @required this.controller,
    @required this.imageSize,
    @required this.transformationController,
  })  : assert(controller != null),
        assert(imageSize != null);

  @override
  void paint(Canvas canvas, Size size) {
    controller.renderScale = size.width / imageSize.width;
    controller.hitBoxScale = 1 / transformationController.value[0];
  }

  @override
  bool shouldRepaint(ArrowPainter oldDelegate) => false;

  @override
  bool hitTest(Offset position) {
    controller.cursorPositionCanvas = Point(position.dx, position.dy);
    return true;
  }
}

final _arrowPaints = [
  Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4.0
    ..color = Colors.white
    ..strokeCap = StrokeCap.round,
  Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.0
    ..color = Colors.indigo
    ..strokeCap = StrokeCap.round,
];

final _selectedArrowPaints = [
  Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4.0
    ..color = Colors.redAccent
    ..strokeCap = StrokeCap.round,
  Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0
    ..color = Colors.white
    ..strokeCap = StrokeCap.round,
];

class ArrowPainter extends CustomPainter {
  final EditorController controller;
  final Line line;
  final double scale;
  final Size imageSize;
  final bool selected;

  ArrowPainter({
    @required this.controller,
    @required this.line,
    @required this.scale,
    @required this.imageSize,
    @required this.selected,
  })  : assert(controller != null),
        assert(line != null),
        assert(scale != null),
        assert(imageSize != null),
        assert(selected != null);

  Path _hitTestPath;

  @override
  void paint(Canvas canvas, Size size) {
    final renderScale = size.width / imageSize.width;

    final scaledStart = line.start * renderScale;
    final scaledEnd = line.end * renderScale;

    /// Decrease hitbox size as the user zooms in
    /// should be at least as big as the line itself
    final hitBoxOffset = max(8.0 * controller.hitBoxScale, 2.0);

    final rect =
        Rect.fromLTWH(0, 0, 0, line.length * renderScale).inflate(hitBoxOffset);

    _hitTestPath = pathFromPoints(
      rotateRect(rect, -line.angle)
          .map(
            (point) => scaledStart - point,
          )
          .toList(),
    );

    /// Draw hitbox

    // canvas
    //   ..drawPath(
    //     _hitTestPath,
    //     Paint()
    //       ..style = PaintingStyle.stroke
    //       ..strokeCap = StrokeCap.square
    //       ..strokeWidth = 2
    //       ..color = Colors.black87,
    //   )
    //   ..drawPath(
    //     _hitTestPath,
    //     Paint()
    //       ..style = PaintingStyle.fill
    //       ..color = Colors.white70,
    //   );

    final linePath = Path()
      ..moveTo(scaledStart.x, scaledStart.y)
      ..lineTo(scaledEnd.x, scaledEnd.y);

    for (final paint in selected ? _selectedArrowPaints : _arrowPaints) {
      canvas.drawPath(linePath, paint);
    }
  }

  @override
  bool shouldRepaint(ArrowPainter oldDelegate) =>
      line.start != oldDelegate.line.start ||
      line.end != oldDelegate.line.end ||
      scale != oldDelegate.scale ||
      selected != oldDelegate.selected;

  @override
  bool hitTest(Offset position) =>
      !controller.currentlyPlacingRuler &&
      (_hitTestPath != null) &&
      _hitTestPath.contains(position);
}
