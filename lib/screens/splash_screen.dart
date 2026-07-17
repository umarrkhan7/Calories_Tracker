import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../authentication/signin_screen.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  late AnimationController lottieController;
  late AnimationController appNameController;

  // word 1: "think." → fades in
  late AnimationController thinkController;
  late Animation<double> thinkFade;

  // word 2: "scan." → slides up
  late AnimationController scanController;
  late Animation<double> scanFade;
  late Animation<Offset> scanSlide;

  // word 3: "transform." → scales in
  late AnimationController transformController;
  late Animation<double> transformFade;
  late Animation<double> transformScale;

  // app name
  late Animation<double> appNameFade;
  late Animation<Offset> appNameSlide;

  @override
  void initState() {
    super.initState();

    lottieController = AnimationController(vsync: this);

    // think. → fade in
    thinkController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    thinkFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: thinkController, curve: Curves.easeIn));

    // scan. → slide up
    scanController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    scanFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: scanController, curve: Curves.easeIn));
    scanSlide = Tween<Offset>(begin: const Offset(0, 0.6), end: Offset.zero).animate(
        CurvedAnimation(parent: scanController, curve: Curves.easeOut));

    // transform. → scale in
    transformController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    transformFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: transformController, curve: Curves.easeIn));
    transformScale = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: transformController, curve: Curves.elasticOut));

    // app name
    appNameController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    appNameFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: appNameController, curve: Curves.easeIn));
    appNameSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
        CurvedAnimation(parent: appNameController, curve: Curves.easeOut));

    startFlow();
  }

  Future<void> startFlow() async {
    // lottie starts immediately via onLoaded

    // stagger text animations
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) thinkController.forward();

    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) scanController.forward();

    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) transformController.forward();

    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) appNameController.forward();

    // total ~3.7s → then navigate
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) navigate();
  }

  Future<void> navigate() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (!mounted) return;

    if (session == null) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const SignInScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
      return;
    }

    final plan = await Supabase.instance.client
        .from('user_plans')
        .select()
        .eq('id', session.user.id)
        .maybeSingle();

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, plan == null ? '/onboarding' : '/dashboard');
  }

  @override
  void dispose() {
    lottieController.dispose();
    thinkController.dispose();
    scanController.dispose();
    transformController.dispose();
    appNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Scaffold(
      backgroundColor: c.bg,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.2),
            radius: 1.3,
            colors: [c.greenDim, c.bg],
          ),
        ),
        child: SafeArea(
          child: Column(children: [

            const Spacer(),

            Center(


           child:  Lottie.asset(
              'assets/animations/splash.json',
              controller: lottieController,
              width: 220,
              height: 220,
              fit: BoxFit.contain,
              onLoaded: (composition) {
                lottieController
                  ..duration = composition.duration
                  ..repeat();
              },
              errorBuilder: (context, error, stack) => Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  color: c.green,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [BoxShadow(color: c.green.withOpacity(0.3), blurRadius: 30, spreadRadius: 8)],
                ),
                child: const Icon(Icons.local_dining_rounded, color: Colors.white, size: 46),
              ),
            ),
            ),
            const SizedBox(height: 36),

            // ── word sequence ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [

                // "think." → fades in
                FadeTransition(
                  opacity: thinkFade,
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'think',
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            color: c.white,
                            letterSpacing: -1.5,
                          ),
                        ),
                        TextSpan(
                          text: '.',
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            color: c.green,
                            letterSpacing: -1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // "scan." → slides up
                SlideTransition(
                  position: scanSlide,
                  child: FadeTransition(
                    opacity: scanFade,
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'scan',
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w800,
                              color: c.white,
                              letterSpacing: -1.5,
                            ),
                          ),
                          TextSpan(
                            text: '.',
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w800,
                              color: c.orange,
                              letterSpacing: -1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),
                ScaleTransition(
                  scale: transformScale,
                  child: FadeTransition(
                    opacity: transformFade,
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'transform',
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w800,
                              color: c.white,
                              letterSpacing: -1.5,
                            ),
                          ),
                          TextSpan(
                            text: '.',
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w800,
                              color: c.green,
                              letterSpacing: -1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ]),
            ),

            const SizedBox(height: 32),

            // app name
            SlideTransition(
              position: appNameSlide,
              child: FadeTransition(
                opacity: appNameFade,
                child: Column(children: [
                  Text('NutriTrack',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: c.subtext,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text('Your personal nutrition guide',
                      style: TextStyle(fontSize: 13, color: c.textHint)),
                ]),
              ),
            ),

            const Spacer(),

            // bottom loading dots
            FadeTransition(
              opacity: thinkFade,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: LoadingDots(color: c.green),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── loading dots ───────────────────────────────────────────────────
class LoadingDots extends StatefulWidget {
  final Color color;
  const LoadingDots({Key? key, required this.color}) : super(key: key);
  @override
  State<LoadingDots> createState() => LoadingDotsState();
}

class LoadingDotsState extends State<LoadingDots> with TickerProviderStateMixin {
  late List<AnimationController> controllers;
  late List<Animation<double>> anims;

  @override
  void initState() {
    super.initState();
    controllers = List.generate(3, (i) => AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500)));
    anims = controllers.map((ctrl) =>
        Tween<double>(begin: 0, end: -8).animate(
            CurvedAnimation(parent: ctrl, curve: Curves.easeInOut))).toList();
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 160), () {
        if (mounted) controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final ctrl in controllers) ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) => AnimatedBuilder(
          animation: anims[i],
          builder: (context, child) => Transform.translate(
            offset: Offset(0, anims[i].value),
            child: Container(
              margin: EdgeInsets.only(left: i > 0 ? 6 : 0),
              width: 7, height: 7,
              decoration: BoxDecoration(
                color: widget.color.withOpacity(i == 1 ? 1.0 : 0.4),
                shape: BoxShape.circle,
              ),
            ),
          ),
        )));
  }
}