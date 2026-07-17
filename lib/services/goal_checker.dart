import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_service.dart';

class GoalChecker {
  static final GoalChecker instance = GoalChecker.internal();
  GoalChecker.internal();

  final Set<String> notifiedToday = {};
  String lastNotifiedDate = '';

  void resetIfNewDay() {
    final today = DateTime.now().toIso8601String().split('T')[0];
    if (lastNotifiedDate != today) {
      notifiedToday.clear();
      lastNotifiedDate = today;
    }
  }

  Future<void> checkAndNotify() async {
    resetIfNewDay();

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      // get user goals
      final plan = await Supabase.instance.client
          .from('user_plans')
          .select('daily_calories, protein_g, carbs_g, fat_g')
          .eq('id', user.id)
          .maybeSingle();

      if (plan == null) return;

      final goalCalories = (plan['daily_calories'] as num?)?.toDouble() ?? 1800;
      final goalProtein  = (plan['protein_g'] as num?)?.toDouble() ?? 120;
      final goalCarbs    = (plan['carbs_g'] as num?)?.toDouble() ?? 200;
      final goalFat      = (plan['fat_g'] as num?)?.toDouble() ?? 60;

      // get today consumed
      final today = DateTime.now().toIso8601String().split('T')[0];
      final log = await Supabase.instance.client
          .from('daily_logs')
          .select('calories_consumed, protein_consumed, carbs_consumed, fat_consumed')
          .eq('user_id', user.id)
          .eq('log_date', today)
          .maybeSingle();

      if (log == null) return;

      final consumed        = (log['calories_consumed'] as num?)?.toDouble() ?? 0;
      final consumedProtein = (log['protein_consumed'] as num?)?.toDouble() ?? 0;
      final consumedCarbs   = (log['carbs_consumed'] as num?)?.toDouble() ?? 0;
      final consumedFat     = (log['fat_consumed'] as num?)?.toDouble() ?? 0;

      // calories
      if (consumed >= goalCalories && !notifiedToday.contains('calories')) {
        notifiedToday.add('calories');
        await NotificationService.instance.showGoalAchieved(
          goalCalories.round(), consumed.round(), 'calories',
        );
      }

      // protein
      if (consumedProtein >= goalProtein && !notifiedToday.contains('protein')) {
        notifiedToday.add('protein');
        await NotificationService.instance.showMacroGoalAchieved(
          'Protein', consumedProtein.round(), goalProtein.round(), '🥩',
        );
      }

      // carbs
      if (consumedCarbs >= goalCarbs && !notifiedToday.contains('carbs')) {
        notifiedToday.add('carbs');
        await NotificationService.instance.showMacroGoalAchieved(
          'Carbs', consumedCarbs.round(), goalCarbs.round(), '🌾',
        );
      }

      // fat
      if (consumedFat >= goalFat && !notifiedToday.contains('fat')) {
        notifiedToday.add('fat');
        await NotificationService.instance.showMacroGoalAchieved(
          'Fats', consumedFat.round(), goalFat.round(), '🥑',
        );
      }

      // all goals done
      if (consumed >= goalCalories &&
          consumedProtein >= goalProtein &&
          consumedCarbs >= goalCarbs &&
          consumedFat >= goalFat &&
          !notifiedToday.contains('all')) {
        notifiedToday.add('all');
        await NotificationService.instance.showAllGoalsAchieved();
      }

    } catch (e) {
      debugPrint('GoalChecker error: $e');
    }
  }
}