import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../services/local_database_service.dart';
import 'onboarding_screen.dart';
import 'auth/login_screen.dart';

/// Welcome screen matching the design with fridge illustration
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimationSequence();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
  }

  void _startAnimationSequence() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _animationController.forward();
    
    await Future.delayed(const Duration(milliseconds: 3000));
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() async {
    final isFirstLaunch = LocalDatabaseService.isFirstLaunch;
    final currentUser = LocalDatabaseService.getCurrentUser();

    if (mounted) {
      if (isFirstLaunch) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const OnboardingScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      } else if (currentUser == null) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const LoginScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      } else {
        // Navigate to main app (will be implemented later)
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const LoginScreen(), // Temporary - will be main app
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pureWhite,
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingXL),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Fridge Illustration
                      Container(
                        width: 280,
                        height: 320,
                        decoration: BoxDecoration(
                          color: AppTheme.lightGray,
                          borderRadius: BorderRadius.circular(AppTheme.radiusL),
                          border: Border.all(
                            color: AppTheme.mediumGray,
                            width: 2,
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Fridge Frame
                            Container(
                              margin: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.pureWhite,
                                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // Top Shelf
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      child: Row(
                                        children: [
                                          _buildFridgeItem(Colors.red, Icons.apple),
                                          const SizedBox(width: 4),
                                          _buildFridgeItem(Colors.orange, Icons.circle),
                                          const SizedBox(width: 4),
                                          _buildFridgeItem(Colors.green, Icons.eco),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Middle Shelf
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      child: Row(
                                        children: [
                                          _buildFridgeItem(Colors.purple, Icons.circle),
                                          const SizedBox(width: 4),
                                          _buildFridgeItem(Colors.blue, Icons.water_drop),
                                          const SizedBox(width: 4),
                                          _buildFridgeItem(Colors.yellow, Icons.circle),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Bottom Shelf
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      child: Row(
                                        children: [
                                          _buildFridgeItem(Colors.green, Icons.eco),
                                          const SizedBox(width: 4),
                                          _buildFridgeItem(Colors.red, Icons.favorite),
                                          const SizedBox(width: 4),
                                          _buildFridgeItem(Colors.orange, Icons.circle),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Fridge Handle
                            Positioned(
                              right: 8,
                              top: 60,
                              child: Container(
                                width: 6,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppTheme.mediumGray,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppTheme.spacingXL),

                      // App Logo - Enhanced
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: AppTheme.pureWhite,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                          border: Border.all(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                            width: 3,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/logos/stayfresh.png',
                              width: 120,
                              height: 120,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.eco,
                                    size: 60,
                                    color: AppTheme.primaryGreen,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppTheme.spacingL),

                      // Welcome Text
                      Text(
                        'Welcome to StayFresh',
                        style: AppTheme.headingLarge.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textDark,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: AppTheme.spacingM),

                      Text(
                        'Track your groceries, manage expiry dates, and reduce food waste with our smart grocery management system.',
                        style: AppTheme.bodyLarge.copyWith(
                          color: AppTheme.textMedium,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: AppTheme.spacingXXL),

                      // Get Started Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            _navigateToNextScreen();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: AppTheme.pureWhite,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusM),
                            ),
                          ),
                          child: Text(
                            'Get Started',
                            style: AppTheme.buttonText.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFridgeItem(Color color, IconData icon) {
    return Expanded(
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: color,
          size: 20,
        ),
      ),
    );
  }
}