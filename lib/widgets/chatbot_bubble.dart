import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'chatbot_sheet.dart';

class ChatbotBubble extends StatefulWidget {
  const ChatbotBubble({Key? key}) : super(key: key);

  @override
  State<ChatbotBubble> createState() => ChatbotBubbleState();
}

class ChatbotBubbleState extends State<ChatbotBubble>
    with TickerProviderStateMixin {

  late AnimationController bounceController;
  late AnimationController shakeController;
  late AnimationController pulseController;

  late Animation<double> bounceAnimation;
  late Animation<double> shakeAnimation;
  late Animation<double> pulseAnimation;

  bool hasShaken = false;

  @override
  void initState() {
    super.initState();

    // bounce up/down continuously
    bounceController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800));
    bounceAnimation = Tween<double>(begin: 0, end: -10).animate(
        CurvedAnimation(parent: bounceController, curve: Curves.easeInOut));
    bounceController.repeat(reverse: true);

    // shake left/right on init (attention)
    shakeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: -8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: shakeController, curve: Curves.easeInOut));

    // glow pulse
    pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
        CurvedAnimation(parent: pulseController, curve: Curves.easeInOut));
    pulseController.repeat(reverse: true);

    // shake after 1.5s to grab attention
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && !hasShaken) {
        hasShaken = true;
        shakeController.forward();
        // repeat shake every 8 seconds
        Future.delayed(const Duration(seconds: 8), () => _repeatShake());
      }
    });
  }

  void _repeatShake() {
    if (!mounted) return;
    shakeController.reset();
    shakeController.forward();
    Future.delayed(const Duration(seconds: 10), () => _repeatShake());
  }

  @override
  void dispose() {
    bounceController.dispose();
    shakeController.dispose();
    pulseController.dispose();
    super.dispose();
  }

  void openChat(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ChatbotSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return AnimatedBuilder(
      animation: Listenable.merge([bounceAnimation, shakeAnimation]),
      builder: (context, child) => Transform.translate(
        offset: Offset(shakeAnimation.value, bounceAnimation.value),
        child: child,
      ),
      child: GestureDetector(
        onTap: () => openChat(context),
        child: ScaleTransition(
          scale: pulseAnimation,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // glow ring
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: c.green.withOpacity(0.35), blurRadius: 20, spreadRadius: 4),
                  ],
                ),
              ),

              // main bubble
              Container(
                width: 58, height: 58,
                decoration: BoxDecoration(
                  color: c.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
                ),
                child: const Center(
                  child: Text('🤖', style: TextStyle(fontSize: 26)),
                ),
              ),

              // notification dot
              Positioned(
                top: 0, right: 0,
                child: Container(
                  width: 14, height: 14,
                  decoration: BoxDecoration(
                    color: c.orange,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.bg, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}