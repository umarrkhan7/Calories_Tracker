import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/fruit_image.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => HistoryScreenState();
}

class HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> allLogs = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => loading = false);
      return;
    }
    try {
      final data = await Supabase.instance.client
          .from('food_logs')
          .select()
          .eq('user_id', user.id)
          .order('logged_at', ascending: false);

      if (mounted) {
        setState(() {
          allLogs = (data as List).map((e) => Map<String, dynamic>.from(e)).toList();
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> deleteLog(Map<String, dynamic> log) async {
    try {
      await Supabase.instance.client.from('food_logs').delete().eq('id', log['id']);
    } catch (e) {
      // If the delete fails server-side, reload so the UI matches reality.
      loadHistory();
    }
  }

  String formatTime(String? isoString) {
    if (isoString == null) return '';
    final dt = DateTime.tryParse(isoString);
    if (dt == null) return '';
    return DateFormat('h:mm a').format(dt.toLocal());
  }

  String dateHeaderLabel(String logDate) {
    final date = DateTime.tryParse(logDate);
    if (date == null) return logDate;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);

    if (d == today) return 'Today';
    if (d == yesterday) return 'Yesterday';
    return DateFormat('EEE, d MMM').format(date);
  }

  Map<String, List<Map<String, dynamic>>> get groupedByDate {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final log in allLogs) {
      final date = (log['log_date'] ?? 'Unknown').toString();
      map.putIfAbsent(date, () => []).add(log);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final grouped = groupedByDate;
    final dateKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

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
        title: Text('History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.white)),
      ),
      body: loading
          ? Center(child: CircularProgressIndicator(color: c.green))
          : allLogs.isEmpty
          ? _buildEmptyState(c)
          : RefreshIndicator(
        onRefresh: loadHistory,
        color: c.green,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: dateKeys.length,
          itemBuilder: (context, index) {
            final dateKey = dateKeys[index];
            final logsForDate = grouped[dateKey]!;
            return _buildDateSection(c, dateKey, logsForDate);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppColorExtension c) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📋', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('No history yet', style: TextStyle(color: c.white, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Fruits you log will show up here', style: TextStyle(color: c.subtext, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildDateSection(AppColorExtension c, String dateKey, List<Map<String, dynamic>> logs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8, left: 4),
          child: Text(
            dateHeaderLabel(dateKey),
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.subtext),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.divider),
          ),
          child: Column(
            children: logs.asMap().entries.map((entry) {
              final i = entry.key;
              final log = entry.value;
              return Column(
                children: [
                  _buildLogTile(c, log),
                  if (i < logs.length - 1)
                    Divider(color: c.divider, height: 1, indent: 16, endIndent: 16),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLogTile(AppColorExtension c, Map<String, dynamic> log) {
    return Dismissible(
      key: ValueKey(log['id'] ?? log.hashCode),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withOpacity(0.15),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: c.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Text('Delete entry?', style: TextStyle(color: c.white, fontWeight: FontWeight.w700)),
            content: Text(
              'This will remove "${log['fruit_name']}" from your history.',
              style: TextStyle(color: c.subtext),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel', style: TextStyle(color: c.subtext)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete', style: TextStyle(color: Color(0xFFEF4444))),
              ),
            ],
          ),
        ) ??
            false;
      },
      onDismissed: (_) {
        setState(() => allLogs.removeWhere((l) => l['id'] == log['id']));
        deleteLog(log);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FruitImage(
                imagePath: log['fruit_image'],
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
                  Text(log['fruit_name'] ?? '',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.white)),
                  const SizedBox(height: 3),
                  Text(
                    '${formatTime(log['logged_at'])} · ${log['servings'] ?? 1}x serving',
                    style: TextStyle(fontSize: 12, color: c.subtext),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: c.greenDim, borderRadius: BorderRadius.circular(20)),
              child: Text(
                '${(log['calories'] as num?)?.round() ?? 0} kcal',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.green),
              ),
            ),
          ],
        ),
      ),
    );
  }
}