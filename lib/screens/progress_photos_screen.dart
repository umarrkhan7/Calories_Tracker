import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import 'progress_compare_screen.dart';

class ProgressPhotosScreen extends StatefulWidget {
  const ProgressPhotosScreen({Key? key}) : super(key: key);

  @override
  State<ProgressPhotosScreen> createState() => ProgressPhotosScreenState();
}

class ProgressPhotosScreenState extends State<ProgressPhotosScreen>
    with SingleTickerProviderStateMixin {

  List<Map<String, dynamic>> photos = [];
  bool loading = true;
  bool uploading = false;
  String? error;

  late AnimationController fadeController;
  late Animation<double> fadeAnimation;

  @override
  void initState() {
    super.initState();
    fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    fadeAnimation = CurvedAnimation(parent: fadeController, curve: Curves.easeIn);
    loadPhotos();
  }

  @override
  void dispose() {
    fadeController.dispose();
    super.dispose();
  }

  Future<void> loadPhotos() async {
    setState(() { loading = true; error = null; });
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final data = await Supabase.instance.client
          .from('progress_photos')
          .select()
          .eq('user_id', user.id)
          .order('taken_at', ascending: false);
      if (mounted) {
        setState(() {
          photos = List<Map<String, dynamic>>.from(data);
          loading = false;
        });
        fadeController.forward();
      }
    } catch (e) {
      if (mounted) setState(() { loading = false; error = e.toString(); });
    }
  }

  Future<void> uploadPhoto() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    // pick date first
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        final c = context.c;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: c.green,
              surface: c.surface,
              onSurface: c.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate == null) return;

    // pick image
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() { uploading = true; error = null; });

    try {
      final file = File(picked.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${user.id}/progress_$timestamp.jpg';

      // upload to storage
      await Supabase.instance.client.storage
          .from('progress-photos')
          .upload(path, file, fileOptions: const FileOptions(upsert: true));

      final url = Supabase.instance.client.storage
          .from('progress-photos')
          .getPublicUrl(path);

      // save to DB with full timestamp
      await Supabase.instance.client.from('progress_photos').insert({
        'user_id': user.id,
        'photo_url': url,
        'taken_at': pickedDate.toIso8601String().split('T')[0],
        'uploaded_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Photo uploaded successfully! 📸'),
          backgroundColor: const Color(0xFF2ECC71),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
        loadPhotos();
      }
    } on StorageException catch (e) {
      if (mounted) setState(() => error = 'Storage error: ${e.message}');
    } catch (e) {
      if (mounted) setState(() => error = 'Upload failed: $e');
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  Future<void> deletePhoto(String id, String photoUrl) async {
    final c = context.c;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Photo', style: TextStyle(color: c.white, fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to delete this photo?', style: TextStyle(color: c.subtext)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: TextStyle(color: c.subtext))),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await Supabase.instance.client.from('progress_photos').delete().eq('id', id);
      loadPhotos();
    } catch (e) {
      if (mounted) setState(() => error = 'Delete failed: $e');
    }
  }

  String formatDate(String? dateStr) {
    if (dateStr == null) return '';
    final dt = DateTime.parse(dateStr);
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String formatUploadTime(String? ts) {
    if (ts == null) return '';
    final dt = DateTime.parse(ts).toLocal();
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year} at $hour:$min';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.surface,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: c.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: c.divider),
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded, color: c.white, size: 16),
          ),
        ),
        title: Text('Progress Photos', style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w700, color: c.white)),
        actions: [
          if (photos.length >= 2)
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ProgressCompareScreen(photos: photos))),
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(color: c.greenDim, borderRadius: BorderRadius.circular(20)),
                child: Row(children: [
                  Icon(Icons.compare_rounded, color: c.green, size: 14),
                  const SizedBox(width: 6),
                  Text('Compare', style: TextStyle(color: c.green, fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
        ],
      ),
      body: loading
          ? Center(child: CircularProgressIndicator(color: c.green))
          : FadeTransition(
        opacity: fadeAnimation,
        child: RefreshIndicator(
          onRefresh: loadPhotos,
          color: c.green,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // error
                if (error != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(error!, style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444)))),
                    ]),
                  ),

                // stats row
                if (photos.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: c.divider),
                    ),
                    child: Row(children: [
                      Expanded(child: Column(children: [
                        Text('${photos.length}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: c.green)),
                        Text('Photos', style: TextStyle(fontSize: 11, color: c.subtext)),
                      ])),
                      Container(width: 1, height: 40, color: c.divider),
                      Expanded(child: Column(children: [
                        Text(formatDate(photos.last['taken_at']),
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.white)),
                        Text('First photo', style: TextStyle(fontSize: 11, color: c.subtext)),
                      ])),
                      Container(width: 1, height: 40, color: c.divider),
                      Expanded(child: Column(children: [
                        Text(formatDate(photos.first['taken_at']),
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.white)),
                        Text('Latest', style: TextStyle(fontSize: 11, color: c.subtext)),
                      ])),
                    ]),
                  ),

                // photos grid
                if (photos.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: c.divider),
                    ),
                    child: Column(children: [
                      Text('📸', style: const TextStyle(fontSize: 48)),
                      const SizedBox(height: 16),
                      Text('No photos yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.white)),
                      const SizedBox(height: 4),
                      Text('Upload your first progress photo!', style: TextStyle(fontSize: 13, color: c.subtext)),
                    ]),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: photos.length,
                    itemBuilder: (context, index) {
                      final photo = photos[index];
                      return GestureDetector(
                        onLongPress: () => deletePhoto(photo['id'], photo['photo_url']),
                        child: Container(
                          decoration: BoxDecoration(
                            color: c.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: c.divider),
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            // photo
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                child: Image.network(
                                  photo['photo_url'],
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return Container(
                                      color: c.surfaceAlt,
                                      child: Center(child: CircularProgressIndicator(color: c.green, strokeWidth: 2)),
                                    );
                                  },
                                  errorBuilder: (_, __, ___) => Container(
                                    color: c.surfaceAlt,
                                    child: Center(child: Icon(Icons.broken_image_rounded, color: c.subtext)),
                                  ),
                                ),
                              ),
                            ),
                            // date info
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(formatDate(photo['taken_at']),
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.white)),
                                const SizedBox(height: 2),
                                Text('Uploaded ${formatUploadTime(photo['uploaded_at'])}',
                                    style: TextStyle(fontSize: 9, color: c.subtext),
                                    maxLines: 2, overflow: TextOverflow.ellipsis),
                              ]),
                            ),
                          ]),
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 100),
              ]),
            ),
          ),
        ),
      ),

      // upload FAB
      floatingActionButton: GestureDetector(
        onTap: uploading ? null : uploadPhoto,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: c.green,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [BoxShadow(color: c.green.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 4))],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            uploading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.add_a_photo_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(uploading ? 'Uploading...' : 'Upload Photo',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
          ]),
        ),
      ),
    );
  }
}