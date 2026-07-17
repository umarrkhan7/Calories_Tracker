import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../onboarding_scaffold.dart';
import '../onboarding_controller.dart';
import '../../theme/app_theme.dart';
import 'ob11_potential_graph.dart';

class AccomplishScreen extends StatefulWidget {
  const AccomplishScreen({Key? key}) : super(key: key);
  @override
  State<AccomplishScreen> createState() => AccomplishScreenState();
}

class AccomplishScreenState extends State<AccomplishScreen>
    with SingleTickerProviderStateMixin {

  final Set<String> selected = {};
  late AnimationController animController;
  late Animation<double> fadeAnimation;
  late Animation<Offset> slideAnimation;

  final List<AccomplishOption> options = const [
    AccomplishOption(value: 'eat_healthy',    label: 'Eat and live healthier',        emoji: '🥦', color: Color(0xFF27AE60), bgColor: Color(0xFFDFF2E9)),
    AccomplishOption(value: 'boost_energy',   label: 'Boost my energy and mood',      emoji: '⚡', color: Color(0xFFF59E0B), bgColor: Color(0xFFFFFBEB)),
    AccomplishOption(value: 'lose_fat',       label: 'Lose body fat',                 emoji: '🔥', color: Color(0xFFEF4444), bgColor: Color(0xFFFEF2F2)),
    AccomplishOption(value: 'build_muscle',   label: 'Build muscle and strength',     emoji: '💪', color: Color(0xFF3B82F6), bgColor: Color(0xFFEFF6FF)),
    AccomplishOption(value: 'improve_sleep',  label: 'Improve my sleep quality',      emoji: '😴', color: Color(0xFF8B5CF6), bgColor: Color(0xFFF5F3FF)),
    AccomplishOption(value: 'reduce_stress',  label: 'Reduce stress and anxiety',     emoji: '🧘', color: Color(0xFF0EA5E9), bgColor: Color(0xFFE0F2FE)),
    AccomplishOption(value: 'track_nutrition',label: 'Track my nutrition better',     emoji: '📊', color: Color(0xFF10B981), bgColor: Color(0xFFD1FAE5)),
    AccomplishOption(value: 'stay_consistent',label: 'Stay consistent with habits',   emoji: '🎯', color: Color(0xFFF97316), bgColor: Color(0xFFFFF7ED)),
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
    if (selected.isEmpty) return;
    final controller = context.read<OnboardingController>();
    controller.accomplish = selected.toList();
    Navigator.push(context, PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => ChangeNotifierProvider.value(
          value: controller, child: const PotentialGraphScreen()),
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
      currentStep: 10, totalSteps: 15, showSkip: false,
      child: FadeTransition(opacity: fadeAnimation, child: SlideTransition(position: slideAnimation,
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 28),
            Text('What would you like to accomplish?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: c.white)),
            const SizedBox(height: 8),
            Row(children: [
              Text('Select all that apply.', style: TextStyle(fontSize: 14, color: c.subtext)),
              const SizedBox(width: 8),
              if (selected.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: c.greenDim, borderRadius: BorderRadius.circular(20)),
                  child: Text('${selected.length} selected', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.green)),
                ),
            ]),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                itemCount: options.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final opt = options[index];
                  final isSelected = selected.contains(opt.value);
                  return GestureDetector(
                    onTap: () => setState(() => isSelected ? selected.remove(opt.value) : selected.add(opt.value)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? opt.bgColor : c.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: isSelected ? opt.color : c.divider, width: isSelected ? 2 : 1),
                        boxShadow: isSelected ? [BoxShadow(color: opt.color.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 4))] : [],
                      ),
                      child: Row(children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 46, height: 46,
                          decoration: BoxDecoration(
                            color: isSelected ? opt.color.withOpacity(0.15) : c.surfaceAlt,
                            shape: BoxShape.circle,
                          ),
                          child: Center(child: Text(opt.emoji, style: const TextStyle(fontSize: 22))),
                        ),
                        const SizedBox(width: 16),
                        Expanded(child: Text(opt.label, style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600,
                            color: isSelected ? opt.color : c.white))),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 24, height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? opt.color : Colors.transparent,
                            border: Border.all(color: isSelected ? opt.color : c.divider, width: 2),
                          ),
                          child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
                        ),
                      ]),
                    ),
                  );
                },
              ),
            ),
            OnboardingContinueButton(
              onTap: selected.isNotEmpty ? goNext : null,
              label: selected.isEmpty ? 'Select at least one' : 'Continue',
            ),
          ]),
        ),
      )),
    );
  }
}

class AccomplishOption {
  final String value, label, emoji;
  final Color color, bgColor;
  const AccomplishOption({required this.value, required this.label, required this.emoji, required this.color, required this.bgColor});
}