import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:azharna_pro/widgets/store_profile_photo.dart';
import 'package:azharna_pro/data/demo_repository.dart';
import 'store_application_persistence_test.dart'
    show ApplicationDatabase, LocalApplicationRepository;

final photoBytes = File('assets/images/catalog/photo_02.png').readAsBytesSync();

class FailingPhotoRepository extends DemoRepository {
  @override
  Future<String> saveStoreProfilePhoto(
      {required String storeId,
      required Uint8List bytes,
      required String fileName}) async {
    throw StateError('offline');
  }
}

void main() {
  test(
      'store photo persists across repository recreation and stays store scoped',
      () async {
    final database = ApplicationDatabase();
    final first = LocalApplicationRepository(database);
    final url = await first.saveStoreProfilePhoto(
        storeId: 'store-1', bytes: photoBytes, fileName: 'photo.png');
    final reopened = LocalApplicationRepository(database);
    expect(await reopened.fetchStoreProfilePhoto('store-1'), url);
    expect(await reopened.fetchStoreProfilePhoto('store-2'), isNull);
  });
  testWidgets('photo requires confirmation and survives widget reopening',
      (tester) async {
    final repository = DemoRepository();
    Widget screen() => MaterialApp(
        home: Scaffold(
            body: StoreProfilePhoto(
                repository: repository,
                storeId: 's1',
                chooseImage: () async =>
                    XFile.fromData(photoBytes, name: 'photo.png'))));
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.text('إضافة صورة المتجر'));
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump(const Duration(milliseconds: 300));
    expect(await repository.fetchStoreProfilePhoto('s1'), isNull);
    await tester.runAsync(() async {
      await tester.tap(find.text('حفظ الصورة'));
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();
    expect(find.text('تم حفظ صورة المتجر'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    expect(find.text('تغيير صورة المتجر'), findsOneWidget);
  });
  testWidgets('failed save never reports success', (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: StoreProfilePhoto(
                repository: FailingPhotoRepository(),
                storeId: 's1',
                chooseImage: () async =>
                    XFile.fromData(photoBytes, name: 'photo.png')))));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.text('إضافة صورة المتجر'));
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump(const Duration(milliseconds: 300));
    await tester.runAsync(() async {
      await tester.tap(find.text('حفظ الصورة'));
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();
    expect(find.text('تم حفظ صورة المتجر'), findsNothing);
    expect(find.textContaining('تعذر حفظ الصورة'), findsOneWidget);
    expect(find.text('إضافة صورة المتجر'), findsOneWidget);
  });
}
