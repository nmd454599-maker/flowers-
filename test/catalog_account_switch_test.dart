import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:azharna_pro/data/demo_repository.dart';
import 'package:azharna_pro/models/models.dart';
import 'package:azharna_pro/services/store_media_service.dart';
import 'package:azharna_pro/state/app_state.dart';
import 'package:azharna_pro/state/operation_runner.dart';

class DelayedCatalogRepository extends DemoRepository {
  final started = Completer<void>();
  final result = Completer<List<Store>>();
  @override
  Future<List<Store>> fetchStores(String city) {
    started.complete();
    return result.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'upload video then switch merchant to customer repeatedly keeps catalog and video available',
      () async {
    final temporary =
        await Directory.systemTemp.createTemp('azharna-account-switch-');
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => temporary.path);
    addTearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      await temporary.delete(recursive: true);
    });
    final repository = DemoRepository();
    final state = AppState(repository: repository);
    addTearDown(state.dispose);
    Future<void> login(String phone, UserRole role) async {
      await state.requestOtp(phone);
      await state.verifyOtp(phone, '1234', role);
    }

    await login('07811234567', UserRole.store);
    final storeId = state.user!.storeId!;
    final stores = state.stores.map((s) => s.id).toSet();
    final products = state.products.map((p) => p.id).toSet();
    expect(stores, isNotEmpty);
    expect(products, isNotEmpty);
    final media = StoreMediaService(repository);
    final video = await media.upload(
        actor: state.user,
        storeId: storeId,
        title: 'فيديو المتجر',
        bytes: Uint8List.fromList(
            [0, 0, 0, 12, 102, 116, 121, 112, 109, 112, 52, 50]),
        fileName: 'clip.mp4',
        durationMs: 1000);
    for (var i = 0; i < 2; i++) {
      await state.logout();
      expect(state.stores, isEmpty);
      expect(state.products, isEmpty);
      await login('07701234567', UserRole.customer);
      expect(state.user!.role, UserRole.customer);
      expect(state.stores.map((s) => s.id).toSet(), stores);
      expect(state.products.map((p) => p.id).toSet(), products);
      expect((await media.videos(storeId)).single.id, video.id);
      expect(await File.fromUri(Uri.parse(video.url)).exists(), isTrue);
      await state.logout();
      await login('07811234567', UserRole.store);
      expect(state.stores, isNotEmpty);
    }
  });

  test(
      'logout cancels a pending login catalog reload without restoring old session data',
      () async {
    final repository = DelayedCatalogRepository();
    final state = AppState(repository: repository);
    addTearDown(state.dispose);
    await state.requestOtp('07701234567');
    final login = state.verifyOtp('07701234567', '1234', UserRole.customer);
    final rejected = expectLater(login, throwsA(isA<StaleOperation>()));
    await repository.started.future;
    final logout = state.logout();
    repository.result.complete(await DemoRepository().fetchStores('بغداد'));
    await rejected;
    await logout;
    expect(state.user, isNull);
    expect(state.stores, isEmpty);
    expect(state.products, isEmpty);
    expect(state.busy, isFalse);
  });
}
