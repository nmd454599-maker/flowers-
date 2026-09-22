import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import '../../models/store_video.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../services/store_media_service.dart';
import '../../services/local_video_files.dart';
import '../customer/store_reels_screen.dart';

class StoreVideosPanel extends StatefulWidget {
  final AppState state;
  final String storeId, storeName;
  final bool inline, showManagement;
  const StoreVideosPanel(
      {super.key,
      required this.state,
      required this.storeId,
      required this.storeName,
      this.inline = false,
      this.showManagement = true});
  @override
  State<StoreVideosPanel> createState() => _StoreVideosPanelState();
}

class _StoreVideosPanelState extends State<StoreVideosPanel> {
  List<StoreVideo> videos = [];
  bool loading = true, busy = false;
  String? error;
  double progress = 0;
  StoreMediaService get service => StoreMediaService(widget.state.repository);
  bool get owner =>
      widget.state.user?.role == UserRole.store &&
      widget.state.user?.storeId == widget.storeId;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final items = await service.videos(widget.storeId);
      if (mounted) {
        setState(() {
          videos = items;
          error = null;
        });
      }
    } catch (_) {
      if (mounted) setState(() => error = 'تعذر تحميل المقاطع. أعد المحاولة.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> add() async {
    if (busy || !owner) return;
    setState(() {
      busy = true;
      progress = 0;
    });
    VideoPlayerController? preview;
    try {
      final actor = widget.state.user;
      await service.requireOwner(actor, widget.storeId);
      final chosen = await ImagePicker().pickVideo(
          source: ImageSource.gallery, maxDuration: const Duration(minutes: 3));
      if (chosen == null || !mounted) return;
      if (await chosen.length() > StoreMediaService.maxBytes) {
        throw StateError('اختر مقطعًا لا يتجاوز 50 ميغابايت');
      }
      preview = videoController(
          kIsWeb ? chosen.path : Uri.file(chosen.path).toString());
      await preview.initialize();
      final duration = preview.value.duration.inMilliseconds;
      if (duration <= 0 || duration > StoreMediaService.maxDurationMs) {
        throw StateError('الحد الأقصى للمقطع 3 دقائق');
      }
      if (!mounted) return;
      final title = TextEditingController();
      final player = preview;
      final accepted = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
                title: const Text('إضافة فيديو للمتجر'),
                content: SingleChildScrollView(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  SizedBox(
                      height: 180,
                      child: AspectRatio(
                          aspectRatio: player.value.aspectRatio,
                          child: VideoPlayer(player))),
                  const SizedBox(height: 12),
                  TextField(
                      controller: title,
                      maxLength: 120,
                      decoration:
                          const InputDecoration(labelText: 'عنوان المقطع')),
                  const Text('حتى 3 دقائق • 50 ميغابايت',
                      style: TextStyle(fontSize: 11)),
                ])),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('إلغاء')),
                  FilledButton(
                      onPressed: () {
                        if (title.text.trim().isNotEmpty) {
                          Navigator.pop(context, true);
                        }
                      },
                      child: const Text('إضافة المقطع')),
                ],
              ));
      final caption = title.text;
      // The dialog route owns its text field until its closing animation ends.
      await Future<void>.delayed(const Duration(milliseconds: 300));
      title.dispose();
      if (accepted != true || !mounted) return;
      Uint8List? thumbnail;
      if (!kIsWeb) {
        try {
          thumbnail = await const MethodChannel('azharna/store_video')
              .invokeMethod<Uint8List>('thumbnail', {'path': chosen.path});
        } catch (_) {}
        if (thumbnail != null && thumbnail.length > 150000) thumbnail = null;
      }
      await service.upload(
          actor: actor,
          storeId: widget.storeId,
          title: caption,
          bytes: await chosen.readAsBytes(),
          fileName: chosen.name,
          durationMs: duration,
          thumbnail: thumbnail,
          onProgress: (value) {
            if (mounted) setState(() => progress = value);
          });
      await load();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تمت إضافة الفيديو')));
      }
    } catch (exception) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(exception is StateError
                ? exception.message.toString()
                : 'تعذر إضافة المقطع. تحقق من الملف والاتصال وحاول مجددًا.')));
      }
    } finally {
      await preview?.dispose();
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> remove(StoreVideo video) async {
    if (busy) return;
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('حذف الفيديو؟'),
                content: Text(video.title),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('إلغاء')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('حذف')),
                ]));
    if (confirmed != true || !mounted) return;
    setState(() => busy = true);
    try {
      await service.delete(widget.state.user, video);
      await load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تعذر حذف المقطع، حاول مجددًا')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
          mainAxisSize: widget.inline ? MainAxisSize.min : MainAxisSize.max,
          children: [
            if (owner && widget.showManagement)
              Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                          onPressed: busy ? null : add,
                          icon: const Icon(Icons.video_call_outlined),
                          label: Text(
                              busy ? 'جارٍ حفظ الفيديو…' : 'إضافة فيديو')))),
            if (busy)
              LinearProgressIndicator(value: progress > 0 ? progress : null),
            Flexible(
              fit: widget.inline ? FlexFit.loose : FlexFit.tight,
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : error != null
                      ? Center(
                          child:
                              TextButton(onPressed: load, child: Text(error!)))
                      : videos.isEmpty
                          ? Center(
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                  const Icon(Icons.video_library_outlined,
                                      size: 54, color: Colors.grey),
                                  const SizedBox(height: 12),
                                  const Text('لا توجد فيديوهات بعد'),
                                  if (owner && widget.showManagement)
                                    const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: Text(
                                            'أضف مقاطع منتجاتك وتجهيز الطلبات')),
                                ]))
                          : RefreshIndicator(
                              onRefresh: load,
                              child: GridView.builder(
                                shrinkWrap: widget.inline,
                                physics: widget.inline
                                    ? const NeverScrollableScrollPhysics()
                                    : null,
                                padding: const EdgeInsets.all(12),
                                gridDelegate:
                                    const SliverGridDelegateWithMaxCrossAxisExtent(
                                        maxCrossAxisExtent: 180,
                                        childAspectRatio: .65,
                                        mainAxisSpacing: 8,
                                        crossAxisSpacing: 8),
                                itemCount: videos.length,
                                itemBuilder: (context, i) {
                                  final video = videos[i];
                                  return InkWell(
                                    onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => StoreReelsScreen(
                                                videos: videos,
                                                initialIndex: i,
                                                storeName: widget.storeName))),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            const ColoredBox(
                                                color: Color(0xFF302332)),
                                            if (video.thumbnail.isNotEmpty)
                                              Image.memory(
                                                  base64Decode(video.thumbnail),
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) =>
                                                      const Icon(
                                                          Icons
                                                              .videocam_outlined,
                                                          color: Colors.white38,
                                                          size: 50)),
                                            const Center(
                                                child: Icon(
                                                    Icons.play_circle_fill,
                                                    color: Colors.white70,
                                                    size: 40)),
                                            Positioned(
                                                left: 0,
                                                right: 0,
                                                bottom: 0,
                                                child: Container(
                                                    padding:
                                                        const EdgeInsets.all(9),
                                                    color: Colors.black54,
                                                    child: Text(video.title,
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 12)))),
                                            if (owner && widget.showManagement)
                                              PositionedDirectional(
                                                  top: 2,
                                                  end: 2,
                                                  child: IconButton(
                                                      tooltip: 'حذف المقطع',
                                                      onPressed: busy
                                                          ? null
                                                          : () => remove(video),
                                                      icon: const Icon(
                                                          Icons.delete_outline,
                                                          color:
                                                              Colors.white))),
                                          ]),
                                    ),
                                  );
                                },
                              )),
            ),
          ]);
}
