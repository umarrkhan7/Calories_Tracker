import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class EditPlanScreen extends StatefulWidget {
  const EditPlanScreen({Key? key}) : super(key: key);

  @override
  State<EditPlanScreen> createState() => EditPlanScreenState();
}

class EditPlanScreenState extends State<EditPlanScreen>
    with TickerProviderStateMixin {

  bool loading = true;
  bool saving = false;
  Map<String, dynamic>? currentPlan;

  // editable values
  double weightKg = 70;
  double heightCm = 170;
  String goal = 'lose';
  String activityLevel = 'moderate';
  String dietType = 'classic';
  int workoutsPerWeek = 3;

  // live preview
  double previewCalories = 0;
  double previewProtein = 0;
  double previewCarbs = 0;
  double previewFat = 0;

  late AnimationController fadeController;
  late AnimationController slideController;
  late Animation<double> fadeAnimation;
  late Animation<Offset> slideAnimation;

  final weightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    fadeAnimation = CurvedAnimation(parent: fadeController, curve: Curves.easeIn);
    slideController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: slideController, curve: Curves.easeOut));
    loadPlan();
  }

  @override
  void dispose() {
    fadeController.dispose();
    slideController.dispose();
    weightController.dispose();
    super.dispose();
  }

  Future<void> loadPlan() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final data = await Supabase.instance.client
          .from('user_plans').select().eq('id', user.id).maybeSingle();
      if (mounted && data != null) {
        setState(() {
          currentPlan     = data;
          weightKg        = (data['weight_kg'] as num?)?.toDouble() ?? 70;
          heightCm        = (data['height_cm'] as num?)?.toDouble() ?? 170;
          goal            = data['goal'] ?? 'lose';
          dietType        = data['diet_type'] ?? 'classic';
          workoutsPerWeek = (data['workouts_per_week'] as num?)?.toInt() ?? 3;
          loading         = false;
        });
        weightController.text = weightKg.round().toString();
        updateActivityFromWorkouts();
        recalculate();
        fadeController.forward();
        slideController.forward();
      }
    } catch (e) {
      if (mounted) setState(() => loading = false);
    }
  }

  void updateActivityFromWorkouts() {
    if (workoutsPerWeek >= 6) activityLevel = 'active';
    else if (workoutsPerWeek >= 3) activityLevel = 'moderate';
    else if (workoutsPerWeek >= 1) activityLevel = 'light';
    else activityLevel = 'sedentary';
  }

  void recalculate() {
    final dob = currentPlan?['date_of_birth'];
    int age = 28;
    if (dob != null) {
      final birth = DateTime.parse(dob);
      age = DateTime.now().year - birth.year;
    }

    final gender = currentPlan?['gender'] ?? 'male';

    double bmr;
    if (gender == 'male') {
      bmr = 10 * weightKg + 6.25 * heightCm - 5 * age + 5;
    } else {
      bmr = 10 * weightKg + 6.25 * heightCm - 5 * age - 161;
    }

    const multipliers = {
      'sedentary': 1.2,
      'light': 1.375,
      'moderate': 1.55,
      'active': 1.725,
    };

    final tdee = bmr * (multipliers[activityLevel] ?? 1.55);

    double calories;
    if (goal == 'lose') calories = tdee - 500;
    else if (goal == 'gain') calories = tdee + 300;
    else calories = tdee;

    calories = calories.clamp(1200, 4000);

    double protein, fat, carbs;
    if (dietType == 'keto') {
      protein = calories * 0.30 / 4;
      fat     = calories * 0.60 / 9;
      carbs   = calories * 0.10 / 4;
    } else if (dietType == 'vegan' || dietType == 'vegetarian') {
      protein = calories * 0.20 / 4;
      fat     = calories * 0.25 / 9;
      carbs   = calories * 0.55 / 4;
    } else {
      protein = calories * 0.30 / 4;
      fat     = calories * 0.30 / 9;
      carbs   = calories * 0.40 / 4;
    }

    setState(() {
      previewCalories = calories;
      previewProtein  = protein;
      previewCarbs    = carbs;
      previewFat      = fat;
    });
  }

  Future<void> savePlan() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    setState(() => saving = true);
    try {
      updateActivityFromWorkouts();
      recalculate();

      await Supabase.instance.client.from('user_plans').update({
        'weight_kg':          weightKg,
        'workouts_per_week':  workoutsPerWeek,
        'goal':               goal,
        'diet_type':          dietType,
        'daily_calories':     previewCalories,
        'protein_g':          previewProtein,
        'carbs_g':            previewCarbs,
        'fat_g':              previewFat,
      }).eq('id', user.id);
      NotificationService.instance.showPlanUpdated();

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Plan updated successfully! 🎯'),
          backgroundColor: const Color(0xFF27AE60),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: c.divider),
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded, color: c.white, size: 16),
          ),
        ),
        title: Text('Edit Your Plan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.white)),
      ),
      body: loading
          ? Center(child: CircularProgressIndicator(color: c.green))
          : FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(
          position: slideAnimation,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // ── live preview card ──────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [c.greenDim, c.surface],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: c.green.withOpacity(0.3)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: c.green, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text('Live Preview', style: TextStyle(fontSize: 12, color: c.green, fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 14),
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: previewCalories),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                      builder: (context, val, child) => Text(
                        val.round().toString(),
                        style: TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: c.white, height: 1, letterSpacing: -2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, left: 6),
                      child: Text('kcal/day', style: TextStyle(fontSize: 14, color: c.subtext)),
                    ),
                  ]),
                  const SizedBox(height: 14),
                  Row(children: [
                    PreviewMacro(label: 'Protein', value: previewProtein, color: const Color(0xFF60A5FA)),
                    const SizedBox(width: 12),
                    PreviewMacro(label: 'Carbs', value: previewCarbs, color: Color(0xFFF97316)),
                    const SizedBox(width: 12),
                    PreviewMacro(label: 'Fats', value: previewFat, color: Color(0xFF27AE60)),
                  ]),
                ]),
              ),

              const SizedBox(height: 24),

              // ── weight ─────────────────────────────────────
              SectionLabel(label: 'Current Weight', c: c),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.divider)),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: weightController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: c.white, fontSize: 16, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: 'Weight',
                        hintStyle: TextStyle(color: c.textHint),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      ),
                      onChanged: (val) {
                        final parsed = double.tryParse(val);
                        if (parsed != null) {
                          weightKg = parsed;
                          recalculate();
                        }
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 18),
                    child: Text('kg', style: TextStyle(color: c.subtext, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),

              const SizedBox(height: 20),

              // ── workouts per week ──────────────────────────
              SectionLabel(label: 'Workouts per Week', c: c),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [0, 1, 3, 5, 6].map((w) {
                  final selected = workoutsPerWeek == w;
                  return GestureDetector(
                    onTap: () {
                      setState(() => workoutsPerWeek = w);
                      updateActivityFromWorkouts();
                      recalculate();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        color: selected ? c.green : c.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: selected ? c.green : c.divider, width: selected ? 2 : 1),
                        boxShadow: selected ? [BoxShadow(color: c.green.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))] : [],
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text('$w', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: selected ? Colors.white : c.white)),
                        Text('days', style: TextStyle(fontSize: 9, color: selected ? Colors.white70 : c.subtext)),
                      ]),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // ── goal ───────────────────────────────────────
              SectionLabel(label: 'Your Goal', c: c),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: GoalChip(
                  label: 'Lose', icon: Icons.trending_down_rounded,
                  color: const Color(0xFF3B82F6),
                  selected: goal == 'lose',
                  onTap: () { setState(() => goal = 'lose'); recalculate(); },
                )),
                const SizedBox(width: 10),
                Expanded(child: GoalChip(
                  label: 'Maintain', icon: Icons.balance_rounded,
                  color: c.green,
                  selected: goal == 'maintain',
                  onTap: () { setState(() => goal = 'maintain'); recalculate(); },
                )),
                const SizedBox(width: 10),
                Expanded(child: GoalChip(
                  label: 'Gain', icon: Icons.trending_up_rounded,
                  color: const Color(0xFFF59E0B),
                  selected: goal == 'gain',
                  onTap: () { setState(() => goal = 'gain'); recalculate(); },
                )),
              ]),

              const SizedBox(height: 20),

              // ── diet type ──────────────────────────────────
              SectionLabel(label: 'Diet Type', c: c),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10, runSpacing: 10,
                children: [
                  {'value': 'classic',    'label': 'Classic',     'emoji': '🍗'},
                  {'value': 'vegetarian', 'label': 'Vegetarian',  'emoji': '🥗'},
                  {'value': 'vegan',      'label': 'Vegan',       'emoji': '🌱'},
                  {'value': 'keto',       'label': 'Keto',        'emoji': '🥑'},
                  {'value': 'pescatarian','label': 'Pescatarian', 'emoji': '🐟'},
                  {'value': 'paleo',      'label': 'Paleo',       'emoji': '🥩'},
                ].map((d) {
                  final selected = dietType == d['value'];
                  return GestureDetector(
                    onTap: () { setState(() => dietType = d['value']!); recalculate(); },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? c.greenDim : c.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: selected ? c.green : c.divider, width: selected ? 2 : 1),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(d['emoji']!, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(d['label']!, style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: selected ? c.green : c.white,
                        )),
                      ]),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),

              // ── save button ────────────────────────────────
              SavePlanButton(saving: saving, onTap: savePlan),

              const SizedBox(height: 20),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── section label ──────────────────────────────────────────────────
class SectionLabel extends StatelessWidget {
  final String label;
  final dynamic c;
  const SectionLabel({Key? key, required this.label, required this.c}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.subtext, letterSpacing: 0.3));
  }
}

// ── preview macro ──────────────────────────────────────────────────
class PreviewMacro extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const PreviewMacro({Key? key, required this.label, required this.value, required this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
        builder: (context, val, child) => Text(
          '${val.round()}g',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color),
        ),
      ),
      Text(label, style: TextStyle(fontSize: 11, color: color.withOpacity(0.7))),
    ]);
  }
}

// ── goal chip ──────────────────────────────────────────────────────
class GoalChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const GoalChip({Key? key, required this.label, required this.icon, required this.color, required this.selected, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : c.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? color : c.divider, width: selected ? 2 : 1),
          boxShadow: selected ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))] : [],
        ),
        child: Column(children: [
          Icon(icon, color: selected ? color : c.subtext, size: 22),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: selected ? color : c.white)),
        ]),
      ),
    );
  }
}

// ── save button ────────────────────────────────────────────────────
class SavePlanButton extends StatefulWidget {
  final bool saving;
  final VoidCallback onTap;
  const SavePlanButton({Key? key, required this.saving, required this.onTap}) : super(key: key);

  @override
  State<SavePlanButton> createState() => SavePlanButtonState();
}

class SavePlanButtonState extends State<SavePlanButton> with SingleTickerProviderStateMixin {
  late AnimationController ctrl;
  late Animation<double> scale;

  @override
  void initState() {
    super.initState();
    ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    scale = Tween<double>(begin: 1.0, end: 0.96).animate(ctrl);
  }

  @override
  void dispose() { ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GestureDetector(
      onTapDown: (_) => ctrl.forward(),
      onTapUp: (_) { ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => ctrl.reverse(),
      child: ScaleTransition(
        scale: scale,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: c.green,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: c.green.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Center(
            child: widget.saving
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Text('Save Plan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ),
      ),
    );
  }
}