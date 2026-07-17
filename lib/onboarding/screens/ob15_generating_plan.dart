import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../onboarding_controller.dart';
import '../../theme/app_theme.dart';
import 'ob16_plan_reveal.dart';

class GeneratingPlanScreen extends StatefulWidget {
  const GeneratingPlanScreen({Key? key}) : super(key: key);
  @override
  State<GeneratingPlanScreen> createState() => GeneratingPlanScreenState();
}

class GeneratingPlanScreenState extends State<GeneratingPlanScreen>
    with TickerProviderStateMixin {

  late AnimationController progressController;
  late AnimationController pulseController;
  late AnimationController fadeController;
  late AnimationController stepFadeController;

  late Animation<double> progressAnimation;
  late Animation<double> pulseAnimation;
  late Animation<double> fadeAnimation;
  late Animation<double> stepFadeAnimation;

  int currentStep = 0;
  bool stepVisible = false;

  final List<String> steps = [
    'Analysing your profile...',
    'Calculating your BMR...',
    'Building your macro plan...',
    'Personalising nutrition goals...',
    'Finalising your plan...',
  ];

  @override
  void initState() {
    super.initState();

    fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    fadeAnimation = CurvedAnimation(parent: fadeController, curve: Curves.easeIn);

    pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    pulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
        CurvedAnimation(parent: pulseController, curve: Curves.easeInOut));

    progressController = AnimationController(vsync: this, duration: const Duration(milliseconds: 3500));
    progressAnimation = CurvedAnimation(parent: progressController, curve: Curves.easeInOut);

    stepFadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    stepFadeAnimation = CurvedAnimation(parent: stepFadeController, curve: Curves.easeInOut);

    fadeController.forward();
    progressController.forward();

    progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) savePlanAndNavigate();
    });

    cycleSteps();
  }

  Future<void> cycleSteps() async {
    for (int i = 0; i < steps.length; i++) {
      if (!mounted) return;
      setState(() { currentStep = i; stepVisible = true; });
      await stepFadeController.forward();

      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      await stepFadeController.reverse();
      setState(() => stepVisible = false);

      await Future.delayed(const Duration(milliseconds: 150));
    }
  }

  Future<void> savePlanAndNavigate() async {
    final controller = context.read<OnboardingController>();
    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      try {
        await Supabase.instance.client.from('user_plans').upsert({
          'id': user.id,
          'gender': controller.gender,
          'workouts_per_week': controller.workoutsPerWeek,
          'heard_from': controller.heardFrom,
          'tried_other_apps': controller.triedOtherApps,
          'height_cm': controller.heightCm,
          'weight_kg': controller.weightKg,
          'date_of_birth': controller.dateOfBirth.toIso8601String(),
          'goal': controller.goal,
          'diet_type': controller.dietType,
          'accomplish': controller.accomplish,
          'add_burned_calories': controller.addBurnedCalories,
          'rollover_calories': controller.rolloverCalories,
          'daily_calories': controller.dailyCalories,
          'protein_g': controller.proteinG,
          'carbs_g': controller.carbsG,
          'fat_g': controller.fatG,
          'weeks_to_goal': controller.weeksToGoal,
        });
      } catch (e) {
        debugPrint('savePlan error: $e');
      }
    }

    if (!mounted) return;
    Navigator.pushReplacement(context, PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          ChangeNotifierProvider.value(value: controller, child: const PlanRevealScreen()),
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 600),
    ));
  }

  @override
  void dispose() {
    progressController.dispose();
    pulseController.dispose();
    fadeController.dispose();
    stepFadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final c = context.c;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                // title
                Text('Building your\ncustom plan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 28, fontWeight: FontWeight.w800,
                        color: c.white, height: 1.2, letterSpacing: -0.8)),

                const SizedBox(height: 48),

                // circular progress ring
                AnimatedBuilder(
                  animation: progressAnimation,
                  builder: (context, child) {
                    final percent = (progressAnimation.value * 100).round();
                    const size = 180.0;
                    const strokeWidth = 10.0;
                    const radius = (size / 2) - (strokeWidth / 2);
                    const circumference = 2 * 3.14159 * radius;
                    final offset = circumference * (1 - progressAnimation.value);

                    return ScaleTransition(
                      scale: pulseAnimation,
                      child: SizedBox(
                        width: size, height: size,
                        child: Stack(alignment: Alignment.center, children: [
                          // background ring
                          SizedBox(
                            width: size, height: size,
                            child: CustomPaint(painter: RingPainter(
                              progress: 1.0,
                              color: c.divider,
                              strokeWidth: strokeWidth,
                            )),
                          ),
                          // progress ring
                          SizedBox(
                            width: size, height: size,
                            child: CustomPaint(painter: RingPainter(
                              progress: progressAnimation.value,
                              color: c.green,
                              strokeWidth: strokeWidth,
                            )),
                          ),
                          // center content
                          Column(mainAxisSize: MainAxisSize.min, children: [
                            Text('$percent%', style: TextStyle(
                                fontSize: 36, fontWeight: FontWeight.w800,
                                color: c.white, letterSpacing: -1)),
                            Text('complete', style: TextStyle(fontSize: 12, color: c.subtext)),
                          ]),
                        ]),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 48),

                // animated step text
                SizedBox(
                  height: 28,
                  child: FadeTransition(
                    opacity: stepFadeAnimation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(stepFadeAnimation),
                      child: Text(
                        currentStep < steps.length ? steps[currentStep] : '',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: c.subtext, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // step dots indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(steps.length, (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == currentStep ? 20 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: i < currentStep
                          ? c.green
                          : i == currentStep
                          ? c.green
                          : c.divider,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  )),
                ),

                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// custom ring painter
class RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  RingPainter({required this.progress, required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - (strokeWidth / 2);
    const startAngle = -3.14159 / 2;
    final sweepAngle = 2 * 3.14159 * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(RingPainter old) =>
      old.progress != progress || old.color != color;
}