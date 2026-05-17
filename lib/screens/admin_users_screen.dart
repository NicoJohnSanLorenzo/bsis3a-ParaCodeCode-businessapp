import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ── Color Palette ─────────────────────────────────────────────────────────────
class _AppColors {
  static const pastelBlue   = Color(0xFFAEC6E8);
  static const deepBlue     = Color(0xFF3A5A8A);
  static const deepOrange   = Color(0xFFD4845A);
  static const pastelOrange = Color(0xFFFFCBA4);
  static const errorRed     = Color(0xFFE57373);
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

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manage Users',
          style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.3),
        ),
        backgroundColor: _AppColors.deepBlue,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: _kBgGradient),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: _AppColors.deepBlue),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}',
                    style: const TextStyle(color: _AppColors.deepBlue)),
              );
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people_outline,
                        size: 56,
                        color: _AppColors.deepBlue.withOpacity(0.45)),
                    const SizedBox(height: 12),
                    Text(
                      'No users found.',
                      style: TextStyle(
                        color: _AppColors.deepBlue.withOpacity(0.70),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc  = docs[index];
                final data = doc.data() as Map<String, dynamic>;
                return _UserCard(uid: doc.id, data: data);
              },
            );
          },
        ),
      ),
    );
  }
}

// ── User Card ─────────────────────────────────────────────────────────────────
class _UserCard extends StatelessWidget {
  final String uid;
  final Map<String, dynamic> data;

  const _UserCard({required this.uid, required this.data});

  Future<void> _changeRole(BuildContext context, String newRole) async {
    // ── Prevent admin from changing their own role ──────────────────────────
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && currentUser.uid == uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('You cannot change your own role.'),
            ],
          ),
          backgroundColor: _AppColors.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    // ── Proceed with role update ────────────────────────────────────────────
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'role': newRole});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('Role updated to $newRole'),
              ],
            ),
            backgroundColor: _AppColors.deepBlue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: _AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final email       = data['email'] ?? 'Unknown';
    final role        = data['role'] ?? 'staff';
    final initials    = email.isNotEmpty ? email[0].toUpperCase() : '?';
    final isAdmin     = role == 'admin';
    final isCurrentUser = currentUser?.uid == uid;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: isAdmin ? _AppColors.deepBlue : _AppColors.pastelOrange,
            width: 4,
          ),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // ── Avatar ───────────────────────────────────────────────────────
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isAdmin
                    ? _AppColors.deepBlue.withOpacity(0.12)
                    : _AppColors.pastelOrange.withOpacity(0.40),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isAdmin
                      ? _AppColors.deepBlue.withOpacity(0.30)
                      : _AppColors.deepOrange.withOpacity(0.30),
                ),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isAdmin
                        ? _AppColors.deepBlue
                        : _AppColors.deepOrange,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // ── Email + role badge ────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          email,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _AppColors.deepBlue,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // ── "You" badge for current user ──────────────────────
                      if (isCurrentUser) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: _AppColors.deepBlue.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'You',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _AppColors.deepBlue,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isAdmin
                          ? _AppColors.deepBlue.withOpacity(0.10)
                          : _AppColors.pastelOrange.withOpacity(0.40),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isAdmin ? 'Admin' : 'Staff',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isAdmin
                            ? _AppColors.deepBlue
                            : _AppColors.deepOrange,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Role dropdown (disabled for current user) ─────────────────
            isCurrentUser
                ? Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(Icons.lock_outline,
                        size: 18,
                        color: _AppColors.deepBlue.withOpacity(0.40)),
                  )
                : DropdownButton<String>(
                    value: role,
                    underline: const SizedBox(),
                    icon: Icon(Icons.expand_more,
                        color: _AppColors.deepBlue, size: 18),
                    style: const TextStyle(
                      fontSize: 13,
                      color: _AppColors.deepBlue,
                      fontWeight: FontWeight.w500,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      DropdownMenuItem(value: 'staff', child: Text('Staff')),
                    ],
                    onChanged: (newRole) {
                      if (newRole != null && newRole != role) {
                        _changeRole(context, newRole);
                      }
                    },
                  ),
          ],
        ),
      ),
    );
  }
}