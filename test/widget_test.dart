import 'package:flutter_test/flutter_test.dart';
import 'package:simk/app.dart';

void main() {
  testWidgets('SIMK app loads login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const SimkApp());
    await tester.pumpAndSettle();

    expect(find.text('Masuk ke akun Anda'), findsOneWidget);
  });
}
