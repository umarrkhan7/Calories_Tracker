import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../onboarding_scaffold.dart';
import '../onboarding_controller.dart';
import '../../theme/app_theme.dart';
import 'ob13_calories_burned.dart';

class ThankYouScreen extends StatefulWidget {
  const ThankYouScreen({Key? key}) : super(key: key);
  @override
  State<ThankYouScreen> createState() => ThankYouScreenState();
}

class ThankYouScreenState extends State<ThankYouScreen>
    with TickerProviderStateMixin {

  late AnimationController pulseController;
  late AnimationController fadeController;
  late AnimationController contentController;
  late Animation<double> pulseAnimation;
  late Animation<double> fadeAnimation;
  late Animation<double> contentFade;
  late Animation<Offset> contentSlide;

  @override
  void initState() {
    super.initState();
    fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    fadeAnimation = CurvedAnimation(parent: fadeController, curve: Curves.easeIn);

    pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
    pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(CurvedAnimation(parent: pulseController, curve: Curves.easeInOut));

    contentController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    contentFade = CurvedAnimation(parent: contentController, curve: Curves.easeIn);
    contentSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: contentController, curve: Curves.easeOut));

    fadeController.forward().then((_) => contentController.forward());
  }

  @override
  void dispose() {
    pulseController.dispose();
    fadeController.dispose();
    contentController.dispose();
    super.dispose();
  }

  void goNext() {
    final controller = context.read<OnboardingController>();
    Navigator.push(context, PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => ChangeNotifierProvider.value(
          value: controller, child: const CaloriesBurnedScreen()),
      transitionsBuilder: (context, animation, secondaryAnimation, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)), child: child),
      transitionDuration: const Duration(milliseconds: 350),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return OnboardingScaffold(
      currentStep: 12, totalSteps: 15, showSkip: false,
      child: FadeTransition(opacity: fadeAnimation,
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Spacer(),
            ScaleTransition(
              scale: pulseAnimation,
              child: Container(
                width: 180, height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    c.greenDim,
                    c.greenDim.withOpacity(0.3),
                    Colors.transparent,
                  ]),
                ),
                child: Center(
                  child: Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.greenDim,
                      border: Border.all(color: c.green.withOpacity(0.2), width: 2),
                    ),
                    child: const Center(child: Text('🤝', style: TextStyle(fontSize: 56))),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            SlideTransition(
              position: contentSlide,
              child: FadeTransition(opacity: contentFade,
                child: Column(children: [
                  Text('Thank you for\ntrusting us!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: c.white, height: 1.2, letterSpacing: -1)),
                  const SizedBox(height: 14),
                  Text('Now let\'s personalise NutriTrack for you...',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: c.subtext)),
                  const SizedBox(height: 32),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    TrustBadge(emoji: '🔒', label: 'Private'),
                    const SizedBox(width: 12),
                    TrustBadge(emoji: '🧪', label: 'Science-based'),
                    const SizedBox(width: 12),
                    TrustBadge(emoji: '💚', label: 'Personalised'),
                  ]),
                ]),
              ),
            ),
            const Spacer(),
            OnboardingContinueButton(onTap: goNext, label: 'Let\'s go!'),
          ]),
        ),
      ),
    );
  }
}

class TrustBadge extends StatelessWidget {
  final String emoji;
  final String label;
  const TrustBadge({Key? key, required this.emoji, required this.label}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.divider),
      ),
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c.subtext)),
      ]),
    );
  }
}