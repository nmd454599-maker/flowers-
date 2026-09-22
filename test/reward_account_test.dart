import 'package:flutter_test/flutter_test.dart';
import 'package:azharna_pro/domain/accounts/reward_account.dart';
void main(){
 test('earn, tier, redeem and spend preserve lifetime points and cash remainder',(){
  final a=RewardAccount({});a.earn(1500999,'order');
  expect(a.points,1500);expect(a.membership,'ذهبية');
  a.redeem('coupon');expect(a.points,1400);expect(a.lifetime,1500);
  a.credit(5000,'Receipt','admin');
  a.spend(orderId:'next',subtotal:10000,deliveryFee:5000,expectedDiscount:1000,walletAmount:5000,couponId:'coupon');
  expect(a.balance,0);expect(a.coupons,isEmpty);
  expect(()=>a.spend(orderId:'again',subtotal:10000,deliveryFee:5000,expectedDiscount:1000,walletAmount:0,couponId:'coupon'),throwsStateError);
 });
 test('insufficient points, invalid credits and overspending are rejected',(){
  final a=RewardAccount({});expect(()=>a.redeem('coupon'),throwsStateError);
  expect(()=>a.credit(-1,'Reason','admin'),throwsStateError);
  expect(()=>a.spend(orderId:'o',subtotal:10000,deliveryFee:5000,expectedDiscount:0,walletAmount:1),throwsStateError);
  expect(a.points,0);expect(a.balance,0);
 });
 test('tiers use earned points rather than unspent balance',(){
  final a=RewardAccount({});a.earn(499000,'one');expect(a.membership,'أساسية');
  a.earn(1000,'two');expect(a.membership,'فضية');a.redeem('coupon');expect(a.membership,'فضية');
 });
}
