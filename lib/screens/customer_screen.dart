import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './add_customer_order_screen.dart';

class CustomerScreen extends StatelessWidget {
  const CustomerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer'),
        backgroundColor: const Color(0xFF1B1B4E),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Add Customer Order button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddCustomerOrderScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Add Customer Order'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B1B4E),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                textStyle: const TextStyle(fontSize: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          // Order list grouped by status
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('customer_orders')
                  .orderBy('dateCreated', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final docs = snapshot.data?.docs ?? [];

                final processing = docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  return (data['orderStatus'] ?? '') == 'Processing';
                }).toList();

                final shipped = docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  return (data['orderStatus'] ?? '') == 'Shipped';
                }).toList();

                final delivered = docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  return (data['orderStatus'] ?? '') == 'Delivered';
                }).toList();

                if (docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          'No customer orders yet.',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    _SectionHeader(
                      label: 'Processing',
                      count: processing.length,
                      color: Colors.orange,
                      icon: Icons.hourglass_empty,
                    ),
                    if (processing.isEmpty)
                      _EmptySection(label: 'No processing orders')
                    else
                      ...processing.map((doc) => _CustomerOrderCard(
                            key: ValueKey(doc.id),
                            docId: doc.id,
                            data: doc.data() as Map<String, dynamic>,
                          )),
                    const SizedBox(height: 8),
                    _SectionHeader(
                      label: 'Shipped',
                      count: shipped.length,
                      color: Colors.blue,
                      icon: Icons.local_shipping_outlined,
                    ),
                    if (shipped.isEmpty)
                      _EmptySection(label: 'No shipped orders')
                    else
                      ...shipped.map((doc) => _CustomerOrderCard(
                            key: ValueKey(doc.id),
                            docId: doc.id,
                            data: doc.data() as Map<String, dynamic>,
                          )),
                    const SizedBox(height: 8),
                    _SectionHeader(
                      label: 'Delivered',
                      count: delivered.length,
                      color: Colors.green,
                      icon: Icons.check_circle_outline,
                    ),
                    if (delivered.isEmpty)
                      _EmptySection(label: 'No delivered orders')
                    else
                      ...delivered.map((doc) => _CustomerOrderCard(
                            key: ValueKey(doc.id),
                            docId: doc.id,
                            data: doc.data() as Map<String, dynamic>,
                          )),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Header ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _SectionHeader({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
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
          const Expanded(child: Divider(indent: 10)),
        ],
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  final String label;
  const _EmptySection({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 28, bottom: 4),
      child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
    );
  }
}

// ── Customer Order Card ────────────────────────────────────────────────────────

class _CustomerOrderCard extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  const _CustomerOrderCard({
    super.key,
    required this.docId,
    required this.data,
  });

  @override
  State<_CustomerOrderCard> createState() => _CustomerOrderCardState();
}

class _CustomerOrderCardState extends State<_CustomerOrderCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnim = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1.2, 0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInCubic));
    _fadeAnim = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _statusColor {
    switch (widget.data['orderStatus'] ?? '') {
      case 'Shipped':
        return Colors.blue;
      case 'Delivered':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  IconData get _statusIcon {
    switch (widget.data['orderStatus'] ?? '') {
      case 'Shipped':
        return Icons.local_shipping_outlined;
      case 'Delivered':
        return Icons.check_circle_outline;
      default:
        return Icons.hourglass_empty;
    }
  }

  String _formatTimestamp(dynamic ts) {
    if (ts == null) return 'No date';
    if (ts is Timestamp) {
      return '${ts.toDate().toLocal()}'.split('.')[0];
    }
    return ts.toString();
  }

  void _showSnack(String msg, {bool isSuccess = false, bool isError = false}) {
    final color = isSuccess
        ? const Color(0xFF1B1B4E)
        : isError
            ? Colors.redAccent
            : null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (isSuccess) const Icon(Icons.check_circle, color: Colors.white, size: 18),
            if (isError) const Icon(Icons.error_outline, color: Colors.white, size: 18),
            if (isSuccess || isError) const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _animateThenDelete() async {
    await _controller.forward();
    await FirebaseFirestore.instance
        .collection('customer_orders')
        .doc(widget.docId)
        .delete();
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Order'),
        content: Text(
            'Are you sure you want to delete the order for "${widget.data['customerName'] ?? 'this customer'}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _animateThenDelete();
              if (mounted) {
                _showSnack(
                  '"${widget.data['customerName'] ?? 'Order'}" deleted.',
                  isError: true,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog() {
    final nameCtrl = TextEditingController(text: widget.data['customerName'] ?? '');
    final addressCtrl = TextEditingController(text: widget.data['customerAddress'] ?? '');
    final phoneCtrl = TextEditingController(text: widget.data['phoneNumber'] ?? '');
    final productCtrl = TextEditingController(text: widget.data['productName'] ?? '');
    final qtyCtrl = TextEditingController(
        text: (widget.data['orderQuantity'] ?? '').toString());
    String status = widget.data['orderStatus'] ?? 'Processing';
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Order'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _editField(nameCtrl, 'Customer Name'),
                const SizedBox(height: 10),
                _editField(addressCtrl, 'Customer Address', maxLines: 2),
                const SizedBox(height: 10),
                _editField(phoneCtrl, 'Phone Number',
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 10),
                _editField(productCtrl, 'Product Name'),
                const SizedBox(height: 10),
                _editField(qtyCtrl, 'Order Quantity',
                    keyboardType: TextInputType.number),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: InputDecoration(
                    labelText: 'Order Status',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  items: ['Processing', 'Shipped', 'Delivered'].map((s) {
                    Color c = s == 'Processing'
                        ? Colors.orange
                        : s == 'Shipped'
                            ? Colors.blue
                            : Colors.green;
                    return DropdownMenuItem(
                      value: s,
                      child: Text(s, style: TextStyle(color: c)),
                    );
                  }).toList(),
                  onChanged: (val) => setDialogState(() => status = val!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      setDialogState(() => isSaving = true);
                      try {
                        await FirebaseFirestore.instance
                            .collection('customer_orders')
                            .doc(widget.docId)
                            .update({
                          'customerName': nameCtrl.text.trim(),
                          'customerAddress': addressCtrl.text.trim(),
                          'phoneNumber': phoneCtrl.text.trim(),
                          'productName': productCtrl.text.trim(),
                          'orderQuantity':
                              int.tryParse(qtyCtrl.text.trim()) ?? 0,
                          'orderStatus': status,
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          _showSnack('Order updated successfully!',
                              isSuccess: true);
                        }
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        if (mounted) {
                          _showSnack('Failed to update: $e', isError: true);
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B1B4E),
                foregroundColor: Colors.white,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isSaving
                    ? const SizedBox(
                        key: ValueKey('saving'),
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(key: ValueKey('save'), 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextField _editField(
    TextEditingController ctrl,
    String label, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = _formatTimestamp(widget.data['dateCreated']);

    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.data['customerName'] ?? 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_statusIcon, size: 13, color: _statusColor),
                          const SizedBox(width: 4),
                          Text(
                            widget.data['orderStatus'] ?? '',
                            style: TextStyle(
                              color: _statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _infoRow(Icons.location_on_outlined,
                    widget.data['customerAddress'] ?? '—'),
                _infoRow(Icons.phone_outlined, widget.data['phoneNumber'] ?? '—'),
                _infoRow(Icons.shopping_cart_outlined,
                    '${widget.data['productName'] ?? '—'}  ×  ${widget.data['orderQuantity'] ?? 0}'),
                _infoRow(Icons.access_time, dateStr),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: _showEditDialog,
                      icon: const Icon(Icons.edit_outlined,
                          size: 16, color: Color(0xFF1B1B4E)),
                      label: const Text('Edit',
                          style: TextStyle(color: Color(0xFF1B1B4E))),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const SizedBox(width: 4),
                    TextButton.icon(
                      onPressed: _confirmDelete,
                      icon: const Icon(Icons.delete_outline,
                          size: 16, color: Colors.redAccent),
                      label: const Text('Delete',
                          style: TextStyle(color: Colors.redAccent)),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    if (text.isEmpty || text == '—') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}