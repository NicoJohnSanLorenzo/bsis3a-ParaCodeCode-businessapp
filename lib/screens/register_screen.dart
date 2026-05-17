import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ── Pastel Palette (same as Landing & Login Screen) ───────────────────────────
class _AppColors {
  static const pastelBlue   = Color(0xFFAEC6E8);
  static const pastelOrange = Color(0xFFFFCBA4);
  static const pastelPeach  = Color(0xFFFFE5CC);
  static const deepBlue     = Color(0xFF3A5A8A);
  static const deepOrange   = Color(0xFFD4845A);
  static const glassWhite   = Color(0x55FFFFFF);
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

// ── Register Screen ───────────────────────────────────────────────────────────
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController emailController    = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController  = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm  = true;
  bool _isLoading       = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  Future<void> submitRegister() async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty ||
        confirmController.text.isEmpty) {
      _showSnack('Please fill in all fields.', isError: true);
      return;
    }
    if (passwordController.text != confirmController.text) {
      _showSnack('Passwords do not match.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      // ── RBAC: Save user profile with default 'staff' role ──────────────
      final user = FirebaseAuth.instance.currentUser!;
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': user.email,
        'role': 'staff', // Default role. Promote to 'admin' via Firebase Console.
        'createdAt': FieldValue.serverTimestamp(),
      });

      emailController.clear();
      passwordController.clear();
      confirmController.clear();

      if (!mounted) return;
      _showSnack('Account created successfully!');
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException code: ${e.code}');
      final message = switch (e.code) {
        'weak-password'        => 'Password is too weak. Use at least 6 characters.',
        'email-already-in-use' => 'This email is already in use.',
        _                      => 'Registration failed. Please try again.',
      };
      if (mounted) _showSnack(message, isError: true);
    } catch (e) {
      debugPrint(e.toString());
      if (mounted) _showSnack('Something went wrong.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: isError
            ? _AppColors.errorRed
            : _AppColors.deepBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: _kBgGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [

                  const SizedBox(height: 20),

                  // ── Brand Logo ───────────────────────────────────────
                  Image.asset(
                    'assets/images/Markify_Logo.png',
                    width: 160,
                    height: 160,
                    fit: BoxFit.contain,
                  ),

                  const SizedBox(height: 16),

                  // ── Title ────────────────────────────────────────────
                  Text(
                    'Create account 🛍️',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: _AppColors.deepBlue,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Sign up to get started',
                    style: TextStyle(
                      fontSize: 13,
                      color: _AppColors.deepBlue.withOpacity(0.65),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Glass card ───────────────────────────────────────
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 28),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.80),
                            width: 1.2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [

                            // Email
                            _GlassField(
                              controller: emailController,
                              label: 'Email address',
                              hint: 'you@email.com',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                            ),

                            const SizedBox(height: 14),

                            // Password
                            _GlassField(
                              controller: passwordController,
                              label: 'Password',
                              hint: '••••••••',
                              icon: Icons.lock_outline,
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: _AppColors.deepBlue,
                                  size: 20,
                                ),
                                onPressed: () => setState(() =>
                                    _obscurePassword = !_obscurePassword),
                              ),
                            ),

                            const SizedBox(height: 14),

                            // Confirm password
                            _GlassField(
                              controller: confirmController,
                              label: 'Confirm password',
                              hint: '••••••••',
                              icon: Icons.lock_outline,
                              obscureText: _obscureConfirm,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: _AppColors.deepBlue,
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Submit button
                            _GlassButton(
                              isLoading: _isLoading,
                              onTap: _isLoading ? null : submitRegister,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Back link ────────────────────────────────────────
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      '← Back to Welcome',
                      style: TextStyle(
                        fontSize: 13,
                        color: _AppColors.deepBlue.withOpacity(0.70),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Glass Text Field ──────────────────────────────────────────────────────────
class _GlassField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? suffixIcon;

  const _GlassField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _AppColors.deepBlue,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: TextStyle(
            color: _AppColors.deepBlue,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: _AppColors.deepBlue.withOpacity(0.45),
              fontSize: 13,
            ),
            prefixIcon: Icon(icon,
                color: _AppColors.pastelBlue, size: 18),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white.withOpacity(0.50),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.65)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: _AppColors.pastelBlue.withOpacity(0.50)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: _AppColors.deepBlue, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Glass Submit Button ───────────────────────────────────────────────────────
class _GlassButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool isLoading;

  const _GlassButton({required this.onTap, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: _AppColors.pastelOrange.withOpacity(0.85),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: Colors.white.withOpacity(0.60), width: 1.2),
            ),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: _AppColors.deepOrange,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_add_alt_1_outlined,
                            color: _AppColors.deepOrange, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          'Create account',
                          style: TextStyle(
                            color: _AppColors.deepOrange,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}