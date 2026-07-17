import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../config/app_config.dart';

class ChatMessage {
  final String role;    // 'user' or 'assistant'
  final String content;
  const ChatMessage({required this.role, required this.content});
}

class ChatbotSheet extends StatefulWidget {
  const ChatbotSheet({Key? key}) : super(key: key);

  @override
  State<ChatbotSheet> createState() => ChatbotSheetState();
}

class ChatbotSheetState extends State<ChatbotSheet>
    with SingleTickerProviderStateMixin {

  final inputController = TextEditingController();
  final scrollController = ScrollController();
  final List<ChatMessage> messages = [];
  bool isTyping = false;
  Map<String, dynamic>? userData;
  Map<String, dynamic>? todayLog;
  List<Map<String, dynamic>> todayFoods = [];

  late AnimationController fadeController;
  late Animation<double> fadeAnimation;

  // quick suggestions
  final List<String> suggestions = [
    'How many calories in a banana? 🍌',
    'What is a healthy BMI?',
    'High protein fruits?',
    'How to lose weight with fruits?',
    'What are macros?',
  ];

  @override
  void initState() {
    super.initState();
    fetchUserContext();
    fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    fadeAnimation = CurvedAnimation(parent: fadeController, curve: Curves.easeIn);
    fadeController.forward();

    // welcome message
    messages.add(const ChatMessage(
      role: 'assistant',
      content: 'Hi! I\'m NutriTrack AI 🥗 Ask me anything about nutrition, calories, or your health goals!',
    ));
  }

  @override
  void dispose() {
    inputController.dispose();
    scrollController.dispose();
    fadeController.dispose();
    super.dispose();
  }
  Future<void> fetchUserContext() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final results = await Future.wait([
      Supabase.instance.client.from('user_plans').select().eq('id', user.id).maybeSingle(),
      Supabase.instance.client.from('daily_logs').select().eq('user_id', user.id).eq('log_date', today).maybeSingle(),
      Supabase.instance.client.from('food_logs').select().eq('user_id', user.id).eq('log_date', today).order('logged_at', ascending: false),
    ]);
    if (mounted) {
      setState(() {
        userData   = results[0] as Map<String, dynamic>?;
        todayLog   = results[1] as Map<String, dynamic>?;
        todayFoods = (results[2] as List).map((f) => Map<String, dynamic>.from(f)).toList();
      });
    }
  }String buildSystemPrompt() {
    final name     = userData?['display_name'] ?? 'User';
    final age      = userData?['date_of_birth'] != null
        ? DateTime.now().year - DateTime.parse(userData!['date_of_birth']).year
        : 'unknown';
    final weight   = userData?['weight_kg'] ?? 'unknown';
    final height   = userData?['height_cm'] ?? 'unknown';
    final goal     = userData?['goal'] ?? 'unknown';
    final diet     = userData?['diet_type'] ?? 'unknown';
    final calories = userData?['daily_calories']?.round() ?? 'unknown';
    final protein  = userData?['protein_g']?.round() ?? 'unknown';
    final carbs    = userData?['carbs_g']?.round() ?? 'unknown';
    final fat      = userData?['fat_g']?.round() ?? 'unknown';

    final consumed = todayLog?['calories_consumed']?.round() ?? 0;
    final remaining = userData?['daily_calories'] != null
        ? (userData!['daily_calories'] - (todayLog?['calories_consumed'] ?? 0)).round()
        : 'unknown';

    final foodList = todayFoods.isEmpty
        ? 'Nothing logged yet today'
        : todayFoods.map((f) => '${f['fruit_name']} (${f['calories']?.round()} kcal)').join(', ');

    return '''
You are NutriTrack AI, a personal nutrition assistant with access to this user's real data.

USER PROFILE:
- Name: $name
- Age: $age years
- Weight: ${weight}kg
- Height: ${height}cm
- Goal: $goal weight
- Diet: $diet
- Daily calorie goal: $calories kcal
- Daily protein goal: ${protein}g
- Daily carbs goal: ${carbs}g
- Daily fat goal: ${fat}g

TODAY'S PROGRESS:
- Calories consumed: $consumed kcal
- Calories remaining: $remaining kcal
- Protein consumed: ${todayLog?['protein_consumed']?.round() ?? 0}g
- Carbs consumed: ${todayLog?['carbs_consumed']?.round() ?? 0}g
- Fat consumed: ${todayLog?['fat_consumed']?.round() ?? 0}g
- Foods eaten today: $foodList

STRICT RULES:
- Use this data to answer personal questions accurately.
- ONLY answer about nutrition, health, fitness, and NutriTrack app.
- Anything else → "I can only help with nutrition and health topics! 🥗"
- Keep responses short (2-3 sentences).
- Be friendly and motivating.
- Never give medical diagnoses.
''';
  }


  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || isTyping) return;
    inputController.clear();

    setState(() {
      messages.add(ChatMessage(role: 'user', content: text.trim()));
      isTyping = true;
    });
    scrollToBottom();

    try {
      // build message history for context
      final history = messages
          .map((m) => {'role': m.role, 'content': m.content})
          .toList();

      final response = await http.post(
        Uri.parse(AppConfig.groqUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppConfig.groqApiKey}',
        },
        body: jsonEncode({
          'model': AppConfig.groqModel,
          'max_tokens': 200,
          'temperature': 0.7,
          'messages': [
            {'role': 'system', 'content': buildSystemPrompt()},
            ...history,
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['choices'][0]['message']['content'] as String;
        if (mounted) {
          setState(() {
            messages.add(ChatMessage(role: 'assistant', content: reply.trim()));
            isTyping = false;
          });
          scrollToBottom();
        }
      } else {
        debugPrint('GROQ STATUS: ${response.statusCode}');
        debugPrint('GROQ BODY: ${response.body}');
        throw Exception('API error ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('GROQ ERROR: $e');
      if (mounted) {
        setState(() {
          messages.add(ChatMessage(
            role: 'assistant',
            content: 'Error: $e',  // show real error
          ));
          isTyping = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return FadeTransition(
      opacity: fadeAnimation,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(children: [

          // handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(color: c.divider, borderRadius: BorderRadius.circular(2)),
          ),

          // header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: c.greenDim, shape: BoxShape.circle),
                child: const Center(child: Text('🤖', style: TextStyle(fontSize: 20))),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('NutriTrack AI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.white)),
                Row(children: [
                  Container(width: 7, height: 7, decoration: BoxDecoration(color: c.green, shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  Text('Online', style: TextStyle(fontSize: 11, color: c.green, fontWeight: FontWeight.w500)),
                ]),
              ]),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(color: c.surfaceAlt, shape: BoxShape.circle),
                  child: Icon(Icons.close_rounded, color: c.subtext, size: 18),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 12),
          Divider(color: c.divider, height: 1),

          // messages
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              itemCount: messages.length + (isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == messages.length && isTyping) {
                  return TypingIndicator(c: c);
                }
                final msg = messages[index];
                return ChatBubble(message: msg, c: c);
              },
            ),
          ),

          // suggestions (show when no user message yet)
          if (messages.length == 1)
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: suggestions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) => GestureDetector(
                  onTap: () => sendMessage(suggestions[i]),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: c.greenDim,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: c.green.withOpacity(0.3)),
                    ),
                    child: Text(suggestions[i],
                        style: TextStyle(fontSize: 12, color: c.green, fontWeight: FontWeight.w500)),
                  ),
                ),
              ),
            ),

          if (messages.length == 1) const SizedBox(height: 10),

          // input row
          Container(
            padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).viewInsets.bottom + 16),
            decoration: BoxDecoration(
              color: c.surface,
              border: Border(top: BorderSide(color: c.divider)),
            ),
            child: Row(children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: c.surfaceAlt,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: c.divider),
                  ),
                  child: TextField(
                    controller: inputController,
                    style: TextStyle(fontSize: 14, color: c.white),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: sendMessage,
                    decoration: InputDecoration(
                      hintText: 'Ask about nutrition...',
                      hintStyle: TextStyle(fontSize: 14, color: c.subtext),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => sendMessage(inputController.text),
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: isTyping ? c.divider : c.green,
                    shape: BoxShape.circle,
                    boxShadow: isTyping ? [] : [BoxShadow(color: c.green.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 3))],
                  ),
                  child: isTyping
                      ? Center(child: SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(color: c.subtext, strokeWidth: 2)))
                      : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── chat bubble ────────────────────────────────────────────────────
class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final AppColorExtension c;
  const ChatBubble({Key? key, required this.message, required this.c}) : super(key: key);

  bool get isUser => message.role == 'user';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(color: c.greenDim, shape: BoxShape.circle),
              child: const Center(child: Text('🤖', style: TextStyle(fontSize: 14))),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? c.green : c.surfaceAlt,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: Text(message.content,
                  style: TextStyle(fontSize: 14, color: isUser ? Colors.white : c.white, height: 1.4)),
            ),
          ),
          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ── typing indicator ───────────────────────────────────────────────
class TypingIndicator extends StatefulWidget {
  final AppColorExtension c;
  const TypingIndicator({Key? key, required this.c}) : super(key: key);
  @override
  State<TypingIndicator> createState() => TypingIndicatorState();
}

class TypingIndicatorState extends State<TypingIndicator> with TickerProviderStateMixin {
  late List<AnimationController> dotControllers;
  late List<Animation<double>> dotAnims;

  @override
  void initState() {
    super.initState();
    dotControllers = List.generate(3, (i) => AnimationController(vsync: this, duration: const Duration(milliseconds: 400)));
    dotAnims = dotControllers.map((c) => Tween<double>(begin: 0, end: -6).animate(CurvedAnimation(parent: c, curve: Curves.easeInOut))).toList();
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) dotControllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in dotControllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Container(width: 30, height: 30,
            decoration: BoxDecoration(color: widget.c.greenDim, shape: BoxShape.circle),
            child: const Center(child: Text('🤖', style: TextStyle(fontSize: 14)))),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: widget.c.surfaceAlt, borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomRight: Radius.circular(18), bottomLeft: Radius.circular(4))),
          child: Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (i) =>
              AnimatedBuilder(
                animation: dotAnims[i],
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, dotAnims[i].value),
                  child: Container(
                    margin: EdgeInsets.only(left: i > 0 ? 4 : 0),
                    width: 7, height: 7,
                    decoration: BoxDecoration(color: widget.c.subtext, shape: BoxShape.circle),
                  ),
                ),
              ))),
        ),
      ]),
    );
  }
}