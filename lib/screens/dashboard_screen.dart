import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './landing_screen.dart';
import './log_list_screen.dart';
import './customer_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: const Color(0xFF1B1B4E),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: 'Menu',
          ),
        ),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF1B1B4E),
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.dashboard, color: Colors.white, size: 36),
                    SizedBox(height: 8),
                    Text(
                      'Menu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.people_alt_outlined, color: Color(0xFF1B1B4E)),
              title: const Text(
                'Customer',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CustomerScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined, color: Color(0xFF1B1B4E)),
              title: const Text(
                'Inventory',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LogListScreen()),
                );
              },
            ),
            const Divider(),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          // ── Customer Orders Section ──────────────────────────────────────
          const _SectionTitle(
            icon: Icons.shopping_bag_outlined,
            label: 'Customer Orders',
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('customer_orders')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _ScorecardsShimmer();
              }

              final docs = snapshot.data?.docs ?? [];
              final total = docs.length;
              final processing = docs.where((d) =>
                  (d.data() as Map<String, dynamic>)['orderStatus'] == 'Processing').length;
              final shipped = docs.where((d) =>
                  (d.data() as Map<String, dynamic>)['orderStatus'] == 'Shipped').length;
              final delivered = docs.where((d) =>
                  (d.data() as Map<String, dynamic>)['orderStatus'] == 'Delivered').length;

              return Column(
                children: [
                  _OrderScorecard(
                    label: 'Total Customer Orders',
                    count: total,
                    icon: Icons.receipt_long_outlined,
                    color: const Color(0xFF1B1B4E),
                    fullWidth: true,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _OrderScorecard(
                          label: 'Processing',
                          count: processing,
                          icon: Icons.hourglass_empty,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _OrderScorecard(
                          label: 'Shipped',
                          count: shipped,
                          icon: Icons.local_shipping_outlined,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _OrderScorecard(
                          label: 'Delivered',
                          count: delivered,
                          icon: Icons.check_circle_outline,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 28),

          // ── Inventory Section ────────────────────────────────────────────
          const _SectionTitle(
            icon: Icons.inventory_2_outlined,
            label: 'Inventory',
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('checkin_logs')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data?.docs ?? [];

              final lowStock = docs.where((d) =>
                  (d.data() as Map<String, dynamic>)['stockStatus'] == 'Low stock').toList();
              final outOfStock = docs.where((d) =>
                  (d.data() as Map<String, dynamic>)['stockStatus'] == 'Out-of-stock').toList();

              if (lowStock.isEmpty && outOfStock.isEmpty) {
                return _InventoryAllGoodCard();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (lowStock.isNotEmpty) ...[
                    _InventoryGroupHeader(
                      label: 'Low Stock',
                      count: lowStock.length,
                      color: Colors.amber.shade700,
                      icon: Icons.warning_amber_rounded,
                    ),
                    const SizedBox(height: 8),
                    ...lowStock.map((doc) => _InventoryProductRow(
                          data: doc.data() as Map<String, dynamic>,
                          statusColor: Colors.amber.shade700,
                        )),
                    const SizedBox(height: 16),
                  ],
                  if (outOfStock.isNotEmpty) ...[
                    _InventoryGroupHeader(
                      label: 'Out-of-Stock',
                      count: outOfStock.length,
                      color: Colors.redAccent,
                      icon: Icons.remove_shopping_cart_outlined,
                    ),
                    const SizedBox(height: 8),
                    ...outOfStock.map((doc) => _InventoryProductRow(
                          data: doc.data() as Map<String, dynamic>,
                          statusColor: Colors.redAccent,
                        )),
                  ],
                ],
              );
            },
          ),

          const SizedBox(height: 32),

          // ── Logout ───────────────────────────────────────────────────────
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LandingScreen()),
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle: const TextStyle(fontSize: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Title ─────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionTitle({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF1B1B4E)),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B1B4E),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(child: Divider()),
      ],
    );
  }
}

// ── Order Scorecard ───────────────────────────────────────────────────────────

class _OrderScorecard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final bool fullWidth;

  const _OrderScorecard({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: fullWidth ? 20 : 12,
        vertical: fullWidth ? 16 : 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border(
          left: BorderSide(color: color, width: 4),
        ),
      ),
      child: fullWidth
          ? Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(height: 8),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
    );
  }
}

// ── Scorecards Shimmer (loading placeholder) ──────────────────────────────────

class _ScorecardsShimmer extends StatelessWidget {
  const _ScorecardsShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(
            3,
            (i) => Expanded(
              child: Container(
                height: 80,
                margin: EdgeInsets.only(left: i > 0 ? 10 : 0),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Inventory Group Header ────────────────────────────────────────────────────

class _InventoryGroupHeader extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _InventoryGroupHeader({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(child: Divider()),
      ],
    );
  }
}

// ── Inventory Product Row ─────────────────────────────────────────────────────

class _InventoryProductRow extends StatelessWidget {
  final Map<String, dynamic> data;
  final Color statusColor;

  const _InventoryProductRow({
    required this.data,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final productName = data['productName'] ?? 'Unnamed Product';
    final status = data['stockStatus'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border(
          left: BorderSide(color: statusColor, width: 3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.inventory_2_outlined, color: statusColor, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              productName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── All Good Card ─────────────────────────────────────────────────────────────

class _InventoryAllGoodCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: Colors.green.shade600, size: 28),
          const SizedBox(width: 12),
          Text(
            'All products are sufficiently stocked.',
            style: TextStyle(
              color: Colors.green.shade700,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
