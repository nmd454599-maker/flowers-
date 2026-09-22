import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../state/app_state.dart';
import '../../widgets/app_components.dart';
import '../auth/welcome_screen.dart';
import '../shared/stores_map_screen.dart';
import 'account_feature_screen.dart';
import 'customer_account_screen.dart';
import 'change_phone_screen.dart';
import 'favorites_screen.dart';
import 'conversations_screen.dart';
import 'notifications_screen.dart';
import 'orders_screen.dart';
import 'cart_screen.dart';
import '../shared/image_library_screen.dart';

class ProfileScreen extends StatelessWidget {
  final AppState state;
  const ProfileScreen({super.key, required this.state});
  void open(BuildContext context, String title) {
    final Widget page = title == 'حذف الحساب'
        ? AccountFeatureScreen(
            title: title,
            icon: Icons.delete_outline,
            items: const [
              ('تنفيذ الحذف', 'بعد اكتمال الطلبات والاستردادات المفتوحة')
            ],
            editable: false,
            onDeleteAccount: state.repository.requestAccountDeletion)
        : title == 'تغيير رقم الهاتف'
            ? ChangePhoneScreen(state: state)
            : CustomerAccountScreen(state: state, title: title);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: state,
      builder: (_, __) {
        Widget entry(IconData icon, String title, String subtitle) =>
            _nav(icon, title, subtitle, () => open(context, title));
        Widget route(
                IconData icon, String title, String subtitle, Widget page) =>
            _nav(
                icon,
                title,
                subtitle,
                () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => page)));
        return Scaffold(
            appBar: AppBar(title: const Text('حسابي'), actions: [
              IconButton(
                  tooltip: 'سلة التسوق',
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => CartScreen(state: state))),
                  icon: Badge(
                      isLabelVisible: state.cartCount > 0,
                      label: Text('${state.cartCount}'),
                      child: Icon(Icons.shopping_bag_outlined,
                          color: Theme.of(context).colorScheme.primary))),
              const ImageLibraryButton(),
              IconButton(
                  tooltip: 'الإعدادات',
                  onPressed: () => open(context, 'الإعدادات'),
                  icon: const Icon(Icons.settings_outlined))
            ]),
            body:
                ListView(padding: const EdgeInsets.only(bottom: 24), children: [
              _Header(state: state, onTap: () => open(context, 'الملف الشخصي')),
              _Section('حسابي وعضويتي', [
                entry(Icons.workspace_premium_outlined, 'مستوى العضوية',
                    'بيانات عضويتك'),
                entry(Icons.confirmation_number_outlined, 'النقاط والكوبونات',
                    'النقاط والقسائم المسجلة'),
                entry(Icons.account_balance_wallet_outlined, 'المحفظة',
                    'الرصيد وسجل العمليات'),
              ]),
              _Section('الطلبات والهدايا', [
                route(
                    Icons.shopping_bag_outlined,
                    'سلة التسوق',
                    state.cartCount == 0
                        ? 'تصفح سلتك وأضف هداياك'
                        : '${state.cartCount} منتجات في السلة',
                    CartScreen(state: state)),
                route(Icons.receipt_long_outlined, 'طلباتي',
                    'الحالية والسابقة والملغاة', OrdersScreen(state: state)),
                entry(Icons.card_giftcard_rounded, 'سجل الهدايا',
                    'طلباتك وتفاصيل الإهداء'),
                entry(Icons.people_outline_rounded, 'الأشخاص المحفوظون',
                    'المستلمون وتفضيلاتهم'),
                entry(Icons.event_outlined, 'دفتر المناسبات',
                    'احفظ تواريخ مناسباتك'),
              ]),
              _Section('العناوين والدفع', [
                entry(Icons.location_on_outlined, 'عناويني',
                    'إضافة وتعديل العنوان الافتراضي'),
                entry(Icons.credit_card_rounded, 'طرق الدفع',
                    'نقدًا عند الاستلام'),
              ]),
              _Section('التفضيلات', [
                const ListTile(
                    title: Text('مظهر التطبيق'), trailing: ThemeModeButton()),
                route(
                    Icons.favorite_border_rounded,
                    'المفضلة',
                    '${state.favorites.length} منتجات محفوظة',
                    FavoritesScreen(state: state)),
                route(Icons.map_outlined, 'الخريطة', 'استكشف المتاجر القريبة',
                    StoresMapScreen(state: state)),
                route(Icons.chat_outlined, 'المحادثات', 'تواصل مع المتاجر',
                    ConversationsScreen(state: state)),
                entry(Icons.visibility_off_outlined, 'خصوصية الهدية',
                    'كيفية مشاركة معلومات الإهداء'),
                route(Icons.notifications_none_rounded, 'الإشعارات',
                    'إشعارات التطبيق', NotificationsScreen(state: state)),
                entry(Icons.language_rounded, 'اللغة والعملة',
                    'العربية • الدينار العراقي'),
              ]),
              _Section('الأمان والخصوصية', [
                entry(Icons.phonelink_lock_outlined, 'الأجهزة والجلسات',
                    'إدارة الجلسة الحالية'),
                entry(Icons.phone_iphone_rounded, 'تغيير رقم الهاتف',
                    'يتطلب رمز تحقق'),
                entry(Icons.privacy_tip_outlined, 'الخصوصية والإشعارات',
                    'إعدادات إشعارات الجهاز'),
              ]),
              _Section('المشاركة والدعم', [
                entry(Icons.star_outline_rounded, 'تقييماتي',
                    'قيّم متاجر طلباتك'),
                entry(Icons.group_add_outlined, 'دعوة الأصدقاء',
                    'شارك التطبيق مع أصدقائك'),
                entry(Icons.support_agent_rounded, 'المساعدة والشكاوى',
                    'أرسل طلبًا وتابع الرد'),
                entry(Icons.rate_review_outlined, 'الشروط ومعلومات التطبيق',
                    'عن التطبيق وسياساته'),
              ]),
              _Section('حسابات الأعمال', [
                entry(Icons.storefront_outlined, 'حوّل إلى حساب متجر',
                    'تقديم طلب انضمام للإدارة'),
                entry(Icons.delivery_dining_outlined, 'سجّل كمندوب',
                    'تقديم طلب للعمل بالتوصيل'),
              ]),
              _Section('إدارة الحساب', [
                entry(Icons.delete_outline_rounded, 'حذف الحساب',
                    'حذف البيانات نهائيًا')
              ]),
              OutlinedButton.icon(
                  onPressed: () async {
                    if (!await confirmLogout(context) || !context.mounted) {
                      return;
                    }
                    await state.logout();
                    if (!context.mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (_) => WelcomeScreen(state: state)),
                        (_) => false);
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('تسجيل الخروج')),
            ]));
      });
}

class _Header extends StatelessWidget {
  final AppState state;
  final VoidCallback onTap;
  const _Header({required this.state, required this.onTap});
  @override
  Widget build(BuildContext context) => ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Text(state.user?.name ?? 'عميل أزهارنا',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        subtitle: state.user?.phone == null
            ? null
            : Text(state.user!.phone,
                style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
        trailing: const Icon(Icons.chevron_left, size: 19),
      );
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section(this.title, this.children);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 4),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600))),
          ...children,
          const SizedBox(height: 8),
          const Divider(height: 1),
        ]),
      );
}

Widget _nav(IconData icon, String title, String subtitle, VoidCallback tap) =>
    Builder(
        builder: (context) => ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              leading: Icon(icon,
                  color: Theme.of(context).colorScheme.onSurface, size: 25),
              title: Text(title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500)),
              subtitle: Text(subtitle,
                  style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: tap,
            ));
