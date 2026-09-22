import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/painting.dart';

Future<String> saveLocalProductImage(Uint8List bytes, String fileName) async =>
    'data:image/${fileName.toLowerCase().endsWith('.png') ? 'png' : 'jpeg'};base64,${base64Encode(bytes)}';
ImageProvider? localProductImage(String source) => null;
