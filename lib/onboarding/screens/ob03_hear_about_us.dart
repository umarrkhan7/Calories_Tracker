import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../onboarding_controller.dart';
import '../onboarding_scaffold.dart';
import 'ob04_tried_apps.dart';

class HearAboutUsScreen extends StatefulWidget {
  const HearAboutUsScreen({Key? key}) : super(key: key);

  @override
  State<HearAboutUsScreen> createState() => _HearAboutUsScreenState();
}

class _HearAboutUsScreenState extends State<HearAboutUsScreen>
    with SingleTickerProviderStateMixin {
  String? _selected;

  final List<_Platform> _platforms = const [
    _Platform(label: 'Instagram', color: Color(0xFFE1306C), icon: Icons.camera_alt_rounded),
    _Platform(label: 'TikTok',    color: Color(0xFF010101), icon: Icons.music_note_rounded),
    _Platform(label: 'YouTube',   color: Color(0xFFFF0000), icon: Icons.play_circle_rounded),
    _Platform(label: 'Facebook',  color: Color(0xFF1877F2), icon: Icons.facebook_rounded),
    _Platform(label: 'Twitter/X', color: Color(0xFF000000), icon: Icons.close_rounded),
    _Platform(label: 'Friend',    color: Color(0xFF27AE60), icon: Icons.people_rounded),
    _Platform(label: 'Google',    color: Color(0xFF4285F4), icon: Icons.search_rounded),
    _Platform(label: 'Other',     color: Color(0xFF9CA3AF), icon: Icons.more_horiz_rounded),
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
    if (_selected == null) return;
    final controller = context.read<OnboardingController>();
    controller.gender = _selected!;
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ChangeNotifierProvider.value(
          value: controller,
          child: const TriedAppsScreen(),
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
      currentStep: 3,
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
                Text('Where did you hear about us?',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: c.white)),
                const SizedBox(height: 10),
                Text('Help us understand how you found NutriTrack.',
                    style: TextStyle(fontSize: 14, color: c.subtext)),
                const SizedBox(height: 36),

                Expanded(
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 2.2,
                    ),
                    itemCount: _platforms.length,
                    itemBuilder: (context, i) {
                      final p = _platforms[i];
                      final selected = _selected == p.label;
                      return GestureDetector(
                        onTap: () => setState(() => _selected = p.label),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: selected ? c.greenDim : c.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: selected ? c.green : c.divider, width: selected ? 2 : 1),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(color: p.color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                                child: Icon(p.icon, color: p.color, size: 18),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(p.label,
                                    style: TextStyle(
                                        fontSize: 13, fontWeight: FontWeight.w600,
                                        color: selected ? c.green : c.white),
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                OnboardingContinueButton(onTap: _selected != null ? _next : null),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Platform {
  final String label;
  final Color color;
  final IconData icon;
  const _Platform({required this.label, required this.color, required this.icon});
}