import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../auth/auth_controller.dart';
import 'order_detail_controller.dart';
import 'order_detail_screen.dart';
import 'order_models.dart';
import 'orders_controller.dart';
import 'orders_repository.dart';

class OrdersListScreen extends StatefulWidget {
  const OrdersListScreen({super.key});

  @override
  State<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends State<OrdersListScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    const threshold = 300.0;
    if (_scrollController.position.extentAfter < threshold) {
      context.read<OrdersController>().loadMore();
    }
  }

  void _openOrder(BuildContext context, OrderSummary order) {
    final repository = context.read<OrdersRepository>();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<OrderDetailController>(
          create: (_) => OrderDetailController(repository, order.id)..load(),
          child: const OrderDetailScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OrdersController>();
    final siteName = context.watch<AuthController>().siteName ?? 'سفارشات';

    return Scaffold(
      appBar: AppBar(
        title: Text(siteName),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'خروج',
            onPressed: () => context.read<AuthController>().logout(),
          ),
        ],
      ),
      body: Column(
        children: [
          _StatusFilterBar(controller: controller),
          Expanded(child: _buildBody(controller)),
        ],
      ),
    );
  }

  Widget _buildBody(OrdersController controller) {
    if (controller.isLoading && controller.orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.error != null && controller.orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(controller.error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: controller.refresh,
                child: const Text('تلاش دوباره'),
              ),
            ],
          ),
        ),
      );
    }

    if (controller.orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: controller.refresh,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Center(child: Text('سفارشی برای نمایش وجود ندارد.')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        itemCount: controller.orders.length + (controller.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= controller.orders.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          return _OrderCard(
            order: controller.orders[index],
            onTap: () => _openOrder(context, controller.orders[index]),
          );
        },
      ),
    );
  }
}

class _StatusFilterBar extends StatelessWidget {
  const _StatusFilterBar({required this.controller});

  final OrdersController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.statusOptions.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: const Text('همه'),
              selected: controller.statusFilter == null,
              onSelected: (_) => controller.setStatusFilter(null),
            ),
          ),
          for (final option in controller.statusOptions)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(option.label),
                selected: controller.statusFilter == option.status,
                onSelected: (_) => controller.setStatusFilter(option.status),
              ),
            ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap});

  final OrderSummary order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dateText = order.dateCreated != null
        ? DateFormat('yyyy-MM-dd HH:mm').format(order.dateCreated!.toLocal())
        : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'سفارش #${order.number}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Chip(
                    label: Text(order.statusLabel, style: const TextStyle(fontSize: 12)),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (order.customerName.isNotEmpty) Text(order.customerName),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(dateText, style: Theme.of(context).textTheme.bodySmall),
                  Text(
                    order.totalFormatted.isNotEmpty
                        ? order.totalFormatted
                        : '${order.total} ${order.currency}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
