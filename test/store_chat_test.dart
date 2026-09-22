import 'package:azharna_pro/data/local/database_schema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:azharna_pro/data/demo_repository.dart';
import 'package:azharna_pro/models/models.dart';
import 'package:azharna_pro/services/local_store_chat.dart';
import 'package:azharna_pro/state/app_state.dart';
import 'package:azharna_pro/screens/shared/stores_map_screen.dart';
import 'package:azharna_pro/screens/shared/store_chat_screen.dart';
import 'package:azharna_pro/screens/customer/product_details_screen.dart';
import 'package:azharna_pro/widgets/chat_image.dart';
import 'store_application_persistence_test.dart'
    show LocalApplicationRepository;
import 'support/test_sqlite.dart';

const customer = AppUser(
    id: 'customer-a',
    name: 'عميل الاختبار',
    phone: '',
    role: UserRole.customer);
const merchant = AppUser(
    id: 'merchant-a',
    name: 'التاجر',
    phone: '',
    role: UserRole.store,
    storeId: 's1');
const otherMerchant = AppUser(
    id: 'merchant-b',
    name: 'تاجر آخر',
    phone: '',
    role: UserRole.store,
    storeId: 's1');
const conversation = <String, Object?>{
  'storeId': 'application-a',
  'storeName': 'زهور الاختبار',
  'ownerId': 'merchant-a',
  'customerId': 'customer-a',
  'customerName': 'عميل الاختبار',
};

void main() {
  testWidgets('product photo draft sends and updates the existing customer inbox', (tester) async {
    final repo = DemoRepository();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final state = AppState(repository: repo)..user = customer;
    await state.loadCatalog();
    addTearDown(state.dispose);
    final product = state.products.first;
    final store = state.stores.firstWhere((s) => s.id == product.storeId);
    await tester.pumpWidget(MaterialApp(home: StoreChatInboxScreen(state: state)));
    await tester.pumpAndSettle();
    tester.state<NavigatorState>(find.byType(Navigator)).push(MaterialPageRoute<void>(
        builder: (_) => ProductDetailsScreen(product: product, state: state)));
    await tester.pumpAndSettle();
    await Scrollable.ensureVisible(tester.element(find.text('محادثة المتجر عن المنتج')),
        alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(find.text('محادثة المتجر عن المنتج'));
    await tester.pumpAndSettle();
    expect(find.byType(ChatImage), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        contains(product.name));
    expect(await repo.fetchAdminRecords(LocalStoreChat.scope), isEmpty);
    await tester.tap(find.byTooltip('إرسال الرسالة'));
    await tester.pumpAndSettle();
    final messages = await LocalStoreChat(repo).messages(customer);
    expect(messages, hasLength(1));
    expect(messages.single.data['image'], isNotNull);
    expect(messages.single.data['text'], contains('${product.price}'));
    const clipboard = 'نص للصق';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.getData') return {'text': clipboard};
      return null;
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    expect(find.byTooltip('نسخ النص'), findsNothing);
    expect(find.byType(SelectableText), findsNothing);
    await tester.tap(find.byTooltip('لصق'));
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, clipboard);
    Navigator.of(tester.element(find.byType(StoreChatScreen))).pop();
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(ProductDetailsScreen))).pop();
    await tester.pumpAndSettle();
    expect(find.text(store.name), findsOneWidget);
    await tester.tap(find.text(store.name));
    await tester.pumpAndSettle();
    expect(find.byType(ChatImage), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  test('image-only messages remain private and reject oversized attachments', () async {
    final repo = DemoRepository();
    final chat = LocalStoreChat(repo);
    await chat.send(user: customer, conversation: conversation, text: '',
        image: 'data:image/png;base64,aGVsbG8=');
    expect((await chat.messages(customer)).single.data['image'], isNotNull);
    expect((await chat.messages(merchant)), hasLength(1));
    expect(await chat.messages(otherMerchant), isEmpty);
    await expectLater(chat.send(user: customer, conversation: conversation, text: '',
        image: 'data:image/png;base64,${'a' * 700001}'), throwsStateError);
  });
  test(
      'direct messages persist and reach only the selected merchant and customer',
      () async {
    final db = await TestSqlite.open(':memory:');
    addTearDown(db.close);
    await DatabaseSchema.create(db);
    await LocalStoreChat(LocalApplicationRepository(db)).send(
        user: customer, conversation: conversation, text: 'هل الورد متوفر؟');
    final service = LocalStoreChat(LocalApplicationRepository(db));
    expect((await service.messages(merchant)).single.data['text'],
        'هل الورد متوفر؟');
    expect(await service.messages(otherMerchant), isEmpty);
    await service.send(
        user: merchant, conversation: conversation, text: 'نعم متوفر');
    expect((await service.messages(customer)).map((r) => r.data['text']),
        ['هل الورد متوفر؟', 'نعم متوفر']);
    await expectLater(
        service.send(
            user: otherMerchant,
            conversation: conversation,
            text: 'رسالة غير مسموحة'),
        throwsStateError);
    await service.send(user: customer, conversation: conversation, text: '   ');
    expect(await service.messages(customer), hasLength(2));
  });

  testWidgets(
      'approved map marker opens named direct chat and merchant inbox receives message',
      (tester) async {
    final repository = DemoRepository();
    await repository.saveAdminRecord('store_applications', 'application-a', {
      'ownerId': 'merchant-a',
      'name': 'زهور الاختبار',
      'status': 'approved',
      'latitude': 33.3152,
      'longitude': 44.3661,
      'specialty': 'ورود',
      'address': 'بغداد',
      'phone': '07700000000',
    });
    final state = AppState(repository: repository)..user = customer;
    await tester.pumpWidget(MaterialApp(home: StoresMapScreen(state: state)));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('registered-store-application-a')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الدردشة مع المتجر'));
    await tester.pumpAndSettle();
    expect(find.byType(StoreChatScreen), findsOneWidget);
    expect(find.text('زهور الاختبار'), findsOneWidget);
    expect(await repository.fetchAdminRecords(LocalStoreChat.scope), isEmpty);
    await tester.enterText(find.byType(TextField), 'مرحبا بالمتجر');
    await tester.tap(find.byTooltip('إرسال الرسالة'));
    await tester.pumpAndSettle();
    expect(find.text('مرحبا بالمتجر'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    state.user = merchant;
    await tester
        .pumpWidget(MaterialApp(home: StoreChatInboxScreen(state: state)));
    await tester.pumpAndSettle();
    expect(find.text('عميل الاختبار'), findsOneWidget);
    await tester.tap(find.text('عميل الاختبار'));
    await tester.pumpAndSettle();
    expect(find.text('مرحبا بالمتجر'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });
}
