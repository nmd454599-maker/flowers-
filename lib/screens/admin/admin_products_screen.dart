import 'dart:convert';

import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';

class AdminProductsScreen extends StatefulWidget {
  final AppState state;
  final String? initialStoreId;

  const AdminProductsScreen(
      {super.key, required this.state, this.initialStoreId});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final search = TextEditingController();
  ProductApprovalStatus? selectedStatus;

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  List<AdminProductRecord> get filtered {
    final query = search.text.trim().toLowerCase();
    return widget.state.adminProducts.where((product) {
      final matchesStore = widget.initialStoreId == null ||
          product.storeId == widget.initialStoreId;
      final matchesStatus =
          selectedStatus == null || product.status == selectedStatus;
      final matchesQuery = query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query) ||
          product.storeId.toLowerCase().contains(query);
      return matchesStore && matchesStatus && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          title: const Text('إدارة المنتجات'),
          actions: [
            IconButton(
              tooltip: 'تحديث',
              onPressed: widget.state.busy ? null : widget.state.loadAdminData,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: AnimatedBuilder(
          animation: widget.state,
          builder: (context, _) {
            final products = filtered;
            return Column(children: [
              if (widget.state.busy)
                const LinearProgressIndicator(minHeight: 2),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
                child: TextField(
                  controller: search,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'اسم المنتج، التصنيف أو المتجر',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),
              SizedBox(
                height: 46,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  children: [
                    _filterChip(null, 'الكل'),
                    _filterChip(ProductApprovalStatus.pending, 'قيد المراجعة'),
                    _filterChip(ProductApprovalStatus.approved, 'مقبول'),
                    _filterChip(ProductApprovalStatus.rejected, 'مرفوض'),
                    _filterChip(ProductApprovalStatus.hidden, 'مخفي'),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                child: Row(children: [
                  Text('${products.length} منتج',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                  const Spacer(),
                  Text(
                    '${widget.state.adminProducts.where((p) => p.status == ProductApprovalStatus.pending).length} بانتظار الإجراء',
                    style:
                        const TextStyle(color: Color(0xFFC47C0A), fontSize: 12),
                  ),
                ]),
              ),
              Expanded(
                child: products.isEmpty
                    ? const _EmptyProducts()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
                        itemCount: products.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, index) =>
                            _productCard(products[index]),
                      ),
              ),
            ]);
          },
        ),
      );

  Widget _filterChip(ProductApprovalStatus? status, String label) => Padding(
        padding: const EdgeInsetsDirectional.only(end: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: selectedStatus == status,
          onSelected: (_) => setState(() => selectedStatus = status),
        ),
      );

  Widget _productCard(AdminProductRecord product) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _image(product),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w800)),
                    ),
                    _status(product.status),
                  ]),
                  const SizedBox(height: 4),
                  Text('${product.price} د.ع · مخزون ${product.stock}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text('${product.category} · متجر ${product.storeId}',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12)),
                  if (product.rejectionReason?.isNotEmpty == true) ...[
                    const SizedBox(height: 5),
                    Text('السبب: ${product.rejectionReason}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Color(0xFFB53A35), fontSize: 11)),
                  ],
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    if (product.status != ProductApprovalStatus.approved)
                      FilledButton.tonalIcon(
                        onPressed: () =>
                            _review(product, ProductApprovalStatus.approved),
                        icon: const Icon(Icons.check_rounded, size: 17),
                        label: const Text('قبول'),
                      ),
                    if (product.status != ProductApprovalStatus.rejected)
                      OutlinedButton.icon(
                        onPressed: () =>
                            _review(product, ProductApprovalStatus.rejected),
                        icon: const Icon(Icons.close_rounded, size: 17),
                        label: const Text('رفض'),
                      ),
                    IconButton.filledTonal(
                      tooltip: product.status == ProductApprovalStatus.hidden
                          ? 'إعادة النشر'
                          : 'إخفاء',
                      onPressed: () => _review(
                        product,
                        product.status == ProductApprovalStatus.hidden
                            ? ProductApprovalStatus.approved
                            : ProductApprovalStatus.hidden,
                      ),
                      icon: Icon(product.status == ProductApprovalStatus.hidden
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_outlined),
                    ),
                  ]),
                ],
              ),
            ),
          ]),
        ),
      );

  Widget _image(AdminProductRecord product) {
    final url = product.imageUrl;
    final fallback = ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: SizedBox(
        width: 82,
        height: 82,
        child: Icon(Icons.inventory_2_outlined,
            color: Theme.of(context).colorScheme.primary),
      ),
    );
    if (url == null || url.isEmpty) return fallback;
    if (url.startsWith('data:')) {
      try {
        return Image.memory(
          base64Decode(url.substring(url.indexOf(',') + 1)),
          width: 82,
          height: 82,
          fit: BoxFit.cover,
        );
      } catch (_) {
        return fallback;
      }
    }
    return Image.network(url,
        width: 82,
        height: 82,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback);
  }

  Widget _status(ProductApprovalStatus status) {
    final (label, color, background) = switch (status) {
      ProductApprovalStatus.draft => (
          'مسودة',
          Theme.of(context).colorScheme.onSurfaceVariant,
          Theme.of(context).colorScheme.surfaceContainerLow
        ),
      ProductApprovalStatus.pending => (
          'معلق',
          const Color(0xFFC47C0A),
          Theme.of(context).colorScheme.surfaceContainerLow
        ),
      ProductApprovalStatus.approved => (
          'مقبول',
          const Color(0xFF238C69),
          Theme.of(context).colorScheme.surfaceContainerLow
        ),
      ProductApprovalStatus.rejected => (
          'مرفوض',
          const Color(0xFFB53A35),
          Theme.of(context).colorScheme.surfaceContainerLow
        ),
      ProductApprovalStatus.hidden => (
          'مخفي',
          Theme.of(context).colorScheme.onSurfaceVariant,
          Theme.of(context).colorScheme.surfaceContainerLow
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: background, borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w700, fontSize: 10)),
    );
  }

  Future<void> _review(
      AdminProductRecord product, ProductApprovalStatus status) async {
    String? reason;
    if (status == ProductApprovalStatus.rejected ||
        status == ProductApprovalStatus.hidden) {
      final controller = TextEditingController();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(status == ProductApprovalStatus.rejected
              ? 'رفض المنتج'
              : 'إخفاء المنتج'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
                labelText: 'السبب', hintText: 'اكتب سببًا واضحًا للمتجر'),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('إلغاء')),
            FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('تأكيد')),
          ],
        ),
      );
      if (confirmed != true) return;
      reason = controller.text.trim();
      controller.dispose();
      if (reason.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('يجب كتابة سبب الإجراء')));
        return;
      }
    }
    try {
      await widget.state.reviewProduct(product, status, reason: reason);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تم تحديث المنتج')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(widget.state.errorMessage ?? 'تعذر تحديث حالة المنتج')));
    }
  }
}

class _EmptyProducts extends StatelessWidget {
  const _EmptyProducts();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.inventory_2_outlined,
                size: 58,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            const Text('لا توجد منتجات مطابقة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('غيّر البحث أو الفلتر لعرض نتائج أخرى'),
          ]),
        ),
      );
}
