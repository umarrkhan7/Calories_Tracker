import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../onboarding_scaffold.dart';
import '../onboarding_controller.dart';
import '../../theme/app_theme.dart';
import 'ob09_diet_type.dart';

class GoalScreen extends StatefulWidget {
  const GoalScreen({Key? key}) : super(key: key);
  @override
  State<GoalScreen> createState() => GoalScreenState();
}

class GoalScreenState extends State<GoalScreen> with SingleTickerProviderStateMixin {
  String? selectedGoal;
  late AnimationController animController;
  late Animation<double> fadeAnimation;
  late Animation<Offset> slideAnimation;

  final List<GoalOption> options = const [
    GoalOption(value: 'lose', label: 'Lose Weight', sublabel: 'Burn fat and reach your ideal body', icon: Icons.trending_down_rounded, color: Color(0xFF3B82F6), bgColor: Color(0xFFEFF6FF)),
    GoalOption(value: 'maintain', label: 'Maintain Weight', sublabel: 'Stay at your current weight and eat healthier', icon: Icons.balance_rounded, color: Color(0xFF27AE60), bgColor: Color(0xFFDFF2E9)),
    GoalOption(value: 'gain', label: 'Gain Weight', sublabel: 'Build muscle and increase your body mass', icon: Icons.trending_up_rounded, color: Color(0xFFF59E0B), bgColor: Color(0xFFFFFBEB)),
  ];

  @override
  void initState() {
    super.initState();
    animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: animController, curve: Curves.easeOut));
    fadeAnimation = CurvedAnimation(parent: animController, curve: Curves.easeIn);
    animController.forward();
  }

  @override
  void dispose() { animController.dispose(); super.dispose(); }

  void goNext() {
    if (selectedGoal == null) return;
    final controller = context.read<OnboardingController>();
    controller.goal = selectedGoal!;
    Navigator.push(context, PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => ChangeNotifierProvider.value(
          value: controller, child: const DietTypeScreen()),
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
      currentStep: 8, totalSteps: 15, showSkip: false,
      child: FadeTransition(opacity: fadeAnimation, child: SlideTransition(position: slideAnimation,
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 28),
            Text('What is your goal?', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: c.white)),
            const SizedBox(height: 8),
            Text('We will build your plan around this.', style: TextStyle(fontSize: 14, color: c.subtext)),
            const SizedBox(height: 36),
            ...options.map((opt) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GoalCard(option: opt, selected: selectedGoal == opt.value,
                  onTap: () => setState(() => selectedGoal = opt.value)),
            )),
            const Spacer(),
            OnboardingContinueButton(onTap: selectedGoal != null ? goNext : null),
          ]),
        ),
      )),
    );
  }
}

class GoalOption {
  final String value, label, sublabel;
  final IconData icon;
  final Color color, bgColor;
  const GoalOption({required this.value, required this.label, required this.sublabel, required this.icon, required this.color, required this.bgColor});
}

class GoalCard extends StatelessWidget {
  final GoalOption option;
  final bool selected;
  final VoidCallback onTap;
  const GoalCard({Key? key, required this.option, required this.selected, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? option.bgColor : c.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? option.color : c.divider, width: selected ? 2 : 1),
          boxShadow: selected ? [BoxShadow(color: option.color.withOpacity(0.15), blurRadius: 16, offset: const Offset(0, 6))] : [],
        ),
        child: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 52, height: 52,
            decoration: BoxDecoration(color: selected ? option.color : c.surfaceAlt, borderRadius: BorderRadius.circular(14)),
            child: Icon(option.icon, color: selected ? Colors.white : c.subtext, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(option.label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                color: selected ? option.color : c.white)),
            const SizedBox(height: 4),
            Text(option.sublabel, style: TextStyle(fontSize: 12, color: c.subtext)),
          ])),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22, height: 22,
            decoration: BoxDecoration(shape: BoxShape.circle, color: selected ? option.color : Colors.transparent,
                border: Border.all(color: selected ? option.color : c.divider, width: 2)),
            child: selected ? const Icon(Icons.check, color: Colors.white, size: 13) : null,
          ),
        ]),
      ),
    );
  }
}