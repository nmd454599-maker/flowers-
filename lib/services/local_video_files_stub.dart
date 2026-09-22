import 'dart:typed_data';
import 'package:video_player/video_player.dart';

Future<String> saveLocalVideo(
        String id, String extension, Uint8List bytes) async =>
    throw UnsupportedError('حفظ الفيديو المحلي متاح في تطبيق الهاتف');
Future<void> deleteLocalVideo(String id, String extension) async {}
VideoPlayerController videoController(String url) =>
    VideoPlayerController.networkUrl(Uri.parse(url));
