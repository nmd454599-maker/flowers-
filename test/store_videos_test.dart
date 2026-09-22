import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:azharna_pro/data/demo_repository.dart';
import 'package:azharna_pro/models/models.dart';
import 'package:azharna_pro/models/store_video.dart';
import 'package:azharna_pro/services/store_media_service.dart';
import 'package:azharna_pro/screens/customer/store_reels_screen.dart';
import 'package:azharna_pro/screens/store/store_videos_panel.dart';
import 'package:azharna_pro/state/app_state.dart';
import 'store_application_persistence_test.dart' show ApplicationDatabase, LocalApplicationRepository;

class FakeReelPlatform extends VideoPlayerPlatform {
  int next = 0;
  final streams = <int, StreamController<VideoEvent>>{};
  final playing = <int>{};
  final disposed = <int>{};
  bool fail = false;
  @override Future<void> init() async {}
  @override Future<int?> createWithOptions(VideoCreationOptions options) async {
    final id = next++;
    final stream = streams[id] = StreamController<VideoEvent>();
    if (fail) {
      stream.addError(PlatformException(code: 'invalid-video', message: 'Invalid video'));
    } else {
      stream.add(VideoEvent(eventType: VideoEventType.initialized, size: const Size(240, 426), duration: const Duration(seconds: 10)));
    }
    return id;
  }
  @override Stream<VideoEvent> videoEventsFor(int playerId) => streams[playerId]!.stream;
  @override Future<void> play(int playerId) async { playing.add(playerId); }
  @override Future<void> pause(int playerId) async { playing.remove(playerId); }
  @override Future<void> dispose(int playerId) async { playing.remove(playerId); disposed.add(playerId); }
  @override Future<void> setLooping(int playerId, bool looping) async {}
  @override Future<void> setVolume(int playerId, double volume) async {}
  @override Future<void> setPlaybackSpeed(int playerId, double speed) async {}
  @override Future<void> seekTo(int playerId, Duration position) async {}
  @override Future<Duration> getPosition(int playerId) async => Duration.zero;
  @override Widget buildViewWithOptions(VideoViewOptions options) => ColoredBox(color: Colors.purple, child: Text('video-${options.playerId}'));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const owner = AppUser(id:'owner', name:'Store', phone:'07700000000', role:UserRole.store, storeId:'shop');
  final bytes = Uint8List.fromList([0,0,0,12,102,116,121,112,109,112,52,50]);
  testWidgets('inline video gallery fits a shared scroll and separates management', (tester) async {
    final repo = DemoRepository();
    await repo.saveAdminRecord('store_videos', 'inline-video', StoreVideo(
        id: 'inline-video', storeId: 'shop', title: 'تجهيز الورد',
        url: 'https://example.com/test.mp4', durationMs: 10000,
        createdAt: DateTime(2026)).toMap());
    final state = AppState(repository: repo)..user = owner;
    addTearDown(state.dispose);
    for (final manage in [false, true]) {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: ListView(children: [
        const Text('صور المنتجات'),
        StoreVideosPanel(state: state, storeId: 'shop', storeName: 'Store',
            inline: true, showManagement: manage),
      ]))));
      await tester.pumpAndSettle();
      expect(find.text('تجهيز الورد'), findsOneWidget);
      expect(find.text('إضافة فيديو'), manage ? findsOneWidget : findsNothing);
      expect(find.byTooltip('حذف المقطع'), manage ? findsOneWidget : findsNothing);
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox());
  });
  late Directory temporary;
  setUp(() async {
    temporary = await Directory.systemTemp.createTemp('azharna-video-test-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'), (_) async => temporary.path);
  });
  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/path_provider'), null);
    await temporary.delete(recursive: true);
  });
  test('video and profile persist across reopening, remain scoped, and delete safely', () async {
    final database = ApplicationDatabase();
    final first = StoreMediaService(LocalApplicationRepository(database));
    final video = await first.upload(actor: owner, storeId:'shop', title:'تجهيز باقة', bytes:bytes, fileName:'clip.mp4', durationMs:10000);
    await first.saveProfile(owner, 'shop', {'description':'متجر الورد', 'address':'بغداد'});
    final reopened = StoreMediaService(LocalApplicationRepository(database));
    expect((await reopened.videos('shop')).single.title, 'تجهيز باقة');
    expect(await reopened.videos('another'), isEmpty);
    expect((await reopened.profile('shop'))['description'], 'متجر الورد');
    expect(await File.fromUri(Uri.parse(video.url)).exists(), isTrue);
    await expectLater(reopened.delete(null, video), throwsStateError);
    await reopened.delete(owner, video);
    expect(await reopened.videos('shop'), isEmpty);
    expect(await File.fromUri(Uri.parse(video.url)).exists(), isFalse);
  });
  test('unauthorized owners, invalid formats and excessive durations are rejected', () async {
    final service = StoreMediaService(DemoRepository());
    await expectLater(service.upload(actor:owner, storeId:'another',title:'clip',bytes:bytes,fileName:'clip.mp4',durationMs:1000),throwsStateError);
    await expectLater(service.upload(actor:null, storeId:'shop',title:'clip',bytes:bytes,fileName:'clip.mp4',durationMs:1000),throwsStateError);
    await expectLater(service.upload(actor:owner, storeId:'shop',title:'clip',bytes:bytes,fileName:'clip.txt',durationMs:1000),throwsStateError);
    await expectLater(service.upload(actor:owner, storeId:'shop',title:'clip',bytes:bytes,fileName:'clip.mp4',durationMs:180001),throwsStateError);
  });
  testWidgets('vertical swipes play only the current clip, lifecycle pauses and close disposes', (tester) async {
    final original = VideoPlayerPlatform.instance;
    final platform = FakeReelPlatform();
    VideoPlayerPlatform.instance = platform;
    addTearDown(() => VideoPlayerPlatform.instance = original);
    final videos = [for (var i = 0; i < 3; i++) StoreVideo(id:'$i', storeId:'shop',title:'مقطع $i',url:'https://example.test/$i.mp4',durationMs:10000,createdAt:DateTime(2026))];
    await tester.pumpWidget(MaterialApp(home: StoreReelsScreen(videos:videos,storeName:'متجر')));
    await tester.pumpAndSettle();
    expect(platform.playing, hasLength(1));
    final first = platform.playing.single;
    await tester.drag(find.byKey(const ValueKey('store-reels-pages')), const Offset(0,-600));
    await tester.pumpAndSettle();
    expect(platform.playing, hasLength(1));
    expect(platform.playing, isNot(contains(first)));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(platform.playing, isEmpty);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(platform.playing, hasLength(1));
    await tester.tap(find.byTooltip('إيقاف مؤقت').hitTestable());
    await tester.pump();
    expect(platform.playing, isEmpty);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await tester.runAsync(() async { await Future<void>.delayed(const Duration(milliseconds: 100)); });
    await tester.pump();
    expect(platform.disposed, hasLength(platform.next));
  });
  testWidgets('an invalid video displays retry without playing audio', (tester) async {
    final original = VideoPlayerPlatform.instance;
    final platform = FakeReelPlatform()..fail = true;
    VideoPlayerPlatform.instance = platform;
    addTearDown(() => VideoPlayerPlatform.instance = original);
    await tester.pumpWidget(MaterialApp(home: StoreReelsScreen(storeName:'Store', videos:[
      StoreVideo(id:'bad',storeId:'shop',title:'bad',url:'https://example.test/bad.mp4',durationMs:10000,createdAt:DateTime(2026))])));
    await tester.pumpAndSettle();
    expect(find.text('إعادة المحاولة'), findsOneWidget);
    expect(platform.playing,isEmpty);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
