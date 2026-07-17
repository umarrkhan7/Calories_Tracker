import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import 'progress_photos_screen.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({Key? key}) : super(key: key);

  @override
  State<ProgressScreen> createState() => ProgressScreenState();
}

class ProgressScreenState extends State<ProgressScreen>
    with SingleTickerProviderStateMixin {

  Map<String, dynamic>? userPlan;
  bool loading = true;
  int selectedWeek = 0;

  late AnimationController fadeController;
  late Animation<double> fadeAnimation;

  Map<String, double> weeklyCalories = {
    'Sun': 0, 'Mon': 0, 'Tue': 0, 'Wed': 0, 'Thu': 0, 'Fri': 0, 'Sat': 0,
  };

  double consumedCalories = 0;
  double burnedCalories = 0;

  @override
  void initState() {
    super.initState();
    fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    fadeAnimation = CurvedAnimation(parent: fadeController, curve: Curves.easeIn);
    loadData();
  }

  @override
  void dispose() {
    fadeController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final plan = await Supabase.instance.client
          .from('user_plans').select().eq('id', user.id).maybeSingle();
      await loadWeekData();
      if (mounted) {
        setState(() { userPlan = plan; loading = false; });
        fadeController.forward();
      }
    } catch (e) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> loadWeekData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final now = DateTime.now();
      final monday = now.subtract(Duration(days: now.weekday - 1 + (selectedWeek * 7)));
      final weekStart = monday.subtract(const Duration(days: 1));
      final weekEnd = weekStart.add(const Duration(days: 6));

      final logs = await Supabase.instance.client
          .from('daily_logs').select()
          .eq('user_id', user.id)
          .gte('log_date', weekStart.toIso8601String().split('T')[0])
          .lte('log_date', weekEnd.toIso8601String().split('T')[0]);

      final newWeekly = {'Sun': 0.0, 'Mon': 0.0, 'Tue': 0.0, 'Wed': 0.0, 'Thu': 0.0, 'Fri': 0.0, 'Sat': 0.0};
      double totalConsumed = 0;
      double totalBurned = 0;
      const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

      for (final log in logs) {
        final date = DateTime.parse(log['log_date']);
        final dayName = dayNames[date.weekday - 1];
        final consumed = (log['calories_consumed'] as num?)?.toDouble() ?? 0;
        newWeekly[dayName] = consumed;
        totalConsumed += consumed;
        totalBurned += (log['calories_burned'] as num?)?.toDouble() ?? 0;
      }

      if (mounted) {
        setState(() {
          weeklyCalories = newWeekly;
          consumedCalories = totalConsumed;
          burnedCalories = totalBurned;
        });
      }
    } catch (e) {}
  }

  double get heightCm => (userPlan?['height_cm'] as num?)?.toDouble() ?? 170;
  double get weightKg => (userPlan?['weight_kg'] as num?)?.toDouble() ?? 70;

  double get bmi {
    final h = heightCm / 100;
    if (h <= 0) return 0;
    return weightKg / (h * h);
  }

  String get bmiCategory {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25)   return 'Healthy';
    if (bmi < 30)   return 'Overweight';
    return 'Obese';
  }

  Color get bmiColor {
    if (bmi < 18.5) return const Color(0xFF3B82F6);
    if (bmi < 25)   return const Color(0xFF27AE60);
    if (bmi < 30)   return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  double get bmiPosition => ((bmi - 15.0) / (35.0 - 15.0)).clamp(0.0, 1.0);
  double get netEnergy => consumedCalories - burnedCalories;

  void onWeekSelect(int week) {
    setState(() => selectedWeek = week);
    loadWeekData();
  }

  void showBmiInfo(BuildContext context, AppColorExtension c) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('What is BMI?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.white)),
            const SizedBox(height: 10),
            Text(
              'Body Mass Index (BMI) is a measure of body fat based on height and weight. '
                  'It helps categorise whether your weight is in a healthy range for your height.',
              style: TextStyle(fontSize: 13, color: c.subtext, height: 1.5),
            ),
            const SizedBox(height: 16),
            Align(alignment: Alignment.centerRight, child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Got it', style: TextStyle(color: c.green, fontWeight: FontWeight.w700)),
            )),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: loading
            ? Center(child: CircularProgressIndicator(color: c.green))
            : FadeTransition(
          opacity: fadeAnimation,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Text('Progress', style: TextStyle(
                    fontSize: 28, fontWeight: FontWeight.w800,
                    color: c.white, letterSpacing: -0.8)),
              ),

              // progress photos card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: c.divider),
                  ),
                  child: Row(children: [
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(color: c.surfaceAlt, borderRadius: BorderRadius.circular(16)),
                      child: Icon(Icons.image_outlined, color: c.subtext, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Progress Photos', style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700, color: c.white)),
                      const SizedBox(height: 4),
                      Text('Want to add a photo to track your progress?',
                          style: TextStyle(fontSize: 12, color: c.subtext, height: 1.4)),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ProgressPhotosScreen()),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(color: c.greenDim, borderRadius: BorderRadius.circular(20)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.add_rounded, color: c.green, size: 14),
                            const SizedBox(width: 4),
                            Text('Upload a Photo', style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600, color: c.green)),
                          ]),
                        ),
                      ),
                    ])),
                  ]),
                ),
              ),

              const SizedBox(height: 16),

              // daily average calories card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: c.divider),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Daily Average Calories', style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700, color: c.white)),
                    const SizedBox(height: 12),
                    Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(
                        (weeklyCalories.values.reduce((a, b) => a + b) / 7).round().toString(),
                        style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: c.white, height: 1),
                      ),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text('cals', style: TextStyle(fontSize: 14, color: c.subtext)),
                      ),
                    ]),
                    const SizedBox(height: 16),

                    // bar chart
                    SizedBox(
                      height: 140,
                      child: BarChart(BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: weeklyCalories.values.every((v) => v == 0)
                            ? 100
                            : weeklyCalories.values.reduce((a, b) => a > b ? a : b) * 1.2,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: weeklyCalories.values.every((v) => v == 0) ? 20 : null,
                          getDrawingHorizontalLine: (v) => FlLine(color: c.divider, strokeWidth: 1, dashArray: [4, 4]),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(sideTitles: SideTitles(
                            showTitles: true, reservedSize: 28,
                            getTitlesWidget: (value, meta) => Text(value.toInt().toString(),
                                style: TextStyle(fontSize: 10, color: c.subtext)),
                          )),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(sideTitles: SideTitles(
                            showTitles: true, reservedSize: 24,
                            getTitlesWidget: (value, meta) {
                              const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
                              return Padding(padding: const EdgeInsets.only(top: 6),
                                  child: Text(days[value.toInt()], style: TextStyle(fontSize: 10, color: c.subtext)));
                            },
                          )),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(7, (i) {
                          const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
                          return BarChartGroupData(x: i, barRods: [
                            BarChartRodData(
                              toY: weeklyCalories[days[i]] ?? 0,
                              color: c.green,
                              width: 22,
                              borderRadius: BorderRadius.circular(6),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: weeklyCalories.values.every((v) => v == 0) ? 100 : weeklyCalories.values.reduce((a, b) => a > b ? a : b) * 1.2,
                                color: c.surfaceAlt,
                              ),
                            ),
                          ]);
                        }),
                      )),
                    ),

                    const SizedBox(height: 16),

                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      LegendDot(emoji: '🥩', label: 'Protein', c: c),
                      const SizedBox(width: 20),
                      LegendDot(emoji: '🌾', label: 'Carbs', c: c),
                      const SizedBox(width: 20),
                      LegendDot(emoji: '🥑', label: 'Fats', c: c),
                    ]),

                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: c.surfaceAlt, borderRadius: BorderRadius.circular(14)),
                      child: Row(children: [
                        WeekTab(label: 'This wk',  selected: selectedWeek == 0, onTap: () => onWeekSelect(0), c: c),
                        WeekTab(label: 'Last wk',  selected: selectedWeek == 1, onTap: () => onWeekSelect(1), c: c),
                        WeekTab(label: '2 wk ago', selected: selectedWeek == 2, onTap: () => onWeekSelect(2), c: c),
                        WeekTab(label: '3 wk ago', selected: selectedWeek == 3, onTap: () => onWeekSelect(3), c: c),
                      ]),
                    ),
                  ]),
                ),
              ),

              const SizedBox(height: 16),

              // weekly energy
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: c.divider),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Weekly Energy', style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700, color: c.white)),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(child: EnergyStat(label: 'Consumed', value: consumedCalories.round().toString(), color: c.white, c: c)),
                      Expanded(child: EnergyStat(label: 'Burned',   value: burnedCalories.round().toString(),   color: c.white, c: c)),
                      Expanded(child: EnergyStat(label: 'Energy',   value: netEnergy.round().toString(),
                          color: netEnergy >= 0 ? const Color(0xFFEF4444) : c.green, c: c)),
                    ]),
                  ]),
                ),
              ),

              const SizedBox(height: 16),

              // expenditure changes
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: c.divider),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Expenditure Changes', style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700, color: c.white)),
                    const SizedBox(height: 14),
                    ExpenditureRow(label: '3 day',   value: '0.0 Kcal', change: 'No change', c: c),
                    ExpenditureRow(label: '7 day',   value: '0.0 Kcal', change: 'No change', c: c),
                    ExpenditureRow(label: '14 day',  value: '0.0 Kcal', change: 'No change', c: c),
                    ExpenditureRow(label: '30 day',  value: '0.0 Kcal', change: 'No change', c: c),
                    ExpenditureRow(label: '90 day',  value: '0.0 Kcal', change: 'No change', c: c),
                    ExpenditureRow(label: 'All Time', value: '0.0 Kcal', change: 'No change', isLast: true, c: c),
                  ]),
                ),
              ),

              const SizedBox(height: 16),

              // BMI card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: c.divider),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text('Your BMI', style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700, color: c.white)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => showBmiInfo(context, c),
                        child: Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(color: c.surfaceAlt, shape: BoxShape.circle),
                          child: Icon(Icons.help_outline_rounded, color: c.subtext, size: 16),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 14),
                    Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(bmi.toStringAsFixed(2), style: TextStyle(
                          fontSize: 36, fontWeight: FontWeight.w800, color: c.white, height: 1)),
                      const SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(children: [
                          Text('Your weight is ', style: TextStyle(fontSize: 13, color: c.subtext)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: bmiColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(bmiCategory, style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700, color: bmiColor)),
                          ),
                        ]),
                      ),
                    ]),
                    const SizedBox(height: 20),

                    SizedBox(
                      height: 24,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            top: 7, left: 0, right: 0,
                            child: Container(
                              height: 10,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                gradient: const LinearGradient(colors: [
                                  Color(0xFF3B82F6),
                                  Color(0xFF27AE60),
                                  Color(0xFFF59E0B),
                                  Color(0xFFEF4444),
                                ], stops: [0.0, 0.3, 0.6, 1.0]),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 2,
                            left: (bmiPosition * (MediaQuery.of(context).size.width - 80)).clamp(0, MediaQuery.of(context).size.width - 80),
                            child: Container(
                              width: 20, height: 20,
                              decoration: BoxDecoration(
                                color: c.bg,
                                shape: BoxShape.circle,
                                border: Border.all(color: bmiColor, width: 3),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 2))],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [
                      BmiLegendItem(color: Color(0xFF3B82F6), label: 'Underweight'),
                      BmiLegendItem(color: Color(0xFF27AE60), label: 'Healthy'),
                      BmiLegendItem(color: Color(0xFFF59E0B), label: 'Overweight'),
                      BmiLegendItem(color: Color(0xFFEF4444), label: 'Obese'),
                    ]),
                  ]),
                ),
              ),

              const SizedBox(height: 110),
            ]),
          ),
        ),
      ),
    );
  }
}

class LegendDot extends StatelessWidget {
  final String emoji, label;
  final AppColorExtension c;
  const LegendDot({Key? key, required this.emoji, required this.label, required this.c}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text(emoji, style: const TextStyle(fontSize: 14)),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.subtext)),
    ]);
  }
}

class WeekTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final AppColorExtension c;
  const WeekTab({Key? key, required this.label, required this.selected, required this.onTap, required this.c}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? c.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))] : [],
          ),
          child: Center(child: Text(label, style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? c.white : c.subtext))),
        ),
      ),
    );
  }
}

class EnergyStat extends StatelessWidget {
  final String label, value;
  final Color color;
  final AppColorExtension c;
  const EnergyStat({Key? key, required this.label, required this.value, required this.color, required this.c}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 12, color: c.subtext)),
      const SizedBox(height: 4),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(width: 3),
        Padding(padding: const EdgeInsets.only(bottom: 3),
            child: Text('cals', style: TextStyle(fontSize: 11, color: c.subtext))),
      ]),
    ]);
  }
}

class ExpenditureRow extends StatelessWidget {
  final String label, value, change;
  final bool isLast;
  final AppColorExtension c;
  const ExpenditureRow({Key? key, required this.label, required this.value,
    required this.change, required this.c, this.isLast = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(children: [
        SizedBox(width: 60, child: Text(label, style: TextStyle(fontSize: 13, color: c.subtext, fontWeight: FontWeight.w500))),
        Expanded(child: Container(height: 1.5, color: c.divider, margin: const EdgeInsets.symmetric(horizontal: 12))),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.white)),
        const SizedBox(width: 8),
        Icon(Icons.arrow_forward_rounded, size: 12, color: c.subtext),
        const SizedBox(width: 4),
        Text(change, style: TextStyle(fontSize: 12, color: c.subtext)),
      ]),
    );
  }
}

class BmiLegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const BmiLegendItem({Key? key, required this.color, required this.label}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 9, color: c.subtext)),
    ]);
  }
}