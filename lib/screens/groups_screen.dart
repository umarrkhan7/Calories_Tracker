import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import 'join_group_dialog.dart';
import 'group_detail_screen.dart';
import 'create_group_dialog.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({Key? key}) : super(key: key);

  @override
  State<GroupsScreen> createState() => GroupsScreenState();
}

class GroupsScreenState extends State<GroupsScreen>
    with SingleTickerProviderStateMixin {

  List<Map<String, dynamic>> myGroups = [];
  List<Map<String, dynamic>> discoverGroups = [];
  bool loading = true;
  String? error;

  late AnimationController fadeController;
  late Animation<double> fadeAnimation;

  @override
  void initState() {
    super.initState();
    fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    fadeAnimation = CurvedAnimation(parent: fadeController, curve: Curves.easeIn);
    loadGroups();
  }

  @override
  void dispose() {
    fadeController.dispose();
    super.dispose();
  }

  Future<void> loadGroups() async {
    setState(() { loading = true; error = null; });

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() { loading = false; error = 'Not logged in'; });
      return;
    }

    try {
      // get my joined group IDs
      final joined = await Supabase.instance.client
          .from('group_members')
          .select('group_id')
          .eq('user_id', user.id);

      final joinedIds = (joined as List).map((e) => e['group_id'].toString()).toList();

      // get all groups
      final all = await Supabase.instance.client
          .from('groups')
          .select()
          .order('created_at', ascending: false);

      final allGroups = List<Map<String, dynamic>>.from(all);

      if (mounted) {
        setState(() {
          myGroups = allGroups.where((g) => joinedIds.contains(g['id'].toString())).toList();
          discoverGroups = allGroups.where((g) => !joinedIds.contains(g['id'].toString())).toList();
          loading = false;
        });
        fadeController.forward();
      }
    } catch (e) {
      if (mounted) setState(() { loading = false; error = 'Failed to load groups: ${e.toString()}'; });
    }
  }

  void onJoined() => loadGroups();

  void showCreateGroup() {
    showDialog(
      context: context,
      builder: (context) => CreateGroupDialog(onCreated: onJoined),
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
            : error != null
            ? Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.error_outline, color: const Color(0xFFEF4444), size: 48),
              const SizedBox(height: 16),
              Text(error!, textAlign: TextAlign.center, style: TextStyle(color: c.subtext, fontSize: 14)),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: loadGroups,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(color: c.green, borderRadius: BorderRadius.circular(12)),
                  child: const Text('Retry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        )
            : FadeTransition(
          opacity: fadeAnimation,
          child: RefreshIndicator(
            onRefresh: loadGroups,
            color: c.green,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(children: [
                    Text('Groups', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: c.white, letterSpacing: -0.8)),
                    const Spacer(),
                    GestureDetector(
                      onTap: showCreateGroup,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(color: c.green, borderRadius: BorderRadius.circular(20)),
                        child: Row(children: [
                          const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          const Text('Create', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    ),
                  ]),
                ),

                const SizedBox(height: 24),

                // my groups
                if (myGroups.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Text('Your Groups', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.white)),
                  ),
                  ...myGroups.asMap().entries.map((entry) {
                    final index = entry.key;
                    final group = entry.value;
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Duration(milliseconds: 400 + (index * 80)),
                      curve: Curves.easeOut,
                      builder: (context, val, child) => Opacity(
                          opacity: val, child: Transform.translate(offset: Offset(0, 20 * (1 - val)), child: child)),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: MyGroupCard(
                          group: group,
                          onTap: () => Navigator.push(context, MaterialPageRoute(
                              builder: (context) => GroupDetailScreen(group: group))).then((_) => loadGroups()),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                ],

                // discover
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Text('Discover Groups', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.white)),
                ),

                if (discoverGroups.isEmpty && myGroups.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(children: [
                        Text('🌱', style: const TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text('No groups yet', style: TextStyle(color: c.white, fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('Create first group!', style: TextStyle(color: c.subtext, fontSize: 13)),
                      ]),
                    ),
                  )
                else if (discoverGroups.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text('No more groups to discover', style: TextStyle(color: c.subtext, fontSize: 14)),
                  )
                else
                  ...discoverGroups.asMap().entries.map((entry) {
                    final index = entry.key;
                    final group = entry.value;
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Duration(milliseconds: 300 + (index * 80)),
                      curve: Curves.easeOut,
                      builder: (context, val, child) => Opacity(
                          opacity: val, child: Transform.translate(offset: Offset(0, 20 * (1 - val)), child: child)),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: DiscoverGroupCard(
                          group: group,
                          onJoin: () => showDialog(
                            context: context,
                            builder: (context) => JoinGroupDialog(group: group, onJoined: onJoined),
                          ),
                        ),
                      ),
                    );
                  }),

                const SizedBox(height: 110),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class MyGroupCard extends StatelessWidget {
  final Map<String, dynamic> group;
  final VoidCallback onTap;

  const MyGroupCard({Key? key, required this.group, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.divider),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 3))],
        ),
        child: Row(children: [
          GroupAvatar(name: group['name'] ?? '', size: 52),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(group['name'] ?? '', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.white)),
              const SizedBox(height: 3),
              Text('${group['member_count'] ?? 0} members', style: TextStyle(fontSize: 12, color: c.subtext)),
              if (group['description'] != null && group['description'].toString().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(group['description'], style: TextStyle(fontSize: 11, color: c.subtext), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ]),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: c.subtext),
        ]),
      ),
    );
  }
}

class DiscoverGroupCard extends StatelessWidget {
  final Map<String, dynamic> group;
  final VoidCallback onJoin;

  const DiscoverGroupCard({Key? key, required this.group, required this.onJoin}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.divider),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GroupAvatar(name: group['name'] ?? '', size: 52),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(group['name'] ?? '', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.white)),
            const SizedBox(height: 2),
            Row(children: [
              Icon(Icons.people_rounded, size: 12, color: c.subtext),
              const SizedBox(width: 4),
              Text('${group['member_count'] ?? 0} members', style: TextStyle(fontSize: 12, color: c.subtext)),
              if (group['is_private'] == true) ...[
                const SizedBox(width: 8),
                Icon(Icons.lock_rounded, size: 12, color: c.subtext),
                const SizedBox(width: 2),
                Text('Private', style: TextStyle(fontSize: 11, color: c.subtext)),
              ],
            ]),
            if (group['description'] != null && group['description'].toString().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(group['description'], style: TextStyle(fontSize: 12, color: c.subtext, height: 1.4),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ]),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: onJoin,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: c.greenDim,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: c.green.withOpacity(0.4), width: 1.5),
            ),
            child: Row(children: [
              Icon(Icons.add_rounded, color: c.green, size: 14),
              const SizedBox(width: 4),
              Text('Join', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.green)),
            ]),
          ),
        ),
      ]),
    );
  }
}

class GroupAvatar extends StatelessWidget {
  final String name;
  final double size;

  const GroupAvatar({Key? key, required this.name, required this.size}) : super(key: key);

  Color get avatarColor {
    final colors = [const Color(0xFF3B82F6), const Color(0xFF10B981), const Color(0xFFF59E0B),
      const Color(0xFFEF4444), const Color(0xFF8B5CF6), const Color(0xFF0EA5E9)];
    return colors[name.length % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: avatarColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(size * 0.3),
        border: Border.all(color: avatarColor.withOpacity(0.3), width: 1.5),
      ),
      child: Center(
        child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'G',
            style: TextStyle(fontSize: size * 0.38, fontWeight: FontWeight.w800, color: avatarColor)),
      ),
    );
  }
}