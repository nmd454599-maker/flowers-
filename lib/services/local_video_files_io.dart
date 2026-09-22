import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

Future<File> _file(String id, String extension) async {
  if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(id) ||
      !['mp4', 'mov', 'm4v'].contains(extension)) {
    throw ArgumentError('معرّف فيديو غير صالح');
  }
  final root = await getApplicationDocumentsDirectory();
  final directory = Directory('${root.path}/store_videos');
  await directory.create(recursive: true);
  return File('${directory.path}/$id.$extension');
}

Future<String> saveLocalVideo(
    String id, String extension, Uint8List bytes) async {
  final file = await _file(id, extension);
  await file.writeAsBytes(bytes, flush: true);
  return file.uri.toString();
}

Future<void> deleteLocalVideo(String id, String extension) async {
  final file = await _file(id, extension);
  if (await file.exists()) await file.delete();
}

VideoPlayerController videoController(String url) {
  final uri = Uri.parse(url);
  return uri.scheme == 'file'
      ? VideoPlayerController.file(File.fromUri(uri))
      : VideoPlayerController.networkUrl(uri);
}
