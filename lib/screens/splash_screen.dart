import 'package:flutter/material.dart';
import 'registration_flow_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.8, curve: Curves.elasticOut)),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF7D108), // Zoodo Yellow background
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(),
                      // Zoodo style yellow/green brand logo circle
                      Center(
                        child: Container(
                          height: 150,
                          width: 150,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 25,
                                offset: const Offset(0, 8),
                              )
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: 110,
                              height: 110,
                              decoration: const BoxDecoration(
                                color: Color(0xFF0C831F), // Brand Green
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.flash_on_rounded,
                                  color: Color(0xFFF7D108), // Brand Yellow
                                  size: 64,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Logo Text
                      const Text(
                        'zoodo',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF122E1A), // Dark Forest Green
                          fontWeight: FontWeight.w900,
                          fontSize: 48,
                          letterSpacing: -1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Super-fast 10 minute delivery of\ngroceries, fresh food, and daily essentials.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF084335), // Dark green text
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                        ),
                      ),
                      const Spacer(),
                      // Start Journey button (Zoodo Green)
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const RegistrationFlowScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0C831F), // Zoodo Green
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          shadowColor: const Color(0xFF0C831F).withValues(alpha: 0.3),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Start Journey',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, color: Colors.white),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Already have an account login button
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF1E293B),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(color: Color(0xFF084335), fontSize: 14),
                            children: [
                              TextSpan(text: 'Already registered? '),
                              TextSpan(
                                text: 'Login here',
                                style: TextStyle(
                                  color: Color(0xFF0C831F), // Zoodo Green link
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
