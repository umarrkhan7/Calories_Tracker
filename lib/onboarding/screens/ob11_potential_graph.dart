import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../onboarding_scaffold.dart';
import '../onboarding_controller.dart';
import '../../theme/app_theme.dart';
import 'ob12_thank_you.dart';

class PotentialGraphScreen extends StatefulWidget {
  const PotentialGraphScreen({Key? key}) : super(key: key);
  @override
  State<PotentialGraphScreen> createState() => PotentialGraphScreenState();
}

class PotentialGraphScreenState extends State<PotentialGraphScreen>
    with TickerProviderStateMixin {

  late AnimationController lineController;
  late AnimationController fadeController;
  late AnimationController badgeController;
  late Animation<double> lineAnimation;
  late Animation<double> fadeAnimation;
  late Animation<double> badgeAnimation;

  @override
  void initState() {
    super.initState();
    fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    fadeAnimation = CurvedAnimation(parent: fadeController, curve: Curves.easeIn);
    lineController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
    lineAnimation = CurvedAnimation(parent: lineController, curve: Curves.easeInOut);
    badgeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    badgeAnimation = CurvedAnimation(parent: badgeController, curve: Curves.elasticOut);
    fadeController.forward().then((_) {
      lineController.forward().then((_) => badgeController.forward());
    });
  }

  @override
  void dispose() {
    lineController.dispose();
    fadeController.dispose();
    badgeController.dispose();
    super.dispose();
  }

  List<FlSpot> getSpots(double progress) {
    final all = [FlSpot(0, 1.0), FlSpot(3, 1.2), FlSpot(7, 1.8), FlSpot(14, 2.8), FlSpot(21, 4.0), FlSpot(30, 5.5)];
    final count = (all.length * progress).ceil().clamp(1, all.length);
    return all.take(count).toList();
  }

  void goNext() {
    final controller = context.read<OnboardingController>();
    Navigator.push(context, PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => ChangeNotifierProvider.value(
          value: controller, child: const ThankYouScreen()),
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
      currentStep: 11, totalSteps: 15, showSkip: false,
      child: FadeTransition(opacity: fadeAnimation,
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFFF59E0B).withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
              child: const Text('Your potential', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 12, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 14),
            Text('You have great\npotential!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: c.white)),
            const SizedBox(height: 8),
            Text('Based on your profile, here is your expected progress.', style: TextStyle(fontSize: 14, color: c.subtext)),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: c.divider),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Your weight transition', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.white)),
                const SizedBox(height: 20),
                SizedBox(
                  height: 190,
                  child: AnimatedBuilder(
                    animation: lineAnimation,
                    builder: (context, child) => LineChart(LineChartData(
                      gridData: FlGridData(
                        show: true, drawVerticalLine: false,
                        getDrawingHorizontalLine: (v) => FlLine(color: c.divider, strokeWidth: 0.8),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(sideTitles: SideTitles(
                          showTitles: true, reservedSize: 28,
                          getTitlesWidget: (value, meta) {
                            const map = {0: '3 Days', 7: '7 Days', 30: '30 Days'};
                            if (!map.containsKey(value)) return const SizedBox();
                            return Padding(padding: const EdgeInsets.only(top: 6),
                                child: Text(map[value]!, style: TextStyle(fontSize: 11, color: c.subtext)));
                          },
                        )),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0, maxX: 30, minY: 0, maxY: 7,
                      lineBarsData: [LineChartBarData(
                        spots: getSpots(lineAnimation.value),
                        isCurved: true,
                        color: c.green,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                            radius: index == getSpots(lineAnimation.value).length - 1 ? 6 : 3,
                            color: c.green,
                            strokeWidth: 2, strokeColor: c.surface,
                          ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [c.green.withOpacity(0.2), c.green.withOpacity(0.0)],
                            begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          ),
                        ),
                      )],
                    )),
                  ),
                ),
                const SizedBox(height: 16),
                ScaleTransition(
                  scale: badgeAnimation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(color: c.greenDim, borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      Icon(Icons.bolt_rounded, color: c.green, size: 18),
                      const SizedBox(width: 10),
                      Expanded(child: Text(
                        'After 7 days your metabolism kicks in — fat burns faster!',
                        style: TextStyle(fontSize: 12, color: c.green, fontWeight: FontWeight.w500, height: 1.4),
                      )),
                    ]),
                  ),
                ),
              ]),
            ),
            const Spacer(),
            OnboardingContinueButton(onTap: goNext),
          ]),
        ),
      ),
    );
  }
}