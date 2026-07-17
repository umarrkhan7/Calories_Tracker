import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

class CreateGroupDialog extends StatefulWidget {
  final VoidCallback onCreated;

  const CreateGroupDialog({Key? key, required this.onCreated}) : super(key: key);

  @override
  State<CreateGroupDialog> createState() => CreateGroupDialogState();
}

class CreateGroupDialogState extends State<CreateGroupDialog>
    with SingleTickerProviderStateMixin {

  final nameController = TextEditingController();
  final descController = TextEditingController();
  bool isPrivate = false;
  bool loading = false;
  String? error;

  late AnimationController animController;
  late Animation<double> scaleAnimation;
  late Animation<double> fadeAnimation;

  @override
  void initState() {
    super.initState();
    animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    scaleAnimation = Tween<double>(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(parent: animController, curve: Curves.easeOutBack));
    fadeAnimation = CurvedAnimation(parent: animController, curve: Curves.easeIn);
    animController.forward();
  }

  @override
  void dispose() {
    animController.dispose();
    nameController.dispose();
    descController.dispose();
    super.dispose();
  }

  Future<void> createGroup() async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      setState(() => error = 'Group name required');
      return;
    }
    if (name.length < 3) {
      setState(() => error = 'Name must be at least 3 characters');
      return;
    }

    setState(() { loading = true; error = null; });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      // create group
      final result = await Supabase.instance.client
          .from('groups')
          .insert({
        'name': name,
        'description': descController.text.trim().isEmpty ? null : descController.text.trim(),
        'is_private': isPrivate,
        'member_count': 1,
      })
          .select()
          .single();

      // auto-join creator as member
      await Supabase.instance.client.from('group_members').insert({
        'group_id': result['id'],
        'user_id': user.id,
        'first_name': 'You',
        'last_name': '(Creator)',
      });

      if (mounted) {
        Navigator.pop(context);
        widget.onCreated();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Group "$name" created!'),
          backgroundColor: const Color(0xFF2ECC71),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } on PostgrestException catch (e) {
      if (mounted) setState(() { loading = false; error = 'DB error: ${e.message}'; });
    } catch (e) {
      if (mounted) setState(() { loading = false; error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: FadeTransition(
        opacity: fadeAnimation,
        child: ScaleTransition(
          scale: scaleAnimation,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(28)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [

              // header
              Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: c.greenDim, borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.group_add_rounded, color: c.green, size: 22),
                ),
                const SizedBox(width: 12),
                Text('Create Group', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c.white)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close_rounded, color: c.subtext, size: 22),
                ),
              ]),

              const SizedBox(height: 24),

              // name field
              _buildLabel('Group Name *', c),
              const SizedBox(height: 8),
              _buildTextField(nameController, 'e.g. Morning Warriors', c),

              const SizedBox(height: 16),

              // description field
              _buildLabel('Description (optional)', c),
              const SizedBox(height: 8),
              _buildTextField(descController, 'What is this group about?', c, maxLines: 3),

              const SizedBox(height: 16),

              // private toggle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: c.surfaceAlt, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.divider)),
                child: Row(children: [
                  Icon(Icons.lock_rounded, color: c.subtext, size: 18),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Private Group', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.white)),
                    Text('Only invited members can join', style: TextStyle(fontSize: 11, color: c.subtext)),
                  ])),
                  Switch(
                    value: isPrivate,
                    onChanged: (val) => setState(() => isPrivate = val),
                    activeColor: c.green,
                  ),
                ]),
              ),

              // error
              if (error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFEF4444).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 15),
                    const SizedBox(width: 8),
                    Expanded(child: Text(error!, style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444)))),
                  ]),
                ),
              ],

              const SizedBox(height: 20),

              // create button
              GestureDetector(
                onTap: loading ? null : createGroup,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: nameController.text.trim().length >= 3 ? c.green : c.surfaceAlt,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: nameController.text.trim().length >= 3
                        ? [BoxShadow(color: c.green.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 6))]
                        : [],
                  ),
                  child: Center(
                    child: loading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Create Group', style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: nameController.text.trim().length >= 3 ? Colors.white : c.subtext)),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, AppColorExtension c) =>
      Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.subtext));

  Widget _buildTextField(TextEditingController ctrl, String hint, AppColorExtension c, {int maxLines = 1}) =>
      Container(
        decoration: BoxDecoration(color: c.surfaceAlt, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.divider)),
        child: TextField(
          controller: ctrl,
          maxLines: maxLines,
          onChanged: (_) => setState(() {}),
          style: TextStyle(fontSize: 14, color: c.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 14, color: c.subtext),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      );
}