import 'package:flutter_test/flutter_test.dart';
import 'package:local_chess/main.dart'; // Adjust if package name is different

void main() {
  testWidgets('Chess App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ChessApp());
    expect(find.text('Local Chess'), findsWidgets);
  });
}
