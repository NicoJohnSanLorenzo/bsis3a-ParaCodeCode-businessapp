import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './create_checkin_screen.dart';

class LogListScreen extends StatelessWidget {
  const LogListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        backgroundColor: const Color(0xFF1B1B4E),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateCheckinScreen()),
          );
        },
        backgroundColor: const Color(0xFF1B1B4E),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Product Order'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('checkin_logs')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No inventory orders yet.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          final inStock = docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            return (data['stockStatus'] ?? '') == 'In-stock';
          }).toList();

          final lowStock = docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            return (data['stockStatus'] ?? '') == 'Low stock';
          }).toList();

          final outOfStock = docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            return (data['stockStatus'] ?? '') == 'Out-of-stock';
          }).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              if (inStock.isNotEmpty) ...[
                _CategoryHeader(
                  label: 'In-stock',
                  count: inStock.length,
                  color: Colors.green,
                  icon: Icons.check_circle_outline,
                ),
                const SizedBox(height: 8),
                ...inStock.map((doc) => _buildCard(doc)),
                const SizedBox(height: 20),
              ],
              if (lowStock.isNotEmpty) ...[
                _CategoryHeader(
                  label: 'Low Stock',
                  count: lowStock.length,
                  color: Colors.orange,
                  icon: Icons.warning_amber_outlined,
                ),
                const SizedBox(height: 8),
                ...lowStock.map((doc) => _buildCard(doc)),
                const SizedBox(height: 20),
              ],
              if (outOfStock.isNotEmpty) ...[
                _CategoryHeader(
                  label: 'Out-of-stock',
                  count: outOfStock.length,
                  color: Colors.redAccent,
                  icon: Icons.cancel_outlined,
                ),
                const SizedBox(height: 8),
                ...outOfStock.map((doc) => _buildCard(doc)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final ts = data['createdAt'] as Timestamp?;
    final dateStr = ts != null ? '${ts.toDate().toLocal()}'.split('.')[0] : 'No date';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _AnimatedInventoryCard(
        key: ValueKey(doc.id),
        docId: doc.id,
        data: data,
        dateStr: dateStr,
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _CategoryHeader({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: color,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Animated card ──────────────────────────────────────────────────────────────

class _AnimatedInventoryCard extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;
  final String dateStr;

  const _AnimatedInventoryCard({
    super.key,
    required this.docId,
    required this.data,
    required this.dateStr,
  });

  @override
  State<_AnimatedInventoryCard> createState() => _AnimatedInventoryCardState();
}

class _AnimatedInventoryCardState extends State<_AnimatedInventoryCard>
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

  Future<void> _animateThenDelete() async {
    await _controller.forward();
    await FirebaseFirestore.instance
        .collection('checkin_logs')
        .doc(widget.docId)
        .delete();
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

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Order'),
        content: Text('Are you sure you want to delete "${widget.data['productName'] ?? 'this order'}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _animateThenDelete();
              if (mounted) {
                _showSnack(
                  '"${widget.data['productName'] ?? 'Order'}" deleted.',
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
    final productCtrl = TextEditingController(text: widget.data['productName'] ?? '');
    final noteCtrl = TextEditingController(text: widget.data['note'] ?? '');
    final createdByCtrl = TextEditingController(text: widget.data['createdBy'] ?? '');
    final supplierCtrl = TextEditingController(text: widget.data['supplierName'] ?? '');
    String? selectedStatus = widget.data['stockStatus'];
    final List<String> statusOptions = ['In-stock', 'Low stock', 'Out-of-stock'];
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Inventory Order'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _editField(productCtrl, 'Product Name'),
                const SizedBox(height: 10),
                _editField(noteCtrl, 'Note', maxLines: 3),
                const SizedBox(height: 10),
                _editField(createdByCtrl, 'Created By'),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Stock Status',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) => setDialogState(() => selectedStatus = val),
                ),
                const SizedBox(height: 10),
                _editField(supplierCtrl, 'Supplier Name'),
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
                            .collection('checkin_logs')
                            .doc(widget.docId)
                            .update({
                          'productName': productCtrl.text.trim(),
                          'note': noteCtrl.text.trim(),
                          'createdBy': createdByCtrl.text.trim(),
                          'stockStatus': selectedStatus ?? 'In-stock',
                          'supplierName': supplierCtrl.text.trim(),
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) _showSnack('Order updated successfully!', isSuccess: true);
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        if (mounted) _showSnack('Failed to update: $e', isError: true);
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
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(key: ValueKey('save'), 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailDialog() {
    final status = widget.data['stockStatus'] ?? '';
    final statusColor = status == 'In-stock'
        ? Colors.green
        : status == 'Low stock'
            ? Colors.orange
            : Colors.redAccent;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(widget.data['productName'] ?? 'Order Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (status.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                  ),
                ),
              _detailRow('Note', widget.data['note']),
              _detailRow('Created By', widget.data['createdBy']),
              _detailRow('Supplier', widget.data['supplierName']),
              _detailRow('Created At', widget.dateStr),
              if (widget.data['lat'] != null && widget.data['lng'] != null)
                _detailRow('GPS', 'Lat: ${widget.data['lat']},  Lng: ${widget.data['lng']}'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _detailRow(String label, dynamic value) {
    if (value == null || value.toString().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value.toString()),
          ],
        ),
      ),
    );
  }

  TextField _editField(TextEditingController ctrl, String label, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'In-stock':
        return Colors.green;
      case 'Low stock':
        return Colors.orange;
      case 'Out-of-stock':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.data['stockStatus'] ?? '';
    final statusColor = _statusColor(status);

    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            leading: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF1B1B4E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF1B1B4E)),
            ),
            title: Text(
              widget.data['productName'] ?? 'Unnamed',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                if (status.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: statusColor.withOpacity(0.4)),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                if ((widget.data['supplierName'] ?? '').toString().isNotEmpty)
                  Text('Supplier: ${widget.data['supplierName']}',
                      style: const TextStyle(fontSize: 12)),
                Text(
                  'By: ${widget.data['createdBy'] ?? '—'}   •   ${widget.dateStr}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Color(0xFF1B1B4E)),
                  onPressed: _showEditDialog,
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: _confirmDelete,
                  tooltip: 'Delete',
                ),
              ],
            ),
            onTap: _showDetailDialog,
          ),
        ),
      ),
    );
  }
}
