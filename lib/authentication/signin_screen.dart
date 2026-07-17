import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/notification_service.dart';
import 'signup_screen.dart';
import '../theme/app_theme.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  State<SignInScreen> createState() => SignInScreenState();
}

class SignInScreenState extends State<SignInScreen>
    with TickerProviderStateMixin {

  final emailController    = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading   = false;
  bool obscurePass = true;
  String? error;

  late AnimationController enterController;
  late AnimationController fruitController;
  late Animation<Offset> topSlide;
  late Animation<Offset> bottomSlide;
  late Animation<double> fadeAnim;
  late Animation<double> fruitFloat;
  late Animation<double> fruitRotate;

  @override
  void initState() {
    super.initState();

    enterController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    topSlide = Tween<Offset>(begin: const Offset(0, -0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: enterController, curve: Curves.easeOut));
    bottomSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: enterController, curve: Curves.easeOut));
    fadeAnim = CurvedAnimation(parent: enterController, curve: Curves.easeIn);
    enterController.forward();

    fruitController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat(reverse: true);
    fruitFloat = Tween<double>(begin: 0, end: -12).animate(
        CurvedAnimation(parent: fruitController, curve: Curves.easeInOut));
    fruitRotate = Tween<double>(begin: -0.04, end: 0.04).animate(
        CurvedAnimation(parent: fruitController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    enterController.dispose();
    fruitController.dispose();
    super.dispose();
  }

  Future<void> signIn() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      setState(() => error = 'Please fill all fields');
      return;
    }
    setState(() { isLoading = true; error = null; });
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      if (!mounted) return;

      await NotificationService.instance.showSignInSuccess();

      Navigator.pushReplacementNamed(context, '/splash');
    } on AuthException catch (e) {
      setState(() => error = e.message);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> skip() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      final plan = await Supabase.instance.client
          .from('user_plans').select().eq('id', session.user.id).maybeSingle();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, plan == null ? '/onboarding' : '/dashboard');
    } else {
      Navigator.pushReplacementNamed(context, '/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Scaffold(
      backgroundColor: c.bg,
      body: FadeTransition(
        opacity: fadeAnim,
        child: Column(children: [
          SlideTransition(
            position: topSlide,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
              child: Container(
                width: double.infinity,
                height: 260,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [c.greenDim, c.surface],
                  ),
                ),
                child: Stack(children: [

                  Positioned(top: 24, left: 30, child: FruitDot(color: c.green.withOpacity(0.4), size: 12)),
                  Positioned(top: 40, right: 40, child: FruitDot(color: c.orange.withOpacity(0.5), size: 16)),
                  Positioned(bottom: 70, left: 50, child: FruitDot(color: c.orange.withOpacity(0.3), size: 10)),
                  Positioned(top: 90, right: 90, child: FruitDot(color: c.green.withOpacity(0.3), size: 8)),

                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: fruitController,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(0, fruitFloat.value),
                        child: Transform.rotate(angle: fruitRotate.value * 0.5, child: child),
                      ),
                      child: Center(
                        child: Text('🥑🍎🍊🍇',
                            style: TextStyle(fontSize: 64, shadows: [
                              Shadow(color: c.bg.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 6)),
                            ])),
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      height: 90,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          colors: [Colors.transparent, c.surface],
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: 18, left: 0, right: 0,
                    child: Column(children: [
                      Text('NutriTrack', style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w800,
                          color: c.green, letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      Text('Track. Eat. Stay Healthy.', style: TextStyle(fontSize: 13, color: c.subtext)),
                    ]),
                  ),

                  Positioned(
                    top: MediaQuery.of(context).padding.top + 12,
                    right: 20,
                    child: GestureDetector(
                      onTap: skip,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: c.surface.withOpacity(0.7),
                          border: Border.all(color: c.divider),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('Skip', style: TextStyle(color: c.subtext, fontSize: 13)),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
              child: SlideTransition(
                position: bottomSlide,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  Text('Welcome back', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: c.white, letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Text('Sign in to continue your journey', style: TextStyle(color: c.subtext, fontSize: 14)),

                  const SizedBox(height: 28),

                  buildField(controller: emailController, hint: 'Email address', icon: Icons.mail_outline_rounded),
                  const SizedBox(height: 14),
                  buildField(controller: passwordController, hint: 'Password', icon: Icons.lock_outline_rounded, isPassword: true),

                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: c.orangeDim,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: c.orange.withOpacity(0.3)),
                      ),
                      child: Row(children: [
                        Icon(Icons.error_outline, color: c.orange, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(error!, style: TextStyle(color: c.orange, fontSize: 13))),
                      ]),
                    ),
                  ],

                  const SizedBox(height: 24),

                  AnimatedSignInButton(
                    c: c,
                    onTap: isLoading ? null : signIn,
                    child: isLoading
                        ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : Text('Sign In', style: TextStyle(color: c.white, fontWeight: FontWeight.w700, fontSize: 16)),
                  ),

                  const SizedBox(height: 20),

                  Row(children: [
                    Expanded(child: Divider(color: c.divider)),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text('or', style: TextStyle(color: c.textHint, fontSize: 13))),
                    Expanded(child: Divider(color: c.divider)),
                  ]),

                  const SizedBox(height: 20),

                  GestureDetector(
                    onTap: () => Navigator.push(context, PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const SignUpScreen(),
                      transitionsBuilder: (_, anim, __, child) => SlideTransition(
                          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                          child: child),
                    )),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(border: Border.all(color: c.divider), borderRadius: BorderRadius.circular(16)),
                      child: Center(child: RichText(text: TextSpan(
                        text: "Don't have an account? ",
                        style: TextStyle(color: c.subtext, fontSize: 14),
                        children: [TextSpan(text: 'Sign Up',
                            style: TextStyle(color: c.green, fontWeight: FontWeight.w700))],
                      ))),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Center(child: GestureDetector(
                    onTap: skip,
                    child: Text('Continue without account →', style: TextStyle(color: c.textHint, fontSize: 13)),
                  )),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    final c = context.c;
    return Container(
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.divider)),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? obscurePass : false,
        style: TextStyle(color: c.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: c.textHint, fontSize: 14),
          prefixIcon: Icon(icon, color: c.subtext, size: 20),
          suffixIcon: isPassword
              ? GestureDetector(
              onTap: () => setState(() => obscurePass = !obscurePass),
              child: Icon(obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: c.subtext, size: 20))
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
      ),
    );
  }
}

// ── fruit dot ─────────────────────────────────────────────────────
class FruitDot extends StatelessWidget {
  final Color color;
  final double size;
  const FruitDot({Key? key, required this.color, required this.size}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }
}

// ── animated sign in button ────────────────────────────────────────
class AnimatedSignInButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final AppColorExtension c;
  const AnimatedSignInButton({Key? key, required this.child, required this.onTap, required this.c}) : super(key: key);

  @override
  State<AnimatedSignInButton> createState() => AnimatedSignInButtonState();
}

class AnimatedSignInButtonState extends State<AnimatedSignInButton>
    with SingleTickerProviderStateMixin {
  late AnimationController ctrl;
  late Animation<double> scale;

  @override
  void initState() {
    super.initState();
    ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    scale = Tween<double>(begin: 1.0, end: 0.96).animate(ctrl);
  }

  @override
  void dispose() { ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => ctrl.forward(),
      onTapUp: (_) { ctrl.reverse(); widget.onTap?.call(); },
      onTapCancel: () => ctrl.reverse(),
      child: ScaleTransition(scale: scale,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: widget.c.green,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: widget.c.green.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Center(child: widget.child),
          )),
    );
  }
}