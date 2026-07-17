import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../services/notification_service.dart';

class FruitDetailScreen extends StatefulWidget {
  final Map<String, dynamic> fruit;

  /// Path to the photo the user just captured/picked during a scan.
  /// When provided, this is shown instead of the stock asset image.
  final String? scannedImagePath;

  /// Model confidence (0-100) for a scan result. When provided, a small
  /// badge is shown over the header image. Null for manual lookups.
  final double? confidence;

  const FruitDetailScreen({
    Key? key,
    required this.fruit,
    this.scannedImagePath,
    this.confidence,
  }) : super(key: key);

  @override
  State<FruitDetailScreen> createState() => FruitDetailScreenState();
}

class FruitDetailScreenState extends State<FruitDetailScreen>
    with TickerProviderStateMixin {

  double servings = 1.0;
  bool logging = false;

  late AnimationController fadeController;
  late Animation<double> fadeAnimation;

  // success overlay controllers
  late AnimationController successController;
  late Animation<double> successScale;
  late Animation<double> successFade;
  late Animation<double> tickAnim;
  bool showSuccess = false;

  @override
  void initState() {
    super.initState();
    fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    fadeAnimation = CurvedAnimation(parent: fadeController, curve: Curves.easeIn);
    fadeController.forward();

    successController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    successScale = Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: successController, curve: Curves.elasticOut));
    successFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: successController, curve: const Interval(0.0, 0.4, curve: Curves.easeIn)));
    tickAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: successController, curve: const Interval(0.4, 1.0, curve: Curves.easeOut)));
  }

  @override
  void dispose() {
    fadeController.dispose();
    successController.dispose();
    super.dispose();
  }

  double get servingGrams => (widget.fruit['serving_size_g'] as num?)?.toDouble() ?? 100;
  double calc(String key) => ((widget.fruit[key] as num?)?.toDouble() ?? 0) * servingGrams / 100 * servings;
  double get totalCalories => calc('calories_per_100g');
  double get totalProtein  => calc('protein_per_100g');
  double get totalFat      => calc('fat_per_100g');
  double get totalCarbs    => calc('carbs_per_100g');
  double get totalFiber    => calc('fiber_per_100g');

  String get todayDate {
    final now = DateTime.now();
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${now.day} ${months[now.month - 1]}';
  }

  /// Returns the image reference to save with this log entry.
  /// - If this came from a scan, uploads the real captured photo to
  ///   Supabase Storage and returns its public URL.
  /// - If this came from manual lookup (no scanned photo), keeps using
  ///   the bundled stock asset path as before.
  Future<String> _resolveLoggedImage(String userId) async {
    if (widget.scannedImagePath == null) {
      return widget.fruit['image'] ?? '';
    }

    try {
      final bytes = await File(widget.scannedImagePath!).readAsBytes();
      final fileName = '$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';

      await Supabase.instance.client.storage.from('fruit-scans').uploadBinary(
        fileName,
        bytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg'),
      );

      return Supabase.instance.client.storage
          .from('fruit-scans')
          .getPublicUrl(fileName);
    } catch (e) {
      // If the upload fails for any reason, don't block logging —
      // just fall back to the stock image so the entry still saves.
      return widget.fruit['image'] ?? '';
    }
  }

  Future<void> logFruit() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    setState(() => logging = true);

    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final loggedImage = await _resolveLoggedImage(user.id);

      // 1. insert food_logs (individual entry)
      await Supabase.instance.client.from('food_logs').insert({
        'user_id':     user.id,
        'log_date':    today,
        'fruit_name':  widget.fruit['name'],
        'fruit_image': loggedImage,
        'servings':    servings,
        'calories':    totalCalories,
        'protein_g':   totalProtein,
        'carbs_g':     totalCarbs,
        'fat_g':       totalFat,
      });

      // 2. upsert daily_logs (running totals)
      final existing = await Supabase.instance.client
          .from('daily_logs').select()
          .eq('user_id', user.id).eq('log_date', today).maybeSingle();

      double newCalories;
      if (existing == null) {
        await Supabase.instance.client.from('daily_logs').insert({
          'user_id':           user.id,
          'log_date':          today,
          'calories_consumed': totalCalories,
          'protein_consumed':  totalProtein,
          'carbs_consumed':    totalCarbs,
          'fat_consumed':      totalFat,
        });
        newCalories = totalCalories;
      } else {
        newCalories = (existing['calories_consumed'] ?? 0) + totalCalories;
        await Supabase.instance.client.from('daily_logs').update({
          'calories_consumed': newCalories,
          'protein_consumed':  (existing['protein_consumed'] ?? 0) + totalProtein,
          'carbs_consumed':    (existing['carbs_consumed']   ?? 0) + totalCarbs,
          'fat_consumed':      (existing['fat_consumed']     ?? 0) + totalFat,
        }).eq('user_id', user.id).eq('log_date', today);
      }

      // 3. check goal
      final plan = await Supabase.instance.client
          .from('user_plans').select('daily_calories').eq('id', user.id).maybeSingle();
      final dailyGoal = (plan?['daily_calories'] as num?)?.toDouble() ?? 1800;
      // if (newCalories >= dailyGoal) {
      //   await NotificationService.instance.showGoalAchieved(dailyGoal.round());
      // }

      // 4. show success overlay
      if (mounted) {
        setState(() { showSuccess = true; logging = false; });
        successController.forward();
        await Future.delayed(const Duration(milliseconds: 2200));
        if (mounted) {
          await successController.reverse();
          setState(() => showSuccess = false);
          if (mounted) Navigator.pop(context, true); // true = refresh home
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => logging = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to log: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(children: [

        // ── main content ──────────────────────────────────────────
        FadeTransition(
          opacity: fadeAnimation,
          child: Column(children: [
            Stack(children: [
              SizedBox(
                height: 280, width: double.infinity,
                child: widget.scannedImagePath != null
                    ? Image.file(
                  File(widget.scannedImagePath!),
                  fit: BoxFit.cover,
                  width: double.infinity,
                )
                    : Image.asset(
                  widget.fruit['image'] ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                      height: 280, color: c.surface,
                      child: const Center(child: Text('🍎', style: TextStyle(fontSize: 80)))),
                ),
              ),
              Positioned(bottom: 0, left: 0, right: 0,
                  child: Container(height: 80, decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        colors: [Colors.transparent, c.bg]),
                  ))),
              Positioned(
                top: MediaQuery.of(context).padding.top + 10, left: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(color: c.bg.withOpacity(0.8), shape: BoxShape.circle, border: Border.all(color: c.divider)),
                    child: Icon(Icons.arrow_back_ios_new_rounded, color: c.white, size: 16),
                  ),
                ),
              ),
              if (widget.confidence != null)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10, right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: c.green,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: c.green.withOpacity(0.4), blurRadius: 10)],
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 13),
                      const SizedBox(width: 5),
                      Text(
                        '${widget.confidence!.toStringAsFixed(0)}% match',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ]),
                  ),
                ),
            ]),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.fruit['name'] ?? '',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: c.white)),
                    const SizedBox(height: 18),

                    // serving row
                    Row(children: [
                      Text('Number of servings', style: TextStyle(fontSize: 14, color: c.subtext)),
                      const Spacer(),
                      ServingButton(icon: Icons.remove_rounded,
                          onTap: () { if (servings > 0.5) setState(() => servings -= 0.5); }),
                      const SizedBox(width: 14),
                      Text(
                        servings == servings.roundToDouble() ? servings.toInt().toString() : servings.toStringAsFixed(1),
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c.white),
                      ),
                      const SizedBox(width: 14),
                      ServingButton(icon: Icons.add_rounded, onTap: () => setState(() => servings += 0.5)),
                    ]),
                    const SizedBox(height: 14),

                    // calories
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.divider)),
                      child: Row(children: [
                        Text('Calories', style: TextStyle(fontSize: 14, color: c.subtext)),
                        const Spacer(),
                        Text('${totalCalories.round()} kcal',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: c.white)),
                        const SizedBox(width: 8),
                        Icon(Icons.edit_outlined, color: c.subtext, size: 16),
                      ]),
                    ),
                    const SizedBox(height: 12),

                    // macros
                    Row(children: [
                      Expanded(child: MacroBox(emoji: '🥩', label: 'Protein', value: '${totalProtein.round()} g')),
                      const SizedBox(width: 10),
                      Expanded(child: MacroBox(emoji: '🔥', label: 'Fats',    value: '${totalFat.round()} g')),
                      const SizedBox(width: 10),
                      Expanded(child: MacroBox(emoji: '✨', label: 'Carbs',   value: '${totalCarbs.round()} g')),
                    ]),
                    const SizedBox(height: 20),

                    // serving info
                    Text('Serving info', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.white)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.divider)),
                      child: Column(children: [
                        InfoRow(label: 'Serving size', value: '${servingGrams.round()}g', c: c),
                        Divider(color: c.divider, height: 16),
                        InfoRow(label: 'Fiber', value: '${totalFiber.toStringAsFixed(1)}g', c: c),
                        Divider(color: c.divider, height: 16),
                        InfoRow(label: 'Per 100g', value: '${(widget.fruit['calories_per_100g'] as num?)?.round() ?? 0} kcal', c: c),
                      ]),
                    ),
                    const SizedBox(height: 24),

                    Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('Today, $todayDate', style: TextStyle(fontSize: 13, color: c.subtext, fontWeight: FontWeight.w500)),
                      const SizedBox(width: 6),
                      const Text('📅', style: TextStyle(fontSize: 13)),
                    ])),
                    const SizedBox(height: 16),

                    LogButton(date: todayDate, loading: logging, onTap: logFruit),
                  ]),
                ),
              ),
            ),
          ]),
        ),

        // ── animated success overlay ───────────────────────────────
        if (showSuccess)
          AnimatedBuilder(
            animation: successFade,
            builder: (context, child) => Opacity(
              opacity: successFade.value,
              child: Container(
                color: Colors.black.withOpacity(0.6),
                child: Center(
                  child: ScaleTransition(
                    scale: successScale,
                    child: Container(
                      width: 200, height: 200,
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: c.green.withOpacity(0.3)),
                        boxShadow: [BoxShadow(color: c.green.withOpacity(0.2), blurRadius: 30, spreadRadius: 5)],
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        AnimatedBuilder(
                          animation: tickAnim,
                          builder: (context, child) => Container(
                            width: 72, height: 72,
                            decoration: BoxDecoration(
                              color: c.green,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: c.green.withOpacity(0.4), blurRadius: 20, spreadRadius: 3)],
                            ),
                            child: Icon(Icons.check_rounded, color: Colors.white, size: 40 * tickAnim.value),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('Logged!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c.white)),
                        const SizedBox(height: 6),
                        Text(widget.fruit['name'] ?? '', style: TextStyle(fontSize: 13, color: c.subtext)),
                        const SizedBox(height: 4),
                        Text('${totalCalories.round()} kcal', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.green)),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}

// ── serving button ─────────────────────────────────────────────────
class ServingButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  const ServingButton({Key? key, required this.icon, required this.onTap}) : super(key: key);
  @override
  State<ServingButton> createState() => ServingButtonState();
}

class ServingButtonState extends State<ServingButton> with SingleTickerProviderStateMixin {
  late AnimationController ctrl;
  late Animation<double> scale;
  @override
  void initState() {
    super.initState();
    ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 80));
    scale = Tween<double>(begin: 1.0, end: 0.88).animate(ctrl);
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
      child: ScaleTransition(scale: scale,
          child: Container(width: 34, height: 34,
              decoration: BoxDecoration(color: c.surface, shape: BoxShape.circle, border: Border.all(color: c.divider)),
              child: Icon(widget.icon, color: c.white, size: 18))),
    );
  }
}

// ── macro box ──────────────────────────────────────────────────────
class MacroBox extends StatelessWidget {
  final String emoji, label, value;
  const MacroBox({Key? key, required this.emoji, required this.label, required this.value}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.divider)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: c.subtext)),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.white)),
          const SizedBox(width: 4),
          Icon(Icons.edit_outlined, color: c.subtext, size: 12),
        ]),
      ]),
    );
  }
}

// ── info row ───────────────────────────────────────────────────────
class InfoRow extends StatelessWidget {
  final String label, value;
  final dynamic c;
  const InfoRow({Key? key, required this.label, required this.value, required this.c}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(label, style: TextStyle(fontSize: 13, color: c.subtext)),
      const Spacer(),
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.white)),
    ]);
  }
}

// ── log button ─────────────────────────────────────────────────────
class LogButton extends StatefulWidget {
  final String date;
  final bool loading;
  final VoidCallback onTap;
  const LogButton({Key? key, required this.date, required this.loading, required this.onTap}) : super(key: key);
  @override
  State<LogButton> createState() => LogButtonState();
}

class LogButtonState extends State<LogButton> with SingleTickerProviderStateMixin {
  late AnimationController ctrl;
  late Animation<double> scale;
  @override
  void initState() {
    super.initState();
    ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    scale = Tween<double>(begin: 1.0, end: 0.97).animate(ctrl);
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
      child: ScaleTransition(scale: scale,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: c.green,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: c.green.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: Center(child: widget.loading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Text('Log to ${widget.date}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white))),
          )),
    );
  }
}