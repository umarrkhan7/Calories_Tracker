import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import 'personal_details_screen.dart' show SettingsCard, LabeledField, FieldBox, DropdownField;

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({Key? key}) : super(key: key);

  @override
  State<PreferencesScreen> createState() => PreferencesScreenState();
}

class PreferencesScreenState extends State<PreferencesScreen> {
  bool loading = true;
  bool saving = false;

  String units = 'Metric';
  String dietaryPreference = 'No restriction';
  final Set<String> allergies = {};

  bool dailyReminders = true;
  bool weeklySummary = true;
  bool streakAlerts = false;

  static const unitOptions = ['Metric', 'Imperial'];
  static const dietaryOptions = [
    'No restriction',
    'Vegetarian',
    'Vegan',
    'Halal',
    'Keto',
    'Other',
  ];
  static const allergyOptions = ['Nuts', 'Dairy', 'Gluten', 'Shellfish', 'Eggs', 'Soy'];

  @override
  void initState() {
    super.initState();
    loadData();
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
        units = (plan['units'] as String?) ?? units;
        dietaryPreference = (plan['dietary_preference'] as String?) ?? dietaryPreference;
        final allergyList = (plan['allergies'] as List?)?.cast<String>() ?? [];
        allergies.addAll(allergyList);
        dailyReminders = (plan['notify_daily'] as bool?) ?? dailyReminders;
        weeklySummary = (plan['notify_weekly'] as bool?) ?? weeklySummary;
        streakAlerts = (plan['notify_streak'] as bool?) ?? streakAlerts;
      }
      if (mounted) setState(() => loading = false);
    } catch (e) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> save() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    setState(() => saving = true);
    try {
      await Supabase.instance.client.from('user_plans').upsert({
        'id': user.id,
        'units': units,
        'dietary_preference': dietaryPreference,
        'allergies': allergies.toList(),
        'notify_daily': dailyReminders,
        'notify_weekly': weeklySummary,
        'notify_streak': streakAlerts,
      });
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preferences saved')),
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

  void toggleAllergy(String a) {
    setState(() {
      if (allergies.contains(a)) {
        allergies.remove(a);
      } else {
        allergies.add(a);
      }
    });
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
                Text('Preferences', style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800,
                    color: c.white, letterSpacing: -0.6)),
              ]),
            ),

            const SizedBox(height: 16),

            SettingsCard(c: c, children: [
              LabeledField(c: c, label: 'Units', child: DropdownField(
                c: c,
                value: units,
                options: unitOptions,
                onChanged: (v) => setState(() => units = v),
              )),
            ]),

            const SizedBox(height: 16),

            SettingsCard(c: c, children: [
              LabeledField(c: c, label: 'Dietary preference', child: DropdownField(
                c: c,
                value: dietaryPreference,
                options: dietaryOptions,
                onChanged: (v) => setState(() => dietaryPreference = v),
              )),
              const SizedBox(height: 16),
              Text('Allergies / intolerances', style: TextStyle(
                  fontSize: 12, color: c.subtext, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: allergyOptions.map((a) {
                final selected = allergies.contains(a);
                return GestureDetector(
                  onTap: () => toggleAllergy(a),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? c.greenDim : c.surfaceAlt,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? c.green : c.divider),
                    ),
                    child: Text(a, style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected ? c.green : c.subtext)),
                  ),
                );
              }).toList()),
            ]),

            const SizedBox(height: 16),

            SettingsCard(c: c, children: [
              Text('Notifications', style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: c.white)),
              const SizedBox(height: 12),
              PreferenceToggle(
                c: c,
                label: 'Daily logging reminders',
                value: dailyReminders,
                onChanged: (v) => setState(() => dailyReminders = v),
              ),
              PreferenceToggle(
                c: c,
                label: 'Weekly summary',
                value: weeklySummary,
                onChanged: (v) => setState(() => weeklySummary = v),
              ),
              PreferenceToggle(
                c: c,
                label: 'Streak alerts',
                value: streakAlerts,
                onChanged: (v) => setState(() => streakAlerts = v),
                isLast: true,
              ),
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

class PreferenceToggle extends StatelessWidget {
  final AppColorExtension c;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isLast;
  const PreferenceToggle({
    Key? key,
    required this.c,
    required this.label,
    required this.value,
    required this.onChanged,
    this.isLast = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(children: [
        Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: c.white))),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: c.green,
        ),
      ]),
    );
  }
}