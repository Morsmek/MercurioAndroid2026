import 'package:flutter_test/flutter_test.dart';

import 'package:mercurio_messenger/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MercurioApp());

    // Verify splash screen shows
    expect(find.text('Mercurio'), findsOneWidget);
  });
}
