import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nivora/app/app.dart';

void main() {
  testWidgets('NivoraApp smoke test renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: NivoraApp(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('NIVORA'), findsOneWidget);

    // Advance past splash navigation timer
    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();
  });
}
