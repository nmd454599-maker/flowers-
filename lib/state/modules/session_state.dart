import '../../data/app_repository.dart';
import '../../models/models.dart';
import '../operation_runner.dart';

class SessionState {
  final AppRepository repository;
  final OperationRunner _run;
  final List<AppOrder> orders;
  final Future<void> Function(OperationToken) loadCatalog;
  AppUser? user;
  AuthChallenge? authChallenge;
  SessionState(
      {required this.repository,
      required OperationRunner run,
      required this.loadCatalog,
      required this.orders})
      : _run = run;
  Future<void> requestOtp(String phone) async {
    await _run((token) async {
      authChallenge = await token.wait(repository.requestOtp(phone));
    });
  }

  Future<void> verifyOtp(String phone, String code, UserRole role) async {
    final challenge = authChallenge;
    if (challenge == null) throw StateError('اطلب رمز التحقق أولًا');
    await _run((token) async {
      user = await token.wait(repository.verifyOtp(
        challenge: challenge,
        code: code,
        phone: phone,
        role: role,
      ));
      final signedIn = user!;
      await loadCatalog(token);
      if (signedIn.role == UserRole.customer) {
        orders
          ..clear()
          ..addAll(await token
              .wait(repository.fetchOrders(customerId: signedIn.id)));
      } else if (signedIn.role == UserRole.store) {
        orders
          ..clear()
          ..addAll(await token
              .wait(repository.fetchOrders(storeId: signedIn.storeId)));
      }
    });
  }

  Future<void> signOut() async {
    await repository.signOut();
    authChallenge = null;
    user = null;
  }
}
