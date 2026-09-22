import 'dart:convert';
import '../data/app_repository.dart';
import '../data/firebase_repository.dart';
import '../models/models.dart';

class StoreReviewsService {
  final AppRepository repository;
  const StoreReviewsService(this.repository);
  static const scope = 'store_reviews';
  Future<List<AdminRecord>> list(String storeId) async {
    final repo = repository;
    final List<AdminRecord> records;
    if (repo is FirebaseRepository) {
      final snapshot = await repo.firestore
          .collection('stores')
          .doc(storeId)
          .collection('reviews')
          .get();
      records = snapshot.docs
          .map((doc) => AdminRecord(id: doc.id, scope: scope, data: doc.data()))
          .toList();
    } else {
      records = (await repo.fetchAdminRecords(scope))
          .where((r) => r.data['storeId'] == storeId)
          .toList();
    }
    return records
      ..sort((a, b) =>
          '${b.data['createdAt']}'.compareTo('${a.data['createdAt']}'));
  }

  Future<void> save(
      {required AppUser? user,
      required String storeId,
      required int rating,
      required String comment}) async {
    if (user == null ||
        user.role != UserRole.customer ||
        storeId.isEmpty ||
        rating < 1 ||
        rating > 5 ||
        comment.trim().isEmpty ||
        comment.trim().length > 2000) {
      throw StateError('أضف تقييمًا من 1 إلى 5 وتعليقًا لا يتجاوز 2000 حرف');
    }
    final data = <String, Object?>{
      'storeId': storeId,
      'customerId': user.id,
      'customerName': user.name,
      'rating': rating,
      'comment': comment.trim(),
      'createdAt': DateTime.now().toIso8601String()
    };
    final repo = repository;
    if (repo is FirebaseRepository) {
      if (repo.auth.currentUser?.uid != user.id)
        throw StateError('سجّل الدخول مجددًا');
      await repo.firestore
          .collection('stores')
          .doc(storeId)
          .collection('reviews')
          .doc(user.id)
          .set(data);
    } else {
      final id = base64Url.encode(utf8.encode(jsonEncode([storeId, user.id])));
      await repo.saveAdminRecord(scope, id, data);
    }
  }
}
