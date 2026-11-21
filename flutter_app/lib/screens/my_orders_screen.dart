import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/marketplace_listing.dart';
import '../services/marketplace_service.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key, required this.service});
  final MarketplaceService service;

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  late Future<List<MarketplaceOrder>> _outgoing;
  late Future<List<MarketplaceOrder>> _incoming;

  @override
  void initState() {
    super.initState();
    _outgoing = widget.service.myPurchaseRequests();
    _incoming = widget.service.incomingOrders();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _refreshOutgoing() async {
    setState(() => _outgoing = widget.service.myPurchaseRequests());
    await _outgoing;
  }

  Future<void> _refreshIncoming() async {
    setState(() => _incoming = widget.service.incomingOrders());
    await _incoming;
  }

  /// Server rules (database trigger):
  /// seller: requested -> confirmed/cancelled, confirmed -> completed/cancelled
  /// buyer: can only cancel.
  Future<void> _changeStatus(MarketplaceOrder order, String status) async {
    try {
      await widget.service.updateOrderStatus(order.id, status);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update order: $e')),
      );
      return;
    }
    if (!mounted) return;
    _refreshIncoming();
    _refreshOutgoing();
  }

  Widget? _actions(MarketplaceOrder o, {required bool asSeller}) {
    if (asSeller) {
      if (o.status == 'requested') {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              tooltip: 'Confirm',
              onPressed: () => _changeStatus(o, 'confirmed'),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              tooltip: 'Decline',
              onPressed: () => _changeStatus(o, 'cancelled'),
            ),
          ],
        );
      }
      if (o.status == 'confirmed') {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.done_all, color: Colors.green),
              tooltip: 'Mark completed',
              onPressed: () => _changeStatus(o, 'completed'),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              tooltip: 'Cancel',
              onPressed: () => _changeStatus(o, 'cancelled'),
            ),
          ],
        );
      }
      return null;
    }

    // Buyer: can only cancel an order that is still open.
    if (o.status == 'requested' || o.status == 'confirmed') {
      return TextButton(
        onPressed: () => _changeStatus(o, 'cancelled'),
        child: const Text('Cancel'),
      );
    }
    return null;
  }

  Widget _orderTile(MarketplaceOrder o, {bool asSeller = false}) {
    final df = DateFormat.yMMMd().add_jm();
    return ListTile(
      title: Text('Quantity: ${o.quantity}'),
      subtitle: Text('${o.status} — ${df.format(o.createdAt)}'),
      trailing: _actions(o, asSeller: asSeller),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My orders'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'My requests'),
            Tab(text: 'Incoming requests'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          RefreshIndicator(
            onRefresh: _refreshOutgoing,
            child: FutureBuilder<List<MarketplaceOrder>>(
              future: _outgoing,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final orders = snap.data ?? [];
                if (orders.isEmpty) {
                  return ListView(children: const [
                    SizedBox(height: 120),
                    Center(child: Text('No purchase requests yet.')),
                  ]);
                }
                return ListView.separated(
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) => _orderTile(orders[i]),
                );
              },
            ),
          ),
          RefreshIndicator(
            onRefresh: _refreshIncoming,
            child: FutureBuilder<List<MarketplaceOrder>>(
              future: _incoming,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final orders = snap.data ?? [];
                if (orders.isEmpty) {
                  return ListView(children: const [
                    SizedBox(height: 120),
                    Center(child: Text('No incoming requests yet.')),
                  ]);
                }
                return ListView.separated(
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) => _orderTile(orders[i], asSeller: true),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
