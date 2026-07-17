import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => SignUpScreenState();
}

class SignUpScreenState extends State<SignUpScreen>
    with TickerProviderStateMixin {

  final emailController    = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController  = TextEditingController();
  bool isLoading     = false;
  bool obscurePass   = true;
  bool obscureConfirm = true;
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
    confirmController.dispose();
    enterController.dispose();
    fruitController.dispose();
    super.dispose();
  }

  Future<void> signUp() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty || confirmController.text.isEmpty) {
      setState(() => error = 'Please fill all fields');
      return;
    }
    if (passwordController.text != confirmController.text) {
      setState(() => error = 'Passwords do not match');
      return;
    }
    if (passwordController.text.length < 6) {
      setState(() => error = 'Password must be at least 6 characters');
      return;
    }
    setState(() { isLoading = true; error = null; });
    try {
      await Supabase.instance.client.auth.signUp(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/onboarding');
    } on AuthException catch (e) {
      setState(() => error = e.message);
    } finally {
      if (mounted) setState(() => isLoading = false);
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

          // ── top fruit section ──────────────────────────────────
          SlideTransition(
            position: topSlide,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
                border: Border.all(color: c.divider),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(children: [
                  const SizedBox(height: 16),

                  // back button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                            color: c.surfaceAlt,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: c.divider),
                          ),
                          child: Icon(Icons.arrow_back_ios_new_rounded, color: c.white, size: 16),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // floating fruit circle — smaller for signup
                  AnimatedBuilder(
                    animation: fruitController,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(0, fruitFloat.value),
                      child: Transform.rotate(angle: fruitRotate.value, child: child),
                    ),
                    child: Container(
                      width: 110, height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c.greenDim,
                        border: Border.all(color: c.green.withOpacity(0.3), width: 2),
                        boxShadow: [BoxShadow(color: c.green.withOpacity(0.2), blurRadius: 20, spreadRadius: 3)],
                      ),
                      child: Stack(children: [
                        Positioned(top: 10, left: 16, child: Container(width: 8, height: 8, decoration: BoxDecoration(color: c.green, shape: BoxShape.circle))),
                        Positioned(top: 8, right: 20, child: Container(width: 10, height: 10, decoration: BoxDecoration(color: c.orange, shape: BoxShape.circle))),
                        Positioned(bottom: 14, left: 14, child: Container(width: 8, height: 8, decoration: BoxDecoration(color: c.green.withOpacity(0.5), shape: BoxShape.circle))),
                        const Center(child: Text('🌱🍎\n🍊', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, height: 1.3))),
                      ]),
                    ),
                  ),

                  const SizedBox(height: 12),
                  Text('NutriTrack', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c.green)),
                  const SizedBox(height: 2),
                  Text('Start your journey today', style: TextStyle(fontSize: 12, color: c.subtext)),
                ]),
              ),
            ),
          ),

          // ── form section ───────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
              child: SlideTransition(
                position: bottomSlide,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  Text('Create account', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: c.white, letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Text('Fill in your details to get started', style: TextStyle(color: c.subtext, fontSize: 14)),

                  const SizedBox(height: 24),

                  buildField(controller: emailController, hint: 'Email address', icon: Icons.mail_outline_rounded),
                  const SizedBox(height: 14),
                  buildField(controller: passwordController, hint: 'Password', icon: Icons.lock_outline_rounded,
                      isPassword: true, obscure: obscurePass, onToggle: () => setState(() => obscurePass = !obscurePass)),
                  const SizedBox(height: 14),
                  buildField(controller: confirmController, hint: 'Confirm password', icon: Icons.lock_outline_rounded,
                      isPassword: true, obscure: obscureConfirm, onToggle: () => setState(() => obscureConfirm = !obscureConfirm)),

                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: c.orangeDim, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.orange.withOpacity(0.3))),
                      child: Row(children: [
                        Icon(Icons.error_outline, color: c.orange, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(error!, style: TextStyle(color: c.orange, fontSize: 13))),
                      ]),
                    ),
                  ],

                  const SizedBox(height: 24),

                  SignUpButton(
                    c: c,
                    onTap: isLoading ? null : signUp,
                    child: isLoading
                        ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : Text('Create Account', style: TextStyle(color: c.white, fontWeight: FontWeight.w700, fontSize: 16)),
                  ),

                  const SizedBox(height: 16),

                  Center(child: Text(
                    'By signing up you agree to our Terms & Privacy Policy',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: c.textHint, fontSize: 12),
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
    bool obscure = false,
    VoidCallback? onToggle,
  }) {
    final c = context.c;
    return Container(
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.divider)),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? obscure : false,
        style: TextStyle(color: c.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: c.textHint, fontSize: 14),
          prefixIcon: Icon(icon, color: c.subtext, size: 20),
          suffixIcon: isPassword
              ? GestureDetector(onTap: onToggle,
              child: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: c.subtext, size: 20))
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
      ),
    );
  }
}

// ── sign up button ────────────────────────────────────────────────
class SignUpButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final AppColorExtension c;
  const SignUpButton({Key? key, required this.child, required this.onTap, required this.c}) : super(key: key);

  @override
  State<SignUpButton> createState() => SignUpButtonState();
}

class SignUpButtonState extends State<SignUpButton> with SingleTickerProviderStateMixin {
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