import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../onboarding_scaffold.dart';
import '../onboarding_controller.dart';
import '../../theme/app_theme.dart';
import 'ob06_height_weight.dart';

class LongTermResultsScreen extends StatefulWidget {
  const LongTermResultsScreen({Key? key}) : super(key: key);

  @override
  State<LongTermResultsScreen> createState() => LongTermResultsScreenState();
}

class LongTermResultsScreenState extends State<LongTermResultsScreen>
    with TickerProviderStateMixin {

  late AnimationController lineController;
  late AnimationController fadeController;
  late AnimationController statController;

  late Animation<double> lineAnimation;
  late Animation<double> fadeAnimation;
  late Animation<double> statAnimation;

  @override
  void initState() {
    super.initState();
    fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    fadeAnimation = CurvedAnimation(parent: fadeController, curve: Curves.easeIn);

    lineController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    lineAnimation = CurvedAnimation(parent: lineController, curve: Curves.easeInOut);

    statController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    statAnimation = CurvedAnimation(parent: statController, curve: Curves.easeOut);

    fadeController.forward().then((_) {
      lineController.forward().then((_) => statController.forward());
    });
  }

  @override
  void dispose() {
    lineController.dispose();
    fadeController.dispose();
    statController.dispose();
    super.dispose();
  }

  List<FlSpot> getNutriSpots(double progress) {
    final allSpots = [FlSpot(0, 5.0), FlSpot(1, 4.2), FlSpot(2, 3.3), FlSpot(3, 2.4), FlSpot(4, 1.8), FlSpot(5, 1.2), FlSpot(6, 0.8)];
    final count = (allSpots.length * progress).ceil().clamp(1, allSpots.length);
    return allSpots.take(count).toList();
  }

  List<FlSpot> getTraditionalSpots(double progress) {
    final allSpots = [FlSpot(0, 5.0), FlSpot(1, 4.8), FlSpot(2, 4.6), FlSpot(3, 4.9), FlSpot(4, 5.2), FlSpot(5, 5.6), FlSpot(6, 6.0)];
    final count = (allSpots.length * progress).ceil().clamp(1, allSpots.length);
    return allSpots.take(count).toList();
  }

  void goNext() {
    final controller = context.read<OnboardingController>();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ChangeNotifierProvider.value(
          value: controller,
          child: const HeightWeightScreen(),
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
      currentStep: 5,
      totalSteps: 15,
      showSkip: false,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 28),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: c.greenDim, borderRadius: BorderRadius.circular(20)),
                child: Text('Science-backed results',
                    style: TextStyle(color: c.green, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
              ),

              const SizedBox(height: 16),

              Text('NutriTrack creates long-term results',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: c.white)),

              const SizedBox(height: 8),
              Text('Our users maintain their progress even months later.',
                  style: TextStyle(fontSize: 14, color: c.subtext)),

              const SizedBox(height: 28),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: c.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Your weight journey', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.white)),
                        const Spacer(),
                        Row(
                          children: [
                            Container(width: 10, height: 10, decoration: BoxDecoration(color: c.green, shape: BoxShape.circle)),
                            const SizedBox(width: 4),
                            Text('NutriTrack', style: TextStyle(fontSize: 11, color: c.subtext, fontWeight: FontWeight.w500)),
                            const SizedBox(width: 10),
                            Container(width: 10, height: 10, decoration: BoxDecoration(color: Colors.redAccent.shade100, shape: BoxShape.circle)),
                            const SizedBox(width: 4),
                            Text('Traditional', style: TextStyle(fontSize: 11, color: c.subtext, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      height: 180,
                      child: AnimatedBuilder(
                        animation: lineAnimation,
                        builder: (context, child) {
                          return LineChart(LineChartData(
                            gridData: FlGridData(
                              show: true, drawVerticalLine: false, horizontalInterval: 2,
                              getDrawingHorizontalLine: (value) => FlLine(color: c.divider, strokeWidth: 0.8),
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    const labels = ['Month 1', '', 'Month 3', '', 'Month 5', '', 'Month 6'];
                                    if (value.toInt() >= labels.length) return const SizedBox();
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(labels[value.toInt()], style: TextStyle(fontSize: 10, color: c.subtext)),
                                    );
                                  },
                                  reservedSize: 28,
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            minX: 0, maxX: 6, minY: 0, maxY: 7,
                            lineBarsData: [
                              LineChartBarData(
                                spots: getNutriSpots(lineAnimation.value),
                                isCurved: true, color: c.green, barWidth: 2.5, isStrokeCapRound: true,
                                dotData: FlDotData(show: true, getDotPainter: (spot, percent, bar, index) =>
                                    FlDotCirclePainter(radius: 3, color: c.green, strokeWidth: 2, strokeColor: c.surface)),
                                belowBarData: BarAreaData(show: true, color: c.green.withOpacity(0.08)),
                              ),
                              LineChartBarData(
                                spots: getTraditionalSpots(lineAnimation.value),
                                isCurved: true, color: Colors.redAccent.shade100, barWidth: 2.5, isStrokeCapRound: true,
                                dotData: FlDotData(show: true, getDotPainter: (spot, percent, bar, index) =>
                                    FlDotCirclePainter(radius: 3, color: Colors.redAccent.shade100, strokeWidth: 2, strokeColor: c.surface)),
                                belowBarData: BarAreaData(show: true, color: Colors.redAccent.withOpacity(0.05)),
                              ),
                            ],
                          ));
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    FadeTransition(
                      opacity: statAnimation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(color: c.greenDim, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            Icon(Icons.verified_rounded, color: c.green, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text('80% of NutriTrack users maintain weight loss even 6 months later',
                                  style: TextStyle(fontSize: 12, color: c.green, fontWeight: FontWeight.w500, height: 1.4)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),
              OnboardingContinueButton(onTap: goNext),
            ],
          ),
        ),
      ),
    );
  }
}