import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../models/store_video.dart';
import '../../services/local_video_files.dart';

class StoreReelsScreen extends StatefulWidget {
  final List<StoreVideo> videos;
  final int initialIndex;
  final String storeName;
  const StoreReelsScreen(
      {super.key,
      required this.videos,
      required this.storeName,
      this.initialIndex = 0});
  @override
  State<StoreReelsScreen> createState() => _StoreReelsScreenState();
}

class _StoreReelsScreenState extends State<StoreReelsScreen>
    with WidgetsBindingObserver {
  late final PageController pages =
      PageController(initialPage: widget.initialIndex);
  late int selected = widget.initialIndex;
  bool foreground = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (mounted) {
      setState(() => foreground = state == AppLifecycleState.resumed);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        body: Stack(children: [
          if (widget.videos.isEmpty)
            const Center(
                child: Text('لا توجد مقاطع متاحة',
                    style: TextStyle(color: Colors.white)))
          else
            PageView.builder(
              key: const ValueKey('store-reels-pages'),
              controller: pages,
              scrollDirection: Axis.vertical,
              itemCount: widget.videos.length,
              onPageChanged: (value) => setState(() => selected = value),
              itemBuilder: (context, index) => _Reel(
                key: ValueKey(widget.videos[index].id),
                video: widget.videos[index],
                storeName: widget.storeName,
                active: index == selected && foreground,
                load: (index - selected).abs() <= 1,
              ),
            ),
          SafeArea(
              child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(children: [
                    IconButton(
                        tooltip: 'رجوع',
                        onPressed: () => Navigator.pop(context),
                        icon:
                            const Icon(Icons.arrow_back, color: Colors.white)),
                    Expanded(
                        child: Text('فيديوهات ${widget.storeName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700))),
                    if (widget.videos.isNotEmpty)
                      Text('${selected + 1} / ${widget.videos.length}',
                          style: const TextStyle(color: Colors.white70)),
                  ]))),
        ]),
      );
}

class _Reel extends StatefulWidget {
  final StoreVideo video;
  final String storeName;
  final bool active, load;
  const _Reel(
      {super.key,
      required this.video,
      required this.storeName,
      required this.active,
      required this.load});
  @override
  State<_Reel> createState() => _ReelState();
}

class _ReelState extends State<_Reel> {
  VideoPlayerController? controller;
  String? error;
  bool paused = false, muted = false;
  int revision = 0;
  @override
  void initState() {
    super.initState();
    if (widget.load) _initialize();
  }

  @override
  void didUpdateWidget(covariant _Reel old) {
    super.didUpdateWidget(old);
    if (!widget.load) {
      _release();
    } else if (controller == null) {
      _initialize();
    }
    if (!old.active && widget.active) paused = false;
    _sync();
  }

  Future<void> _initialize() async {
    final token = ++revision;
    final player = videoController(widget.video.url);
    controller = player;
    error = null;
    try {
      await player.initialize();
      if (!mounted || token != revision) return;
      await player.setLooping(true);
      if (!mounted || token != revision) return;
      _sync();
      setState(() {});
    } catch (_) {
      if (mounted && token == revision) {
        setState(() =>
            error = 'تعذر تشغيل المقطع. تحقق من الاتصال أو أعد المحاولة.');
      }
    }
  }

  void _sync() {
    final player = controller;
    if (player == null || !player.value.isInitialized) return;
    player.setVolume(muted ? 0 : 1);
    if (widget.active && !paused) {
      player.play();
    } else {
      player.pause();
    }
  }

  void _release() {
    revision++;
    final player = controller;
    controller = null;
    player?.dispose();
  }

  @override
  void dispose() {
    _release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = controller;
    return Stack(fit: StackFit.expand, children: [
      GestureDetector(
        onTap: () {
          setState(() => paused = !paused);
          _sync();
        },
        child: ColoredBox(
            color: Colors.black,
            child: Center(
              child: error != null
                  ? Column(mainAxisSize: MainAxisSize.min, children: [
                      Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white))),
                      TextButton(
                          onPressed: () {
                            _release();
                            _initialize();
                            setState(() {});
                          },
                          child: const Text('إعادة المحاولة',
                              style: TextStyle(color: Colors.white))),
                    ])
                  : player == null || !player.value.isInitialized
                      ? const CircularProgressIndicator(color: Colors.white)
                      : AspectRatio(
                          aspectRatio: player.value.aspectRatio,
                          child: VideoPlayer(player)),
            )),
      ),
      if (paused && error == null)
        const IgnorePointer(
            child: Center(
                child: Icon(Icons.play_circle_outline,
                    size: 72, color: Colors.white70))),
      Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: Container(
          padding: EdgeInsets.fromLTRB(
              18, 50, 18, MediaQuery.paddingOf(context).bottom + 18),
          decoration: const BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xD9000000)])),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  Expanded(
                      child: Text(widget.storeName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700))),
                  IconButton(
                      tooltip: muted ? 'تشغيل الصوت' : 'كتم الصوت',
                      onPressed: () {
                        setState(() => muted = !muted);
                        _sync();
                      },
                      icon: Icon(muted ? Icons.volume_off : Icons.volume_up,
                          color: Colors.white)),
                  IconButton(
                      tooltip: paused ? 'تشغيل' : 'إيقاف مؤقت',
                      onPressed: () {
                        setState(() => paused = !paused);
                        _sync();
                      },
                      icon: Icon(paused ? Icons.play_arrow : Icons.pause,
                          color: Colors.white)),
                ]),
                Text(widget.video.title,
                    style: const TextStyle(color: Colors.white, fontSize: 14)),
                const SizedBox(height: 10),
                if (player != null && player.value.isInitialized)
                  VideoProgressIndicator(player,
                      allowScrubbing: true,
                      colors: const VideoProgressColors(
                          playedColor: Colors.white,
                          bufferedColor: Colors.white38,
                          backgroundColor: Colors.white12)),
                const SizedBox(height: 12),
                const Text('اسحب للأعلى أو للأسفل للتنقل',
                    style: TextStyle(color: Colors.white60, fontSize: 11)),
              ]),
        ),
      ),
    ]);
  }
}
