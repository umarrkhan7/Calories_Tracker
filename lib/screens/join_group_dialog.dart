import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

class JoinGroupDialog extends StatefulWidget {
  final Map<String, dynamic> group;
  final VoidCallback onJoined;

  const JoinGroupDialog({Key? key, required this.group, required this.onJoined}) : super(key: key);

  @override
  State<JoinGroupDialog> createState() => JoinGroupDialogState();
}

class JoinGroupDialogState extends State<JoinGroupDialog>
    with SingleTickerProviderStateMixin {

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  File? pickedImage;
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
    firstNameController.dispose();
    lastNameController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (picked != null && mounted) setState(() => pickedImage = File(picked.path));
    } catch (e) {
      if (mounted) setState(() => error = 'Failed to pick image: $e');
    }
  }

  String get initials {
    final first = firstNameController.text.trim();
    final last = lastNameController.text.trim();
    if (first.isEmpty && last.isEmpty) return '?';
    return '${first.isNotEmpty ? first[0] : ''}${last.isNotEmpty ? last[0] : ''}'.toUpperCase();
  }

  Future<void> joinGroup() async {
    final first = firstNameController.text.trim();
    final last = lastNameController.text.trim();

    if (first.isEmpty) { setState(() => error = 'First name required'); return; }
    if (last.isEmpty) { setState(() => error = 'Last name required'); return; }

    setState(() { loading = true; error = null; });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      // check already member
      final existing = await Supabase.instance.client
          .from('group_members')
          .select('id')
          .eq('group_id', widget.group['id'])
          .eq('user_id', user.id)
          .maybeSingle();

      if (existing != null) {
        setState(() { loading = false; error = 'Already a member of this group'; });
        return;
      }

      String? uploadedAvatarUrl;

      // upload avatar
      if (pickedImage != null) {
        try {
          final ext = pickedImage!.path.split('.').last;
          final path = '${user.id}/group_avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';
          await Supabase.instance.client.storage
              .from('avatars')
              .upload(path, pickedImage!, fileOptions: const FileOptions(upsert: true));
          uploadedAvatarUrl = Supabase.instance.client.storage.from('avatars').getPublicUrl(path);
        } catch (e) {
          // avatar upload failed → continue without it
          debugPrint('Avatar upload failed: $e');
        }
      }

      // insert member
      await Supabase.instance.client.from('group_members').insert({
        'group_id': widget.group['id'],
        'user_id': user.id,
        'first_name': first,
        'last_name': last,
        'avatar_url': uploadedAvatarUrl,
      });

      // increment member count
      final currentCount = (widget.group['member_count'] as int?) ?? 0;
      await Supabase.instance.client
          .from('groups')
          .update({'member_count': currentCount + 1})
          .eq('id', widget.group['id']);

      if (mounted) {
        Navigator.pop(context);
        widget.onJoined();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Joined ${widget.group['name']}! 🎉'),
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
    final canJoin = firstNameController.text.trim().isNotEmpty && lastNameController.text.trim().isNotEmpty;

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
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [

                // group header
                Row(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: c.greenDim, borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.group_rounded, color: c.green, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.group['name'] ?? '', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.white)),
                    Text('${widget.group['member_count'] ?? 0} members', style: TextStyle(fontSize: 12, color: c.subtext)),
                  ])),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close_rounded, color: c.subtext, size: 22),
                  ),
                ]),

                const SizedBox(height: 20),

                Text('Set up your profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c.white)),
                const SizedBox(height: 4),
                Text('How should the group see you?', style: TextStyle(fontSize: 14, color: c.subtext)),

                const SizedBox(height: 20),

                // avatar
                GestureDetector(
                  onTap: pickImage,
                  child: Stack(alignment: Alignment.center, children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 88, height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle, color: c.greenDim,
                        border: Border.all(color: c.green.withOpacity(0.3), width: 2),
                        image: pickedImage != null ? DecorationImage(image: FileImage(pickedImage!), fit: BoxFit.cover) : null,
                      ),
                      child: pickedImage == null
                          ? Center(child: Text(initials, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: c.green)))
                          : null,
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        width: 26, height: 26,
                        decoration: BoxDecoration(color: c.green, shape: BoxShape.circle, border: Border.all(color: c.surface, width: 2)),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 13),
                      ),
                    ),
                  ]),
                ),

                const SizedBox(height: 6),
                Text('Tap to add photo (optional)', style: TextStyle(fontSize: 11, color: c.subtext)),

                const SizedBox(height: 16),

                // name fields
                Row(children: [
                  Expanded(child: _buildField(firstNameController, 'First name', c)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildField(lastNameController, 'Last name', c)),
                ]),

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

                const SizedBox(height: 16),

                // join button
                GestureDetector(
                  onTap: loading ? null : joinGroup,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: canJoin ? c.green : c.surfaceAlt,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: canJoin ? [BoxShadow(color: c.green.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 6))] : [],
                    ),
                    child: Center(
                      child: loading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text('Join Group', style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700,
                          color: canJoin ? Colors.white : c.subtext)),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('Cancel', style: TextStyle(fontSize: 14, color: c.subtext, fontWeight: FontWeight.w500)),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String hint, AppColorExtension c) =>
      Container(
        decoration: BoxDecoration(color: c.surfaceAlt, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.divider)),
        child: TextField(
          controller: ctrl,
          onChanged: (_) => setState(() {}),
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: c.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 14, color: c.subtext),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      );
}