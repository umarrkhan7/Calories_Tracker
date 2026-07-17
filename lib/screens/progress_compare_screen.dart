import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

class ProgressCompareScreen extends StatefulWidget {
  final List<Map<String, dynamic>> photos;

  const ProgressCompareScreen({Key? key, required this.photos}) : super(key: key);

  @override
  State<ProgressCompareScreen> createState() => ProgressCompareScreenState();
}

class ProgressCompareScreenState extends State<ProgressCompareScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController fadeController;
  late Animation<double> fadeAnimation;

  // available dates from photos
  List<String> availableDates = [];

  String? beforeDate;
  String? afterDate;

  Map<String, dynamic>? beforePhoto;
  Map<String, dynamic>? afterPhoto;

  @override
  void initState() {
    super.initState();
    fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    fadeAnimation = CurvedAnimation(parent: fadeController, curve: Curves.easeIn);

    // extract unique dates sorted
    final dates = widget.photos
        .map((p) => p['taken_at'] as String)
        .toSet()
        .toList()
      ..sort();
    availableDates = dates;

    if (availableDates.length >= 2) {
      beforeDate = availableDates.first;
      afterDate = availableDates.last;
      loadPhotosForDates();
    }

    fadeController.forward();
  }

  @override
  void dispose() {
    fadeController.dispose();
    super.dispose();
  }

  void loadPhotosForDates() {
    if (beforeDate != null) {
      final matches = widget.photos.where((p) => p['taken_at'] == beforeDate).toList();
      beforePhoto = matches.isNotEmpty ? matches.first : null;
    }
    if (afterDate != null) {
      final matches = widget.photos.where((p) => p['taken_at'] == afterDate).toList();
      afterPhoto = matches.isNotEmpty ? matches.first : null;
    }
    if (mounted) setState(() {});
  }

  String formatDate(String? dateStr) {
    if (dateStr == null) return 'Select date';
    final dt = DateTime.parse(dateStr);
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  // days between two dates
  int get daysBetween {
    if (beforeDate == null || afterDate == null) return 0;
    final before = DateTime.parse(beforeDate!);
    final after = DateTime.parse(afterDate!);
    return after.difference(before).inDays.abs();
  }

  void showDatePicker(bool isBefore) {
    final c = context.c;
    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            decoration: BoxDecoration(color: c.divider, borderRadius: BorderRadius.circular(2)),
          ),
          Text(isBefore ? 'Select Before Date' : 'Select After Date',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.white)),
          const SizedBox(height: 16),
          ...availableDates.map((date) {
            final selected = isBefore ? date == beforeDate : date == afterDate;
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isBefore) beforeDate = date;
                  else afterDate = date;
                });
                loadPhotosForDates();
                Navigator.pop(ctx);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: selected ? c.greenDim : c.surfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: selected ? c.green : c.divider),
                ),
                child: Row(children: [
                  Icon(Icons.calendar_today_rounded,
                      color: selected ? c.green : c.subtext, size: 16),
                  const SizedBox(width: 12),
                  Text(formatDate(date), style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600,
                      color: selected ? c.green : c.white)),
                  const Spacer(),
                  if (selected) Icon(Icons.check_circle_rounded, color: c.green, size: 18),
                ]),
              ),
            );
          }).toList(),
          const SizedBox(height: 24),
        ],
      ),
    );
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
        title: Text('Compare Progress', style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w700, color: c.white)),
      ),
      body: FadeTransition(
        opacity: fadeAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [

              // days between badge
              if (daysBetween > 0)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: c.greenDim,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: c.green.withOpacity(0.3)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.timeline_rounded, color: c.green, size: 16),
                    const SizedBox(width: 8),
                    Text('$daysBetween days of progress',
                        style: TextStyle(color: c.green, fontWeight: FontWeight.w600, fontSize: 13)),
                  ]),
                ),

              // date selectors row
              Row(children: [
                // before
                Expanded(child: GestureDetector(
                  onTap: () => showDatePicker(true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: c.divider),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('BEFORE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                          color: c.subtext, letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      Row(children: [
                        Icon(Icons.calendar_today_rounded, color: c.green, size: 13),
                        const SizedBox(width: 6),
                        Expanded(child: Text(formatDate(beforeDate),
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.white),
                            overflow: TextOverflow.ellipsis)),
                      ]),
                    ]),
                  ),
                )),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(Icons.compare_arrows_rounded, color: c.subtext, size: 22),
                ),

                // after
                Expanded(child: GestureDetector(
                  onTap: () => showDatePicker(false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: c.divider),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('AFTER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                          color: c.subtext, letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      Row(children: [
                        Icon(Icons.calendar_today_rounded, color: c.green, size: 13),
                        const SizedBox(width: 6),
                        Expanded(child: Text(formatDate(afterDate),
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.white),
                            overflow: TextOverflow.ellipsis)),
                      ]),
                    ]),
                  ),
                )),
              ]),

              const SizedBox(height: 16),

              // photos comparison
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // before photo
                Expanded(child: Column(children: [
                  Container(
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: c.divider),
                    ),
                    child: Column(children: [
                      // label
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.15),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: const Center(
                          child: Text('BEFORE', style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w800,
                              color: Color(0xFF3B82F6), letterSpacing: 1)),
                        ),
                      ),
                      // photo
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                        child: beforePhoto != null
                            ? Image.network(
                          beforePhoto!['photo_url'],
                          width: double.infinity,
                          height: 280,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              height: 280, color: c.surfaceAlt,
                              child: Center(child: CircularProgressIndicator(color: c.green, strokeWidth: 2)),
                            );
                          },
                          errorBuilder: (_, __, ___) => Container(
                            height: 280, color: c.surfaceAlt,
                            child: Center(child: Icon(Icons.broken_image_rounded, color: c.subtext, size: 40)),
                          ),
                        )
                            : Container(
                          height: 280, color: c.surfaceAlt,
                          child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.photo_outlined, color: c.subtext, size: 40),
                            const SizedBox(height: 8),
                            Text('No photo\nfor this date', textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: c.subtext)),
                          ])),
                        ),
                      ),
                    ]),
                  ),
                  if (beforePhoto != null) ...[
                    const SizedBox(height: 8),
                    Text(formatDate(beforePhoto!['taken_at']),
                        style: TextStyle(fontSize: 11, color: c.subtext, fontWeight: FontWeight.w600)),
                  ],
                ])),

                const SizedBox(width: 12),

                // after photo
                Expanded(child: Column(children: [
                  Container(
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: c.divider),
                    ),
                    child: Column(children: [
                      // label
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: c.greenDim,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: Center(
                          child: Text('AFTER', style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w800,
                              color: c.green, letterSpacing: 1)),
                        ),
                      ),
                      // photo
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                        child: afterPhoto != null
                            ? Image.network(
                          afterPhoto!['photo_url'],
                          width: double.infinity,
                          height: 280,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              height: 280, color: c.surfaceAlt,
                              child: Center(child: CircularProgressIndicator(color: c.green, strokeWidth: 2)),
                            );
                          },
                          errorBuilder: (_, __, ___) => Container(
                            height: 280, color: c.surfaceAlt,
                            child: Center(child: Icon(Icons.broken_image_rounded, color: c.subtext, size: 40)),
                          ),
                        )
                            : Container(
                          height: 280, color: c.surfaceAlt,
                          child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.photo_outlined, color: c.subtext, size: 40),
                            const SizedBox(height: 8),
                            Text('No photo\nfor this date', textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: c.subtext)),
                          ])),
                        ),
                      ),
                    ]),
                  ),
                  if (afterPhoto != null) ...[
                    const SizedBox(height: 8),
                    Text(formatDate(afterPhoto!['taken_at']),
                        style: TextStyle(fontSize: 11, color: c.subtext, fontWeight: FontWeight.w600)),
                  ],
                ])),
              ]),

              const SizedBox(height: 24),

              // motivation card
              if (beforePhoto != null && afterPhoto != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: c.greenDim,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: c.green.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    const Text('🏆', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Amazing Progress!', style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800, color: c.green)),
                      const SizedBox(height: 4),
                      Text('$daysBetween days of dedication. You should be proud! 💪',
                          style: TextStyle(fontSize: 12, color: c.subtext, height: 1.4)),
                    ])),
                  ]),
                ),

              const SizedBox(height: 32),
            ]),
          ),
        ),
      ),
    );
  }
}