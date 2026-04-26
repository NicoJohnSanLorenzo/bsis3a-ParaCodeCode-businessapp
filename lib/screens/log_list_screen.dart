import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LogListScreen extends StatelessWidget {
  const LogListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log List'),
        backgroundColor: const Color(0xFF1B1B4E),
        foregroundColor: Colors.white,
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
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No check-in logs yet.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final ts = data['createdAt'] as Timestamp?;
              final dateStr = ts != null
                  ? '${ts.toDate().toLocal()}'.split('.')[0]
                  : 'No date';

              return _AnimatedLogCard(
                key: ValueKey(doc.id),
                docId: doc.id,
                data: data,
                dateStr: dateStr,
              );
            },
          );
        },
      ),
    );
  }
}

// ── Animated card wrapper ──────────────────────────────────────────────────────

class _AnimatedLogCard extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;
  final String dateStr;

  const _AnimatedLogCard({
    super.key,
    required this.docId,
    required this.data,
    required this.dateStr,
  });

  @override
  State<_AnimatedLogCard> createState() => _AnimatedLogCardState();
}

class _AnimatedLogCardState extends State<_AnimatedLogCard>
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
        title: const Text('Delete Log'),
        content: Text('Are you sure you want to delete "${widget.data['businessName'] ?? 'this log'}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _animateThenDelete();
              if (mounted) {
                _showSnack(
                  '"${widget.data['businessName'] ?? 'Log'}" deleted.',
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
    final businessCtrl = TextEditingController(text: widget.data['businessName'] ?? '');
    final noteCtrl = TextEditingController(text: widget.data['note'] ?? '');
    final createdByCtrl = TextEditingController(text: widget.data['createdBy'] ?? '');
    final stockCtrl = TextEditingController(text: widget.data['stockIssue'] ?? '');
    final supplierCtrl = TextEditingController(text: widget.data['supplierName'] ?? '');
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Log'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _editField(businessCtrl, 'Business Name'),
                const SizedBox(height: 10),
                _editField(noteCtrl, 'Note', maxLines: 3),
                const SizedBox(height: 10),
                _editField(createdByCtrl, 'Created By'),
                const SizedBox(height: 10),
                _editField(stockCtrl, 'Stock Issue'),
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
                          'businessName': businessCtrl.text.trim(),
                          'note': noteCtrl.text.trim(),
                          'createdBy': createdByCtrl.text.trim(),
                          'stockIssue': stockCtrl.text.trim(),
                          'supplierName': supplierCtrl.text.trim(),
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) _showSnack('Log updated successfully!', isSuccess: true);
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(widget.data['businessName'] ?? 'Log Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if ((widget.data['photoUrl'] ?? '').toString().isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(widget.data['photoUrl'], fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox()),
                ),
                const SizedBox(height: 10),
              ],
              _detailRow('Note', widget.data['note']),
              _detailRow('Created By', widget.data['createdBy']),
              _detailRow('Supplier', widget.data['supplierName']),
              _detailRow('Stock Issue', widget.data['stockIssue']),
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

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            leading: widget.data['photoUrl'] != null &&
                    widget.data['photoUrl'].toString().isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.data['photoUrl'],
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.image_not_supported, size: 40),
                    ),
                  )
                : Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B1B4E).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.store, color: Color(0xFF1B1B4E)),
                  ),
            title: Text(
              widget.data['businessName'] ?? 'Unnamed',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                if ((widget.data['supplierName'] ?? '').toString().isNotEmpty)
                  Text('Supplier: ${widget.data['supplierName']}',
                      style: const TextStyle(fontSize: 12)),
                if ((widget.data['stockIssue'] ?? '').toString().isNotEmpty)
                  Text('Stock Issue: ${widget.data['stockIssue']}',
                      style: const TextStyle(fontSize: 12, color: Colors.orange)),
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