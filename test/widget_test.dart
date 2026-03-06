import 'package:flutter_test/flutter_test.dart';

import 'package:scope_it/main.dart';

void main() {
  testWidgets('ScopeIt app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ScopeItApp());
    await tester.pump();
  });
}
