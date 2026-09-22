import 'dart:convert';
import 'dart:async';
import '../data/app_repository.dart';
import '../models/models.dart';
import '../data/firebase_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Direct store/customer conversations in local and connected accounts.
class LocalStoreChat {
  LocalStoreChat(this.repository);
  final AppRepository repository;
  static const scope = 'store_chat_messages';
  static final _changes = Expando<StreamController<void>>();
  StreamController<void> get changes =>
      _changes[repository] ??= StreamController<void>.broadcast();

  static String threadId(String storeId, String customerId) =>
      base64Url.encode(utf8.encode(jsonEncode([storeId, customerId])));

  static bool canRead(Map<String, Object?> data, AppUser user) =>
      data['customerId'] == user.id ||
      (user.role == UserRole.store &&
          (data['ownerId'] == user.id ||
              ((data['ownerId'] == null || data['ownerId'] == '') &&
                  user.storeId != null &&
                  data['storeId'] == user.storeId)));

  Future<List<AdminRecord>> messages(AppUser user) async {
    final repo = repository;
    if (repo is FirebaseRepository) {
      return _records(await _query(repo, user).get());
    }
    final records = await repository.fetchAdminRecords(scope);
    return records
        .where((r) => user.role == UserRole.superAdmin || canRead(r.data, user))
        .toList()
      ..sort((a, b) =>
          '${a.data['createdAt']}'.compareTo('${b.data['createdAt']}'));
  }

  Query<Map<String, dynamic>> _query(FirebaseRepository repo, AppUser user) {
    if (repo.auth.currentUser?.uid != user.id ||
        ![UserRole.customer, UserRole.store].contains(user.role)) {
      throw StateError('يجب تسجيل الدخول');
    }
    return repo.firestore.collection('storeDirectMessages').where(
        user.role == UserRole.store ? 'storeId' : 'customerId',
        isEqualTo:
            user.role == UserRole.store ? user.storeId ?? '__none__' : user.id);
  }

  List<AdminRecord> _records(QuerySnapshot<Map<String, dynamic>> snapshot) =>
      snapshot.docs
          .map((doc) => AdminRecord(id: doc.id, scope: scope, data: doc.data()))
          .toList()
        ..sort((a, b) =>
            '${a.data['createdAt']}'.compareTo('${b.data['createdAt']}'));

  Stream<List<AdminRecord>> watch(AppUser user) {
    final repo = repository;
    if (repo is FirebaseRepository) {
      return _query(repo, user).snapshots().map(_records);
    } else {
      return Stream.multi((events) {
        var cancelled = false;
        Future<void> refresh() async {
          try {
            final records = await messages(user);
            if (!cancelled) events.add(records);
          } catch (error, stack) {
            if (!cancelled) events.addError(error, stack);
          }
        }

        final subscription = changes.stream.listen((_) => refresh());
        refresh();
        events.onCancel = () {
          cancelled = true;
          subscription.cancel();
        };
      });
    }
  }

  Future<void> send(
      {required AppUser user,
      required Map<String, Object?> conversation,
      required String text,
      String? image}) async {
    final body = text.trim().isEmpty && image != null ? 'صورة' : text.trim();
    if (body.isEmpty) return;
    if (body.length > 4000 ||
        !(canRead(conversation, user) ||
            (repository is! FirebaseRepository &&
                user.role == UserRole.superAdmin))) {
      throw StateError('تعذر إرسال الرسالة');
    }
    if (image != null &&
        (image.length > 700000 ||
            !(image.startsWith('data:image/jpeg;base64,') ||
                image.startsWith('data:image/png;base64,') ||
                image.startsWith('https://') ||
                image.startsWith('assets/images/')))) {
      throw StateError('الصورة كبيرة أو غير مدعومة');
    }
    final data = <String, Object?>{
      for (final key in ['storeId', 'storeName', 'customerId', 'customerName'])
        key: conversation[key],
      'threadId': threadId(conversation['storeId'] as String,
          conversation['customerId'] as String),
      'senderId': user.id,
      'text': body,
      if (image != null) 'image': image,
      'createdAt': DateTime.now().toIso8601String(),
    };
    final repo = repository;
    if (repo is FirebaseRepository) {
      if (repo.auth.currentUser?.uid != user.id) {
        throw StateError('يجب تسجيل الدخول');
      }
      await repo.firestore.collection('storeDirectMessages').add(data);
    } else {
      await repo.saveAdminRecord(scope, null, {
        ...data,
        if (conversation.containsKey('ownerId'))
          'ownerId': conversation['ownerId'],
      });
      changes.add(null);
    }
  }
}
