import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../onboarding_scaffold.dart';
import '../onboarding_controller.dart';
import '../../theme/app_theme.dart';
import 'ob15_generating_plan.dart';
import 'ob13_calories_burned.dart' show YesNoButton;

class RolloverCaloriesScreen extends StatefulWidget {
  const RolloverCaloriesScreen({Key? key}) : super(key: key);
  @override
  State<RolloverCaloriesScreen> createState() => RolloverCaloriesScreenState();
}

class RolloverCaloriesScreenState extends State<RolloverCaloriesScreen>
    with SingleTickerProviderStateMixin {

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
    controller.rolloverCalories = value;
    controller.generatePlan();
    Navigator.push(context, PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => ChangeNotifierProvider.value(
          value: controller, child: const GeneratingPlanScreen()),
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
      currentStep: 14, totalSteps: 15, showSkip: false,
      child: FadeTransition(opacity: fadeAnimation, child: SlideTransition(position: slideAnimation,
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 28),
            Text('Rollover extra calories\nto the next day?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: c.white)),
            const SizedBox(height: 8),
            Text('Unused calories from yesterday get added to today\'s goal.', style: TextStyle(fontSize: 14, color: c.subtext)),
            const SizedBox(height: 32),

            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.4)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.local_fire_department_rounded, color: Color(0xFFEF4444), size: 16),
                    const SizedBox(width: 6),
                    const Text('Yesterday', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFEF4444))),
                  ]),
                  const SizedBox(height: 12),
                  Text('1200', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: c.white)),
                  Text('/ 1800 cals', style: TextStyle(fontSize: 12, color: c.subtext)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(8)),
                    child: const Text('600 cals left', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFEF4444))),
                  ),
                ]),
              )),
              const SizedBox(width: 12),
              Padding(padding: const EdgeInsets.only(top: 36), child: Icon(Icons.arrow_forward_rounded, color: c.green, size: 22)),
              const SizedBox(width: 12),
              Expanded(child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: c.greenDim,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: c.green.withOpacity(0.3)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Icons.local_fire_department_rounded, color: c.green, size: 16),
                    const SizedBox(width: 6),
                    Text('Today', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.green)),
                  ]),
                  const SizedBox(height: 12),
                  Text('1800', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: c.white)),
                  Text('/ 2400 cals', style: TextStyle(fontSize: 12, color: c.subtext)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(8)),
                    child: Text('+600 rolled over', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c.green)),
                  ),
                ]),
              )),
            ]),

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

// class YesNoButton extends StatefulWidget {
//   final String label;
//   final bool isYes;
//   final VoidCallback onTap;
//   const YesNoButton({Key? key, required this.label, required this.isYes, required this.onTap}) : super(key: key);
//   @override
//   State<YesNoButton> createState() => YesNoButtonState();
// }
//
// class YesNoButtonState extends State<YesNoButton> with SingleTickerProviderStateMixin {
//   late AnimationController ctrl;
//   late Animation<double> scale;
//   @override
//   void initState() {
//     super.initState();
//     ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
//     scale = Tween<double>(begin: 1.0, end: 0.96).animate(ctrl);
//   }
//   @override
//   void dispose() { ctrl.dispose(); super.dispose(); }
//
//   @override
//   Widget build(BuildContext context) {
//     final c = context.c;
//     return GestureDetector(
//       onTapDown: (_) => ctrl.forward(),
//       onTapUp: (_) { ctrl.reverse(); widget.onTap(); },
//       onTapCancel: () => ctrl.reverse(),
//       child: ScaleTransition(scale: scale,
//         child: Container(
//           padding: const EdgeInsets.symmetric(vertical: 18),
//           decoration: BoxDecoration(
//             color: widget.isYes ? c.green : c.surface,
//             borderRadius: BorderRadius.circular(16),
//             border: Border.all(color: widget.isYes ? c.green : c.divider, width: 1.5),
//             boxShadow: widget.isYes ? [BoxShadow(color: c.green.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 6))] : [],
//           ),
//           child: Center(child: Text(widget.label, style: TextStyle(
//               fontSize: 16, fontWeight: FontWeight.w700,
//               color: widget.isYes ? Colors.white : c.subtext))),
//         ),
//       ),
//     );
//   }
// }