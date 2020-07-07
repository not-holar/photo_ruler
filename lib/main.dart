import 'dart:math';

import 'package:filepicker_windows/filepicker_windows.dart';
// import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import 'photo.dart';
import 'ruler_arrow.dart';

void main() {
  // if (bool.fromEnvironment('dart.vm.product')) {
  //   debugPrint = (String message, {int wrapWidth}) {};
  // }

  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
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
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<ValueNotifier<Photo>>(
            create: (_) => ValueNotifier(null),
          ),
          ChangeNotifierProvider<ValueNotifier<double>>(
            create: (_) => ValueNotifier(1.0),
          ),
          ChangeNotifierProvider<ValueNotifier<int>>(
            create: (_) => ValueNotifier(null),
          ),
          ChangeNotifierProvider<RulerList>(
            create: (_) => RulerList(),
          ),
        ],
        child: Home(),
      ),
    );
  }
}

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      body: Consumer<ValueNotifier<Photo>>(
        builder: (context, photo, _) {
          final _editorKey = GlobalKey();

          final transformationController = TransformationController();

          if (photo.value == null) {
            return Center(
              child: RaisedButton.icon(
                onPressed: () async {
                  final picker = FilePicker();
                  picker.title = 'Select an image';
                  picker.filterSpecification = {'All Files (*.*)': '*.*'};

                  final file = picker.getFile();

                  if (file == null) return;

                  photo.value = await Photo.fromList(
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
                        aspectRatio: photo.value.size.aspectRatio,
                        child: RulerEditor(
                          key: _editorKey,
                          photo: photo.value,
                          transformationController: transformationController,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Material(
              color: Theme.of(context).canvasColor,
              elevation: 20,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                child: Builder(builder: (context) {
                  return Row(children: [
                    IconButton(
                      onPressed: () {
                        final rulers = context.read<RulerList>();
                        // TODO
                      },
                      icon: const Icon(Icons.delete_outline),
                    )
                  ]);
                }),
              ),
            ),
          ]);
        },
      ),
    );
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
            if (controller.currentlyPlacingRuler == true) return;
            controller.currentlyPlacingRuler = true;
            final position = controller.cursorPosition;
            rulerBeingPlaced = context
                //
                .read<RulerList>()
                .add(Ruler(
                  Line(position, position),
                  unfinished: true,
                ));
          },
          onTap: () {
            if (controller.currentlyPlacingRuler == true) {
              controller.currentlyPlacingRuler = false;
              final position = controller.cursorPosition;
              rulerBeingPlaced.line.value = Line(
                rulerBeingPlaced.line.value.start,
                position,
              );
              rulerBeingPlaced.unfinished = false;
            } else {
              // TODO deselect arrow
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
        Builder(builder: (context) {
          final scale = context.watch<ValueNotifier<double>>().value;

          return Stack(
            fit: StackFit.expand,
            children: context
                .watch<RulerList>()
                .items
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
      onTap: () => print('yay'), // TODO select arrow
      child: ValueListenableBuilder<Line>(
        valueListenable: ruler.line,
        builder: (context, line, child) {
          return CustomPaint(
            key: ValueKey(ruler),
            painter: ArrowPainter(
              controller: controller,
              line: line,
              scale: scale,
              imageSize: widget.photo.size,
            ),
          );
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

class ArrowPainter extends CustomPainter {
  final EditorController controller;
  final Line line;
  final double scale;
  final Size imageSize;

  ArrowPainter({
    @required this.controller,
    @required this.line,
    @required this.scale,
    @required this.imageSize,
  })  : assert(controller != null),
        assert(line != null),
        assert(scale != null),
        assert(imageSize != null);

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

    canvas
      ..drawPath(
        _hitTestPath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.square
          ..strokeWidth = 2
          ..color = Colors.black87,
      )
      ..drawPath(
        _hitTestPath,
        Paint()
          ..style = PaintingStyle.fill
          ..color = Colors.white70,
      );

    for (final paint in _arrowPaints) {
      canvas
          // ..drawCircle(
          //   Offset(scaledStart.x, scaledStart.y),
          //   0.00001,
          //   paint,
          // )
          // ..drawCircle(
          //   Offset(scaledEnd.x, scaledEnd.y),
          //   0.00001,
          //   paint,
          // ).
          .drawPath(
        Path()
          ..moveTo(scaledStart.x, scaledStart.y)
          ..lineTo(scaledEnd.x, scaledEnd.y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ArrowPainter oldDelegate) =>
      line.start != oldDelegate.line.start ||
      line.end != oldDelegate.line.end ||
      scale != oldDelegate.scale;

  @override
  bool hitTest(Offset position) =>
      !controller.currentlyPlacingRuler &&
      (_hitTestPath != null) &&
      _hitTestPath.contains(position);
}
