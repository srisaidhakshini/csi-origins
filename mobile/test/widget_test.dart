import 'package:flutter_test/flutter_test.dart';
import 'package:financial_agent_app/main.dart';

void main() {
  testWidgets('App smoke test loads onboarding screen', (WidgetTester tester) async {
    await tester.pumpWidget(const FinancialAgentApp());
    expect(find.text('Financial Onboarding'), findsOneWidget);
    expect(find.text('Launch Financial Copilot'), findsOneWidget);
  });
}
