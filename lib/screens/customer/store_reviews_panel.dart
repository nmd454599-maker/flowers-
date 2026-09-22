import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../services/store_reviews_service.dart';

class StoreReviewsPanel extends StatefulWidget {
  final AppState state;
  final String storeId;
  final VoidCallback? onSaved;
  const StoreReviewsPanel(
      {super.key, required this.state, required this.storeId, this.onSaved});
  @override
  State<StoreReviewsPanel> createState() => _StoreReviewsPanelState();
}

class _StoreReviewsPanelState extends State<StoreReviewsPanel> {
  late Future<List<AdminRecord>> future = service.list(widget.storeId);
  StoreReviewsService get service =>
      StoreReviewsService(widget.state.repository);
  Future<void> edit(List<AdminRecord> records) async {
    Map<String, Object?> existing = {};
    for (final r in records) {
      if (r.data['customerId'] == widget.state.user?.id) existing = r.data;
    }
    final value = await showDialog<(int, String)>(
        context: context, builder: (_) => _ReviewEditor(data: existing));
    if (value == null || !mounted) return;
    try {
      await service.save(
          user: widget.state.user,
          storeId: widget.storeId,
          rating: value.$1,
          comment: value.$2);
      if (mounted) {
        setState(() {
          future = service.list(widget.storeId);
        });
        widget.onSaved?.call();
      }
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تعذر حفظ التقييم، حاول مجددًا')));
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<AdminRecord>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Center(
              child: TextButton(
                  onPressed: () => setState(() {
                        future = service.list(widget.storeId);
                      }),
                  child: const Text('تعذر تحميل التعليقات • إعادة المحاولة')));
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final reviews = snapshot.data!;
        final average = reviews.isEmpty
            ? 0.0
            : reviews.fold<double>(
                    0, (sum, r) => sum + (r.data['rating'] as num).toDouble()) /
                reviews.length;
        return ListView(padding: const EdgeInsets.all(20), children: [
          const Text('التقييمات والتعليقات',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          if (reviews.isNotEmpty)
            Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                children: [
                  const Icon(Icons.star, color: Colors.amber),
                  Text('${average.toStringAsFixed(1)} / 5',
                      style: const TextStyle(
                          fontSize: 26, fontWeight: FontWeight.bold)),
                  Text('${reviews.length} تقييم')
                ]),
          if (widget.state.user?.role == UserRole.customer)
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: FilledButton.icon(
                    onPressed: () => edit(reviews),
                    icon: const Icon(Icons.rate_review_outlined),
                    label: Text(reviews.any((r) =>
                            r.data['customerId'] == widget.state.user?.id)
                        ? 'تعديل تقييمي وتعليقي'
                        : 'أضف تقييمك وتعليقك'))),
          if (reviews.isEmpty)
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Text('لا توجد تقييمات أو تعليقات بعد',
                    textAlign: TextAlign.center)),
          for (final review in reviews)
            Card(
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${review.data['customerName']}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          Row(children: [
                            for (var i = 1; i <= 5; i++)
                              Icon(
                                  i <= (review.data['rating'] as num)
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 20)
                          ]),
                          const SizedBox(height: 8),
                          Text('${review.data['comment']}'),
                          const SizedBox(height: 8),
                          Text('${review.data['createdAt']}'.split('T').first,
                              style: Theme.of(context).textTheme.bodySmall),
                        ]))),
        ]);
      });
}

class _ReviewEditor extends StatefulWidget {
  final Map<String, Object?> data;
  const _ReviewEditor({required this.data});
  @override
  State<_ReviewEditor> createState() => _ReviewEditorState();
}

class _ReviewEditorState extends State<_ReviewEditor> {
  late int rating = (widget.data['rating'] as num?)?.toInt() ?? 5;
  late final comment =
      TextEditingController(text: widget.data['comment'] as String? ?? '');
  @override
  void dispose() {
    comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
          title: const Text('تقييم المتجر'),
          content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            Wrap(children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                    tooltip: '$i نجوم',
                    onPressed: () => setState(() => rating = i),
                    icon: Icon(i <= rating ? Icons.star : Icons.star_border,
                        color: Colors.amber))
            ]),
            TextField(
                controller: comment,
                maxLength: 2000,
                minLines: 3,
                maxLines: 6,
                decoration:
                    const InputDecoration(labelText: 'تعليقك عن المتجر')),
          ])),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء')),
            FilledButton(
                onPressed: () {
                  if (comment.text.trim().isNotEmpty)
                    Navigator.pop(context, (rating, comment.text.trim()));
                },
                child: const Text('حفظ التقييم'))
          ]);
}
