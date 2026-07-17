import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService instance = NotificationService.internal();
  NotificationService.internal();

  final FlutterLocalNotificationsPlugin plugin = FlutterLocalNotificationsPlugin();
  bool initialized = false;

  static const motivationChannel = AndroidNotificationChannel(
    'motivation_channel', 'Daily Motivation',
    description: 'Morning motivation and daily reminders',
    importance: Importance.high,
  );
  static const reminderChannel = AndroidNotificationChannel(
    'reminder_channel', 'Meal Reminders',
    description: 'Lunch and evening reminders',
    importance: Importance.high,
  );
  static const achievementChannel = AndroidNotificationChannel(
    'achievement_channel', 'Achievements',
    description: 'Goal and streak achievements',
    importance: Importance.max,
  );
  static const goalChannel = AndroidNotificationChannel(
    'goal_channel', 'Goal Notifications',
    description: 'Daily calorie goal notifications',
    importance: Importance.high,
  );

  Future<void> init() async {
    if (initialized) return;
    tz.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await plugin.initialize(const InitializationSettings(android: android, iOS: ios));
    final androidPlugin = plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(motivationChannel);
    await androidPlugin?.createNotificationChannel(reminderChannel);
    await androidPlugin?.createNotificationChannel(achievementChannel);
    await androidPlugin?.createNotificationChannel(goalChannel);
    await androidPlugin?.requestNotificationsPermission();
    initialized = true;
  }

  Future<void> scheduleAllNotifications() async {
    await init();
    await plugin.cancelAll();
    await scheduleMorningMotivation();
    await scheduleLunchReminder();
    await scheduleEveningReminder();
    await scheduleNightSummary();
    await scheduleFruitFact();
  }

  Future<void> scheduleMorningMotivation() async {
    const quotes = [
      'Your body is your temple. Fuel it with purpose! 🌱',
      'Every meal is a chance to nourish your potential! ⚡',
      'Small habits today = big results tomorrow! 🏆',
      'You are one scan away from a healthier you! 📱',
      'Champions are made in the morning. Let\'s go! 💪',
      'Today is a perfect day to eat well! 🍎',
      'Your health journey continues. Own it! 🔥',
    ];
    final quote = quotes[DateTime.now().weekday % quotes.length];
    await plugin.zonedSchedule(1, '🌞 Good Morning!', quote, nextInstanceOfTime(9, 0),
      NotificationDetails(android: AndroidNotificationDetails(
        motivationChannel.id, motivationChannel.name,
        channelDescription: motivationChannel.description,
        importance: Importance.high, priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: BigTextStyleInformation(quote),
      ), iOS: const DarwinNotificationDetails()),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> scheduleLunchReminder() async {
    const body = 'Don\'t forget to log your lunch! Track it to stay on goal 🍽';
    await plugin.zonedSchedule(2, '🍽 Lunch Time!', body, nextInstanceOfTime(13, 0),
      NotificationDetails(android: AndroidNotificationDetails(
        reminderChannel.id, reminderChannel.name,
        channelDescription: reminderChannel.description,
        importance: Importance.high, priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: const BigTextStyleInformation(body),
      ), iOS: const DarwinNotificationDetails()),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> scheduleEveningReminder() async {
    const body = 'Evening check-in! How are your nutrition goals looking? 🌇';
    await plugin.zonedSchedule(3, '🌇 Evening Check-in', body, nextInstanceOfTime(18, 0),
      NotificationDetails(android: AndroidNotificationDetails(
        reminderChannel.id, reminderChannel.name,
        channelDescription: reminderChannel.description,
        importance: Importance.high, priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: const BigTextStyleInformation(body),
      ), iOS: const DarwinNotificationDetails()),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> scheduleNightSummary() async {
    const body = 'Great day! Check your nutrition summary and plan for tomorrow 🌙';
    await plugin.zonedSchedule(4, '🌙 Daily Summary', body, nextInstanceOfTime(21, 30),
      NotificationDetails(android: AndroidNotificationDetails(
        motivationChannel.id, motivationChannel.name,
        channelDescription: motivationChannel.description,
        importance: Importance.high, priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: const BigTextStyleInformation(body),
      ), iOS: const DarwinNotificationDetails()),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> scheduleFruitFact() async {
    const facts = [
      '🍋 Lemons float in water but limes sink!',
      '🍓 Strawberries have more Vitamin C than oranges!',
      '🍌 Bananas are technically berries. Surprising? 🤯',
      '🥝 Kiwi has more Vitamin C than an orange per 100g!',
      '🍎 Apples are 25% air — that\'s why they float!',
      '🍉 Watermelon is 92% water — perfect hydration!',
      '🍇 Grapes are one of the oldest cultivated fruits!',
    ];
    final fact = facts[DateTime.now().weekday % facts.length];
    await plugin.zonedSchedule(5, '📚 Fruit Fact of the Day', fact, nextInstanceOfTime(11, 0),
      NotificationDetails(android: AndroidNotificationDetails(
        motivationChannel.id, motivationChannel.name,
        channelDescription: motivationChannel.description,
        importance: Importance.defaultImportance, priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: BigTextStyleInformation(fact),
      ), iOS: const DarwinNotificationDetails()),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // Future<void> showGoalAchieved(int dailyGoal) async {
  //   await init();
  //   const quotes = [
  //     'Tomorrow: push harder. Today proved you can! 💪',
  //     'Consistency beats perfection. See you tomorrow! 🌟',
  //     'Your body thanks you. Keep the streak alive! 🔥',
  //     'Goals hit today. Habits built for life! ⚡',
  //     'Champion energy. Bring it again tomorrow! 🏆',
  //   ];
  //   final quote = quotes[DateTime.now().second % quotes.length];
  //   final body = 'You hit $dailyGoal kcal today! $quote';
  //   await plugin.show(6, '🎯 Daily Goal Achieved!', body,
  //     NotificationDetails(android: AndroidNotificationDetails(
  //       goalChannel.id, goalChannel.name,
  //       channelDescription: goalChannel.description,
  //       importance: Importance.max, priority: Priority.high,
  //       icon: '@mipmap/ic_launcher',
  //       largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
  //       styleInformation: BigTextStyleInformation(body),
  //     ), iOS: const DarwinNotificationDetails()),
  //   );
  // }

  Future<void> showStreakAchievement(int days) async {
    await init();
    final body = 'You\'ve logged your nutrition for $days days in a row! Keep it up! 🔥';
    await plugin.show(7, '🔥 $days Day Streak!', body,
      NotificationDetails(android: AndroidNotificationDetails(
        achievementChannel.id, achievementChannel.name,
        channelDescription: achievementChannel.description,
        importance: Importance.max, priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: BigTextStyleInformation(body),
      ), iOS: const DarwinNotificationDetails()),
    );
  }

  Future<void> scheduleInactivityReminder() async {
    await init();
    const body = 'We miss you! Come back and track your nutrition 👋';
    final scheduleTime = tz.TZDateTime.now(tz.local).add(const Duration(days: 3));
    await plugin.zonedSchedule(8, '👋 We Miss You!', body, scheduleTime,
      NotificationDetails(android: AndroidNotificationDetails(
        reminderChannel.id, reminderChannel.name,
        channelDescription: reminderChannel.description,
        importance: Importance.high, priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: const BigTextStyleInformation(body),
      ), iOS: const DarwinNotificationDetails()),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> showSignInSuccess() async {
    await init();
    const body = 'You\'re signed in. Let\'s hit your goals today! 💪';
    await plugin.show(9, '👋 Welcome back!', body,
      const NotificationDetails(android: AndroidNotificationDetails(
        'signin_channel', 'Sign In Notifications',
        channelDescription: 'Sign in success notifications',
        importance: Importance.high, priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: BigTextStyleInformation(body),
      ), iOS: DarwinNotificationDetails()),
    );
  }

  tz.TZDateTime nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) scheduled = scheduled.add(const Duration(days: 1));
    return scheduled;
  }
  Future<void> showGoalAchieved(int goal, int consumed, String type) async {
    await init();
    const quotes = [
      'Tomorrow: push harder. Today proved you can! 💪',
      'Consistency beats perfection. See you tomorrow! 🌟',
      'Your body thanks you. Keep the streak alive! 🔥',
      'Goals hit today. Habits built for life! ⚡',
      'Champion energy. Bring it again tomorrow! 🏆',
    ];
    final quote = quotes[DateTime.now().second % quotes.length];
    final body = 'You hit $consumed/$goal kcal today! $quote';

    await plugin.show(
       6,
      '🎯 Calorie Goal Achieved!',
      body,
       NotificationDetails(
        android: AndroidNotificationDetails(
          goalChannel.id, goalChannel.name,
          channelDescription: goalChannel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
  Future<void> showPlanUpdated() async {
    await init();
    const body = 'Your nutrition plan has been recalculated based on your new details! 🎯';
    await plugin.show(
      10,
      '📊 Plan Updated!',
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'goal_channel', 'Goal Notifications',
          channelDescription: 'Daily calorie goal notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> showMacroGoalAchieved(String macro, int consumed, int goal, String emoji) async {
    await init();
    final body = '$emoji $macro goal hit! $consumed/$goal g consumed today. Keep it up!';
    await plugin.show(
       macro.hashCode.abs() % 100 + 10,
       '$emoji $macro Goal Achieved!',
       body,
     NotificationDetails(
        android: AndroidNotificationDetails(
          goalChannel.id, goalChannel.name,
          channelDescription: goalChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> showAllGoalsAchieved() async {
    await init();
    const body = 'Calories + Protein + Carbs + Fats — ALL goals crushed today! You are unstoppable! 🏆🔥';
    await plugin.show(
      20,
      '🏆 Perfect Day!',
     body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          achievementChannel.id, achievementChannel.name,
          channelDescription: achievementChannel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: const BigTextStyleInformation(body),
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }


  Future<void> cancelAll() async => plugin.cancelAll();
}