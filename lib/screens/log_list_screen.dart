import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './create_checkin_screen.dart';

class _AppColors {
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

const _kBgGradient = LinearGradient(
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

class LogListScreen extends StatefulWidget {
  const LogListScreen({super.key});

  @override
  State<LogListScreen> createState() => _LogListScreenState();
}

class _LogListScreenState extends State<LogListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'All'; // All, In-stock, Low stock, Out-of-stock

  // Initialized at declaration so it's ready before build() ever runs.
  final Stream<QuerySnapshot> _logsStream = FirebaseFirestore.instance
      .collection('checkin_logs')
      .orderBy('createdAt', descending: true)
      .snapshots();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() =>
          _searchQuery = _searchController.text.toLowerCase().trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<QueryDocumentSnapshot> _applyFilters(
      List<QueryDocumentSnapshot> docs) {
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final product  = (data['productName']  ?? '').toString().toLowerCase();
      final supplier = (data['supplierName'] ?? '').toString().toLowerCase();
      final status   = (data['stockStatus']  ?? '').toString();

      final matchesSearch = _searchQuery.isEmpty ||
          product.contains(_searchQuery) ||
          supplier.contains(_searchQuery);
      final matchesStatus =
          _selectedStatus == 'All' || status == _selectedStatus;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Inventory',
            style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.3)),
        backgroundColor: _AppColors.deepBlue,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CreateCheckinScreen())),
        backgroundColor: _AppColors.pastelBlue,
        foregroundColor: _AppColors.deepBlue,
        elevation: 2,
        child: const Icon(Icons.add),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: _kBgGradient),
        child: Column(
          children: [
            // ── Search + Filter lives OUTSIDE StreamBuilder so typing never
            //    causes the widget to be recreated and the keyboard stays open.
            _InventorySearchFilterBar(
              controller: _searchController,
              selectedStatus: _selectedStatus,
              onStatusChanged: (s) => setState(() => _selectedStatus = s),
            ),

            // ── Stream-driven list ────────────────────────────────────────
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _logsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(color: _AppColors.deepBlue));
                  }
                  if (snapshot.hasError) {
                    return Center(
                        child: Text('Error: ${snapshot.error}',
                            style: const TextStyle(color: _AppColors.deepBlue)));
                  }

                  final allDocs = snapshot.data?.docs ?? [];

                  if (allDocs.isEmpty) {
                    return const _EmptyState();
                  }

                  final filtered = _applyFilters(allDocs);

                  final lowStockList = filtered
                      .where((d) => (d.data() as Map)['stockStatus'] == 'Low stock')
                      .toList();
                  final outOfStockList = filtered
                      .where((d) => (d.data() as Map)['stockStatus'] == 'Out-of-stock')
                      .toList();
                  final inStockList = filtered
                      .where((d) => (d.data() as Map)['stockStatus'] == 'In-stock')
                      .toList();

                  return Column(
                    children: [
                      // ── Results count + clear ───────────────────────────
                      if (_searchQuery.isNotEmpty || _selectedStatus != 'All')
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                          child: Row(
                            children: [
                              Icon(Icons.filter_list,
                                  size: 14,
                                  color: _AppColors.deepBlue.withOpacity(0.55)),
                              const SizedBox(width: 6),
                              Text(
                                '${filtered.length} result${filtered.length != 1 ? "s" : ""}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: _AppColors.deepBlue.withOpacity(0.55),
                                    fontWeight: FontWeight.w500),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  setState(() => _selectedStatus = 'All');
                                },
                                child: Text('Clear filters',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: _AppColors.deepOrange,
                                        fontWeight: FontWeight.w500)),
                              ),
                            ],
                          ),
                        ),

                      // ── List ───────────────────────────────────────────
                      Expanded(
                        child: filtered.isEmpty
                            ? _buildNoResults()
                            : ListView(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                                children: [
                                  if ((_selectedStatus == 'All' ||
                                          _selectedStatus == 'Low stock') &&
                                      lowStockList.isNotEmpty) ...[
                                    _SectionHeader(
                                        label: 'Low Stock',
                                        count: lowStockList.length,
                                        color: _AppColors.lowStock,
                                        icon: Icons.warning_amber_outlined),
                                    const SizedBox(height: 8),
                                    ...lowStockList.map((doc) => _InventoryCard(
                                        doc: doc, statusColor: _AppColors.lowStock)),
                                    const SizedBox(height: 16),
                                  ],
                                  if ((_selectedStatus == 'All' ||
                                          _selectedStatus == 'Out-of-stock') &&
                                      outOfStockList.isNotEmpty) ...[
                                    _SectionHeader(
                                        label: 'Out-of-stock',
                                        count: outOfStockList.length,
                                        color: _AppColors.outOfStock,
                                        icon: Icons.cancel_outlined),
                                    const SizedBox(height: 8),
                                    ...outOfStockList.map((doc) => _InventoryCard(
                                        doc: doc, statusColor: _AppColors.outOfStock)),
                                    const SizedBox(height: 16),
                                  ],
                                  if ((_selectedStatus == 'All' ||
                                          _selectedStatus == 'In-stock') &&
                                      inStockList.isNotEmpty) ...[
                                    _SectionHeader(
                                        label: 'In-stock',
                                        count: inStockList.length,
                                        color: _AppColors.inStock,
                                        icon: Icons.check_circle_outline),
                                    const SizedBox(height: 8),
                                    ...inStockList.map((doc) => _InventoryCard(
                                        doc: doc, statusColor: _AppColors.inStock)),
                                  ],
                                ],
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off,
              size: 48, color: _AppColors.deepBlue.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text('No items match your search.',
              style: TextStyle(
                  color: _AppColors.deepBlue.withOpacity(0.6),
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () {
              _searchController.clear();
              setState(() => _selectedStatus = 'All');
            },
            child: Text('Clear filters',
                style: TextStyle(
                    color: _AppColors.deepOrange,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── Inventory Search + Filter Bar ─────────────────────────────────────────────
class _InventorySearchFilterBar extends StatelessWidget {
  final TextEditingController controller;
  final String selectedStatus;
  final ValueChanged<String> onStatusChanged;

  const _InventorySearchFilterBar({
    required this.controller,
    required this.selectedStatus,
    required this.onStatusChanged,
  });

  static const _statuses = [
    'All', 'Low stock', 'Out-of-stock', 'In-stock'
  ];

  static Color _chipColor(String status) {
    switch (status) {
      case 'Low stock':    return _AppColors.lowStock;
      case 'Out-of-stock': return _AppColors.outOfStock;
      case 'In-stock':     return _AppColors.inStock;
      default:             return _AppColors.deepBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search field
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.90),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: _AppColors.pastelBlue.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2))
              ],
            ),
            child: TextField(
              controller: controller,
              style: const TextStyle(
                  fontSize: 14, color: _AppColors.deepBlue),
              decoration: InputDecoration(
                hintText: 'Search by product or supplier name…',
                hintStyle: TextStyle(
                    fontSize: 13,
                    color: _AppColors.deepBlue.withOpacity(0.40)),
                prefixIcon: Icon(Icons.search,
                    color: _AppColors.deepBlue.withOpacity(0.5), size: 20),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear,
                            color: _AppColors.deepBlue.withOpacity(0.5),
                            size: 18),
                        onPressed: () => controller.clear(),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 13),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Status filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statuses.map((s) {
                final isSelected = selectedStatus == s;
                final color = _chipColor(s);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => onStatusChanged(s),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color
                            : Colors.white.withOpacity(0.80),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: isSelected
                                ? color
                                : color.withOpacity(0.35),
                            width: 1.5),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                    color: color.withOpacity(0.25),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2))
                              ]
                            : [],
                      ),
                      child: Text(s,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : color)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────
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
          Text(label,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: color)),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12)),
            child: Text('$count',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color)),
          ),
        ],
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 56,
                color: _AppColors.deepBlue.withOpacity(0.45)),
            const SizedBox(height: 14),
            Text('No inventory items yet.',
                style: TextStyle(
                    color: _AppColors.deepBlue.withOpacity(0.70),
                    fontSize: 15,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text('Tap the + button to add inventory',
                style: TextStyle(
                    color: _AppColors.deepBlue.withOpacity(0.50),
                    fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// ── Inventory Card ────────────────────────────────────────────────────────────
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
    final dateStr    = _formatDate(data['createdAt']);
    final status     = data['stockStatus'] ?? 'Unknown';
    final proofLabel = data['proofLabel']  ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: statusColor, width: 4)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    data['productName'] ?? 'Unnamed Product',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _AppColors.deepBlue),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getStatusIcon(status),
                          size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(status,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusColor)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (proofLabel.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _AppColors.pastelBlue.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: _AppColors.deepBlue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_outlined,
                        size: 14, color: _AppColors.deepBlue),
                    const SizedBox(width: 6),
                    const Text('Proof: ',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _AppColors.deepBlue)),
                    Expanded(
                        child: Text(proofLabel,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _AppColors.deepBlue))),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            _buildInfoRow(Icons.local_shipping_outlined,
                'Supplier: ${data['supplierName'] ?? 'Not specified'}'),
            _buildInfoRow(Icons.person_outline,
                'Created by: ${data['createdBy'] ?? 'Unknown'}'),
            _buildInfoRow(
                Icons.calendar_today, 'Date: $dateStr'),
            if (data['note'] != null &&
                data['note'].toString().isNotEmpty)
              _buildInfoRow(Icons.notes, 'Note: ${data['note']}'),
            if (data['lat'] != null && data['lng'] != null)
              _buildInfoRow(
                  Icons.location_on_outlined, 'Location captured'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: _AppColors.deepBlue.withOpacity(0.6)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: TextStyle(
                      fontSize: 13,
                      color: _AppColors.deepBlue.withOpacity(0.85)))),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'In-stock':    return Icons.check_circle_outline;
      case 'Low stock':   return Icons.warning_amber_outlined;
      case 'Out-of-stock': return Icons.cancel_outlined;
      default:            return Icons.help_outline;
    }
  }
}