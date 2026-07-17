import 'package:calories_tracker/services/notification_service.dart';
import 'package:calories_tracker/theme/app_theme.dart';
import 'package:calories_tracker/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dashboard/home_screen.dart';
import 'onboarding/onboarding_flow.dart';
import 'screens/splash_screen.dart';
import 'authentication/signin_screen.dart';
import 'authentication/signup_screen.dart';
import 'authentication/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: '',
    anonKey: '',
  );
  await NotificationService.instance.init();
  NotificationService.instance.scheduleAllNotifications();
  NotificationService.instance.scheduleInactivityReminder();


  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    return MaterialApp(
      title: 'NutriTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: tp.isDark ? ThemeMode.dark : ThemeMode.light,
      initialRoute: '/',
      routes: {
        '/':           (context) => const SplashScreen(),
        '/splash':     (context) => const SplashScreen(),
        '/signin':     (context) => const SignInScreen(),
        '/signup':     (context) => const SignUpScreen(),
        '/onboarding': (context) => const OnboardingFlow(),
        '/dashboard':  (context) => const HomeScreen(),
      },
    );
  }
}