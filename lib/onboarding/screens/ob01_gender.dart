import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../onboarding_controller.dart';
import '../onboarding_scaffold.dart';
import 'ob02_workout_frequency.dart';

class GenderScreen extends StatefulWidget {
  const GenderScreen({Key? key}) : super(key: key);

  @override
  State<GenderScreen> createState() => _GenderScreenState();
}

class _GenderScreenState extends State<GenderScreen>
    with SingleTickerProviderStateMixin {
  String? _selected;

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
    if (_selected == null) return;
    final controller = context.read<OnboardingController>();
    controller.gender = _selected!;
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ChangeNotifierProvider.value(
          value: controller,
          child: const WorkoutFrequencyScreen(),
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
      currentStep: 1,
      totalSteps: 15,
      showSkip: false,
      // onSkip: () => Navigator.pushReplacementNamed(context, '/dashboard'),
      onBack: () => Navigator.pushReplacementNamed(context, '/signin'),
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
                Text('What is your gender?', style: TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w800, color: c.white)),
                const SizedBox(height: 10),
                Text('This helps us calculate your nutrition needs.',
                    style: TextStyle(fontSize: 14, color: c.subtext)),
                const SizedBox(height: 48),

                _GenderCard(label: 'Male', icon: Icons.male_rounded,
                    selected: _selected == 'male', onTap: () => setState(() => _selected = 'male')),
                const SizedBox(height: 16),
                _GenderCard(label: 'Female', icon: Icons.female_rounded,
                    selected: _selected == 'female', onTap: () => setState(() => _selected = 'female')),
                const SizedBox(height: 16),
                _GenderCard(label: 'Prefer not to say', icon: Icons.person_outline_rounded,
                    selected: _selected == 'other', onTap: () => setState(() => _selected = 'other')),

                const Spacer(),
                OnboardingContinueButton(onTap: _selected != null ? _next : null),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GenderCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _GenderCard({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
              child: Icon(icon, color: selected ? Colors.white : c.subtext, size: 22),
            ),
            const SizedBox(width: 16),
            Text(label, style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600,
                color: selected ? c.green : c.white)),
            const Spacer(),
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
    );
  }
}