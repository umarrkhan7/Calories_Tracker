import 'package:flutter/material.dart';

class OnboardingController extends ChangeNotifier {
  // answers
  String gender = '';
  int workoutsPerWeek = 0;
  String heardFrom = '';
  bool triedOtherApps = false;
  double heightCm = 170;
  double weightKg = 70;
  DateTime dateOfBirth = DateTime(1995, 1, 1);
  String goal = '';           // lose / maintain / gain
  String dietType = '';
  List<String> accomplish = [];
  bool addBurnedCalories = false;
  bool rolloverCalories = false;

  // generated plan
  double dailyCalories = 0;
  double proteinG = 0;
  double carbsG = 0;
  double fatG = 0;
  double weeksToGoal = 0;
  double targetWeightKg = 70;

  // ── plan generation (Mifflin-St Jeor) ──────────────────────────
  void generatePlan() {
    final age = DateTime.now().year - dateOfBirth.year;

    double bmr;
    if (gender == 'male') {
      bmr = 10 * weightKg + 6.25 * heightCm - 5 * age + 5;
    } else {
      bmr = 10 * weightKg + 6.25 * heightCm - 5 * age - 161;
    }

    const multipliers = {
      'sedentary': 1.2,
      'light': 1.375,
      'moderate': 1.55,
      'active': 1.725,
    };

    String activityKey = 'sedentary';
    if (workoutsPerWeek >= 6) activityKey = 'active';
    else if (workoutsPerWeek >= 3) activityKey = 'moderate';
    else if (workoutsPerWeek >= 1) activityKey = 'light';

    final tdee = bmr * multipliers[activityKey]!;

    if (goal == 'lose') {
      dailyCalories = tdee - 500;
    } else if (goal == 'gain') {
      dailyCalories = tdee + 300;
    } else {
      dailyCalories = tdee;
    }

    dailyCalories = dailyCalories.clamp(1200, 4000);

    // macros
    if (dietType == 'keto') {
      proteinG = dailyCalories * 0.30 / 4;
      fatG     = dailyCalories * 0.60 / 9;
      carbsG   = dailyCalories * 0.10 / 4;
    } else if (dietType == 'vegan' || dietType == 'vegetarian') {
      proteinG = dailyCalories * 0.20 / 4;
      fatG     = dailyCalories * 0.25 / 9;
      carbsG   = dailyCalories * 0.55 / 4;
    } else {
      proteinG = dailyCalories * 0.30 / 4;
      fatG     = dailyCalories * 0.30 / 9;
      carbsG   = dailyCalories * 0.40 / 4;
    }

    // weeks to goal
    final diff = (weightKg - targetWeightKg).abs();
    weeksToGoal = diff > 0 ? (diff / 0.5).ceilToDouble() : 0;

    notifyListeners();
  }
}