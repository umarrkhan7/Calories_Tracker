import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../onboarding_scaffold.dart';
import '../onboarding_controller.dart';
import '../../theme/app_theme.dart';
import 'ob10_accomplish.dart';

class DietTypeScreen extends StatefulWidget {
  const DietTypeScreen({Key? key}) : super(key: key);

  @override
  State<DietTypeScreen> createState() => DietTypeScreenState();
}

class DietTypeScreenState extends State<DietTypeScreen>
    with SingleTickerProviderStateMixin {

  String? selectedDiet;

  late AnimationController animController;
  late Animation<double> fadeAnimation;
  late Animation<Offset> slideAnimation;

  final List<DietOption> options = const [
    DietOption(value: 'classic', label: 'Classic', sublabel: 'No restrictions, balanced diet', emoji: '🍗', color: Color(0xFFEF4444), bgColor: Color(0xFFFEF2F2)),
    DietOption(value: 'pescatarian', label: 'Pescatarian', sublabel: 'Fish and seafood, no meat', emoji: '🐟', color: Color(0xFF0EA5E9), bgColor: Color(0xFFE0F2FE)),
    DietOption(value: 'vegetarian', label: 'Vegetarian', sublabel: 'No meat or fish', emoji: '🥗', color: Color(0xFF27AE60), bgColor: Color(0xFFDFF2E9)),
    DietOption(value: 'vegan', label: 'Vegan', sublabel: 'No animal products at all', emoji: '🌱', color: Color(0xFF10B981), bgColor: Color(0xFFD1FAE5)),
    DietOption(value: 'keto', label: 'Keto', sublabel: 'High fat, very low carbs', emoji: '🥑', color: Color(0xFFF59E0B), bgColor: Color(0xFFFFFBEB)),
    DietOption(value: 'paleo', label: 'Paleo', sublabel: 'Whole foods, no processed', emoji: '🥩', color: Color(0xFF92400E), bgColor: Color(0xFFFEF3C7)),
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
  void dispose() {
    animController.dispose();
    super.dispose();
  }

  void goNext() {
    if (selectedDiet == null) return;
    final controller = context.read<OnboardingController>();
    controller.dietType = selectedDiet!;
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ChangeNotifierProvider.value(
          value: controller,
          child: const AccomplishScreen(),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
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
      currentStep: 9,
      totalSteps: 15,
      showSkip: false,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(
          position: slideAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 28),
                Text('Do you follow a specific diet?', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: c.white)),
                const SizedBox(height: 8),
                Text('We will adjust your nutrition plan accordingly.', style: TextStyle(fontSize: 14, color: c.subtext)),

                const SizedBox(height: 32),

                Expanded(
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 1.1,
                    ),
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final opt = options[index];
                      final selected = selectedDiet == opt.value;

                      return GestureDetector(
                        onTap: () => setState(() => selectedDiet = opt.value),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: selected ? opt.bgColor : c.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: selected ? opt.color : c.divider, width: selected ? 2 : 1),
                            boxShadow: selected ? [BoxShadow(color: opt.color.withOpacity(0.15), blurRadius: 14, offset: const Offset(0, 5))] : [],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 44, height: 44,
                                    decoration: BoxDecoration(
                                      color: selected ? opt.color.withOpacity(0.15) : c.surfaceAlt,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(child: Text(opt.emoji, style: const TextStyle(fontSize: 22))),
                                  ),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 20, height: 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: selected ? opt.color : Colors.transparent,
                                      border: Border.all(color: selected ? opt.color : c.divider, width: 2),
                                    ),
                                    child: selected ? const Icon(Icons.check, color: Colors.white, size: 12) : null,
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Text(opt.label, style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700,
                                  color: selected ? opt.color : c.white)),
                              const SizedBox(height: 3),
                              Text(opt.sublabel, style: TextStyle(fontSize: 11, color: c.subtext, height: 1.3),
                                  maxLines: 2, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                OnboardingContinueButton(onTap: selectedDiet != null ? goNext : null),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DietOption {
  final String value, label, sublabel, emoji;
  final Color color, bgColor;
  const DietOption({required this.value, required this.label, required this.sublabel,
    required this.emoji, required this.color, required this.bgColor});
}