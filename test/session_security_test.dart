import 'package:azharna_pro/data/demo_repository.dart';
import 'package:azharna_pro/models/models.dart';
import 'package:azharna_pro/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';

class SessionRepository extends DemoRepository {
  bool signedOut = false;
  @override
  Future<void> signOut() async { signedOut = true; }
}
void main() {
  test('logout ends backend session and removes private data before another login', () async {
    final repository = SessionRepository();
    final state = AppState(repository: repository);
    state.user = const AppUser(id: 'customer', name: 'Customer', phone: '+9647700000000', role: UserRole.customer);
    state.adminOrders = const [];
    state.addresses.add(const Address(id: 'private', title: 'Work', city: 'Baghdad', details: 'Private address'));
    await state.logout();
    expect(repository.signedOut, isTrue);
    expect(state.isLoggedIn, isFalse);
    expect(state.addresses, isEmpty);
    expect(state.messages, isEmpty);
  });
}
