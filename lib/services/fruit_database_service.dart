import 'dart:convert';
import 'package:flutter/services.dart';

/// Loads and indexes assets/data/fruits.json once, then serves it two ways:
///   - `allVarieties`      : flat list of every named variety (for manual search)
///   - `findGenericByLabel`: category-level generic nutrition data, matched
///                            against the raw label returned by the ML model
///                            (e.g. "Apple", "Kiwi", "Strawberry")
class FruitDatabaseService {
  FruitDatabaseService._internal();
  static final FruitDatabaseService instance = FruitDatabaseService._internal();

  List<Map<String, dynamic>> _allVarieties = [];
  final Map<String, Map<String, dynamic>> _genericByCategory = {};
  bool _loaded = false;

  /// Loads the JSON from assets exactly once; safe to call repeatedly.
  Future<void> load() async {
    if (_loaded) return;

    final jsonStr = await rootBundle.loadString('assets/data/fruits.json');
    final data = jsonDecode(jsonStr);

    final varieties = <Map<String, dynamic>>[];

    for (final fruit in data['fruits']) {
      final categoryName = fruit['name'] as String;

      for (final variety in fruit['varieties']) {
        varieties.add({
          ...Map<String, dynamic>.from(variety),
          'category': categoryName,
        });
      }

      if (fruit['generic'] != null) {
        _genericByCategory[categoryName.toLowerCase()] = {
          ...Map<String, dynamic>.from(fruit['generic']),
          'category': categoryName,
        };
      }
    }

    _allVarieties = varieties;
    _loaded = true;
  }

  /// Flat list of every variety, used by the manual lookup/search screen.
  List<Map<String, dynamic>> get allVarieties => _allVarieties;

  /// Matches a raw ML model label (e.g. "Apple") to its generic nutrition
  /// entry. Returns null if that category has no data yet — this can
  /// happen if the model's class list grows ahead of fruits.json.
  Map<String, dynamic>? findGenericByLabel(String label) {
    return _genericByCategory[label.toLowerCase().trim()];
  }

  /// Whether the database has already been loaded into memory.
  bool get isLoaded => _loaded;
}