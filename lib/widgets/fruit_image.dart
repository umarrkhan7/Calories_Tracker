import 'package:flutter/material.dart';

/// Renders a fruit image regardless of source:
///   - a bundled stock asset path from fruits.json (e.g. "assets/images/apple/...")
///   - a Supabase Storage URL from a real scanned photo (e.g. "https://...supabase.co/...")
///
/// Use this everywhere a fruit image is shown (history, lookup, detail screens)
/// so scanned photos and stock images both render correctly without extra
/// branching logic at each call site.
class FruitImage extends StatelessWidget {
  final String? imagePath;
  final BoxFit fit;
  final double? width;
  final double? height;

  const FruitImage({
    super.key,
    required this.imagePath,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  bool get _isNetworkImage =>
      imagePath != null &&
          (imagePath!.startsWith('http://') || imagePath!.startsWith('https://'));

  @override
  Widget build(BuildContext context) {
    if (imagePath == null || imagePath!.isEmpty) {
      return _placeholder();
    }

    if (_isNetworkImage) {
      return Image.network(
        imagePath!,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => _placeholder(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _placeholder(loading: true);
        },
      );
    }

    return Image.asset(
      imagePath!,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder({bool loading = false}) {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFF1A1A1A),
      child: Center(
        child: loading
            ? const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
        )
            : const Icon(Icons.image_outlined, color: Colors.grey, size: 28),
      ),
    );
  }
}