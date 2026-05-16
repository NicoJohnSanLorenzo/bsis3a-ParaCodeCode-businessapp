import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './create_checkin_screen.dart';

// Your color palette - matching all screens
class AppColors {
  static const pastelBlue     = Color(0xFFAEC6E8);
  static const pastelOrange   = Color(0xFFFFCBA4);
  static const pastelPeach    = Color(0xFFFFE5CC);
  static const pastelLavender = Color(0xFFEAD5F0);
  static const deepBlue       = Color(0xFF3A5A8A);
  static const deepOrange     = Color(0xFFD4845A);
  static const inStock        = Color(0xFF5A8A6A);
  static const lowStock       = Color(0xFFCB9A50);
  static const outOfStock     = Color(0xFFCC6666);
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

class LogListScreen extends StatelessWidget {
  const LogListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Inventory',
          style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.3),
        ),
        backgroundColor: AppColors.deepBlue,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateCheckinScreen()),
        ),
        child: const Icon(Icons.add),
        backgroundColor: AppColors.pastelBlue,
        foregroundColor: AppColors.deepBlue,
        elevation: 2,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: kBgGradient),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('checkin_logs')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.deepBlue),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}', 
                  style: TextStyle(color: AppColors.deepBlue)),
              );
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return const _EmptyState();
            }

            // Separate by status
            final lowStock = docs.where((d) => 
              (d.data() as Map)['stockStatus'] == 'Low stock').toList();
            final outOfStock = docs.where((d) => 
              (d.data() as Map)['stockStatus'] == 'Out-of-stock').toList();
            final inStock = docs.where((d) => 
              (d.data() as Map)['stockStatus'] == 'In-stock').toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              children: [
                // Low Stock Section
                if (lowStock.isNotEmpty) ...[
                  _SectionHeader(
                    label: 'Low Stock',
                    count: lowStock.length,
                    color: AppColors.lowStock,
                    icon: Icons.warning_amber_outlined,
                  ),
                  const SizedBox(height: 8),
                  ...lowStock.map((doc) => _InventoryCard(doc: doc, statusColor: AppColors.lowStock)),
                  const SizedBox(height: 16),
                ],
                
                // Out of Stock Section
                if (outOfStock.isNotEmpty) ...[
                  _SectionHeader(
                    label: 'Out-of-stock',
                    count: outOfStock.length,
                    color: AppColors.outOfStock,
                    icon: Icons.cancel_outlined,
                  ),
                  const SizedBox(height: 8),
                  ...outOfStock.map((doc) => _InventoryCard(doc: doc, statusColor: AppColors.outOfStock)),
                  const SizedBox(height: 16),
                ],
                
                // In Stock Section
                if (inStock.isNotEmpty) ...[
                  _SectionHeader(
                    label: 'In-stock',
                    count: inStock.length,
                    color: AppColors.inStock,
                    icon: Icons.check_circle_outline,
                  ),
                  const SizedBox(height: 8),
                  ...inStock.map((doc) => _InventoryCard(doc: doc, statusColor: AppColors.inStock)),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

// Section Header with icon and count
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
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 8),
          Text(
            label,
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
        ],
      ),
    );
  }
}

// Empty State
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 56, color: AppColors.deepBlue.withOpacity(0.45)),
            const SizedBox(height: 14),
            Text(
              'No inventory items yet.',
              style: TextStyle(
                color: AppColors.deepBlue.withOpacity(0.70),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add inventory',
              style: TextStyle(
                color: AppColors.deepBlue.withOpacity(0.50),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Inventory Card - matching customer screen design with Proof Label
class _InventoryCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final Color statusColor;

  const _InventoryCard({required this.doc, required this.statusColor});

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'No date';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.month}/${date.day}/${date.year}';
    }
    return timestamp.toString();
  }

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final dateStr = _formatDate(data['createdAt']);
    final status = data['stockStatus'] ?? 'Unknown';
    final proofLabel = data['proofLabel'] ?? '';
    final groupName = data['groupName'] ?? '';
    final businessType = data['businessType'] ?? '';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: statusColor, width: 4),
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
            // Row with product name and status
            Row(
              children: [
                Expanded(
                  child: Text(
                    data['productName'] ?? 'Unnamed Product',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.deepBlue,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getStatusIcon(status), size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            
            // Proof Label Section (NEW - prominently displayed)
            if (proofLabel.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.pastelBlue.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.deepBlue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.verified_outlined, size: 14, color: AppColors.deepBlue),
                    const SizedBox(width: 6),
                    const Text(
                      'Proof: ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.deepBlue,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        proofLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.deepBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            
            // Info rows
            _buildInfoRow(Icons.local_shipping_outlined, 'Supplier: ${data['supplierName'] ?? 'Not specified'}'),
            _buildInfoRow(Icons.person_outline, 'Created by: ${data['createdBy'] ?? 'Unknown'}'),
            _buildInfoRow(Icons.calendar_today, 'Date: $dateStr'),
            if (data['note'] != null && data['note'].toString().isNotEmpty)
              _buildInfoRow(Icons.notes, 'Note: ${data['note']}'),
            if (data['lat'] != null && data['lng'] != null)
              _buildInfoRow(Icons.location_on_outlined, 'Location captured'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    if (text.isEmpty || text.contains('Not specified') && text != 'Supplier: Not specified') 
      return const SizedBox.shrink();
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

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'In-stock':
        return Icons.check_circle_outline;
      case 'Low stock':
        return Icons.warning_amber_outlined;
      case 'Out-of-stock':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }
}