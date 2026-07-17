import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../onboarding_scaffold.dart';
import '../onboarding_controller.dart';
import '../../theme/app_theme.dart';
import 'ob08_goal.dart';

class DateOfBirthScreen extends StatefulWidget {
  const DateOfBirthScreen({Key? key}) : super(key: key);

  @override
  State<DateOfBirthScreen> createState() => DateOfBirthScreenState();
}

class DateOfBirthScreenState extends State<DateOfBirthScreen>
    with SingleTickerProviderStateMixin {

  int selectedDay = 15;
  int selectedMonth = 6;
  int selectedYear = 1995;

  late AnimationController animController;
  late Animation<Offset> slideAnimation;
  late Animation<double> fadeAnimation;

  final List<int> days = List.generate(31, (i) => i + 1);
  final List<int> months = List.generate(12, (i) => i + 1);
  final List<int> years = List.generate(83, (i) => 1940 + i);

  final List<String> monthNames = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

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

  int get age {
    final now = DateTime.now();
    final dob = DateTime(selectedYear, selectedMonth, selectedDay);
    int years = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) years--;
    return years;
  }

  void goNext() {
    final controller = context.read<OnboardingController>();
    controller.dateOfBirth = DateTime(selectedYear, selectedMonth, selectedDay);
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ChangeNotifierProvider.value(
          value: controller,
          child: const GoalScreen(),
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
      currentStep: 7,
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
                Text('When were you born?', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: c.white)),
                const SizedBox(height: 8),
                Text('Your age helps us personalise your nutrition plan.', style: TextStyle(fontSize: 14, color: c.subtext)),

                const SizedBox(height: 24),

                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 500),
                  builder: (context, val, child) => Opacity(opacity: val, child: child),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: c.greenDim,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: c.green.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.cake_rounded, color: c.green, size: 20),
                        const SizedBox(width: 10),
                        Text('You are $age years old', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.green)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: DobPickerColumn(
                          label: 'Day', items: days.map((d) => d.toString().padLeft(2, '0')).toList(),
                          selectedIndex: days.indexOf(selectedDay), onChanged: (i) => setState(() => selectedDay = days[i]))),
                      const SizedBox(width: 12),
                      Expanded(flex: 2, child: DobPickerColumn(
                          label: 'Month', items: monthNames,
                          selectedIndex: selectedMonth - 1, onChanged: (i) => setState(() => selectedMonth = i + 1))),
                      const SizedBox(width: 12),
                      Expanded(flex: 2, child: DobPickerColumn(
                          label: 'Year', items: years.map((y) => y.toString()).toList(),
                          selectedIndex: years.indexOf(selectedYear), onChanged: (i) => setState(() => selectedYear = years[i]))),
                    ],
                  ),
                ),

                OnboardingContinueButton(onTap: goNext),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DobPickerColumn extends StatefulWidget {
  final String label;
  final List<String> items;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const DobPickerColumn({Key? key, required this.label, required this.items,
    required this.selectedIndex, required this.onChanged}) : super(key: key);

  @override
  State<DobPickerColumn> createState() => DobPickerColumnState();
}

class DobPickerColumnState extends State<DobPickerColumn> {
  late FixedExtentScrollController scrollController;

  @override
  void initState() {
    super.initState();
    scrollController = FixedExtentScrollController(initialItem: widget.selectedIndex >= 0 ? widget.selectedIndex : 0);
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      children: [
        Text(widget.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.subtext, letterSpacing: 0.3)),
        const SizedBox(height: 10),
        Expanded(
          child: Container(
            decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.divider)),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Center(
                  child: Container(
                    height: 44,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: c.greenDim, borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: c.green.withOpacity(0.25)),
                    ),
                  ),
                ),
                CupertinoPicker(
                  scrollController: scrollController,
                  itemExtent: 44,
                  backgroundColor: Colors.transparent,
                  selectionOverlay: const SizedBox(),
                  onSelectedItemChanged: widget.onChanged,
                  children: List.generate(widget.items.length, (i) {
                    final selected = i == widget.selectedIndex;
                    return Center(
                      child: Text(widget.items[i], style: TextStyle(
                          fontSize: selected ? 18 : 15, fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                          color: selected ? c.green : c.subtext)),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}