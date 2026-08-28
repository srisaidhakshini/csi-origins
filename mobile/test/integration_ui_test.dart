import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:financial_agent_app/main.dart';
import 'package:financial_agent_app/models/insight.dart';
import 'package:financial_agent_app/widgets/insight_card.dart';
import 'package:financial_agent_app/widgets/graph_path_view.dart';
import 'package:financial_agent_app/screens/main_navigation_screen.dart';

void main() {
  testWidgets('Full Mobile UI Workflow Test', (WidgetTester tester) async {
    // 1. Launch App & Test Onboarding
    await tester.pumpWidget(const FinancialAgentApp());
    expect(find.text('Financial Onboarding'), findsOneWidget);
    expect(find.text('Gmail Financial Signals'), findsOneWidget);
    expect(find.text('Low (Defensive)'), findsOneWidget);
    expect(find.text('Medium (Balanced)'), findsOneWidget);

    // Scroll to button & Tap "Launch Financial Copilot"
    final launchBtn = find.text('Launch Financial Copilot');
    await tester.ensureVisible(launchBtn);
    await tester.tap(launchBtn);
    await tester.pumpAndSettle();

    // 2. Verify Main Navigation Screen Loaded
    expect(find.byType(MainNavigationScreen), findsOneWidget);
    expect(find.text('Insights'), findsOneWidget);
    expect(find.text('Gate Log'), findsOneWidget);
    expect(find.text('Causal Graph'), findsOneWidget);

    // 3. Test Insight Card with Causal Graph Path
    final sampleCascade = Insight(
      id: 'test-cascade-1',
      userId: 'test-user',
      triggerType: 'cascade',
      severity: 85.0,
      confidence: 90.0,
      urgency: 80.0,
      gateScore: 85.5,
      status: 'surfaced',
      explanation: 'Your ₹35,000 retainer is delayed by 5 days, creating a ₹16,000 deficit for Rent.',
      graphPath: {
        'totalShortfall': 16000,
        'steps': [
          {'from': 'TechCorp Retainer', 'to': 'HDFC Checking Balance', 'relation': 'funds', 'depth': 1},
          {'from': 'HDFC Checking Balance', 'to': 'Apartment Rent', 'relation': 'funds', 'depth': 2},
        ],
        'affectedObligations': [
          {'label': 'Apartment Rent', 'amount': 28000, 'shortfall': 16000}
        ]
      },
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: InsightCard(insight: sampleCascade),
        ),
      ),
    );

    expect(find.text('CASCADE RISK'), findsOneWidget);
    expect(find.text('Gate Score: '), findsOneWidget);
    expect(find.text('85.5'), findsOneWidget);
    expect(find.text('Why? (Inspect Causal Graph Path)'), findsOneWidget);

    // Tap "Why?" to expand graph traversal view
    await tester.tap(find.text('Why? (Inspect Causal Graph Path)'));
    await tester.pumpAndSettle();

    expect(find.byType(GraphPathView), findsOneWidget);
    expect(find.text('Causal Graph Traversal (Depth ≤ 5)'), findsOneWidget);
    expect(find.text('Deficit: -₹16000'), findsOneWidget);
    expect(find.text('TechCorp Retainer'), findsOneWidget);
    expect(find.text('HDFC Checking Balance'), findsAtLeastNWidgets(1));
  });
}
