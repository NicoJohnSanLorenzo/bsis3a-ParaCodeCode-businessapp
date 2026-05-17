import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './add_customer_order_screen.dart';
import '../services/user_role_service.dart';

// ── Color Palette ─────────────────────────────────────────────────────────────
class AppColors {
  static const pastelBlue     = Color(0xFFAEC6E8);
  static const pastelOrange   = Color(0xFFFFCBA4);
  static const pastelPeach    = Color(0xFFFFE5CC);
  static const pastelLavender = Color(0xFFEAD5F0);
  static const deepBlue       = Color(0xFF3A5A8A);
  static const deepOrange     = Color(0xFFD4845A);
  static const processing     = Color(0xFFD4845A);
  static const shipped        = Color(0xFF5A8AB0);
  static const delivered      = Color(0xFF5A8A6A);
}

const kBgGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  stops: [0.0, 0.40, 0.75, 1.0],
  colors: [
    Color(0xFFDCEAF7),
    Color(0xFFEAD5F0),
    Color(0xFFFFE5CC),
    Color(0xFFFFD6B0),
  ],
);

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({super.key});

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  AppRole _role = AppRole.unknown;

  @override
  void initState() {
    super.initState();
    UserRoleService.getCurrentRole().then((r) {
      if (mounted) setState(() => _role = r);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Customer Orders',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.deepBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      // ── FAB visible to all (both admin & staff can add orders) ────────────
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddCustomerOrderScreen()),
        ),
        backgroundColor: AppColors.pastelBlue,
        foregroundColor: AppColors.deepBlue,
        child: const Icon(Icons.add),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: kBgGradient),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('customer_orders')
              .orderBy('dateCreated', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.deepBlue),
              );
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Center(
                child: Text('No orders found. Tap + to add.'),
              );
            }

            final processing = docs.where((d) =>
              (d.data() as Map)['orderStatus'] == 'Processing').toList();
            final shipped = docs.where((d) =>
              (d.data() as Map)['orderStatus'] == 'Shipped').toList();
            final delivered = docs.where((d) =>
              (d.data() as Map)['orderStatus'] == 'Delivered').toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              children: [
                _buildSectionHeader('Processing', processing.length,
                    AppColors.processing, Icons.hourglass_empty),
                const SizedBox(height: 8),
                ...processing.map((doc) => _OrderCard(
                      docId: doc.id,
                      data: doc.data() as Map<String, dynamic>,
                      statusColor: AppColors.processing,
                      statusIcon: Icons.hourglass_empty,
                      role: _role,
                    )),
                if (processing.isEmpty) _buildEmptyMessage('No processing orders'),

                const SizedBox(height: 24),

                _buildSectionHeader('Shipped', shipped.length,
                    AppColors.shipped, Icons.local_shipping_outlined),
                const SizedBox(height: 8),
                ...shipped.map((doc) => _OrderCard(
                      docId: doc.id,
                      data: doc.data() as Map<String, dynamic>,
                      statusColor: AppColors.shipped,
                      statusIcon: Icons.local_shipping_outlined,
                      role: _role,
                    )),
                if (shipped.isEmpty) _buildEmptyMessage('No shipped orders'),

                const SizedBox(height: 24),

                _buildSectionHeader('Delivered', delivered.length,
                    AppColors.delivered, Icons.check_circle_outline),
                const SizedBox(height: 8),
                ...delivered.map((doc) => _OrderCard(
                      docId: doc.id,
                      data: doc.data() as Map<String, dynamic>,
                      statusColor: AppColors.delivered,
                      statusIcon: Icons.check_circle_outline,
                      role: _role,
                    )),
                if (delivered.isEmpty) _buildEmptyMessage('No delivered orders'),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
      String title, int count, Color color, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const Expanded(child: SizedBox()),
      ],
    );
  }

  Widget _buildEmptyMessage(String message) {
    return Padding(
      padding: const EdgeInsets.only(left: 30, top: 4, bottom: 8),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 12,
          fontStyle: FontStyle.italic,
          color: AppColors.deepBlue.withOpacity(0.5),
        ),
      ),
    );
  }
}

// ── Order Card (role-aware) ───────────────────────────────────────────────────
class _OrderCard extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;
  final Color statusColor;
  final IconData statusIcon;
  final AppRole role;

  const _OrderCard({
    required this.docId,
    required this.data,
    required this.statusColor,
    required this.statusIcon,
    required this.role,
  });

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  void _deleteOrder() async {
    try {
      await FirebaseFirestore.instance
          .collection('customer_orders')
          .doc(widget.docId)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order deleted successfully'),
            backgroundColor: AppColors.deepBlue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting: $e')),
        );
      }
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Order'),
        content: Text(
          'Delete order for "${widget.data['customerName'] ?? 'this customer'}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteOrder();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _editOrder() {
    final nameCtrl    = TextEditingController(text: widget.data['customerName'] ?? '');
    final addressCtrl = TextEditingController(text: widget.data['customerAddress'] ?? '');
    final phoneCtrl   = TextEditingController(text: widget.data['phoneNumber'] ?? '');
    final productCtrl = TextEditingController(text: widget.data['productName'] ?? '');
    final qtyCtrl     = TextEditingController(
        text: (widget.data['orderQuantity'] ?? 0).toString());
    String status = widget.data['orderStatus'] ?? 'Processing';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Order'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Customer Name')),
                const SizedBox(height: 8),
                TextField(
                    controller: addressCtrl,
                    decoration: const InputDecoration(labelText: 'Address'),
                    maxLines: 2),
                const SizedBox(height: 8),
                TextField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 8),
                TextField(
                    controller: productCtrl,
                    decoration: const InputDecoration(labelText: 'Product Name')),
                const SizedBox(height: 8),
                TextField(
                    controller: qtyCtrl,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    keyboardType: TextInputType.number),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'Processing', child: Text('Processing')),
                    DropdownMenuItem(value: 'Shipped',    child: Text('Shipped')),
                    DropdownMenuItem(value: 'Delivered',  child: Text('Delivered')),
                  ],
                  onChanged: (val) => setDialogState(() => status = val!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance
                      .collection('customer_orders')
                      .doc(widget.docId)
                      .update({
                    'customerName':    nameCtrl.text.trim(),
                    'customerAddress': addressCtrl.text.trim(),
                    'phoneNumber':     phoneCtrl.text.trim(),
                    'productName':     productCtrl.text.trim(),
                    'orderQuantity':   int.tryParse(qtyCtrl.text.trim()) ?? 0,
                    'orderStatus':     status,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Order updated!')),
                    );
                  }
                } catch (e) {
                  // handle error
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.role == AppRole.admin;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: widget.statusColor, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer name + status badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.data['customerName'] ?? 'Unknown Customer',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.deepBlue,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(widget.statusIcon, size: 12, color: widget.statusColor),
                      const SizedBox(width: 4),
                      Text(
                        widget.data['orderStatus'] ?? 'Processing',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: widget.statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Info rows
            _buildInfoRow(Icons.person_outline, widget.data['customerName'] ?? ''),
            _buildInfoRow(Icons.shopping_bag_outlined, widget.data['productName'] ?? ''),
            _buildInfoRow(Icons.numbers, 'Quantity: ${widget.data['orderQuantity'] ?? 0}'),
            _buildInfoRow(Icons.location_on_outlined, widget.data['customerAddress'] ?? ''),
            _buildInfoRow(Icons.phone_outlined, widget.data['phoneNumber'] ?? ''),
            if (widget.data['dateCreated'] != null)
              _buildInfoRow(Icons.calendar_today, _formatDate(widget.data['dateCreated'])),
            const SizedBox(height: 8),
            // ── Admin-only: Edit & Delete buttons ────────────────────────────
            if (isAdmin)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildActionButton(
                      Icons.edit_outlined, 'Edit', AppColors.deepBlue, _editOrder),
                  const SizedBox(width: 8),
                  _buildActionButton(
                      Icons.delete_outline, 'Delete', Colors.red, _confirmDelete),
                ],
              ),
            // ── Staff: read-only label ────────────────────────────────────────
            if (!isAdmin && widget.role != AppRole.unknown)
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'View only',
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: AppColors.deepBlue.withOpacity(0.40),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.deepBlue.withOpacity(0.6)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.deepBlue.withOpacity(0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'No date';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.month}/${date.day}/${date.year}';
    }
    return timestamp.toString();
  }
}