import 'package:flutter_test/flutter_test.dart';
import 'package:android_dex/app.dart';

void main() {
  testWidgets('App renders boot screen', (WidgetTester tester) async {
    await tester.pumpWidget(const AndroidDexApp());
    expect(find.text('Android DEX'), findsOneWidget);
  });
}
