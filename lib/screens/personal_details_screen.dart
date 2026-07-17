import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

class PersonalDetailsScreen extends StatefulWidget {
  const PersonalDetailsScreen({Key? key}) : super(key: key);

  @override
  State<PersonalDetailsScreen> createState() => PersonalDetailsScreenState();
}

class PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  bool loading = true;
  bool saving = false;

  final nameController = TextEditingController();
  final heightController = TextEditingController();
  final weightController = TextEditingController();
  final goalWeightController = TextEditingController();

  DateTime? dateOfBirth;
  String gender = 'Prefer not to say';
  String activityLevel = 'Lightly active';

  static const genderOptions = ['Male', 'Female', 'Other', 'Prefer not to say'];
  static const activityOptions = [
    'Sedentary',
    'Lightly active',
    'Active',
    'Very active',
  ];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    nameController.dispose();
    heightController.dispose();
    weightController.dispose();
    goalWeightController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => loading = false);
      return;
    }
    try {
      final plan = await Supabase.instance.client
          .from('user_plans')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (plan != null) {
        nameController.text = (plan['full_name'] as String?) ?? (user.userMetadata?['name'] ?? '');
        heightController.text = (plan['height_cm'] as num?)?.toString() ?? '';
        weightController.text = (plan['weight_kg'] as num?)?.toString() ?? '';
        goalWeightController.text = (plan['goal_weight_kg'] as num?)?.toString() ?? '';
        gender = (plan['gender'] as String?) ?? gender;
        activityLevel = (plan['activity_level'] as String?) ?? activityLevel;
        final dobRaw = plan['date_of_birth'] as String?;
        if (dobRaw != null) dateOfBirth = DateTime.tryParse(dobRaw);
      }
      if (mounted) setState(() => loading = false);
    } catch (e) {
      if (mounted) setState(() => loading = false);
    }
  }

  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int years = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      years--;
    }
    return years;
  }

  Future<void> pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: dateOfBirth ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - 5),
    );
    if (picked != null) setState(() => dateOfBirth = picked);
  }

  Future<void> save() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    setState(() => saving = true);
    try {
      await Supabase.instance.client.from('user_plans').upsert({
        'id': user.id,
        'full_name': nameController.text.trim(),
        'height_cm': double.tryParse(heightController.text),
        'weight_kg': double.tryParse(weightController.text),
        'goal_weight_kg': double.tryParse(goalWeightController.text),
        'gender': gender,
        'activity_level': activityLevel,
        'date_of_birth': dateOfBirth?.toIso8601String(),
      });
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Personal details saved')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: loading
            ? Center(child: CircularProgressIndicator(color: c.green))
            : SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.arrow_back_ios_new_rounded, color: c.white, size: 20),
                ),
                const SizedBox(width: 16),
                Text('Personal Details', style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800,
                    color: c.white, letterSpacing: -0.6)),
              ]),
            ),

            const SizedBox(height: 16),

            SettingsCard(c: c, children: [
              LabeledField(c: c, label: 'Full name', child: FieldBox(
                c: c,
                child: TextField(
                  controller: nameController,
                  style: TextStyle(color: c.white, fontSize: 14),
                  decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                ),
              )),
              const SizedBox(height: 16),
              LabeledField(c: c, label: 'Date of birth', child: GestureDetector(
                onTap: pickDateOfBirth,
                child: FieldBox(
                  c: c,
                  child: Row(children: [
                    Expanded(child: Text(
                      dateOfBirth == null
                          ? 'Select date'
                          : '${dateOfBirth!.day}/${dateOfBirth!.month}/${dateOfBirth!.year}'
                          '${age != null ? '  ($age yrs)' : ''}',
                      style: TextStyle(color: dateOfBirth == null ? c.subtext : c.white, fontSize: 14),
                    )),
                    Icon(Icons.calendar_today_rounded, size: 16, color: c.subtext),
                  ]),
                ),
              )),
              const SizedBox(height: 16),
              LabeledField(c: c, label: 'Gender', child: DropdownField(
                c: c,
                value: gender,
                options: genderOptions,
                onChanged: (v) => setState(() => gender = v),
              )),
            ]),

            const SizedBox(height: 16),

            SettingsCard(c: c, children: [
              Row(children: [
                Expanded(child: LabeledField(c: c, label: 'Height (cm)', child: FieldBox(
                  c: c,
                  child: TextField(
                    controller: heightController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: c.white, fontSize: 14),
                    decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                  ),
                ))),
                const SizedBox(width: 12),
                Expanded(child: LabeledField(c: c, label: 'Weight (kg)', child: FieldBox(
                  c: c,
                  child: TextField(
                    controller: weightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(color: c.white, fontSize: 14),
                    decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                  ),
                ))),
              ]),
              const SizedBox(height: 16),
              LabeledField(c: c, label: 'Goal weight (kg)', child: FieldBox(
                c: c,
                child: TextField(
                  controller: goalWeightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(color: c.white, fontSize: 14),
                  decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                ),
              )),
            ]),

            const SizedBox(height: 16),

            SettingsCard(c: c, children: [
              LabeledField(c: c, label: 'Activity level', child: DropdownField(
                c: c,
                value: activityLevel,
                options: activityOptions,
                onChanged: (v) => setState(() => activityLevel = v),
              )),
            ]),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: saving ? null : save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: saving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ),

            const SizedBox(height: 100),
          ]),
        ),
      ),
    );
  }
}

// ---------- Shared small widgets (reusable by PreferencesScreen too) ----------

class SettingsCard extends StatelessWidget {
  final AppColorExtension c;
  final List<Widget> children;
  const SettingsCard({Key? key, required this.c, required this.children}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        margin: const EdgeInsets.only(bottom: 0),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.divider),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      ),
    );
  }
}

class LabeledField extends StatelessWidget {
  final AppColorExtension c;
  final String label;
  final Widget child;
  const LabeledField({Key? key, required this.c, required this.label, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 12, color: c.subtext, fontWeight: FontWeight.w500)),
      const SizedBox(height: 6),
      child,
    ]);
  }
}

class FieldBox extends StatelessWidget {
  final AppColorExtension c;
  final Widget child;
  const FieldBox({Key? key, required this.c, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(color: c.surfaceAlt, borderRadius: BorderRadius.circular(12)),
      child: child,
    );
  }
}

class DropdownField extends StatelessWidget {
  final AppColorExtension c;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  const DropdownField({Key? key, required this.c, required this.value, required this.options, required this.onChanged}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Guard against a stored value that isn't in `options` (or duplicate
    // options) — DropdownButton requires the value to match exactly one item.
    final uniqueOptions = options.toSet().toList();
    final safeValue = uniqueOptions.contains(value)
        ? value
        : (uniqueOptions.isNotEmpty ? uniqueOptions.first : null);

    return FieldBox(
      c: c,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue,
          isExpanded: true,
          dropdownColor: c.surfaceAlt,
          style: TextStyle(color: c.white, fontSize: 14),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: c.subtext),
          items: uniqueOptions.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
          onChanged: (v) { if (v != null) onChanged(v); },
        ),
      ),
    );
  }
}