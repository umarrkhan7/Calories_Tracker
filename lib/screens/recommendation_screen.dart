import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

/// Simple data model for one fruit suggestion.
class FruitTip {
  final String emoji;
  final String name;
  final String reason;
  const FruitTip({required this.emoji, required this.name, required this.reason});
}

/// Everything shown on the recommendation screen for a given BMI category.
class BmiRecommendation {
  final String title;
  final String summary;
  final Color color;
  final List<FruitTip> fruits;
  final List<String> avoid;
  const BmiRecommendation({
    required this.title,
    required this.summary,
    required this.color,
    required this.fruits,
    required this.avoid,
  });
}

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({Key? key}) : super(key: key);

  @override
  State<RecommendationScreen> createState() => RecommendationScreenState();
}

class RecommendationScreenState extends State<RecommendationScreen> {
  Map<String, dynamic>? userPlan;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // Same pattern as ProgressScreenState.loadData() in progress_screen.dart:
  // pull height_cm / weight_kg (and age, if you store it) from `user_plans`.
  Future<void> loadData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => loading = false);
      return;
    }
    try {
      final plan = await Supabase.instance.client
          .from('user_plans')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      if (mounted) {
        setState(() {
          userPlan = plan;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => loading = false);
    }
  }

  double get heightCm => (userPlan?['height_cm'] as num?)?.toDouble() ?? 170;
  double get weightKg => (userPlan?['weight_kg'] as num?)?.toDouble() ?? 70;

  // Optional — only used to fine-tune wording, not required for the logic to work.
  int? get age => (userPlan?['age'] as num?)?.toInt();

  double get bmi {
    final h = heightCm / 100;
    if (h <= 0) return 0;
    return weightKg / (h * h);
  }

  String get bmiCategory {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Healthy';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Color get bmiColor {
    if (bmi < 18.5) return const Color(0xFF3B82F6);
    if (bmi < 25) return const Color(0xFF27AE60);
    if (bmi < 30) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  // ---- Hardcoded fruit recommendations, keyed off BMI category ----
  BmiRecommendation get recommendation {
    switch (bmiCategory) {
      case 'Underweight':
        return BmiRecommendation(
          title: 'Calorie & Fat-Enriched Fruits',
          summary: age != null && age! < 25
              ? 'Your BMI is on the lower side. At your age, your body benefits from '
              'extra energy-dense fruit to support healthy weight gain and growth.'
              : 'Your BMI is on the lower side. Adding calorie and fat-rich fruit to '
              'your day is an easy, natural way to increase your energy intake.',
          color: const Color(0xFF3B82F6),
          fruits: const [
            FruitTip(emoji: '🥑', name: 'Avocado', reason: 'Rich in healthy fats — great blended into smoothies'),
            FruitTip(emoji: '🍌', name: 'Banana', reason: 'Dense in natural sugars and quick energy'),
            FruitTip(emoji: '🥭', name: 'Mango', reason: 'High in calories and natural sweetness'),
            FruitTip(emoji: '🌰', name: 'Dates', reason: 'Very calorie-dense, easy to snack on between meals'),
            FruitTip(emoji: '🥥', name: 'Coconut (fresh or dried)', reason: 'High in healthy saturated fats'),
            FruitTip(emoji: '🍇', name: 'Dried fruit (raisins, apricots)', reason: 'Concentrated calories in small portions'),
          ],
          avoid: const [
            'Very watery, low-calorie fruit as your only snack (e.g. watermelon alone)',
            'Skipping fruit with meals — pair it with nuts or yoghurt for extra calories',
          ],
        );
      case 'Healthy':
        return BmiRecommendation(
          title: 'Balanced Everyday Fruits',
          summary: 'Your BMI is in a healthy range. The goal here is variety and balance '
              'rather than pushing calories up or down.',
          color: const Color(0xFF27AE60),
          fruits: const [
            FruitTip(emoji: '🍎', name: 'Apple', reason: 'Good fibre, keeps you satisfied between meals'),
            FruitTip(emoji: '🫐', name: 'Berries (mixed)', reason: 'High in antioxidants, low in calories'),
            FruitTip(emoji: '🍊', name: 'Orange', reason: 'Vitamin C and hydration'),
            FruitTip(emoji: '🍌', name: 'Banana', reason: 'A quick, balanced pre/post-workout snack'),
            FruitTip(emoji: '🍍', name: 'Pineapple', reason: 'Great source of natural digestive enzymes'),
          ],
          avoid: const [
            'Relying on fruit juice instead of whole fruit — you lose the fibre',
          ],
        );
      case 'Overweight':
        return BmiRecommendation(
          title: 'Low-Calorie, High-Fibre Fruits',
          summary: 'Your BMI is a little above the healthy range. Swapping in high-fibre, '
              'lower-calorie fruit can help you feel full for longer while keeping '
              'overall calories down.',
          color: const Color(0xFFF59E0B),
          fruits: const [
            FruitTip(emoji: '🍏', name: 'Green apple', reason: 'High fibre, very filling for the calories'),
            FruitTip(emoji: '🍓', name: 'Strawberries', reason: 'Low sugar, high volume — great for snacking'),
            FruitTip(emoji: '🍉', name: 'Watermelon', reason: 'Mostly water, very low calorie density'),
            FruitTip(emoji: '🍈', name: 'Papaya', reason: 'Aids digestion, low in calories'),
            FruitTip(emoji: '🍊', name: 'Grapefruit', reason: 'Low glycaemic load, keeps you fuller for longer'),
          ],
          avoid: const [
            'High-calorie dried fruit and fruit in syrup',
            'Large portions of very sweet tropical fruit (mango, grapes) in one sitting',
          ],
        );
      default: // Obese
        return BmiRecommendation(
          title: 'Low-Calorie, Nutrient-Dense Fruits',
          summary: 'Your BMI suggests focusing on fruit that\'s filling but low in '
              'calories. Pair this with your overall nutrition plan, and consider '
              'checking in with a doctor or dietitian for a plan tailored to you.',
          color: const Color(0xFFEF4444),
          fruits: const [
            FruitTip(emoji: '🍉', name: 'Watermelon', reason: 'Very low calorie density, high water content'),
            FruitTip(emoji: '🍓', name: 'Strawberries', reason: 'Low sugar, high fibre'),
            FruitTip(emoji: '🍈', name: 'Papaya', reason: 'Supports digestion, low in calories'),
            FruitTip(emoji: '🍏', name: 'Green apple', reason: 'High fibre keeps hunger in check'),
            FruitTip(emoji: '🥝', name: 'Kiwi', reason: 'Nutrient-dense without many calories'),
          ],
          avoid: const [
            'Dried fruit, fruit juice, and fruit in syrup — all much higher in calories than whole fresh fruit',
            'Using fruit to replace vegetables entirely — keep both in the mix',
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final rec = recommendation;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: loading
            ? Center(child: CircularProgressIndicator(color: c.green))
            : SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.arrow_back_ios_new_rounded, color: c.white, size: 20),
                ),
                const SizedBox(width: 16),
                Text('Your Recommendation', style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800,
                    color: c.white, letterSpacing: -0.6)),
              ]),
            ),

            const SizedBox(height: 16),

            // BMI summary card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: c.divider),
                ),
                child: Row(children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Your BMI', style: TextStyle(fontSize: 12, color: c.subtext)),
                    const SizedBox(height: 4),
                    Text(bmi.toStringAsFixed(1), style: TextStyle(
                        fontSize: 28, fontWeight: FontWeight.w800, color: c.white)),
                  ]),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: bmiColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(bmiCategory, style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700, color: bmiColor)),
                  ),
                ]),
              ),
            ),

            const SizedBox(height: 16),

            // Recommendation card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: c.divider),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: rec.color.withOpacity(0.15), shape: BoxShape.circle),
                      child: Icon(Icons.eco_rounded, color: rec.color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(rec.title, style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700, color: c.white))),
                  ]),
                  const SizedBox(height: 12),
                  Text(rec.summary, style: TextStyle(fontSize: 13, color: c.subtext, height: 1.5)),

                  const SizedBox(height: 18),
                  Text('Recommended fruits', style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: c.white)),
                  const SizedBox(height: 10),

                  ...rec.fruits.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(f.emoji, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(f.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.white)),
                        const SizedBox(height: 2),
                        Text(f.reason, style: TextStyle(fontSize: 12, color: c.subtext, height: 1.4)),
                      ])),
                    ]),
                  )),

                  const SizedBox(height: 6),
                  Text('Go easy on', style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: c.white)),
                  const SizedBox(height: 10),
                  ...rec.avoid.map((a) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(Icons.remove_circle_outline_rounded, size: 16, color: c.subtext),
                      const SizedBox(width: 8),
                      Expanded(child: Text(a, style: TextStyle(fontSize: 12, color: c.subtext, height: 1.4))),
                    ]),
                  )),
                ]),
              ),
            ),

            const SizedBox(height: 100),
          ]),
        ),
      ),
    );
  }
}