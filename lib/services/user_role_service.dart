import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum AppRole { admin, staff, unknown }

class UserRoleService {
  static Future<AppRole> getCurrentRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return AppRole.unknown;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final role = doc.data()?['role'] ?? 'staff';
    return role == 'admin' ? AppRole.admin : AppRole.staff;
  }
}