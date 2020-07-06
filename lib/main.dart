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
        ChangeNotifierProvider<ValueNotifier<List<RulerArrow>>>(
          create: (_) => ValueNotifier([
            RulerArrow(
              const Point(20, 4),
              const Point(600, 500),
            )
          ]),
        ),
      ],
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          brightness: Brightness.dark,
          primarySwatch: Colors.grey,
          backgroundColor: Colors.grey.shade900,
          visualDensity: VisualDensity.adaptivePlatformDensity,
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

          return ConstrainedBox(
            constraints: const BoxConstraints.expand(),
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
          );
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
    return Stack(children: [
      Expanded(
        child: Image.memory(
          widget.photo.bytes,
          filterQuality: FilterQuality.high,
        ),
      ),
      Expanded(
        child: Builder(builder: (context) {
          final scale = context.watch<ValueNotifier<double>>().value;

          return Stack(
            children: context
                .watch<ValueNotifier<List<RulerArrow>>>()
                .value
                .asMap()
                .entries
                .map(
                  (arrow) => arrowBuilder(arrow.key, arrow.value, scale),
                )
                .toList(),
          );
        }),
      ),
    ]);
  }

  Widget arrowBuilder(int index, RulerArrow arrow, double scale) {
    return CustomPaint(
      key: ValueKey(index),
      painter: ArrowPainter(
        arrow: arrow,
        scale: scale,
        imageSize: widget.photo.size,
      ),
    );
  }
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

  final arrowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4.0
    ..color = Colors.indigo;

  @override
  void paint(Canvas canvas, Size size) {
    final renderScale = imageSize.width / size.width;

    canvas.drawPath(
      Path()
        ..moveTo(
          arrow.start.x * renderScale,
          arrow.start.y * renderScale,
        )
        ..lineTo(
          arrow.end.x * renderScale,
          arrow.end.y * renderScale,
        ),
      arrowPaint,
    );
  }

  @override
  bool shouldRepaint(ArrowPainter oldDelegate) =>
      arrow.start != oldDelegate.arrow.start ||
      arrow.end != oldDelegate.arrow.end ||
      scale != oldDelegate.scale;
}
