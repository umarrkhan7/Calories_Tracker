import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../onboarding_controller.dart';
import '../onboarding_scaffold.dart';
import 'ob05_long_term_results.dart';

class TriedAppsScreen extends StatefulWidget {
  const TriedAppsScreen({Key? key}) : super(key: key);

  @override
  State<TriedAppsScreen> createState() => TriedAppsScreenState();
}

class TriedAppsScreenState extends State<TriedAppsScreen>
    with SingleTickerProviderStateMixin {
  bool? tried;

  late AnimationController animCtrl;
  late Animation<Offset> slideAnim;
  late Animation<double> fadeAnim;

  @override
  void initState() {
    super.initState();
    animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    slideAnim = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: animCtrl, curve: Curves.easeOut));
    fadeAnim = CurvedAnimation(parent: animCtrl, curve: Curves.easeIn);
    animCtrl.forward();
  }

  @override
  void dispose() {
    animCtrl.dispose();
    super.dispose();
  }

  void next() {
    if (tried == null) return;
    final controller = context.read<OnboardingController>();
    controller.triedOtherApps = tried!;
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ChangeNotifierProvider.value(
          value: controller,
          child: const LongTermResultsScreen(),
        ),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return OnboardingScaffold(
      currentStep: 4,
      totalSteps: 15,
      child: FadeTransition(
        opacity: fadeAnim,
        child: SlideTransition(
          position: slideAnim,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                Text('Have you tried other\ncalorie tracking apps?',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: c.white)),
                const SizedBox(height: 10),
                Text('We want to make your experience better.',
                    style: TextStyle(fontSize: 14, color: c.subtext)),
                const SizedBox(height: 60),

                Row(
                  children: [
                    Expanded(child: ThumbCard(
                        label: 'Yes', isThumbUp: true, selected: tried == true,
                        onTap: () => setState(() => tried = true))),
                    const SizedBox(width: 16),
                    Expanded(child: ThumbCard(
                        label: 'No', isThumbUp: false, selected: tried == false,
                        onTap: () => setState(() => tried = false))),
                  ],
                ),

                const Spacer(),
                OnboardingContinueButton(onTap: tried != null ? next : null),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ThumbCard extends StatelessWidget {
  final String label;
  final bool isThumbUp;
  final bool selected;
  final VoidCallback onTap;

  const ThumbCard({Key? key, required this.label, required this.isThumbUp,
    required this.selected, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: selected ? c.greenDim : c.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? c.green : c.divider, width: selected ? 2 : 1),
          boxShadow: selected
              ? [BoxShadow(color: c.green.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 4))]
              : [],
        ),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: selected ? c.green : c.surfaceAlt,
                shape: BoxShape.circle,
              ),
              child: Icon(isThumbUp ? Icons.thumb_up_rounded : Icons.thumb_down_rounded,
                  color: selected ? Colors.white : c.subtext, size: 30),
            ),
            const SizedBox(height: 14),
            Text(label, style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700,
                color: selected ? c.green : c.white)),
          ],
        ),
      ),
    );
  }
}