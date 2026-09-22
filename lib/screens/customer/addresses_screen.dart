import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../widgets/iraq_map_picker.dart';

class AddressesScreen extends StatelessWidget {
  final AppState state;
  const AddressesScreen({super.key, required this.state});

  void add(BuildContext context) {
    final title = TextEditingController(text: 'المنزل');
    final details = TextEditingController();
    var city = state.selectedCity;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: .9,
          minChildSize: .65,
          maxChildSize: .96,
          builder: (_, controller) => ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              Text('حدد موقعك في العراق',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text('اضغط على المحافظة في الخريطة أو اخترها من القائمة',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 14),
              IraqMapPicker(
                selected: city,
                onSelected: (value) => setSheetState(() => city = value),
              ),
              const SizedBox(height: 20),
              TextField(
                  controller: title,
                  decoration: const InputDecoration(
                      labelText: 'اسم العنوان',
                      prefixIcon: Icon(Icons.bookmark_outline_rounded))),
              const SizedBox(height: 10),
              TextField(
                  controller: details,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: 'المنطقة، الشارع، أقرب نقطة دالة',
                      prefixIcon: Icon(Icons.home_work_outlined))),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: city.isEmpty
                    ? null
                    : () {
                        state.addAddress(title.text, city, details.text);
                        Navigator.pop(context);
                      },
                icon: const Icon(Icons.check_circle_outline_rounded),
                label:
                    Text(city.isEmpty ? 'اختر المحافظة أولًا' : 'حفظ العنوان'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: state,
        builder: (_, __) => Scaffold(
          appBar: AppBar(title: const Text('عناويني')),
          floatingActionButton: FloatingActionButton.extended(
              onPressed: () => add(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('إضافة عنوان')),
          body: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.addresses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final a = state.addresses[i];
              return Card(
                  child: ListTile(
                      leading: const Icon(Icons.location_on_outlined),
                      title: Text(a.title,
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text('${a.city}\n${a.details}'),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_left_rounded)));
            },
          ),
        ),
      );
}
