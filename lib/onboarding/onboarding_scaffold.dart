import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class OnboardingScaffold extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final Widget child;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;
  final bool showSkip;

  const OnboardingScaffold({
    Key? key,
    required this.currentStep,
    required this.totalSteps,
    required this.child,
    this.onBack,
    this.onSkip,
    this.showSkip = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(children: [
              GestureDetector(
                onTap: onBack ?? () => Navigator.pop(context),
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
              const SizedBox(width: 14),
              Expanded(child: _AnimatedProgressBar(progress: currentStep / totalSteps, c: c)),
              const SizedBox(width: 14),
              // if (showSkip)
              //   // GestureDetector(
              //   //   onTap: onSkip,
              //   //   child: Text('Skip', style: TextStyle(fontSize: 13, color: c.subtext)),
              //   // )
              // else
              //   const SizedBox(width: 38),
            ]),
          ),
          Expanded(child: child),
        ]),
      ),
    );
  }
}

class _AnimatedProgressBar extends StatelessWidget {
  final double progress;
  final AppColorExtension c;
  const _AnimatedProgressBar({required this.progress, required this.c});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: Container(
        height: 5,
        color: c.surfaceAlt,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: progress),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          builder: (context, value, _) => FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value,
            child: Container(
              decoration: BoxDecoration(color: c.green, borderRadius: BorderRadius.circular(100)),
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingContinueButton extends StatefulWidget {
  final VoidCallback? onTap;
  final String label;
  final bool isLoading;

  const OnboardingContinueButton({
    Key? key,
    required this.onTap,
    this.label = 'Continue',
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<OnboardingContinueButton> createState() => _OnboardingContinueButtonState();
}

class _OnboardingContinueButtonState extends State<OnboardingContinueButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) { _ctrl.reverse(); widget.onTap?.call(); },
        onTapCancel: () => _ctrl.reverse(),
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: c.green,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: c.green.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : Text(widget.label, style: const TextStyle(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ),
    );
  }
}