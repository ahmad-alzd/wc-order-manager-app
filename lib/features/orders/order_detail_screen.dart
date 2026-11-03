import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'order_detail_controller.dart';
import 'order_models.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key});

  Future<void> _pickStatus(BuildContext context, OrderDetailController controller) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('تغییر وضعیت سفارش', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              for (final option in controller.statusOptions)
                ListTile(
                  title: Text(option.label),
                  trailing: option.status == controller.order?.status
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () => Navigator.of(sheetContext).pop(option.status),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (selected == null) return;

    final success = await controller.changeStatus(selected);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'وضعیت سفارش تغییر کرد.' : (controller.error ?? 'تغییر وضعیت ناموفق بود.')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OrderDetailController>();
    final order = controller.order;

    return Scaffold(
      appBar: AppBar(
        title: Text(order != null ? 'سفارش #${order.number}' : 'سفارش'),
      ),
      body: _buildBody(context, controller, order),
      floatingActionButton: order == null
          ? null
          : FloatingActionButton.extended(
              onPressed: controller.isUpdatingStatus ? null : () => _pickStatus(context, controller),
              icon: controller.isUpdatingStatus
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.sync_alt),
              label: const Text('تغییر وضعیت'),
            ),
    );
  }

  Widget _buildBody(BuildContext context, OrderDetailController controller, OrderDetail? order) {
    if (controller.isLoading && order == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.error != null && order == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(controller.error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: controller.load, child: const Text('تلاش دوباره')),
            ],
          ),
        ),
      );
    }

    if (order == null) {
      return const SizedBox.shrink();
    }

    final dateText = order.dateCreated != null
        ? DateFormat('yyyy-MM-dd HH:mm').format(order.dateCreated!.toLocal())
        : '';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionCard(
          title: 'وضعیت',
          child: Row(
            children: [
              Chip(label: Text(order.statusLabel)),
              const SizedBox(width: 12),
              if (dateText.isNotEmpty) Text(dateText, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        _SectionCard(
          title: 'مشتری',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (order.customerName.isNotEmpty) Text(order.customerName),
              if (order.billing.phone?.isNotEmpty ?? false)
                Text(order.billing.phone!, textDirection: TextDirection.ltr),
              if (order.billing.email?.isNotEmpty ?? false)
                Text(order.billing.email!, textDirection: TextDirection.ltr),
              if (order.billing.singleLine.isNotEmpty) Text(order.billing.singleLine),
            ],
          ),
        ),
        if (!order.shipping.isEmpty && order.shipping.singleLine != order.billing.singleLine)
          _SectionCard(
            title: 'آدرس ارسال',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (order.shipping.name.isNotEmpty) Text(order.shipping.name),
                if (order.shipping.singleLine.isNotEmpty) Text(order.shipping.singleLine),
              ],
            ),
          ),
        _SectionCard(
          title: 'اقلام سفارش',
          child: Column(
            children: [
              for (final item in order.lineItems)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('${item.name}${item.sku.isNotEmpty ? " (${item.sku})" : ""}'),
                      ),
                      Text('× ${item.quantity}'),
                      const SizedBox(width: 12),
                      Text('${item.total} ${order.currency}', textDirection: TextDirection.ltr),
                    ],
                  ),
                ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('جمع کل', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    order.totalFormatted.isNotEmpty
                        ? order.totalFormatted
                        : '${order.total} ${order.currency}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (order.paymentMethodTitle.isNotEmpty)
          _SectionCard(title: 'روش پرداخت', child: Text(order.paymentMethodTitle)),
        if (order.customerNote.isNotEmpty)
          _SectionCard(title: 'یادداشت مشتری', child: Text(order.customerNote)),
        const SizedBox(height: 72), // leaves room for the FAB
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
