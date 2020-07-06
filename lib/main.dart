import 'dart:math';

import 'package:filepicker_windows/filepicker_windows.dart';
import 'package:flutter/gestures.dart';
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
              const Point(.2, .4),
              const Point(.6, .5),
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

// class Home extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     final _controller = PhotoViewController();
//     final _globalKey = GlobalKey();

//     return Scaffold(
//       backgroundColor: Theme.of(context).backgroundColor,
//       body: Consumer<ValueNotifier<Photo>>(
//         builder: (context, photo, _) {
//           if (photo.value == null) {
//             return Center(
//               child: RaisedButton.icon(
//                 onPressed: () async {
//                   final picker = FilePicker();
//                   picker.title = 'Select an image';
//                   picker.filterSpecification = {'All Files (*.*)': '*.*'};

//                   final file = picker.getFile();

//                   if (file == null) return;

//                   photo.value = await Photo.fromList(
//                     await file.readAsBytes(),
//                   );
//                 },
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 32,
//                   vertical: 20,
//                 ),
//                 icon: const Icon(Icons.photo),
//                 label: const Text(
//                   "Open Image",
//                   textScaleFactor: 1.2,
//                 ),
//               ),
//             );
//           }

//           return LayoutBuilder(builder: (context, constraints) {
//             final screenSize = Offset(
//               constraints.maxWidth,
//               constraints.maxHeight,
//             );
//             Offset mousePosition = Offset.zero;

//             return MouseRegion(
//               onHover: (event) {
//                 mousePosition = event.position;
//               },
//               child: Listener(
//                 onPointerSignal: (pointerSignal) async {
//                   if (pointerSignal is PointerScrollEvent) {
//                     final sign = pointerSignal.scrollDelta.dy.sign;
//                     final divisor = 1 + sign / 10;
//                     final newScale = _controller.scale / divisor;
//                     final cursorPosition = -(mousePosition - screenSize / 2);
//                     final newPosition =
//                         (_controller.position + cursorPosition) / divisor -
//                             cursorPosition;

//                     _controller.updateMultiple(
//                       scale: newScale,
//                       position: newPosition,
//                     );
//                   }
//                 },
//                 child: PhotoView.customChild(
//                   key: _globalKey,
//                   childSize: photo.value.size,
//                   backgroundDecoration: const BoxDecoration(
//                     color: Colors.transparent,
//                   ),
//                   controller: _controller,
//                   // childSize: image.value.item2,
//                   child: Center(
//                     child: AspectRatio(
//                       aspectRatio: photo.value.size.aspectRatio,
//                       child: Material(
//                         color: Colors.transparent,
//                         borderRadius: BorderRadius.zero,
//                         elevation: 12,
//                         child: Consumer2<ValueNotifier<double>,
//                             ValueNotifier<List<RulerArrow>>>(
//                           builder: (context, scale, arrows, _) {
//                             return CustomPaint(
//                               size: photo.value.size,
//                               isComplex: true,
//                               willChange: true,
//                               painter: PhotoPainter(
//                                 photo.value,
//                                 arrows.value,
//                                 scale.value,
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             );
//           });
//         },
//       ),
//     );
//   }
// }

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
          return Stack(
            children: context
                .watch<ValueNotifier<List<RulerArrow>>>()
                .value
                .asMap()
                .entries
                .map(
                  arrowBuilder,
                )
                .toList(),
          );
        }),
      ),
    ]);

    // return CustomPaint(
    //   isComplex: true,
    //   willChange: true,
    //   painter: PhotoPainter(
    //     photo: widget.photo,
    //     arrows: Provider.of<ValueNotifier<List<RulerArrow>>>(
    //       context,
    //       listen: false,
    //     ),
    //     scale: Provider.of<ValueNotifier<double>>(
    //       context,
    //       listen: false,
    //     ),
    //   ),
    // );
  }

  Widget arrowBuilder(MapEntry<int, RulerArrow> arrow) {
    final startOffset = Offset(
      arrow.value.start.x,
      arrow.value.start.y,
    );
    final endOffset = Offset(
      arrow.value.end.x,
      arrow.value.end.y,
    );

    final rect = Rect.fromPoints(
      startOffset,
      endOffset,
    );

    return FractionallySizedBox(
      child: AnimatedAlign(
        key: ValueKey(arrow.key),
        alignment: Alignment(rect.left, rect.top),
        duration: const Duration(milliseconds: 250),
        child: const ColoredBox(
          color: Colors.pinkAccent,
          child: SizedBox.expand(),
        ),
      ),
    );
  }
}

class PhotoPainter extends CustomPainter {
  final Photo photo;
  final ValueNotifier<List<RulerArrow>> arrows;
  final ValueNotifier<double> scale;

  PhotoPainter({
    @required this.photo,
    @required this.arrows,
    @required this.scale,
  })  : assert(photo != null),
        assert(arrows != null),
        assert(scale != null),
        super(repaint: Listenable.merge([arrows, scale]));

  @override
  void paint(Canvas canvas, Size size) {
    print(size);

    paintImage(
      canvas: canvas,
      rect: Rect.fromLTWH(0, 0, size.width, size.height),
      image: photo.image,
      filterQuality: FilterQuality.high,
    );

    final arrowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = Colors.indigo;

    for (final arrow in arrows.value) {
      canvas.drawPath(
        Path()
          ..moveTo(arrow.start.x, arrow.start.y)
          ..lineTo(arrow.end.x, arrow.end.y),
        arrowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(PhotoPainter oldDelegate) => true;
}
