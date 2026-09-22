import 'dart:typed_data';
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import '../data/app_repository.dart';
import '../data/firebase_repository.dart';
import '../models/models.dart';
import '../models/store_video.dart';
import 'local_video_files.dart' as files;

class StoreMediaService {
  final AppRepository repository;
  const StoreMediaService(this.repository);
  static const maxBytes = 50 * 1024 * 1024;
  static const maxDurationMs = 180000;

  Future<void> requireOwner(AppUser? actor, String storeId) async {
    if (actor == null ||
        actor.role != UserRole.store ||
        actor.storeId != storeId ||
        storeId.isEmpty) {
      throw StateError('إدارة هذا المحتوى متاحة لصاحب المتجر فقط');
    }
    final repo = repository;
    if (repo is FirebaseRepository) {
      final uid = repo.auth.currentUser?.uid;
      if (uid == null || uid != actor.id) {
        throw StateError('سجّل الدخول مجددًا');
      }
      final user =
          (await repo.firestore.collection('users').doc(uid).get()).data();
      if (user?['active'] != true ||
          user?['role'] != 'store' ||
          user?['storeId'] != storeId) {
        throw StateError('لا تملك صلاحية تعديل هذا المتجر');
      }
    }
  }

  Future<List<StoreVideo>> videos(String storeId) async {
    final repo = repository;
    final result = <StoreVideo>[];
    if (repo is FirebaseRepository) {
      final snapshot = await repo.firestore
          .collection('stores')
          .doc(storeId)
          .collection('videos')
          .get();
      for (final doc in snapshot.docs) {
        if (doc.data()['active'] == true) {
          result.add(StoreVideo.fromMap(doc.id, doc.data()));
        }
      }
    } else {
      final records = await repo.fetchAdminRecords('store_videos');
      for (final record in records) {
        if (record.data['storeId'] == storeId &&
            record.data['active'] == true) {
          result.add(StoreVideo.fromMap(
              record.id, Map<String, dynamic>.from(record.data)));
        }
      }
    }
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  Future<StoreVideo> upload(
      {required AppUser? actor,
      required String storeId,
      required String title,
      required Uint8List bytes,
      required String fileName,
      required int durationMs,
      Uint8List? thumbnail,
      void Function(double)? onProgress}) async {
    await requireOwner(actor, storeId);
    final extension = fileName.split('.').last.toLowerCase();
    if (!['mp4', 'mov', 'm4v'].contains(extension) ||
        bytes.length < 12 ||
        String.fromCharCodes(bytes.sublist(4, 8)) != 'ftyp') {
      throw StateError('اختر فيديو MP4 أو MOV صالحًا');
    }
    if (bytes.length > maxBytes ||
        durationMs <= 0 ||
        durationMs > maxDurationMs) {
      throw StateError('الحد الأقصى للمقطع 3 دقائق و50 ميغابايت');
    }
    if (title.trim().isEmpty || title.trim().length > 120) {
      throw StateError('اكتب عنوانًا من 1 إلى 120 حرفًا');
    }
    if (thumbnail != null && thumbnail.length > 150000) {
      throw StateError('الصورة المصغرة كبيرة جدًا');
    }
    final repo = repository;
    final id = repo is FirebaseRepository
        ? repo.firestore
            .collection('stores')
            .doc(storeId)
            .collection('videos')
            .doc()
            .id
        : 'video_${DateTime.now().microsecondsSinceEpoch}';
    String url;
    Reference? remote;
    if (repo is FirebaseRepository) {
      remote =
          FirebaseStorage.instance.ref('store-videos/$storeId/$id.$extension');
      final task = remote.putData(
          bytes,
          SettableMetadata(
              contentType:
                  extension == 'mov' ? 'video/quicktime' : 'video/mp4'));
      final subscription = task.snapshotEvents.listen((snapshot) {
        if (snapshot.totalBytes > 0) {
          onProgress?.call(snapshot.bytesTransferred / snapshot.totalBytes);
        }
      });
      try {
        await task;
      } finally {
        await subscription.cancel();
      }
      url = await remote.getDownloadURL();
    } else {
      url = await files.saveLocalVideo(id, extension, bytes);
      onProgress?.call(1);
    }
    final video = StoreVideo(
        id: id,
        storeId: storeId,
        title: title.trim(),
        url: url,
        durationMs: durationMs,
        extension: extension,
        createdAt: DateTime.now(),
        thumbnail: thumbnail == null ? '' : base64Encode(thumbnail));
    try {
      if (repo is FirebaseRepository) {
        await repo.firestore
            .collection('stores')
            .doc(storeId)
            .collection('videos')
            .doc(id)
            .set(video.toMap());
      } else {
        await repo.saveAdminRecord('store_videos', id, video.toMap());
      }
    } catch (_) {
      try {
        if (remote != null) {
          await remote.delete();
        } else {
          await files.deleteLocalVideo(id, extension);
        }
      } catch (_) {}
      rethrow;
    }
    return video;
  }

  Future<void> delete(AppUser? actor, StoreVideo video) async {
    await requireOwner(actor, video.storeId);
    final owned = await videos(video.storeId);
    if (!owned.any((item) => item.id == video.id && item.extension == video.extension)) {
      throw StateError('المقطع غير موجود في هذا المتجر');
    }
    final repo = repository;
    if (repo is FirebaseRepository) {
      await repo.firestore
          .collection('stores')
          .doc(video.storeId)
          .collection('videos')
          .doc(video.id)
          .delete();
      await FirebaseStorage.instance
          .ref('store-videos/${video.storeId}/${video.id}.${video.extension}')
          .delete();
    } else {
      await repo.saveAdminRecord(
          'store_videos', video.id, {...video.toMap(), 'active': false});
      await files.deleteLocalVideo(video.id, video.extension);
    }
  }

  Future<Map<String, String>> profile(String storeId) async {
    final repo = repository;
    Map<String, dynamic>? data;
    if (repo is FirebaseRepository) {
      data =
          (await repo.firestore.collection('storeProfiles').doc(storeId).get())
              .data();
    } else {
      for (final record
          in await repo.fetchAdminRecords('store_public_profiles')) {
        if (record.id == storeId) data = Map<String, dynamic>.from(record.data);
      }
    }
    return {
      for (final field in ['description', 'address', 'hours', 'phone'])
        field: data?[field] as String? ?? ''
    };
  }

  Future<void> saveProfile(
      AppUser? actor, String storeId, Map<String, String> data) async {
    await requireOwner(actor, storeId);
    final clean = {
      for (final field in ['description', 'address', 'hours', 'phone'])
        field: (data[field] ?? '').trim()
    };
    if (clean.values.any((value) => value.length > 1500)) {
      throw StateError('المعلومات أطول من الحد المسموح');
    }
    final repo = repository;
    if (repo is FirebaseRepository) {
      await repo.firestore.collection('storeProfiles').doc(storeId).set(clean);
    } else {
      await repo.saveAdminRecord('store_public_profiles', storeId, clean);
    }
  }
}
