import 'package:flutter_test/flutter_test.dart';

import 'package:proyecto_asistencia/main.dart';

void main() {
  testWidgets('GeoCheck app loads the auth screen', (WidgetTester tester) async {
    await tester.pumpWidget(const GeoCheckApp());

    expect(find.text('GeoCheck Campus'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsOneWidget);
  });
}
