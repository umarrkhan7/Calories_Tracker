import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../onboarding_scaffold.dart';
import '../onboarding_controller.dart';
import '../../theme/app_theme.dart';
import 'ob07_date_of_birth.dart';

class HeightWeightScreen extends StatefulWidget {
  const HeightWeightScreen({Key? key}) : super(key: key);

  @override
  State<HeightWeightScreen> createState() => HeightWeightScreenState();
}

class HeightWeightScreenState extends State<HeightWeightScreen>
    with SingleTickerProviderStateMixin {

  bool isMetric = true;
  int selectedCm = 170;
  int selectedKg = 70;
  int selectedFt = 5;
  int selectedIn = 7;
  int selectedLb = 154;

  late AnimationController animController;
  late Animation<Offset> slideAnimation;
  late Animation<double> fadeAnimation;

  final List<int> cmValues = List.generate(151, (i) => 100 + i);
  final List<int> kgValues = List.generate(201, (i) => 30 + i);
  final List<int> ftValues = List.generate(5, (i) => 3 + i);
  final List<int> inValues = List.generate(12, (i) => i);
  final List<int> lbValues = List.generate(441, (i) => 66 + i);

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

  double get heightInCm => isMetric ? selectedCm.toDouble() : (selectedFt * 30.48) + (selectedIn * 2.54);
  double get weightInKg => isMetric ? selectedKg.toDouble() : selectedLb * 0.453592;

  void goNext() {
    final controller = context.read<OnboardingController>();
    controller.heightCm = heightInCm;
    controller.weightKg = weightInKg;
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ChangeNotifierProvider.value(
          value: controller,
          child: const DateOfBirthScreen(),
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
      currentStep: 6,
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
                Text('Height & Weight', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: c.white)),
                const SizedBox(height: 8),
                Text('Used to calculate your daily nutrition goals.', style: TextStyle(fontSize: 14, color: c.subtext)),

                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: c.surfaceAlt, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.divider)),
                  child: Row(
                    children: [
                      Expanded(child: UnitToggleButton(label: 'Metric', selected: isMetric, onTap: () => setState(() => isMetric = true))),
                      Expanded(child: UnitToggleButton(label: 'Imperial', selected: !isMetric, onTap: () => setState(() => isMetric = false))),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                Expanded(
                  child: Row(
                    children: [
                      if (isMetric) ...[
                        Expanded(child: PickerColumn(label: 'Height', unit: 'cm', values: cmValues, selectedValue: selectedCm, onChanged: (v) => setState(() => selectedCm = v))),
                        const SizedBox(width: 16),
                        Expanded(child: PickerColumn(label: 'Weight', unit: 'kg', values: kgValues, selectedValue: selectedKg, onChanged: (v) => setState(() => selectedKg = v))),
                      ] else ...[
                        Expanded(child: PickerColumn(label: 'Feet', unit: 'ft', values: ftValues, selectedValue: selectedFt, onChanged: (v) => setState(() => selectedFt = v))),
                        const SizedBox(width: 8),
                        Expanded(child: PickerColumn(label: 'Inches', unit: 'in', values: inValues, selectedValue: selectedIn, onChanged: (v) => setState(() => selectedIn = v))),
                        const SizedBox(width: 8),
                        Expanded(child: PickerColumn(label: 'Weight', unit: 'lb', values: lbValues, selectedValue: selectedLb, onChanged: (v) => setState(() => selectedLb = v))),
                      ],
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

class UnitToggleButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const UnitToggleButton({Key? key, required this.label, required this.selected, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? c.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: selected ? Border.all(color: c.divider) : null,
          boxShadow: selected ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))] : [],
        ),
        child: Center(
          child: Text(label, style: TextStyle(
              fontSize: 14, fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? c.white : c.subtext)),
        ),
      ),
    );
  }
}

class PickerColumn extends StatefulWidget {
  final String label;
  final String unit;
  final List<int> values;
  final int selectedValue;
  final ValueChanged<int> onChanged;

  const PickerColumn({Key? key, required this.label, required this.unit,
    required this.values, required this.selectedValue, required this.onChanged}) : super(key: key);

  @override
  State<PickerColumn> createState() => PickerColumnState();
}

class PickerColumnState extends State<PickerColumn> {
  late FixedExtentScrollController scrollController;

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.values.indexOf(widget.selectedValue);
    scrollController = FixedExtentScrollController(initialItem: initialIndex >= 0 ? initialIndex : 0);
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
        Text(widget.label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.subtext, letterSpacing: 0.3)),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.divider)),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Center(
                  child: Container(
                    height: 44,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: c.greenDim, borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: c.green.withOpacity(0.3)),
                    ),
                  ),
                ),
                CupertinoPicker(
                  scrollController: scrollController,
                  itemExtent: 44,
                  backgroundColor: Colors.transparent,
                  selectionOverlay: const SizedBox(),
                  onSelectedItemChanged: (index) => widget.onChanged(widget.values[index]),
                  children: widget.values.map((val) {
                    final selected = val == widget.selectedValue;
                    return Center(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(text: '$val', style: TextStyle(
                                fontSize: selected ? 20 : 16, fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                                color: selected ? c.green : c.subtext)),
                            TextSpan(text: ' ${widget.unit}', style: TextStyle(
                                fontSize: 12, color: selected ? c.green : c.subtext, fontWeight: FontWeight.w400)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}