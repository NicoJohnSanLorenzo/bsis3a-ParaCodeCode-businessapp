import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './landing_screen.dart';
import './log_list_screen.dart';
import './customer_screen.dart';

// ── Pastel Palette ────────────────────────────────────────────────────────────
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
  static const lowStock       = Color(0xFFCB9A50);
  static const outOfStock     = Color(0xFFCC6666);
  static const avatarGlass    = Color(0x88FFCBA4);
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

// ── Dashboard Screen ──────────────────────────────────────────────────────────
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const _SimpleAppBar(),
      drawer: const _SimpleDrawer(),
      body: Container(
        decoration: const BoxDecoration(gradient: kBgGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: const [
              _SimpleGreeting(),
              SizedBox(height: 20),
              _SimpleSectionTitle(
                icon: Icons.shopping_bag_outlined,
                label: 'Customer Orders',
              ),
              SizedBox(height: 10),
              _CustomerOrdersStream(),
              SizedBox(height: 26),
              _SimpleSectionTitle(
                icon: Icons.inventory_2_outlined,
                label: 'Inventory',
              ),
              SizedBox(height: 10),
              _InventoryStream(),
              SizedBox(height: 30),
              _SimpleLogoutButton(),
            ],
          ),
        ),
      ),
    );
  }
}

// Separate stream builders
class _CustomerOrdersStream extends StatelessWidget {
  const _CustomerOrdersStream();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('customer_orders')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SimpleScorecardsShimmer();
        }
        
        if (snapshot.hasError) {
          return _SimpleErrorCard(message: 'Error loading orders: ${snapshot.error}');
        }
        
        final docs = snapshot.data?.docs ?? [];
        final total = docs.length;
        
        if (total == 0) {
          return const _SimpleEmptyStateCard(
            message: 'No customer orders yet',
            icon: Icons.shopping_bag_outlined,
          );
        }
        
        final processing = docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          return data['orderStatus'] == 'Processing';
        }).length;
        
        final shipped = docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          return data['orderStatus'] == 'Shipped';
        }).length;
        
        final delivered = docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          return data['orderStatus'] == 'Delivered';
        }).length;

        return Column(
          children: [
            _SimpleScorecard(
              label: 'Total Customer Orders',
              count: total,
              icon: Icons.receipt_long_outlined,
              accentColor: AppColors.deepBlue,
              fullWidth: true,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _SimpleScorecard(
                  label: 'Processing',
                  count: processing,
                  icon: Icons.hourglass_empty,
                  accentColor: AppColors.processing,
                )),
                const SizedBox(width: 8),
                Expanded(child: _SimpleScorecard(
                  label: 'Shipped',
                  count: shipped,
                  icon: Icons.local_shipping_outlined,
                  accentColor: AppColors.shipped,
                )),
                const SizedBox(width: 8),
                Expanded(child: _SimpleScorecard(
                  label: 'Delivered',
                  count: delivered,
                  icon: Icons.check_circle_outline,
                  accentColor: AppColors.delivered,
                )),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _InventoryStream extends StatelessWidget {
  const _InventoryStream();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('checkin_logs')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.deepBlue),
          );
        }
        
        if (snapshot.hasError) {
          return _SimpleErrorCard(message: 'Error loading inventory: ${snapshot.error}');
        }
        
        final docs = snapshot.data?.docs ?? [];
        
        if (docs.isEmpty) {
          return const _SimpleEmptyStateCard(
            message: 'No inventory items found',
            icon: Icons.inventory_2_outlined,
          );
        }
        
        final lowStock = docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          final status = data['stockStatus'];
          return status == 'Low stock' || status == 'Low Stock';
        }).toList();
        
        final outOfStock = docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          final status = data['stockStatus'];
          return status == 'Out-of-stock' || status == 'Out of stock';
        }).toList();

        if (lowStock.isEmpty && outOfStock.isEmpty) {
          return const _SimpleInventoryAllGoodCard();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (lowStock.isNotEmpty) ...[
              _SimpleInventoryGroupHeader(
                label: 'Low Stock',
                count: lowStock.length,
                color: AppColors.lowStock,
                icon: Icons.warning_amber_rounded,
              ),
              const SizedBox(height: 8),
              ...lowStock.map((doc) => _SimpleInventoryRow(
                    data: doc.data() as Map<String, dynamic>,
                    statusColor: AppColors.lowStock,
                  )),
              const SizedBox(height: 14),
            ],
            if (outOfStock.isNotEmpty) ...[
              _SimpleInventoryGroupHeader(
                label: 'Out-of-Stock',
                count: outOfStock.length,
                color: AppColors.outOfStock,
                icon: Icons.remove_shopping_cart_outlined,
              ),
              const SizedBox(height: 8),
              ...outOfStock.map((doc) => _SimpleInventoryRow(
                    data: doc.data() as Map<String, dynamic>,
                    statusColor: AppColors.outOfStock,
                  )),
            ],
          ],
        );
      },
    );
  }
}

// ── Simple App Bar ────────────────────────────────────────────────
class _SimpleAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _SimpleAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.deepBlue,
      foregroundColor: Colors.white,
      automaticallyImplyLeading: false,
      elevation: 2,
      title: const Text(
        'Dashboard',
        style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.3),
      ),
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      actions: [
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_outlined),
              onPressed: () {},
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.pastelOrange,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Simple Drawer (Fixed - Logo only, white background) ─────────────────────────────────────────────────
class _SimpleDrawer extends StatelessWidget {
  const _SimpleDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(gradient: kBgGradient),
        child: Column(
          children: [
            // Header - Only Logo with white background
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 52, 18, 20),
              decoration: const BoxDecoration(
                color: AppColors.deepBlue,
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.asset(
                    'assets/images/markify_logo.png',
                    width: 100,
                    height: 50,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => 
                      const Icon(Icons.store, size: 50, color: AppColors.deepBlue),
                  ),
                ),
              ),
            ),

            // Menu items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _SimpleDrawerItem(
                    icon: Icons.dashboard_outlined,
                    label: 'Dashboard',
                    subtitle: 'Overview & alerts',
                    isActive: true,
                    onTap: () => Navigator.pop(context),
                  ),
                  _SimpleDrawerItem(
                    icon: Icons.people_alt_outlined,
                    label: 'Customer',
                    subtitle: 'Manage customers',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const CustomerScreen()));
                    },
                  ),
                  _SimpleDrawerItem(
                    icon: Icons.inventory_2_outlined,
                    label: 'Inventory',
                    subtitle: 'Stock & products',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const LogListScreen()));
                    },
                  ),
                ],
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.30),
                border: const Border(
                  top: BorderSide(color: Colors.white54),
                ),
              ),
              child: const Row(
                children: [
                  _SimpleAvatarIcon(),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Juan Dela Cruz',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.deepBlue,
                        ),
                      ),
                      Text(
                        'Store Admin',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.deepBlue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Simple Drawer Item ───────────────────────────────────────────────────────
class _SimpleDrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isActive;
  final VoidCallback onTap;

  const _SimpleDrawerItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.pastelBlue.withOpacity(0.5)
              : Colors.transparent,
          border: const Border(
            bottom: BorderSide(color: Colors.white30),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.pastelBlue.withOpacity(0.55)
                    : Colors.white.withOpacity(0.35),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: Colors.white.withOpacity(0.55)),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isActive
                    ? AppColors.deepBlue
                    : AppColors.deepBlue.withOpacity(0.65),
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.deepBlue,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.deepBlue.withOpacity(0.60),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SimpleAvatarIcon extends StatelessWidget {
  const _SimpleAvatarIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.avatarGlass,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.6)),
      ),
      child: const Center(
        child: Text(
          'JD',
          style: TextStyle(
            color: AppColors.deepOrange,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ── Simple Greeting ──────────────────────────────────────────────────────────
class _SimpleGreeting extends StatelessWidget {
  const _SimpleGreeting();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hello, Juan 👋',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppColors.deepBlue,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          "Here's what's happening today",
          style: TextStyle(
            fontSize: 14,
            color: AppColors.deepBlue.withOpacity(0.65),
          ),
        ),
      ],
    );
  }
}

// ── Simple Section Title ─────────────────────────────────────────────────────
class _SimpleSectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SimpleSectionTitle({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.80),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: Colors.white),
          ),
          child: Icon(icon, size: 14, color: AppColors.deepBlue),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.deepBlue,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Divider(color: Colors.white.withOpacity(0.80)),
        ),
      ],
    );
  }
}

// ── Simple Scorecard ─────────────────────────────────────────────────────────
class _SimpleScorecard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color accentColor;
  final bool fullWidth;

  const _SimpleScorecard({
    required this.label,
    required this.count,
    required this.icon,
    required this.accentColor,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: fullWidth ? 16 : 10,
        vertical: fullWidth ? 14 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: fullWidth
          ? Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: accentColor.withOpacity(0.25)),
                  ),
                  child: Icon(icon, color: accentColor, size: 22),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.deepBlue.withOpacity(0.80),
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
                Icon(icon, color: accentColor, size: 18),
                const SizedBox(height: 6),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.deepBlue.withOpacity(0.80),
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

// ── Simple Scorecards Shimmer ────────────────────────────────────────────────
class _SimpleScorecardsShimmer extends StatelessWidget {
  const _SimpleScorecardsShimmer();

  Widget _shimmer() => Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.80),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 72, child: _shimmer()),
        const SizedBox(height: 8),
        Row(
          children: List.generate(3, (i) {
            return Expanded(
              child: Container(
                height: 80,
                margin: EdgeInsets.only(left: i > 0 ? 8 : 0),
                child: _shimmer(),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ── Simple Inventory Group Header ───────────────────────────────────────────
class _SimpleInventoryGroupHeader extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _SimpleInventoryGroupHeader({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.35)),
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
        Expanded(
            child: Divider(color: Colors.white.withOpacity(0.80))),
      ],
    );
  }
}

// ── Simple Inventory Row ─────────────────────────────────────────────────────
class _SimpleInventoryRow extends StatelessWidget {
  final Map<String, dynamic> data;
  final Color statusColor;

  const _SimpleInventoryRow({
    required this.data,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final productName = data['productName'] ?? 'Unnamed Product';
    final status = data['stockStatus'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor.withOpacity(0.30)),
            ),
            child: Icon(Icons.inventory_2_outlined,
                color: statusColor, size: 15),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              productName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.deepBlue,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withOpacity(0.30)),
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

// ── Simple Inventory All Good Card ───────────────────────────────────────────
class _SimpleInventoryAllGoodCard extends StatelessWidget {
  const _SimpleInventoryAllGoodCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_outline,
              color: AppColors.delivered, size: 26),
          SizedBox(width: 12),
          Text(
            'All products are sufficiently stocked.',
            style: TextStyle(
              color: AppColors.delivered,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Simple Empty State Card ──────────────────────────────────────────────────
class _SimpleEmptyStateCard extends StatelessWidget {
  final String message;
  final IconData icon;

  const _SimpleEmptyStateCard({
    required this.message,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.deepBlue.withOpacity(0.5), size: 48),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              color: AppColors.deepBlue.withOpacity(0.7),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add data to get started',
            style: TextStyle(
              color: AppColors.deepBlue.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Simple Error Card ────────────────────────────────────────────────────────
class _SimpleErrorCard extends StatelessWidget {
  final String message;

  const _SimpleErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outOfStock.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.outOfStock),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppColors.deepBlue,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Simple Logout Button ─────────────────────────────────────────────────────
class _SimpleLogoutButton extends StatelessWidget {
  const _SimpleLogoutButton();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LandingScreen()),
        (route) => false,
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.pastelOrange,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white, width: 1.2),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: AppColors.deepOrange, size: 18),
            SizedBox(width: 8),
            Text(
              'Logout',
              style: TextStyle(
                color: AppColors.deepOrange,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}