import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:azharna_pro/data/demo_repository.dart';
import 'package:azharna_pro/models/models.dart';
import 'package:azharna_pro/screens/customer/checkout_screen.dart';
import 'package:azharna_pro/state/app_state.dart';
void main(){
 testWidgets('coupon and wallet selections reduce the cash amount shown', (tester) async {
  final repo=DemoRepository();
  final state=AppState(repository:repo)..user=const AppUser(id:'customer',name:'Customer',phone:'07701234567',role:UserRole.customer);
  addTearDown(state.dispose);
  state.addToCart(const Product(id:'p',storeId:'s',name:'Rose',category:'Flowers',price:10000,emoji:'',rating:5,description:''));
  await repo.saveAdminRecord('customer_account_benefits','test',{'ownerId':'customer','balance':5000,'coupons':[{'id':'AZ123456789123456789','code':'AZ123456789123456789','value':1000}]});
  await tester.pumpWidget(MaterialApp(home:CheckoutScreen(state:state)));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(find.byKey(const Key('checkout-coupon')),300,scrollable:find.byType(Scrollable).first);
  await tester.tap(find.byKey(const Key('checkout-coupon')));
  await tester.pumpAndSettle();
  await tester.tap(find.textContaining('خصم 1,000 د.ع').last);
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.byKey(const Key('checkout-wallet')));
  await tester.tap(find.byKey(const Key('checkout-wallet')));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(find.text('مراجعة الطلب • 9000 د.ع'),250,scrollable:find.byType(Scrollable).first);
  expect(find.text('مراجعة الطلب • 9000 د.ع'),findsOneWidget);
  expect(tester.takeException(),isNull);
 });
}
