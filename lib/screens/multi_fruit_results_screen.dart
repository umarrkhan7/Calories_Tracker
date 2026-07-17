import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../services/scan_api_service.dart';
import '../services/fruit_database_service.dart';
import '../widgets/fruit_image.dart';
import 'fruit_detail_screen.dart';

class MultiFruitResultsScreen extends StatefulWidget {
  final List<Detection> detections;
  final String scannedImagePath;

  const MultiFruitResultsScreen({
    super.key,
    required this.detections,
    required this.scannedImagePath,
  });

  @override
  State<MultiFruitResultsScreen> createState() => MultiFruitResultsScreenState();
}

class MultiFruitResultsScreenState extends State<MultiFruitResultsScreen> {
  bool isLoggingAll = false;

  /// Pairs each detection with its matched nutrition entry (if any).
  List<MapEntry<Detection, Map<String, dynamic>?>> get matchedDetections {
    return widget.detections.map((d) {
      final match = FruitDatabaseService.instance.findGenericByLabel(d.label);
      return MapEntry(d, match);
    }).toList();
  }

  Future<void> logAll() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final loggable = matchedDetections.where((e) => e.value != null).toList();
    if (loggable.isEmpty) return;

    setState(() => isLoggingAll = true);

    try {
      // Upload the scanned photo once and reuse the URL for every entry,
      // instead of uploading it once per detected fruit.
      String imageUrl;
      try {
        final bytes = await File(widget.scannedImagePath).readAsBytes();
        final fileName = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        await Supabase.instance.client.storage.from('fruit-scans').uploadBinary(
          fileName,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );
        imageUrl = Supabase.instance.client.storage.from('fruit-scans').getPublicUrl(fileName);
      } catch (e) {
        imageUrl = loggable.first.value!['image'] ?? '';
      }

      final today = DateTime.now().toIso8601String().split('T')[0];

      for (final entry in loggable) {
        final fruit = entry.value!;
        final servingGrams = (fruit['serving_size_g'] as num?)?.toDouble() ?? 100;
        double calc(String key) => ((fruit[key] as num?)?.toDouble() ?? 0) * servingGrams / 100;

        await Supabase.instance.client.from('food_logs').insert({
          'user_id':    user.id,
          'log_date':   today,
          'fruit_name': fruit['name'],
          'fruit_image': imageUrl,
          'servings':   1,
          'calories':   calc('calories_per_100g'),
          'protein_g':  calc('protein_per_100g'),
          'carbs_g':    calc('carbs_per_100g'),
          'fat_g':      calc('fat_per_100g'),
        });
      }

      if (mounted) {
        Navigator.pop(context, true); // true = refresh home
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to log: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => isLoggingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final results = matchedDetections;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: c.divider),
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded, color: c.white, size: 16),
          ),
        ),
        title: Text(
          '${results.length} Fruit${results.length == 1 ? '' : 's'} Found',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.white),
        ),
      ),
      body: SafeArea(
        child: results.isEmpty
            ? _buildEmptyState(c)
            : Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(
                  File(widget.scannedImagePath),
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const BouncingScrollPhysics(),
                itemCount: results.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final detection = results[index].key;
                  final match = results[index].value;
                  return _buildFruitTile(c, detection, match);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: isLoggingAll ? null : logAll,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: c.green,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: c.green.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Center(
                    child: isLoggingAll
                        ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                        : Text(
                      'Log All (1 serving each)',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppColorExtension c) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('No fruit detected', style: TextStyle(color: c.white, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              'Try a clearer photo with the fruits spaced apart.',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.subtext, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFruitTile(AppColorExtension c, Detection detection, Map<String, dynamic>? match) {
    return GestureDetector(
      onTap: match == null
          ? null
          : () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FruitDetailScreen(
              fruit: match,
              scannedImagePath: widget.scannedImagePath,
              confidence: detection.confidence,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.divider),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: FruitImage(
                imagePath: match?['image'],
                width: 52,
                height: 52,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(detection.label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.white)),
                  const SizedBox(height: 3),
                  Text(
                    match == null
                        ? 'No nutrition data available'
                        : '${(match['calories_per_100g'] as num?)?.round() ?? 0} kcal per 100g',
                    style: TextStyle(fontSize: 12, color: c.subtext),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: c.greenDim, borderRadius: BorderRadius.circular(20)),
              child: Text(
                '${detection.confidence.toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.green),
              ),
            ),
            if (match != null) ...[
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: c.subtext, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}