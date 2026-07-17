import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../onboarding_controller.dart';
import '../onboarding_scaffold.dart';
import 'ob03_hear_about_us.dart';

class WorkoutFrequencyScreen extends StatefulWidget {
  const WorkoutFrequencyScreen({Key? key}) : super(key: key);

  @override
  State<WorkoutFrequencyScreen> createState() => _WorkoutFrequencyScreenState();
}

class _WorkoutFrequencyScreenState extends State<WorkoutFrequencyScreen>
    with SingleTickerProviderStateMixin {
  int? _selectedIndex;

  final List<_WorkoutOption> _options = const [
    _WorkoutOption(label: '0 workouts', sublabel: 'I am not active right now', icon: Icons.bedtime_outlined, value: 0),
    _WorkoutOption(label: '1 - 2 workouts', sublabel: 'Now and then', icon: Icons.directions_walk_rounded, value: 1),
    _WorkoutOption(label: '3 - 5 workouts', sublabel: 'A few workouts per week', icon: Icons.fitness_center_rounded, value: 3),
    _WorkoutOption(label: '6+ workouts', sublabel: 'I train almost every day', icon: Icons.sports_gymnastics_rounded, value: 6),
  ];

  late AnimationController _animCtrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_selectedIndex == null) return;
    final controller = context.read<OnboardingController>();
    controller.workoutsPerWeek = _options[_selectedIndex!].value;
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ChangeNotifierProvider.value(
          value: controller,
          child: const HearAboutUsScreen(),
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
      currentStep: 2,
      totalSteps: 15,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                Text('How many workouts do you do per week?',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: c.white)),
                const SizedBox(height: 10),
                Text('We use this to calculate your activity level.',
                    style: TextStyle(fontSize: 14, color: c.subtext)),
                const SizedBox(height: 36),

                ...List.generate(_options.length, (i) {
                  final opt = _options[i];
                  final selected = _selectedIndex == i;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedIndex = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: selected ? c.greenDim : c.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: selected ? c.green : c.divider, width: selected ? 2 : 1),
                          boxShadow: selected
                              ? [BoxShadow(color: c.green.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 4))]
                              : [],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: selected ? c.green : c.surfaceAlt,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(opt.icon, color: selected ? Colors.white : c.subtext, size: 22),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(opt.label, style: TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.w600,
                                      color: selected ? c.green : c.white)),
                                  Text(opt.sublabel, style: TextStyle(fontSize: 12, color: c.subtext)),
                                ],
                              ),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 22, height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: selected ? c.green : Colors.transparent,
                                border: Border.all(color: selected ? c.green : c.divider, width: 2),
                              ),
                              child: selected ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                const Spacer(),
                OnboardingContinueButton(onTap: _selectedIndex != null ? _next : null),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkoutOption {
  final String label, sublabel;
  final IconData icon;
  final int value;
  const _WorkoutOption({required this.label, required this.sublabel, required this.icon, required this.value});
}