import 'package:calories_tracker/screens/groups_screen.dart';
import 'package:calories_tracker/screens/profile_screen.dart';
import 'package:calories_tracker/screens/progress_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/loopup_database.dart';
import '../screens/scan_fruit.dart';
import '../screens/history_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/chatbot_bubble.dart';
import '../widgets/fruit_image.dart';
import '../services/goal_checker.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int selectedNav = 0;
  DateTime selectedDate = DateTime.now();
  Map<String, dynamic>? userPlan;
  List<Map<String, dynamic>> recentFoods = [];
  bool loading = true;

  late AnimationController fadeController;
  late AnimationController pulseController;
  late Animation<double> fadeAnimation;
  late Animation<double> pulseAnimation;

  double consumedCalories = 0;
  double consumedProtein = 0;
  double consumedCarbs = 0;
  double consumedFat = 0;

  @override
  void initState() {
    super.initState();
    fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    fadeAnimation = CurvedAnimation(parent: fadeController, curve: Curves.easeOut);
    pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    pulseAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
        CurvedAnimation(parent: pulseController, curve: Curves.easeInOut));
    pulseController.repeat(reverse: true);
    loadData();
  }

  @override
  void dispose() {
    fadeController.dispose();
    pulseController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];

      // load plan + today's log + recent foods in parallel
      final results = await Future.wait([
        Supabase.instance.client.from('user_plans').select().eq('id', user.id).maybeSingle(),
        Supabase.instance.client.from('daily_logs').select().eq('user_id', user.id).eq('log_date', today).maybeSingle(),
        Supabase.instance.client.from('food_logs').select().eq('user_id', user.id).eq('log_date', today).order('logged_at', ascending: false).limit(10),
      ]);

      final plan     = results[0] as Map<String, dynamic>?;
      final todayLog = results[1] as Map<String, dynamic>?;
      final foods    = results[2] as List;

      if (mounted) {
        setState(() {
          userPlan          = plan;
          consumedCalories  = (todayLog?['calories_consumed'] as num?)?.toDouble() ?? 0;
          consumedProtein   = (todayLog?['protein_consumed']  as num?)?.toDouble() ?? 0;
          consumedCarbs     = (todayLog?['carbs_consumed']    as num?)?.toDouble() ?? 0;
          consumedFat       = (todayLog?['fat_consumed']      as num?)?.toDouble() ?? 0;
          recentFoods       = foods.map((f) => Map<String, dynamic>.from(f)).toList();
          loading           = false;
        });
        fadeController.forward();
      }
      await GoalChecker.instance.checkAndNotify();
    } catch (e) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> refreshData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final results = await Future.wait([
        Supabase.instance.client.from('daily_logs').select().eq('user_id', user.id).eq('log_date', today).maybeSingle(),
        Supabase.instance.client.from('food_logs').select().eq('user_id', user.id).eq('log_date', today).order('logged_at', ascending: false).limit(10),
      ]);
      final plan     = results[0] as Map<String, dynamic>?;
      final todayLog = results[0] as Map<String, dynamic>?;
      final foods    = results[1] as List;
      if (mounted) {
        setState(() {
          userPlan         = plan;
          consumedCalories = (todayLog?['calories_consumed'] as num?)?.toDouble() ?? 0;
          consumedProtein  = (todayLog?['protein_consumed']  as num?)?.toDouble() ?? 0;
          consumedCarbs    = (todayLog?['carbs_consumed']    as num?)?.toDouble() ?? 0;
          consumedFat      = (todayLog?['fat_consumed']      as num?)?.toDouble() ?? 0;
          recentFoods      = foods.map((f) => Map<String, dynamic>.from(f)).toList();
        });
      }
      await GoalChecker.instance.checkAndNotify();
    } catch (e) {}
  }

  List<DateTime> get weekDates {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  double get dailyCalories => (userPlan?['daily_calories'] as num?)?.toDouble() ?? 1800;
  double get dailyProtein  => (userPlan?['protein_g']      as num?)?.toDouble() ?? 120;
  double get dailyCarbs    => (userPlan?['carbs_g']        as num?)?.toDouble() ?? 200;
  double get dailyFat      => (userPlan?['fat_g']          as num?)?.toDouble() ?? 60;
  double get caloriesLeft  => (dailyCalories - consumedCalories).clamp(0, dailyCalories);
  double get proteinLeft   => (dailyProtein - consumedProtein).clamp(0, dailyProtein);
  double get carbsLeft     => (dailyCarbs - consumedCarbs).clamp(0, dailyCarbs);
  double get fatLeft       => (dailyFat - consumedFat).clamp(0, dailyFat);
  double get caloriesProgress => dailyCalories > 0 ? consumedCalories / dailyCalories : 0;

  String dayName(int weekday) {
    const d = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return d[weekday - 1];
  }

  String get greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Future<void> openHistory() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
    // in case entries were deleted in History, refresh today's view
    refreshData();
  }

  Widget buildHomeContent(AppColorExtension c) {
    return RefreshIndicator(
      onRefresh: refreshData,
      color: c.green,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(greeting, style: TextStyle(fontSize: 13, color: c.subtext)),
                  const SizedBox(height: 2),
                  Text('NutriTrack 🌿', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c.white, letterSpacing: -0.5)),
                ]),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: c.orangeDim, borderRadius: BorderRadius.circular(20), border: Border.all(color: c.orange.withOpacity(0.3))),
                  child: Row(children: [
                    const Text('🔥', style: TextStyle(fontSize: 15)),
                    const SizedBox(width: 6),
                    Text(consumedCalories.round().toString(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.orange)),
                  ]),
                ),
              ]),
            ),

            const SizedBox(height: 20),

            // week calendar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: weekDates.map((date) {
                  final isSelected = date.day == selectedDate.day && date.month == selectedDate.month;
                  final isToday = date.day == DateTime.now().day && date.month == DateTime.now().month;
                  return GestureDetector(
                    onTap: () => setState(() => selectedDate = date),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 42,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? c.green : Colors.transparent,
                        borderRadius: BorderRadius.circular(22),
                        border: isToday && !isSelected ? Border.all(color: c.green.withOpacity(0.5), width: 1.5) : null,
                      ),
                      child: Column(children: [
                        Text(dayName(date.weekday), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: isSelected ? Colors.black : c.subtext)),
                        const SizedBox(height: 6),
                        Text(date.day.toString(), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isSelected ? Colors.black : c.white)),
                      ]),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // calories card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(28), border: Border.all(color: c.divider)),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Calories left', style: TextStyle(fontSize: 13, color: c.subtext)),
                    const SizedBox(height: 6),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: caloriesLeft),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOut,
                      builder: (context, val, child) => Text(val.round().toString(),
                          style: TextStyle(fontSize: 52, fontWeight: FontWeight.w800, color: c.white, height: 1.0, letterSpacing: -2)),
                    ),
                    const SizedBox(height: 12),
                    HomeMacroBar(label: 'Protein', consumed: consumedProtein, total: dailyProtein, color: const Color(0xFF60A5FA)),
                    const SizedBox(height: 6),
                    HomeMacroBar(label: 'Carbs',   consumed: consumedCarbs,   total: dailyCarbs,   color: c.orange),
                    const SizedBox(height: 6),
                    HomeMacroBar(label: 'Fats',    consumed: consumedFat,     total: dailyFat,     color: c.green),
                  ])),
                  const SizedBox(width: 20),
                  ScaleTransition(scale: pulseAnimation,
                      child: SizedBox(width: 90, height: 90,
                        child: Stack(alignment: Alignment.center, children: [
                          SizedBox(width: 90, height: 90,
                              child: CircularProgressIndicator(
                                value: caloriesProgress.clamp(0.0, 1.0),
                                strokeWidth: 8, backgroundColor: c.divider, color: c.green, strokeCap: StrokeCap.round,
                              )),
                          Column(mainAxisSize: MainAxisSize.min, children: [
                            const Text('🌿', style: TextStyle(fontSize: 22)),
                            Text('${(caloriesProgress * 100).round()}%',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.green)),
                          ]),
                        ]),
                      )),
                ]),
              ),
            ),

            const SizedBox(height: 14),

            // macro cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                Expanded(child: HomeMacroCard(label: 'Protein', value: '${proteinLeft.round()}g', emoji: '🥩', color: const Color(0xFF60A5FA), dimColor: const Color(0xFF1A2540))),
                const SizedBox(width: 10),
                Expanded(child: HomeMacroCard(label: 'Carbs',   value: '${carbsLeft.round()}g',  emoji: '🌾', color: c.orange, dimColor: c.orangeDim)),
                const SizedBox(width: 10),
                Expanded(child: HomeMacroCard(label: 'Fats',    value: '${fatLeft.round()}g',    emoji: '🥑', color: c.green,  dimColor: c.greenDim)),
              ]),
            ),

            const SizedBox(height: 24),

            // recently uploaded header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Text('Recently uploaded', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: c.white)),
                const Spacer(),
                GestureDetector(
                  onTap: openHistory,
                  child: Text('See all', style: TextStyle(fontSize: 12, color: c.green, fontWeight: FontWeight.w600)),
                ),
              ]),
            ),

            const SizedBox(height: 12),

            // recently uploaded list
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: recentFoods.isEmpty
                  ? Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: c.divider)),
                child: Column(children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: c.surfaceAlt, borderRadius: BorderRadius.circular(14)),
                    child: Row(children: [
                      const Text('🥗', style: TextStyle(fontSize: 36)),
                      const SizedBox(width: 14),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(width: 110, height: 10, decoration: BoxDecoration(color: c.divider, borderRadius: BorderRadius.circular(6))),
                        const SizedBox(height: 8),
                        Container(width: 75, height: 8, decoration: BoxDecoration(color: c.textHint, borderRadius: BorderRadius.circular(6))),
                      ]),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  Text('Tap + to add your first meal of the day',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: c.subtext, height: 1.4)),
                ]),
              )
                  : Container(
                decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: c.divider)),
                child: Column(
                  children: recentFoods.asMap().entries.map((entry) {
                    final i = entry.key;
                    final food = entry.value;
                    return Column(children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(children: [
                          // fruit image — handles both stock assets and
                          // real scanned photos (Supabase Storage URLs)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: FruitImage(
                              imagePath: food['fruit_image'],
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(food['fruit_name'] ?? '', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.white)),
                            const SizedBox(height: 3),
                            Text('${(food['calories'] as num?)?.round() ?? 0} kcal · ${food['servings']}x serving',
                                style: TextStyle(fontSize: 12, color: c.subtext)),
                          ])),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: c.greenDim, borderRadius: BorderRadius.circular(20)),
                            child: Text('${(food['calories'] as num?)?.round() ?? 0}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.green)),
                          ),
                        ]),
                      ),
                      if (i < recentFoods.length - 1)
                        Divider(color: c.divider, height: 1, indent: 16, endIndent: 16),
                    ]);
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 110),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    final screens = [
      buildHomeContent(c),
      const ProgressScreen(),
      const GroupsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(
        children: [
          SafeArea(
            child: loading
                ? Center(child: CircularProgressIndicator(color: c.green))
                : IndexedStack(index: selectedNav, children: screens),
          ),

          // chatbot bubble → above nav bar
          Positioned(
            bottom: 1,  // above nav bar height
            right: 20,
            child: const ChatbotBubble(),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        color: c.bg,
        child: Row(children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(32), border: Border.all(color: c.divider)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // replace all nav items with:
                  HomeNavItem(icon: Icons.home_rounded, label: 'Home', selected: selectedNav == 0,
                      onTap: () {
                        if (selectedNav != 0) refreshData(); // reload when returning to home
                        setState(() => selectedNav = 0);
                      }),
                  HomeNavItem(icon: Icons.bar_chart_rounded, label: 'Progress', selected: selectedNav == 1,
                      onTap: () => setState(() => selectedNav = 1)),
                  HomeNavItem(icon: Icons.people_rounded, label: 'Groups', selected: selectedNav == 2,
                      onTap: () => setState(() => selectedNav = 2)),
                  HomeNavItem(icon: Icons.person_rounded, label: 'Profile', selected: selectedNav == 3,
                      onTap: () => setState(() => selectedNav = 3)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: c.surface,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                builder: (context) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('Choose an Option', style: TextStyle(color: c.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    ListTile(
                      leading: Icon(Icons.camera_alt, color: c.orange),
                      title: Text('Scan Fruit', style: TextStyle(color: c.white)),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanFruitScreen()));
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.search, color: c.green),
                      title: Text('Look Up Database', style: TextStyle(color: c.white)),
                      onTap: () async {
                        Navigator.pop(context);
                        final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const LookupDatabaseScreen()));
                        if (result == true) refreshData(); // refresh after logging
                      },
                    ),
                    const SizedBox(height: 10),
                  ]),
                ),
              );
            },
            child: Container(
              width: 52, height: 52,
              decoration: BoxDecoration(color: c.orange, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: c.orange.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 4))]),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
            ),
          ),
        ]),
      ),
    );
  }
}

class HomeMacroBar extends StatelessWidget {
  final String label;
  final double consumed, total;
  final Color color;
  const HomeMacroBar({Key? key, required this.label, required this.consumed, required this.total, required this.color}) : super(key: key);
  double get progress => total > 0 ? (consumed / total).clamp(0.0, 1.0) : 0;
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Row(children: [
      SizedBox(width: 44, child: Text(label, style: TextStyle(fontSize: 10, color: c.subtext))),
      const SizedBox(width: 8),
      Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4),
          child: Container(height: 5, color: c.divider,
              child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: progress, child: Container(color: color))))),
    ]);
  }
}

class HomeMacroCard extends StatelessWidget {
  final String label, value, emoji;
  final Color color, dimColor;
  const HomeMacroCard({Key? key, required this.label, required this.value, required this.emoji, required this.color, required this.dimColor}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: c.divider)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: dimColor, borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18)))),
        const SizedBox(height: 10),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: c.subtext)),
      ]),
    );
  }
}

class HomeNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const HomeNavItem({Key? key, required this.icon, required this.label, required this.selected, required this.onTap}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(color: selected ? c.greenDim : Colors.transparent, borderRadius: BorderRadius.circular(20)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: selected ? c.green : c.subtext, size: 20),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: selected ? FontWeight.w700 : FontWeight.w400, color: selected ? c.green : c.subtext)),
        ]),
      ),
    );
  }
}