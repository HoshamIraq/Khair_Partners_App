import 'package:flutter_test/flutter_test.dart';
import 'package:khair_partners_app/data/providers/app_state.dart';
import 'package:khair_partners_app/main.dart';

void main() {
  testWidgets('KhairPartnersApp basic widget smoke test', (WidgetTester tester) async {
    final appState = AppState();
    await tester.pumpWidget(KhairPartnersApp(appState: appState));
    expect(find.byType(KhairPartnersApp), findsOneWidget);
  });
}
