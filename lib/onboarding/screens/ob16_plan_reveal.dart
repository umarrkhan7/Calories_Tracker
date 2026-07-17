import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../onboarding_controller.dart';
import '../../theme/app_theme.dart';

class PlanRevealScreen extends StatefulWidget {
  const PlanRevealScreen({Key? key}) : super(key: key);
  @override
  State<PlanRevealScreen> createState() => PlanRevealScreenState();
}

class PlanRevealScreenState extends State<PlanRevealScreen>
    with TickerProviderStateMixin {

  late AnimationController fadeController;
  late AnimationController cardsController;
  late Animation<double> fadeAnimation;
  late Animation<double> cardsAnimation;

  @override
  void initState() {
    super.initState();
    fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    fadeAnimation = CurvedAnimation(parent: fadeController, curve: Curves.easeIn);
    cardsController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    cardsAnimation = CurvedAnimation(parent: cardsController, curve: Curves.easeOut);
    fadeController.forward().then((_) => cardsController.forward());
  }

  @override
  void dispose() { fadeController.dispose(); cardsController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final ctrl = context.watch<OnboardingController>();

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: FadeTransition(opacity: fadeAnimation,
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(children: [
              const SizedBox(height: 32),

              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, val, child) => Transform.scale(scale: val, child: child),
                child: Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: c.greenDim,
                      border: Border.all(color: c.green.withOpacity(0.3), width: 2)),
                  child: Icon(Icons.check_circle_rounded, color: c.green, size: 40),
                ),
              ),

              const SizedBox(height: 20),
              Text('Your plan is ready!',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: c.white, letterSpacing: -0.8)),
              const SizedBox(height: 6),
              Text(
                ctrl.goal == 'lose' ? 'You should lose weight gradually'
                    : ctrl.goal == 'gain' ? 'You should gain weight steadily'
                    : 'You should maintain your current weight',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: c.subtext),
              ),

              const SizedBox(height: 28),

              SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(cardsAnimation),
                child: FadeTransition(opacity: cardsAnimation,
                  child: Column(children: [
                    MacroCard(
                      label: 'Daily Calories',
                      value: ctrl.dailyCalories.round().toString(),
                      unit: 'kcal',
                      emoji: '🔥',
                      color: const Color(0xFFEF4444),
                      bgColor: const Color(0xFFEF4444).withOpacity(0.1),
                      fullWidth: true,
                    ),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(child: MacroCard(label: 'Protein', value: ctrl.proteinG.round().toString(), unit: 'g', emoji: '🥩', color: const Color(0xFF3B82F6), bgColor: const Color(0xFF3B82F6).withOpacity(0.1))),
                      const SizedBox(width: 14),
                      Expanded(child: MacroCard(label: 'Carbs', value: ctrl.carbsG.round().toString(), unit: 'g', emoji: '🌾', color: const Color(0xFFF59E0B), bgColor: const Color(0xFFF59E0B).withOpacity(0.1))),
                      const SizedBox(width: 14),
                      Expanded(child: MacroCard(label: 'Fats', value: ctrl.fatG.round().toString(), unit: 'g', emoji: '🥑', color: const Color(0xFF10B981), bgColor: const Color(0xFF10B981).withOpacity(0.1))),
                    ]),
                    if (ctrl.weeksToGoal > 0) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          color: c.greenDim,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: c.green.withOpacity(0.2)),
                        ),
                        child: Row(children: [
                          Icon(Icons.flag_rounded, color: c.green, size: 20),
                          const SizedBox(width: 12),
                          Expanded(child: Text(
                            'Estimated ${ctrl.weeksToGoal.round()} weeks to reach your goal',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.green),
                          )),
                        ]),
                      ),
                    ],
                  ]),
                ),
              ),

              const Spacer(),

              GestureDetector(
                onTap: () => Navigator.pushReplacementNamed(context, '/dashboard'),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: c.green,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: c.green.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: const Center(child: Text('Start Tracking', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700))),
                ),
              ),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ),
    );
  }
}

class MacroCard extends StatelessWidget {
  final String label, value, unit, emoji;
  final Color color, bgColor;
  final bool fullWidth;

  const MacroCard({Key? key, required this.label, required this.value, required this.unit,
    required this.emoji, required this.color, required this.bgColor, this.fullWidth = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(fullWidth ? 18 : 14),
      decoration: BoxDecoration(
        color: bgColor, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: fullWidth
          ? Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(value, style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: color, height: 1.1)),
            const SizedBox(width: 4),
            Padding(padding: const EdgeInsets.only(bottom: 4),
                child: Text(unit, style: TextStyle(fontSize: 14, color: color.withOpacity(0.7), fontWeight: FontWeight.w500))),
          ]),
        ]),
      ])
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color, height: 1.1)),
          const SizedBox(width: 2),
          Padding(padding: const EdgeInsets.only(bottom: 2),
              child: Text(unit, style: TextStyle(fontSize: 11, color: color.withOpacity(0.7)))),
        ]),
      ]),
    );
  }
}