import 'dart:ui';
import 'package:flutter/material.dart';
import './register_screen.dart';
import './login_screen.dart';

// ── Pastel Palette ────────────────────────────────────────────────────────────
class _AppColors {
  static const pastelBlue   = Color(0xFFAEC6E8); // Soft blue
  static const pastelOrange = Color(0xFFFFCBA4); // Soft orange
  static const pastelPeach  = Color(0xFFFFE5CC); // Light peach
  static const deepBlue     = Color(0xFF3A5A8A); // Muted dark blue (text)
  static const deepOrange   = Color(0xFFD4845A); // Muted orange (text)
  static const glassWhite   = Color(0x55FFFFFF);
}

const _kBgGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  stops: [0.0, 0.40, 0.75, 1.0],
  colors: [
    Color(0xFFDCEAF7), // Pastel blue top-left
    Color(0xFFEAD5F0), // Pastel lavender mid
    Color(0xFFFFE5CC), // Pastel peach mid
    Color(0xFFFFD6B0), // Warm pastel orange bottom-right
  ],
);

// ── Landing Screen ────────────────────────────────────────────────────────────
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

                  // ── Brand Logo ─────────────────────────────────────────
                  Image.asset(
                    'assets/images/markify_logo.png',
                    width: 360,
                    height: 360,
                    fit: BoxFit.contain,
                  ),

                  const SizedBox(height: 40),

                  // ── Glass card container ───────────────────────────────
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 32),
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
                            Text(
                              'Welcome back 👋',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: _AppColors.deepBlue,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Sign in to continue or create a new account',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: _AppColors.deepBlue.withOpacity(0.65),
                              ),
                            ),
                            const SizedBox(height: 28),

                            // ── Login button (Pastel Blue) ─────────────
                            _GlassButton(
                              label: 'Login',
                              icon: Icons.login_rounded,
                              glassColor: _AppColors.pastelBlue.withOpacity(0.85),
                              borderColor: Colors.white.withOpacity(0.60),
                              textColor: _AppColors.deepBlue,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const LoginScreen()),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // ── Register button (Pastel Orange) ───────
                            _GlassButton(
                              label: 'Register',
                              icon: Icons.person_add_alt_1_outlined,
                              glassColor: _AppColors.pastelOrange.withOpacity(0.85),
                              borderColor: Colors.white.withOpacity(0.60),
                              textColor: _AppColors.deepOrange,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const RegisterScreen()),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Footer ─────────────────────────────────────────────
                  Text(
                    '© 2026 Markify. All rights reserved.',
                    style: TextStyle(
                      fontSize: 10,
                      color: _AppColors.deepBlue.withOpacity(0.40),
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

// ── Glass Button ──────────────────────────────────────────────────────────────
class _GlassButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color glassColor;
  final Color borderColor;
  final Color textColor;
  final VoidCallback onTap;

  const _GlassButton({
    required this.label,
    required this.icon,
    required this.glassColor,
    required this.borderColor,
    required this.textColor,
    required this.onTap,
  });

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
              color: glassColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: 1.2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: textColor, size: 18),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: textColor,
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
    );
  }
}