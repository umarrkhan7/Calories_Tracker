import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../services/scan_api_service.dart';
import '../services/fruit_database_service.dart';
import 'fruit_detail_screen.dart';
import 'multi_fruit_results_screen.dart';

enum ScanMode { single, multi }

class ScanFruitScreen extends StatefulWidget {
  const ScanFruitScreen({super.key});

  @override
  State<ScanFruitScreen> createState() => ScanFruitScreenState();
}

class ScanFruitScreenState extends State<ScanFruitScreen> {
  File? selectedImage;
  final picker = ImagePicker();

  // true while we're waiting on the model's prediction
  bool isAnalyzing = false;

  // which pipeline to use when "Use Photo" is tapped
  ScanMode scanMode = ScanMode.single;

  Future<void> openCamera() async {
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,          // plenty for a 224x224 model input
      maxWidth: 1024,            // caps file size without hurting accuracy
      maxHeight: 1024,
      preferredCameraDevice: CameraDevice.rear,
    );
    if (picked != null && mounted) {
      setState(() => selectedImage = File(picked.path));
    }
  }

  Future<void> openGallery() async {
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (picked != null && mounted) {
      setState(() => selectedImage = File(picked.path));
    }
  }

  void clearImage() => setState(() => selectedImage = null);

  Future<void> analyzeAndProceed() async {
    if (selectedImage == null || isAnalyzing) return;

    if (scanMode == ScanMode.multi) {
      await _analyzeMulti();
    } else {
      await _analyzeSingle();
    }
  }

  Future<void> _analyzeSingle() async {
    setState(() => isAnalyzing = true);

    try {
      final result = await ScanApiService.predict(selectedImage!);

      if (!mounted) return;

      // Model explicitly says this isn't a fruit at all.
      if (result.label.toLowerCase() == 'nonfruit') {
        setState(() => isAnalyzing = false);
        _showNotAFruitDialog();
        return;
      }

      await FruitDatabaseService.instance.load();
      final match = FruitDatabaseService.instance.findGenericByLabel(result.label);

      if (!mounted) return;
      setState(() => isAnalyzing = false);

      if (match == null) {
        // Model recognized a fruit we don't have nutrition data for yet.
        _showNoDataSnackBar(result.label);
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FruitDetailScreen(
            fruit: match,
            scannedImagePath: selectedImage!.path,
            confidence: result.confidence,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => isAnalyzing = false);
      _showErrorSnackBar(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _analyzeMulti() async {
    setState(() => isAnalyzing = true);

    try {
      final result = await ScanApiService.predictMulti(selectedImage!);
      await FruitDatabaseService.instance.load();

      if (!mounted) return;
      setState(() => isAnalyzing = false);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MultiFruitResultsScreen(
            detections: result.detections,
            scannedImagePath: selectedImage!.path,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => isAnalyzing = false);
      _showErrorSnackBar(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showNotAFruitDialog() {
    final c = context.c;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text("Hmm, that's not a fruit",
            style: TextStyle(color: c.white, fontWeight: FontWeight.w700)),
        content: Text(
          "We couldn't recognize a fruit in this photo. Try again with the "
              "fruit centered and well lit.",
          style: TextStyle(color: c.subtext),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              clearImage();
            },
            child: Text('Retake', style: TextStyle(color: c.green, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showNoDataSnackBar(String label) {
    final c = context.c;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Recognized \"$label\" but nutrition data isn't available yet."),
      backgroundColor: c.orange,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: const Color(0xFFEF4444),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;

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
        title: Text('Scan Fruit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.white)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // single / multi fruit mode toggle — only shown before capture
            if (selectedImage == null) ...[
              _buildModeToggle(c),
              const SizedBox(height: 16),
            ],

            // image preview or placeholder
            Expanded(
              child: selectedImage == null
                  ? _buildPlaceholder(c)
                  : _buildImagePreview(c),
            ),

            const SizedBox(height: 20),

            // buttons
            if (selectedImage == null) ...[
              // camera button
              _ActionButton(
                label: 'Take Photo',
                icon: Icons.camera_alt_rounded,
                color: c.green,
                dimColor: c.greenDim,
                onTap: openCamera,
              ),
              const SizedBox(height: 12),
              // gallery button
              _ActionButton(
                label: 'Upload from Gallery',
                icon: Icons.photo_library_rounded,
                color: c.orange,
                dimColor: c.orangeDim,
                onTap: openGallery,
              ),
            ] else ...[
              // retake / use buttons
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: isAnalyzing ? null : clearImage,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: c.divider),
                      ),
                      child: Center(child: Text('Retake', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.white))),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: isAnalyzing ? null : analyzeAndProceed,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: c.green,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: c.green.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: Center(
                        child: isAnalyzing
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                            : const Text('Use Photo', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ),
                  ),
                ),
              ]),
            ],

            const SizedBox(height: 12),
          ]),
        ),
      ),
    );
  }

  Widget _buildModeToggle(AppColorExtension c) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.divider),
      ),
      child: Row(
        children: [
          Expanded(child: _buildModeButton(c, ScanMode.single, 'Single Fruit', Icons.filter_center_focus_rounded)),
          Expanded(child: _buildModeButton(c, ScanMode.multi, 'Multi Fruit', Icons.grid_view_rounded)),
        ],
      ),
    );
  }

  Widget _buildModeButton(AppColorExtension c, ScanMode mode, String label, IconData icon) {
    final selected = scanMode == mode;
    return GestureDetector(
      onTap: () => setState(() => scanMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? c.green : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: selected ? Colors.black : c.subtext),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.black : c.subtext,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(AppColorExtension c) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.divider, width: 1.5),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 90, height: 90,
          decoration: BoxDecoration(color: c.greenDim, shape: BoxShape.circle),
          child: Icon(Icons.camera_alt_rounded, color: c.green, size: 40),
        ),
        const SizedBox(height: 20),
        Text('Take or upload a photo', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c.white)),
        const SizedBox(height: 8),
        Text('of a fruit to get started', style: TextStyle(fontSize: 14, color: c.subtext)),
      ]),
    );
  }

  Widget _buildImagePreview(AppColorExtension c) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.divider),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.file(
          selectedImage!,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color, dimColor;
  final VoidCallback onTap;

  const _ActionButton({required this.label, required this.icon, required this.color, required this.dimColor, required this.onTap});

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> with SingleTickerProviderStateMixin {
  late AnimationController ctrl;
  late Animation<double> scale;

  @override
  void initState() {
    super.initState();
    ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    scale = Tween<double>(begin: 1.0, end: 0.97).animate(ctrl);
  }

  @override
  void dispose() { ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GestureDetector(
      onTapDown: (_) => ctrl.forward(),
      onTapUp: (_) { ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => ctrl.reverse(),
      child: ScaleTransition(
        scale: scale,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: widget.dimColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.color.withOpacity(0.3)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(widget.icon, color: widget.color, size: 22),
            const SizedBox(width: 10),
            Text(widget.label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: widget.color)),
          ]),
        ),
      ),
    );
  }
}