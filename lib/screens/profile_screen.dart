import 'dart:io';
import 'package:calories_tracker/screens/personal_details_screen.dart';
import 'package:calories_tracker/screens/preferences_screen.dart';
import 'package:calories_tracker/screens/recommendation_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../services/notification_service.dart';
import 'edit_plan_screen.dart';
import 'weight_goal_screen.dart';
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {

  Map<String, dynamic>? userPlan;
  bool loading = true;
  bool uploadingImage = false;
  String? avatarUrl;
  String displayName = '';
  final nameController = TextEditingController();

  late AnimationController fadeController;
  late Animation<double> fadeAnimation;

  @override
  void initState() {
    super.initState();
    fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    fadeAnimation = CurvedAnimation(parent: fadeController, curve: Curves.easeIn);
    loadProfile();
  }

  @override
  void dispose() {
    fadeController.dispose();
    nameController.dispose();
    super.dispose();
  }

  Future<void> loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final data = await Supabase.instance.client
          .from('user_plans').select().eq('id', user.id).maybeSingle();
      if (mounted) {
        setState(() {
          userPlan = data;
          displayName = data?['display_name'] ?? '';
          avatarUrl = data?['avatar_url'];
          nameController.text = displayName;
          loading = false;
        });
        fadeController.forward();
      }
    } catch (e) {
      if (mounted) setState(() => loading = false);
    }
  }

  int get userAge {
    final dob = userPlan?['date_of_birth'];
    if (dob == null) return 0;
    final birth = DateTime.parse(dob);
    final now = DateTime.now();
    int age = now.year - birth.year;
    if (now.month < birth.month || (now.month == birth.month && now.day < birth.day)) age--;
    return age;
  }

  Future<void> pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return;

    setState(() => uploadingImage = true);
    try {
      final user = Supabase.instance.client.auth.currentUser!;
      final file = File(picked.path);
      final ext = picked.path.split('.').last;
      final path = '${user.id}/avatar.$ext';

      await Supabase.instance.client.storage.from('avatars').upload(
        path, file,
        fileOptions: const FileOptions(upsert: true),
      );

      final url = Supabase.instance.client.storage.from('avatars').getPublicUrl(path);
      await Supabase.instance.client.from('user_plans')
          .update({'avatar_url': url}).eq('id', user.id);

      if (mounted) setState(() => avatarUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload image')));
      }
    } finally {
      if (mounted) setState(() => uploadingImage = false);
    }
  }

  Future<void> saveName(String name) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    await Supabase.instance.client.from('user_plans')
        .update({'display_name': name}).eq('id', user.id);
    setState(() => displayName = name);
  }

  void showEditName(AppColorExtension c) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Your name', style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w700, color: c.white)),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: TextStyle(color: c.white),
          decoration: InputDecoration(
            hintText: 'Enter your name',
            hintStyle: TextStyle(color: c.subtext),
            filled: true,
            fillColor: c.surfaceAlt,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: c.subtext)),
          ),
          TextButton(
            onPressed: () {
              saveName(nameController.text.trim());
              Navigator.pop(ctx);
            },
            child: Text('Save', style: TextStyle(
                color: c.green, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) Navigator.pushReplacementNamed(context, '/signin');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final tp = context.watch<ThemeProvider>();
    final email = Supabase.instance.client.auth.currentUser?.email ?? '';

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

              // ── header + theme toggle ────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Row(children: [
                  Text('Profile', style: TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w800,
                      color: c.white, letterSpacing: -0.8)),
                  const Spacer(),
                  // theme toggle
                  GestureDetector(
                    onTap: () => tp.toggle(),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: c.divider),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(
                          tp.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                          color: c.green, size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          tp.isDark ? 'Dark' : 'Light',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600, color: c.white),
                        ),
                      ]),
                    ),
                  ),
                ]),
              ),

              // ── avatar + name card ───────────────────────────
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
                    GestureDetector(
                      onTap: pickAndUploadImage,
                      child: Stack(children: [
                        Container(
                          width: 62, height: 62,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: c.surfaceAlt,
                            border: Border.all(color: c.divider, width: 2),
                            image: avatarUrl != null
                                ? DecorationImage(image: NetworkImage(avatarUrl!), fit: BoxFit.cover)
                                : null,
                          ),
                          child: avatarUrl == null
                              ? Icon(Icons.person_rounded, color: c.subtext, size: 32)
                              : null,
                        ),
                        if (uploadingImage)
                          Positioned.fill(child: Container(
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black26),
                            child: const Center(child: SizedBox(width: 20, height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))),
                          )),
                        Positioned(bottom: 0, right: 0,
                            child: Container(
                              width: 20, height: 20,
                              decoration: BoxDecoration(
                                color: c.green, shape: BoxShape.circle,
                                border: Border.all(color: c.surface, width: 1.5),
                              ),
                              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 11),
                            )),
                      ]),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        GestureDetector(
                          onTap: () => showEditName(c),
                          child: Row(children: [
                            Text(
                              displayName.isEmpty ? 'Enter your name' : displayName,
                              style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600,
                                color: displayName.isEmpty ? c.subtext : c.white,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.edit_rounded, size: 14, color: c.subtext),
                          ]),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          userAge > 0 ? '$userAge years old' : email,
                          style: TextStyle(fontSize: 12, color: c.subtext),
                        ),
                      ]),
                    ),
                  ]),
                ),
              ),

              const SizedBox(height: 24),



              // ── account ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Text('Account', style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: c.subtext, letterSpacing: 0.3)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: c.divider),
                  ),
                  child: Column(children: [
                    ProfileMenuItem(icon: Icons.badge_outlined,    label: 'Personal details', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalDetailsScreen())), c: c),
                    MenuDivider(c: c),
                    ProfileMenuItem(icon: Icons.settings_outlined, label: 'Preferences',      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PreferencesScreen())), c: c),
                    MenuDivider(c: c),
                    ProfileMenuItem(icon: Icons.translate_rounded, label: 'Language',         onTap: () {}, c: c),
                  ]),
                ),
              ),

              const SizedBox(height: 24),

              // ── goals & tracking ─────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Text('Goals & Tracking', style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: c.subtext, letterSpacing: 0.3)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: c.divider),
                  ),
                  child: Column(children: [
                    ProfileMenuItem(icon: Icons.track_changes_rounded, label: 'Edit Nutrition Goals',  onTap: () async {
                      final updated = await Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const EditPlanScreen()));
                      if (updated == true) loadProfile(); // refresh if saved
                    }, c: c),
                    MenuDivider(c: c),
                    ProfileMenuItem(icon: Icons.access_time_rounded,   label: 'Get your Recommendation',  onTap: () {Navigator.push(context, MaterialPageRoute(builder: (_)=>const RecommendationScreen()));}, c: c),
                    MenuDivider(c: c),
                    ProfileMenuItem(
                      icon: Icons.flag_rounded,
                      label: 'Goal & current weight',
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const WeightGoalScreen())),
                      c: c,
                    ),
                  ]),
                ),
              ),

              const SizedBox(height: 24),
              // add anywhere in profile screen build()

              // ── logout ───────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: logout,
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                    ),
                    child: const Row(children: [
                      Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 20),
                      SizedBox(width: 14),
                      Text('Log out', style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFFEF4444))),
                    ]),
                  ),
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

// ── menu item ─────────────────────────────────────────────────────
class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final AppColorExtension c;

  const ProfileMenuItem({Key? key, required this.icon, required this.label,
    required this.onTap, required this.c}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(children: [
          Icon(icon, color: c.white, size: 20),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w500, color: c.white))),
          Icon(Icons.arrow_forward_ios_rounded, size: 13, color: c.subtext),
        ]),
      ),
    );
  }
}

// ── divider ───────────────────────────────────────────────────────
class MenuDivider extends StatelessWidget {
  final AppColorExtension c;
  const MenuDivider({Key? key, required this.c}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 52),
      child: Divider(height: 1, color: c.divider),
    );
  }
}