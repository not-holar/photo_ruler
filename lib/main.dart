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
    return MultiProvider(
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
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          brightness: Brightness.dark,
          primarySwatch: Colors.grey,
          backgroundColor: Colors.grey.shade900,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          canvasColor: const Color(0xff121212),
        ),
        home: Home(),
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

class RulerEditor extends StatefulWidget {
  final Photo photo;

  const RulerEditor({Key key, this.photo}) : super(key: key);

  @override
  _RulerEditorState createState() => _RulerEditorState();
}

class _RulerEditorState extends State<RulerEditor> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.memory(
          widget.photo.bytes,
          filterQuality: FilterQuality.high,
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
    ValueNotifier<RulerArrow> arrow,
    double scale,
  ) {
    return GestureDetector(
      key: ValueKey(index),
      onTap: () => print('yay'),
      child: ValueListenableBuilder(
        key: ValueKey(index),
        valueListenable: arrow,
        builder: (context, RulerArrow arrow, _) {
          return CustomPaint(
            key: ValueKey(index),
            painter: ArrowPainter(
              arrow: arrow,
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

class ArrowPainter extends CustomPainter {
  final RulerArrow arrow;
  final double scale;
  final Size imageSize;

  ArrowPainter({
    @required this.arrow,
    @required this.scale,
    @required this.imageSize,
  })  : assert(arrow != null),
        assert(scale != null),
        assert(imageSize != null);

  final _arrowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4.0
    ..color = Colors.indigo;

  Path _hitTestPath;

  @override
  void paint(Canvas canvas, Size size) {
    final renderScale = size.width / imageSize.width;

    final scaledStart = arrow.start * renderScale;
    final scaledEnd = arrow.end * renderScale;

    final rect = Rect.fromLTWH(0, 0, 0, arrow.length * renderScale).inflate(8);

    _hitTestPath = pathFromPoints(
      rotateRect(rect, -arrow.angle)
          .map(
            (point) => scaledStart - point,
          )
          .toList(),
    );

    // Draw hitbox

    // canvas
    //   ..drawPath(
    //     _hitTestPath,
    //     Paint()
    //       ..style = PaintingStyle.fill
    //       ..color = Colors.white70,
    //   )
    //   ..drawPath(
    //     _hitTestPath,
    //     Paint()
    //       ..style = PaintingStyle.stroke
    //       ..strokeWidth = 2
    //       ..color = Colors.black87,
    //   );

    canvas.drawPath(
      Path()
        ..moveTo(scaledStart.x, scaledStart.y)
        ..lineTo(scaledEnd.x, scaledEnd.y),
      _arrowPaint,
    );
  }

  @override
  bool shouldRepaint(ArrowPainter oldDelegate) =>
      arrow.start != oldDelegate.arrow.start ||
      arrow.end != oldDelegate.arrow.end ||
      scale != oldDelegate.scale;

  @override
  bool hitTest(Offset position) =>
      (_hitTestPath != null) && _hitTestPath.contains(position);
}
