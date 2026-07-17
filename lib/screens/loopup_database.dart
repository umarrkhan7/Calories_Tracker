import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'fruit_detail_screen.dart';

class LookupDatabaseScreen extends StatefulWidget {
  const LookupDatabaseScreen({Key? key}) : super(key: key);

  @override
  State<LookupDatabaseScreen> createState() => LookupDatabaseScreenState();
}

class LookupDatabaseScreenState extends State<LookupDatabaseScreen> {
  final searchController = TextEditingController();
  List<Map<String, dynamic>> allVarieties = [];
  List<Map<String, dynamic>> filteredResults = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadFruits();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadFruits() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/data/fruits.json');
      final data = jsonDecode(jsonStr);
      final List<Map<String, dynamic>> varieties = [];

      for (final fruit in data['fruits']) {
        for (final variety in fruit['varieties']) {
          varieties.add({
            ...Map<String, dynamic>.from(variety),
            'category': fruit['name'],
          });
        }
      }

      if (mounted) {
        setState(() {
          allVarieties = varieties;
          filteredResults = varieties;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => loading = false);
    }
  }

  void onSearch(String query) {
    final q = query.toLowerCase().trim();
    setState(() {
      if (q.isEmpty) {
        filteredResults = allVarieties;
      } else {
        filteredResults = allVarieties
            .where((v) =>
        v['name'].toString().toLowerCase().contains(q) ||
            v['category'].toString().toLowerCase().contains(q))
            .toList();
      }
    });
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {},
              child: Text('Manual entry',
                  style: TextStyle(color: c.green, fontSize: 14, fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline, decorationColor: c.green)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Container(
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.green.withOpacity(0.5), width: 1.5),
              ),
              child: TextField(
                controller: searchController,
                onChanged: onSearch,
                autofocus: true,
                style: TextStyle(color: c.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Search for food database',
                  hintStyle: TextStyle(color: c.subtext, fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded, color: c.subtext, size: 20),
                  suffixIcon: searchController.text.isNotEmpty
                      ? GestureDetector(
                      onTap: () {
                        searchController.clear();
                        onSearch('');
                      },
                      child: Icon(Icons.close_rounded, color: c.subtext, size: 18))
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // results header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Database results',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.white)),
          ),

          const SizedBox(height: 8),

          // results list
          Expanded(
            child: loading
                ? Center(child: CircularProgressIndicator(color: c.green))
                : filteredResults.isEmpty
                ? Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('🍽️', style: const TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text('No results found', style: TextStyle(color: c.subtext, fontSize: 15)),
              ]),
            )
                : ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredResults.length,
              separatorBuilder: (context, index) => Divider(color: c.divider, height: 1),
              itemBuilder: (context, index) {
                final fruit = filteredResults[index];
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          FruitDetailScreen(fruit: fruit),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                          SlideTransition(
                            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                                .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
                            child: child,
                          ),
                      transitionDuration: const Duration(milliseconds: 300),
                    ),
                  ),
                  child: Container(
                    color: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(children: [
                      // small fruit thumbnail
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          fruit['image'] ?? '',
                          width: 40, height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(8)),
                            child: Icon(Icons.image_outlined, color: c.subtext, size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(fruit['name'] ?? '',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: c.white)),
                          Text(fruit['category'] ?? '',
                              style: TextStyle(fontSize: 12, color: c.subtext)),
                        ]),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, color: c.subtext, size: 14),
                    ]),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}