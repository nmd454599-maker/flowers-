import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/painting.dart';
import 'package:path_provider/path_provider.dart';

Future<String> saveLocalProductImage(Uint8List bytes, String fileName) async {
  final root = await getApplicationDocumentsDirectory();
  final directory = Directory('${root.path}/product_images');
  await directory.create(recursive: true);
  final extension = fileName.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
  final file = File(
      '${directory.path}/${DateTime.now().microsecondsSinceEpoch}.$extension');
  await file.writeAsBytes(bytes, flush: true);
  return file.uri.toString();
}

ImageProvider? localProductImage(String source) {
  if (!source.startsWith('file:')) return null;
  try {
    return FileImage(File.fromUri(Uri.parse(source)));
  } on FormatException {
    return null;
  } on ArgumentError {
    return null;
  }
}
