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

class _MyOrdersScreenState extends State<MyOrdersScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  late Future<List<MarketplaceOrder>> _outgoing;
  late Future<List<MarketplaceOrder>> _incoming;

  @override
  void initState() {
    super.initState();
    _outgoing = widget.service.myPurchaseRequests();
    _incoming = widget.service.incomingOrders();
  }

  Future<void> _refreshIncoming() async {
    setState(() => _incoming = widget.service.incomingOrders());
    await _incoming;
  }

  Future<void> _respond(MarketplaceOrder order, String status) async {
    await widget.service.updateOrderStatus(order.id, status);
    _refreshIncoming();
  }

  Widget _orderTile(MarketplaceOrder o, {bool asSeller = false}) {
    final df = DateFormat.yMMMd().add_jm();
    return ListTile(
      title: Text('Quantity: ${o.quantity}'),
      subtitle: Text('${o.status} — ${df.format(o.createdAt)}'),
      trailing: asSeller && o.status == 'requested'
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  tooltip: 'Confirm',
                  onPressed: () => _respond(o, 'confirmed'),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  tooltip: 'Decline',
                  onPressed: () => _respond(o, 'cancelled'),
                ),
              ],
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My orders'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [Tab(text: 'My requests'), Tab(text: 'Incoming requests')],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          FutureBuilder<List<MarketplaceOrder>>(
            future: _outgoing,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final orders = snap.data ?? [];
              if (orders.isEmpty) return const Center(child: Text('No purchase requests yet.'));
              return ListView.separated(
                itemCount: orders.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) => _orderTile(orders[i]),
              );
            },
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
