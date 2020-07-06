import 'dart:typed_data';
import 'dart:ui' as ui show Image;

import 'package:flutter/material.dart';

class Photo {
  final Uint8List bytes;
  final ui.Image image;
  final Size size;

  Photo(
    this.bytes,
    this.image,
    this.size,
  )   : assert(image != null),
        assert(size != null);

  static Future<Photo> fromList(Uint8List bytes) async {
    final decodedImage = await decodeImageFromList(bytes);

    return Photo(
      bytes,
      decodedImage,
      Size(
        decodedImage.width.toDouble(),
        decodedImage.height.toDouble(),
      ),
    );
  }

  @override
  String toString() {
    return 'Photo { $image, $size }';
  }
}
