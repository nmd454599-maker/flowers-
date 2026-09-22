import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:azharna_pro/core/market_theme.dart';
import 'package:azharna_pro/core/color_direction.dart';
import 'package:azharna_pro/data/demo_repository.dart';
import 'package:azharna_pro/models/models.dart';
import 'package:azharna_pro/state/app_state.dart';
import 'package:azharna_pro/services/store_reviews_service.dart';
import 'package:azharna_pro/screens/customer/store_details_screen.dart';
import 'package:azharna_pro/screens/shared/store_chat_screen.dart';
import 'package:azharna_pro/widgets/store_profile_photos.dart';
import 'store_application_persistence_test.dart'
    show ApplicationDatabase, LocalApplicationRepository;

void main() {
  const customer = AppUser(
      id: 'customer',
      name: 'زبون',
      phone: '07700000000',
      role: UserRole.customer);
  test(
      'reviews persist and editing replaces only the same customer/store review',
      () async {
    final db = ApplicationDatabase();
    final service = StoreReviewsService(LocalApplicationRepository(db));
    await service.save(
        user: customer, storeId: 'shop', rating: 4, comment: 'خدمة جميلة');
    await service.save(
        user: customer, storeId: 'other', rating: 2, comment: 'متجر آخر');
    await service.save(
        user: customer, storeId: 'shop', rating: 5, comment: 'تحديث رأيي');
    final reopened = StoreReviewsService(LocalApplicationRepository(db));
    expect((await reopened.list('shop')).single.data['comment'], 'تحديث رأيي');
    expect((await reopened.list('other')).single.data['rating'], 2);
    await expectLater(
        service.save(user: null, storeId: 'shop', rating: 5, comment: 'x'),
        throwsStateError);
    await expectLater(
        service.save(
            user: const AppUser(
                id: 'owner',
                name: 'Owner',
                phone: '',
                role: UserRole.store,
                storeId: 'shop'),
            storeId: 'shop',
            rating: 5,
            comment: 'x'),
        throwsStateError);
    await expectLater(
        service.save(user: customer, storeId: 'shop', rating: 6, comment: 'x'),
        throwsStateError);
  });
  testWidgets(
      'visitor sees photos videos details reviews and store-specific chat without merchant controls',
      (tester) async {
    await (FontLoader('Tajawal')
          ..addFont(rootBundle.load('assets/fonts/Tajawal-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Tajawal-Bold.ttf')))
        .load();
    final state = AppState(repository: DemoRepository());
    await state.loadCatalog();
    state.user = customer;
    addTearDown(state.dispose);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final store = state.stores.first;
    await tester.pumpWidget(MaterialApp(
        theme:
            MarketTheme.apply(ColorDirection.turquoise.theme(Brightness.light)),
        builder: (_, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
        home: StoreDetailsScreen(store: store, state: state)));
    await tester.pumpAndSettle();
    expect(find.text('تعديل المعلومات'), findsNothing);
    await tester.tap(find.text('الصور'));
    await tester.pumpAndSettle();
    expect(find.byType(StoreProfilePhotos), findsOneWidget);
    await tester.tap(find.text('الفيديوهات'));
    await tester.pumpAndSettle();
    expect(find.text('إضافة فيديو'), findsNothing);
    await tester.tap(find.text('التقييمات'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('أضف تقييمك وتعليقك'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'منتجات جميلة');
    await tester.tap(find.text('حفظ التقييم'));
    await tester.pumpAndSettle();
    expect(await StoreReviewsService(state.repository).list(store.id),
        hasLength(1));
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.text('منتجات جميلة'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('منتجات جميلة'), findsOneWidget);
    expect(find.text('تعديل تقييمي وتعليقي'), findsOneWidget);
    await tester.tap(find.text('عن المتجر'));
    await tester.pumpAndSettle();
    expect(find.text('العنوان'), findsOneWidget);
    await tester.tap(find.text('محادثة'));
    await tester.pumpAndSettle();
    final chat = tester.widget<StoreChatScreen>(find.byType(StoreChatScreen));
    expect(chat.conversation['storeId'], store.id);
    expect(chat.conversation['customerId'], customer.id);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
