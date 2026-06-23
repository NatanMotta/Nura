import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../auth/presentation/auth_providers.dart';
import 'role_gate.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // Wait for a brief moment to show the splash
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (!mounted) return;
    
    // We navigate to RoleGate immediately. 
    // RoleGate will wait for authStateProvider to resolve.
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const RoleGate(
          vibe: NuraVibe.premium,
          accent: NuraBrand.pink,
          waveform: 'assets/animations/wave_chill.json',
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: NuraBrand.pink.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.headphones,
                  size: 50,
                  color: NuraBrand.pink,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'NURA',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Elevate your sound.',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 16,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
