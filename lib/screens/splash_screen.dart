import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'auth/login_screen.dart';
import 'main_navigation_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    
    Future.delayed(const Duration(milliseconds: 500), () {
      _controller.forward();
    });
    
    Future.delayed(const Duration(milliseconds: 3000), () {
      _checkAuthAndNavigate();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryTeal,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.translate,
                size: 80,
                color: AppColors.primaryTeal,
              ),
            )
            .animate(controller: _controller)
            .scale(
              begin: const Offset(0, 0),
              end: const Offset(1, 1),
              duration: 800.ms,
              curve: Curves.elasticOut,
            )
            .then()
            .shimmer(duration: 1200.ms),
            
            const SizedBox(height: 40),
            
            Text(
              'Soma',
              style: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 4,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            )
            .animate(controller: _controller)
            .fadeIn(delay: 600.ms)
            .slideY(begin: 0.3, end: 0, delay: 600.ms),
            
            const SizedBox(height: 16),
            
            Text(
              'Master Languages Through Play',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withValues(alpha: 0.9),
                letterSpacing: 1,
              ),
            )
            .animate(controller: _controller)
            .fadeIn(delay: 900.ms),
          ],
        ),
      ),
    );
  }

  void _checkAuthAndNavigate() {
    final authProvider = context.read<AuthProvider>();
    
    if (authProvider.isAuthenticated || authProvider.isGuest) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainNavigationScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const LoginScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

