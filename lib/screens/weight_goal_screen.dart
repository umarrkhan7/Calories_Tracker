import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

class WeightGoalScreen extends StatefulWidget {
  const WeightGoalScreen({Key? key}) : super(key: key);

  @override
  State<WeightGoalScreen> createState() => WeightGoalScreenState();
}

class WeightGoalScreenState extends State<WeightGoalScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController fadeController;
  late Animation<double> fadeAnimation;

  bool loading = true;
  bool saving = false;
  String? error;

  double currentWeight = 0;
  double goalWeight = 0;
  double startWeight = 0;
  List<Map<String, dynamic>> weightLogs = [];
  Map<String, dynamic>? userPlan;

  final weightController = TextEditingController();
  final goalController = TextEditingController();
  final noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    fadeAnimation = CurvedAnimation(parent: fadeController, curve: Curves.easeOut);
    loadData();
  }

  @override
  void dispose() {
    fadeController.dispose();
    weightController.dispose();
    goalController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    setState(() { loading = true; error = null; });
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final results = await Future.wait([
        Supabase.instance.client.from('user_plans').select().eq('id', user.id).maybeSingle(),
        Supabase.instance.client.from('weight_logs').select()
            .eq('user_id', user.id)
            .order('log_date', ascending: true)
            .limit(30),
      ]);

      final plan = results[0] as Map<String, dynamic>?;
      final logs = List<Map<String, dynamic>>.from(results[1] as List);

      if (mounted) {
        setState(() {
          userPlan = plan;
          weightLogs = logs;
          currentWeight = (plan?['weight_kg'] as num?)?.toDouble() ?? 0;
          goalWeight = (plan?['goal_weight_kg'] as num?)?.toDouble() ?? 0;
          startWeight = logs.isNotEmpty
              ? (logs.first['weight_kg'] as num?)?.toDouble() ?? currentWeight
              : currentWeight;
          if (logs.isNotEmpty) {
            currentWeight = (logs.last['weight_kg'] as num?)?.toDouble() ?? currentWeight;
          }
          goalController.text = goalWeight > 0 ? goalWeight.toStringAsFixed(1) : '';
          loading = false;
        });
        fadeController.forward();
      }
    } catch (e) {
      if (mounted) setState(() { loading = false; error = e.toString(); });
    }
  }

  double get progressPercent {
    if (startWeight == goalWeight || startWeight == 0 || goalWeight == 0) return 0;
    final total = (startWeight - goalWeight).abs();
    final done = (startWeight - currentWeight).abs();
    return (done / total).clamp(0.0, 1.0);
  }

  double get weightToGo => (currentWeight - goalWeight).abs();

  String get goalLabel {
    if (goalWeight == 0 || currentWeight == 0) return 'Set your goal';
    if (currentWeight > goalWeight) return 'to lose';
    if (currentWeight < goalWeight) return 'to gain';
    return 'Goal reached!';
  }

  Color progressColor(AppColorExtension c) {
    if (progressPercent >= 1.0) return c.green;
    if (progressPercent >= 0.5) return const Color(0xFFF59E0B);
    return const Color(0xFF3B82F6);
  }

  String formatDate(String dateStr) {
    final dt = DateTime.parse(dateStr);
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  Future<void> logWeight(DateTime date) async {
    final weightText = weightController.text.trim();
    if (weightText.isEmpty) return;
    final weight = double.tryParse(weightText);
    if (weight == null || weight <= 0) return;

    setState(() => saving = true);
    final user = Supabase.instance.client.auth.currentUser!;

    try {
      await Supabase.instance.client.from('weight_logs').upsert({
        'user_id': user.id,
        'weight_kg': weight,
        'log_date': date.toIso8601String().split('T')[0],
        'note': noteController.text.trim().isEmpty ? null : noteController.text.trim(),
      });

      // update current weight in user_plans
      await Supabase.instance.client.from('user_plans')
          .update({'weight_kg': weight}).eq('id', user.id);

      weightController.clear();
      noteController.clear();
      if (mounted) Navigator.pop(context);
      await loadData();
    } catch (e) {
      if (mounted) setState(() => error = 'Failed to log weight: $e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> updateGoal() async {
    final goalText = goalController.text.trim();
    if (goalText.isEmpty) return;
    final goal = double.tryParse(goalText);
    if (goal == null || goal <= 0) return;

    final user = Supabase.instance.client.auth.currentUser!;
    try {
      await Supabase.instance.client.from('user_plans')
          .update({'goal_weight_kg': goal}).eq('id', user.id);
      await loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Goal updated!'),
          backgroundColor: const Color(0xFF2ECC71),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) setState(() => error = 'Failed to update goal: $e');
    }
  }

  void showLogWeightSheet() {
    final c = context.c;
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: c.divider, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),

            Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: c.greenDim, borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.monitor_weight_rounded, color: c.green, size: 22),
              ),
              const SizedBox(width: 14),
              Text('Log Weight', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c.white)),
            ]),

            const SizedBox(height: 24),

            // date picker
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  builder: (context, child) => Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.dark(primary: c.green, surface: c.surface, onSurface: c.white),
                    ),
                    child: child!,
                  ),
                );
                if (picked != null) setSheetState(() => selectedDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: c.surfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.divider),
                ),
                child: Row(children: [
                  Icon(Icons.calendar_today_rounded, color: c.green, size: 16),
                  const SizedBox(width: 10),
                  Text(
                    '${selectedDate.day} ${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][selectedDate.month-1]} ${selectedDate.year}',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.white),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_drop_down_rounded, color: c.subtext),
                ]),
              ),
            ),

            const SizedBox(height: 14),

            // weight input
            Container(
              decoration: BoxDecoration(
                color: c.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.divider),
              ),
              child: TextField(
                controller: weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                style: TextStyle(fontSize: 16, color: c.white, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'Weight (kg)',
                  hintStyle: TextStyle(color: c.subtext),
                  prefixIcon: Icon(Icons.monitor_weight_outlined, color: c.subtext, size: 20),
                  suffixText: 'kg',
                  suffixStyle: TextStyle(color: c.green, fontWeight: FontWeight.w700),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // note input
            Container(
              decoration: BoxDecoration(
                color: c.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.divider),
              ),
              child: TextField(
                controller: noteController,
                style: TextStyle(fontSize: 14, color: c.white),
                decoration: InputDecoration(
                  hintText: 'Add a note (optional)',
                  hintStyle: TextStyle(color: c.subtext),
                  prefixIcon: Icon(Icons.notes_rounded, color: c.subtext, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: 20),

            GestureDetector(
              onTap: saving ? null : () => logWeight(selectedDate),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: c.green,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: c.green.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: Center(
                  child: saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save Weight', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void showEditGoalSheet() {
    final c = context.c;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: c.divider, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),

          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: c.greenDim, borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.flag_rounded, color: c.green, size: 22),
            ),
            const SizedBox(width: 14),
            Text('Set Goal Weight', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c.white)),
          ]),

          const SizedBox(height: 24),

          Container(
            decoration: BoxDecoration(
              color: c.surfaceAlt,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.divider),
            ),
            child: TextField(
              controller: goalController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: TextStyle(fontSize: 16, color: c.white, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Goal weight (kg)',
                hintStyle: TextStyle(color: c.subtext),
                prefixIcon: Icon(Icons.flag_outlined, color: c.subtext, size: 20),
                suffixText: 'kg',
                suffixStyle: TextStyle(color: c.green, fontWeight: FontWeight.w700),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),

          const SizedBox(height: 20),

          GestureDetector(
            onTap: () {
              Navigator.pop(ctx);
              updateGoal();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: c.green,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: c.green.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: const Center(
                child: Text('Update Goal', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.surface,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: c.surfaceAlt, borderRadius: BorderRadius.circular(10), border: Border.all(color: c.divider)),
            child: Icon(Icons.arrow_back_ios_new_rounded, color: c.white, size: 16),
          ),
        ),
        title: Text('Weight & Goal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.white)),
        actions: [
          GestureDetector(
            onTap: showEditGoalSheet,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(color: c.greenDim, borderRadius: BorderRadius.circular(20)),
              child: Row(children: [
                Icon(Icons.flag_rounded, color: c.green, size: 14),
                const SizedBox(width: 6),
                Text('Edit Goal', style: TextStyle(color: c.green, fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ],
      ),
      body: loading
          ? Center(child: CircularProgressIndicator(color: c.green))
          : error != null
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.error_outline, color: const Color(0xFFEF4444), size: 48),
        const SizedBox(height: 12),
        Text(error!, style: TextStyle(color: c.subtext, fontSize: 13), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        GestureDetector(onTap: loadData, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(color: c.green, borderRadius: BorderRadius.circular(12)),
          child: const Text('Retry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        )),
      ]))
          : FadeTransition(
        opacity: fadeAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // stats row
              Row(children: [
                Expanded(child: StatCard(
                  label: 'Current',
                  value: currentWeight > 0 ? '${currentWeight.toStringAsFixed(1)} kg' : '--',
                  icon: Icons.monitor_weight_rounded,
                  color: const Color(0xFF3B82F6),
                  c: c,
                )),
                const SizedBox(width: 12),
                Expanded(child: StatCard(
                  label: 'Goal',
                  value: goalWeight > 0 ? '${goalWeight.toStringAsFixed(1)} kg' : 'Not set',
                  icon: Icons.flag_rounded,
                  color: c.green,
                  c: c,
                )),
                const SizedBox(width: 12),
                Expanded(child: StatCard(
                  label: goalLabel,
                  value: goalWeight > 0 && currentWeight > 0 ? '${weightToGo.toStringAsFixed(1)} kg' : '--',
                  icon: Icons.trending_down_rounded,
                  color: const Color(0xFFF59E0B),
                  c: c,
                )),
              ]),

              const SizedBox(height: 16),

              // progress card
              if (goalWeight > 0 && currentWeight > 0)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: c.divider),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text('Progress to Goal', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.white)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: progressColor(c).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('${(progressPercent * 100).round()}%',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: progressColor(c))),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 12, color: c.surfaceAlt,
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progressPercent,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 800),
                            decoration: BoxDecoration(
                              color: progressColor(c),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      Text('Start: ${startWeight.toStringAsFixed(1)} kg', style: TextStyle(fontSize: 11, color: c.subtext)),
                      const Spacer(),
                      Text('Goal: ${goalWeight.toStringAsFixed(1)} kg', style: TextStyle(fontSize: 11, color: c.subtext)),
                    ]),
                  ]),
                ),

              const SizedBox(height: 16),

              // chart
              if (weightLogs.length >= 2)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: c.divider),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Weight History', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.white)),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 180,
                      child: LineChart(LineChartData(
                        gridData: FlGridData(
                          show: true, drawVerticalLine: false,
                          getDrawingHorizontalLine: (v) => FlLine(color: c.divider, strokeWidth: 0.8),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(sideTitles: SideTitles(
                            showTitles: true, reservedSize: 40,
                            getTitlesWidget: (value, meta) => Text(
                              '${value.toStringAsFixed(0)}kg',
                              style: TextStyle(fontSize: 10, color: c.subtext),
                            ),
                          )),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(sideTitles: SideTitles(
                            showTitles: true, reservedSize: 24,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= weightLogs.length) return const SizedBox();
                              if (index % (weightLogs.length > 7 ? (weightLogs.length ~/ 5) : 1) != 0) return const SizedBox();
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(formatDate(weightLogs[index]['log_date']),
                                    style: TextStyle(fontSize: 9, color: c.subtext)),
                              );
                            },
                          )),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          // weight line
                          LineChartBarData(
                            spots: weightLogs.asMap().entries.map((e) =>
                                FlSpot(e.key.toDouble(), (e.value['weight_kg'] as num).toDouble())).toList(),
                            isCurved: true,
                            color: const Color(0xFF3B82F6),
                            barWidth: 2.5,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                                radius: 4, color: const Color(0xFF3B82F6),
                                strokeWidth: 2, strokeColor: c.surface,
                              ),
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              color: const Color(0xFF3B82F6).withOpacity(0.08),
                            ),
                          ),
                          // goal line
                          if (goalWeight > 0)
                            LineChartBarData(
                              spots: [
                                FlSpot(0, goalWeight),
                                FlSpot((weightLogs.length - 1).toDouble(), goalWeight),
                              ],
                              isCurved: false,
                              color: c.green.withOpacity(0.5),
                              barWidth: 1.5,
                              dashArray: [6, 4],
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(show: false),
                            ),
                        ],
                      )),
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      Container(width: 12, height: 3, color: const Color(0xFF3B82F6)),
                      const SizedBox(width: 6),
                      Text('Your weight', style: TextStyle(fontSize: 11, color: c.subtext)),
                      const SizedBox(width: 16),
                      Container(width: 12, height: 3, color: c.green.withOpacity(0.5)),
                      const SizedBox(width: 6),
                      Text('Goal', style: TextStyle(fontSize: 11, color: c.subtext)),
                    ]),
                  ]),
                ),

              const SizedBox(height: 16),

              // history list
              if (weightLogs.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: c.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text('History', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.white)),
                      ),
                      ...weightLogs.reversed.toList().asMap().entries.map((entry) {
                        final i = entry.key;
                        final log = entry.value;
                        final weight = (log['weight_kg'] as num).toDouble();
                        final isFirst = i == 0;
                        // compare with next entry (previous in time)
                        final logs = weightLogs.reversed.toList();
                        double? diff;
                        if (i < logs.length - 1) {
                          diff = weight - (logs[i + 1]['weight_kg'] as num).toDouble();
                        }

                        return Column(children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  color: isFirst ? c.greenDim : c.surfaceAlt,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(child: Icon(
                                  Icons.monitor_weight_outlined,
                                  color: isFirst ? c.green : c.subtext,
                                  size: 18,
                                )),
                              ),
                              const SizedBox(width: 14),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(formatDate(log['log_date']),
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.white)),
                                if (log['note'] != null && log['note'].toString().isNotEmpty)
                                  Text(log['note'], style: TextStyle(fontSize: 11, color: c.subtext)),
                              ])),
                              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                Text('${weight.toStringAsFixed(1)} kg',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: c.white)),
                                if (diff != null)
                                  Row(mainAxisSize: MainAxisSize.min, children: [
                                    Icon(
                                      diff < 0 ? Icons.trending_down_rounded : diff > 0 ? Icons.trending_up_rounded : Icons.remove_rounded,
                                      size: 12,
                                      color: diff < 0 ? c.green : diff > 0 ? const Color(0xFFEF4444) : c.subtext,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)} kg',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: diff < 0 ? c.green : diff > 0 ? const Color(0xFFEF4444) : c.subtext,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ]),
                              ]),
                            ]),
                          ),
                          if (i < weightLogs.length - 1)
                            Divider(color: c.divider, height: 1, indent: 16, endIndent: 16),
                        ]);
                      }).toList(),
                    ],
                  ),
                ),

              if (weightLogs.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: c.divider),
                  ),
                  child: Column(children: [
                    Text('⚖️', style: const TextStyle(fontSize: 48)),
                    const SizedBox(height: 16),
                    Text('No weight logged yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.white)),
                    const SizedBox(height: 4),
                    Text('Tap the button below to log your first weight!',
                        textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: c.subtext)),
                  ]),
                ),

              const SizedBox(height: 100),
            ]),
          ),
        ),
      ),

      floatingActionButton: GestureDetector(
        onTap: showLogWeightSheet,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: c.green,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [BoxShadow(color: c.green.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 4))],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.add_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            const Text('Log Weight', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
          ]),
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final AppColorExtension c;

  const StatCard({Key? key, required this.label, required this.value,
    required this.icon, required this.color, required this.c}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.divider),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(height: 10),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: c.white)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10, color: c.subtext)),
      ]),
    );
  }
}