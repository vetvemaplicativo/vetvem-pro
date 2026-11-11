import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vetvem_pro/app/modules/calc/convert_page.dart';
import 'package:vetvem_pro/app/modules/calc/dilution_page.dart';
import 'package:vetvem_pro/app/modules/calc/dose_page.dart';
import 'package:vetvem_pro/app/modules/calc/volume_page.dart';

Future<void> pump(WidgetTester t, Widget w) async {
  t.view.physicalSize = const Size(800, 2000);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(home: w));
}

Future<void> tapText(WidgetTester t, String s) async {
  final b = find.widgetWithText(ElevatedButton, s);
  final target = b.evaluate().isNotEmpty ? b : find.widgetWithText(OutlinedButton, s);
  await t.ensureVisible(target);
  await t.tap(target);
  await t.pump();
}

void main() {
  testWidgets('Dose: campos vazios mostram mensagem e nenhum resultado', (t) async {
    await pump(t, const DosePage());
    await tapText(t, 'Calcular');
    expect(find.textContaining('Atenção'), findsOneWidget);
    expect(find.byKey(const Key('calc_result')), findsNothing);
  });

  testWidgets('Dose: calcula quantidade e volume, depois limpa', (t) async {
    await pump(t, const DosePage());
    final f = find.byType(TextField);
    await t.enterText(f.at(0), '10');
    await t.enterText(f.at(1), '5');
    await t.enterText(f.at(2), '25');
    await tapText(t, 'Calcular');
    expect(find.byKey(const Key('calc_result')), findsOneWidget);
    expect(tester(t), '2 mL');
    expect(find.textContaining('Confira os parâmetros'), findsOneWidget);
    await tapText(t, 'Limpar');
    expect(find.byKey(const Key('calc_result')), findsNothing);
  });

  testWidgets('Dose: entrada inválida remove resultado anterior', (t) async {
    await pump(t, const DosePage());
    final f = find.byType(TextField);
    await t.enterText(f.at(0), '10');
    await t.enterText(f.at(1), '5');
    await tapText(t, 'Calcular');
    expect(find.byKey(const Key('calc_result')), findsOneWidget);
    await t.enterText(f.at(0), '0');
    await tapText(t, 'Calcular');
    expect(find.byKey(const Key('calc_result')), findsNothing);
    expect(find.textContaining('Atenção'), findsOneWidget);
  });

  testWidgets('Dose em modo prontuário mostra "Usar no prontuário"', (t) async {
    await pump(t, const DosePage(pickMode: true));
    expect(find.text('Usar no prontuário'), findsNothing);
    final f = find.byType(TextField);
    await t.enterText(f.at(0), '10');
    await t.enterText(f.at(1), '5');
    await tapText(t, 'Calcular');
    expect(find.text('Usar no prontuário'), findsOneWidget);
  });

  testWidgets('Volume: calcula 50 mg a 25 mg/mL = 2 mL', (t) async {
    await pump(t, const VolumePage());
    final f = find.byType(TextField);
    await t.enterText(f.at(0), '50');
    await t.enterText(f.at(1), '25');
    await tapText(t, 'Calcular');
    expect(tester(t), '2 mL');
  });

  testWidgets('Conversão: 1500 mg para g', (t) async {
    await pump(t, const ConvertPage());
    await t.enterText(find.byType(TextField).first, '1500');
    await tapText(t, 'Converter');
    expect(find.byKey(const Key('calc_result')), findsOneWidget);
    expect(tester(t), contains('1,5'));
  });

  testWidgets('Diluição: C1·V1 = C2·V2 calcula V2', (t) async {
    await pump(t, const DilutionPage());
    final f = find.byType(TextField);
    await t.enterText(f.at(0), '10'); // C1
    await t.enterText(f.at(1), '2'); // V1
    await t.enterText(f.at(2), '5'); // C2
    await tapText(t, 'Calcular');
    expect(find.byKey(const Key('calc_result')), findsOneWidget);
    expect(tester(t), '4 mL');
  });
}

String tester(WidgetTester t) => (t.widget(find.byKey(const Key('calc_result'))) as Text).data!;
