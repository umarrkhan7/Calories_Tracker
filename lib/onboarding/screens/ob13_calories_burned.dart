import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../onboarding_scaffold.dart';
import '../onboarding_controller.dart';
import '../../theme/app_theme.dart';
import 'ob14_rollover_calories.dart';

class CaloriesBurnedScreen extends StatefulWidget {
  const CaloriesBurnedScreen({Key? key}) : super(key: key);
  @override
  State<CaloriesBurnedScreen> createState() => CaloriesBurnedScreenState();
}

class CaloriesBurnedScreenState extends State<CaloriesBurnedScreen>
    with SingleTickerProviderStateMixin {

  bool? selected;
  late AnimationController animController;
  late Animation<double> fadeAnimation;
  late Animation<Offset> slideAnimation;

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

  void goNext(bool value) {
    final controller = context.read<OnboardingController>();
    controller.addBurnedCalories = value;
    Navigator.push(context, PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => ChangeNotifierProvider.value(
          value: controller, child: const RolloverCaloriesScreen()),
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
      currentStep: 13, totalSteps: 15, showSkip: false,
      child: FadeTransition(opacity: fadeAnimation, child: SlideTransition(position: slideAnimation,
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 28),
            Text('Add calories burned\nback to your goal?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: c.white)),
            const SizedBox(height: 8),
            Text('When you exercise, should we add those calories back to your daily goal?', style: TextStyle(fontSize: 14, color: c.subtext)),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: c.divider),
              ),
              child: Column(children: [
                Row(children: [
                  Container(width: 40, height: 40,
                      decoration: BoxDecoration(color: const Color(0xFFEF4444).withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.local_fire_department_rounded, color: Color(0xFFEF4444), size: 22)),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Today\'s goal', style: TextStyle(fontSize: 12, color: c.subtext)),
                    Text('1800 Cals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c.white)),
                  ]),
                ]),
                const SizedBox(height: 16),
                Container(height: 1, color: c.divider),
                const SizedBox(height: 16),
                Row(children: [
                  Container(width: 40, height: 40,
                      decoration: BoxDecoration(color: c.greenDim, borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.directions_run_rounded, color: c.green, size: 22)),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Running 30 min', style: TextStyle(fontSize: 12, color: c.subtext)),
                    Text('+250 cals added back', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.green)),
                  ]),
                ]),
              ]),
            ),
            const Spacer(),
            Row(children: [
              Expanded(child: YesNoButton(label: 'No', isYes: false, onTap: () => goNext(false))),
              const SizedBox(width: 14),
              Expanded(child: YesNoButton(label: 'Yes', isYes: true, onTap: () => goNext(true))),
            ]),
            const SizedBox(height: 32),
          ]),
        ),
      )),
    );
  }
}

class YesNoButton extends StatefulWidget {
  final String label;
  final bool isYes;
  final VoidCallback onTap;
  const YesNoButton({Key? key, required this.label, required this.isYes, required this.onTap}) : super(key: key);
  @override
  State<YesNoButton> createState() => YesNoButtonState();
}

class YesNoButtonState extends State<YesNoButton> with SingleTickerProviderStateMixin {
  late AnimationController ctrl;
  late Animation<double> scale;
  @override
  void initState() {
    super.initState();
    ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    scale = Tween<double>(begin: 1.0, end: 0.96).animate(ctrl);
  }
  @override
  void dispose() { ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GestureDetector(
      onTapDown: (_) => ctrl.forward(),
      onTapUp: (_) { ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => ctrl.reverse(),
      child: ScaleTransition(scale: scale,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: widget.isYes ? c.green : c.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.isYes ? c.green : c.divider, width: 1.5),
            boxShadow: widget.isYes ? [BoxShadow(color: c.green.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 6))] : [],
          ),
          child: Center(child: Text(widget.label, style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700,
              color: widget.isYes ? Colors.white : c.subtext))),
        ),
      ),
    );
  }
}