import 'package:flutter_test/flutter_test.dart';
import 'package:waldo_guard_app/main.dart';

void main() {
  testWidgets('WaldoGuardApp loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const WaldoGuardApp(isLoggedIn: false));
    expect(find.text('Sign in'), findsWidgets);
  });
}
