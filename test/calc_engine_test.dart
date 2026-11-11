import 'package:flutter_test/flutter_test.dart';
import 'package:vetvem_pro/app/modules/calc/calc_engine.dart';

void expectCalcError(void Function() f, [Pattern? message]) {
  try {
    f();
  } on CalcException catch (e) {
    if (message != null) expect(e.message, matches(message));
    return;
  }
  fail('esperava CalcException');
}

void main() {
  group('parseInput', () {
    test('aceita vírgula e ponto', () {
      expect(parseInput('2,5', 'peso'), 2.5);
      expect(parseInput('2.5', 'peso'), 2.5);
      expect(parseInput(' 10 ', 'peso'), 10);
      expect(parseInput('0,001', 'peso'), 0.001);
    });
    test('recusa vazio, texto, negativo, zero, científico e separador de milhar', () {
      expectCalcError(() => parseInput('', 'o peso'), 'Informe o peso.');
      expectCalcError(() => parseInput('   ', 'o peso'));
      expectCalcError(() => parseInput('abc', 'o peso'));
      expectCalcError(() => parseInput('-5', 'o peso'));
      expectCalcError(() => parseInput('0', 'o peso'), 'o peso precisa ser maior que zero.');
      expectCalcError(() => parseInput('0,0', 'o peso'));
      expectCalcError(() => parseInput('1e3', 'o peso'));
      expectCalcError(() => parseInput('1.000,5', 'o peso'));
      expectCalcError(() => parseInput('NaN', 'o peso'));
      expectCalcError(() => parseInput('Infinity', 'o peso'));
      expectCalcError(() => parseInput('2,5,1', 'o peso'));
    });
    test('limites técnicos de entrada', () {
      expect(parseInput('10000000', 'x'), 10000000);
      expectCalcError(() => parseInput('10000001', 'x'), r'não é limite clínico');
      expect(parseInput('0,123456', 'x'), 0.123456);
      expectCalcError(() => parseInput('0,1234567', 'x'), 'no máximo 6 casas');
    });
  });

  group('dose por peso (mg)', () {
    test('10 kg × 5 mg/kg = 50 mg', () {
      expect(totalDoseMg(weight: 10, weightUnit: kg, dose: 5, doseUnit: doseMgKg), 50);
    });
    test('peso em gramas é normalizado', () {
      expect(totalDoseMg(weight: 500, weightUnit: gWeight, dose: 10, doseUnit: doseMgKg), 5);
      expect(totalDoseMg(weight: 2500, weightUnit: gWeight, dose: 2, doseUnit: doseMgKg), 5);
    });
    test('dose em µg/kg e g/kg', () {
      expect(totalDoseMg(weight: 10, weightUnit: kg, dose: 5000, doseUnit: doseUgKg), 50);
      expect(totalDoseMg(weight: 10, weightUnit: kg, dose: 0.005, doseUnit: doseGKg), 50);
    });
    test('decimais não geram resíduo de ponto flutuante', () {
      expect(totalDoseMg(weight: 0.1, weightUnit: kg, dose: 3, doseUnit: doseMgKg), 0.3);
      expect(totalDoseMg(weight: 3.3, weightUnit: kg, dose: 0.1, doseUnit: doseMgKg), 0.33);
      expect(formatNumber(0.1 + 0.2), '0,3');
    });
    test('valores muito pequenos e grandes (dentro dos limites)', () {
      expect(totalDoseMg(weight: 0.001, weightUnit: kg, dose: 0.001, doseUnit: doseMgKg), 0.000001);
      expect(totalDoseMg(weight: 10000000, weightUnit: kg, dose: 10000000, doseUnit: doseMgKg), 1e14);
    });
    test('unidades incompatíveis', () {
      expectCalcError(() => totalDoseMg(weight: 10, weightUnit: massMg, dose: 5, doseUnit: doseMgKg), 'unidades são compatíveis');
      expectCalcError(() => totalDoseMg(weight: 10, weightUnit: kg, dose: 5, doseUnit: concMgMl), 'unidades são compatíveis');
    });
  });

  group('volume por concentração (mL)', () {
    test('50 mg ÷ 25 mg/mL = 2 mL', () {
      expect(volumeMl(amount: 50, amountUnit: massMg, concentration: 25, concUnit: concMgMl), 2);
    });
    test('% é peso/volume: 1 % = 10 mg/mL', () {
      expect(volumeMl(amount: 50, amountUnit: massMg, concentration: 1, concUnit: concPercent), 5);
      expect(volumeMl(amount: 50, amountUnit: massMg, concentration: 2, concUnit: concPercent), 2.5);
      expect(convertValue(1, concPercent, concMgMl), 10);
      expect(convertValue(10, concMgMl, concPercent), 1);
    });
    test('quantidade em g e µg, concentração em µg/mL e g/L', () {
      expect(volumeMl(amount: 0.05, amountUnit: massG, concentration: 25, concUnit: concMgMl), 2);
      expect(volumeMl(amount: 500, amountUnit: massUg, concentration: 250, concUnit: concUgMl), 2);
      expect(volumeMl(amount: 50, amountUnit: massMg, concentration: 25, concUnit: concGL), 2);
      expect(volumeMl(amount: 50, amountUnit: massMg, concentration: 0.025, concUnit: concGMl), 2);
    });
    test('cadeia peso × dose ÷ concentração', () {
      final mg = totalDoseMg(weight: 10, weightUnit: kg, dose: 5, doseUnit: doseMgKg);
      expect(volumeMl(amount: mg, amountUnit: massMg, concentration: 25, concUnit: concMgMl), 2);
      final mg2 = totalDoseMg(weight: 4.2, weightUnit: kg, dose: 0.5, doseUnit: doseMgKg);
      expect(mg2, 2.1);
      expect(volumeMl(amount: mg2, amountUnit: massMg, concentration: 10, concUnit: concMgMl), 0.21);
    });
    test('concentração zero e unidades incompatíveis', () {
      expectCalcError(() => volumeMl(amount: 50, amountUnit: massMg, concentration: 0, concUnit: concMgMl), 'maior que zero');
      expectCalcError(() => volumeMl(amount: 50, amountUnit: volMl, concentration: 25, concUnit: concMgMl), 'compatíveis');
      expectCalcError(() => volumeMl(amount: 50, amountUnit: massMg, concentration: 25, concUnit: doseMgKg), 'compatíveis');
    });
  });

  group('conversões', () {
    test('massa', () {
      expect(convertValue(1, massKg, massG), 1000);
      expect(convertValue(1, massG, massMg), 1000);
      expect(convertValue(1, massMg, massUg), 1000);
      expect(convertValue(1000, massUg, massMg), 1);
      expect(convertValue(1500, massMg, massG), 1.5);
    });
    test('volume', () {
      expect(convertValue(1, volL, volMl), 1000);
      expect(convertValue(250, volMl, volL), 0.25);
    });
    test('peso do paciente', () {
      expect(convertValue(2.5, kg, gWeight), 2500);
      expect(convertValue(500, gWeight, kg), 0.5);
    });
    test('ida e volta preserva o valor', () {
      for (final v in [0.001, 0.3, 1.2345, 99.99, 12345.678]) {
        expect(convertValue(convertValue(v, massMg, massUg), massUg, massMg), v);
      }
    });
    test('dimensões diferentes são recusadas', () {
      expectCalcError(() => convertValue(1, massMg, volMl), 'compatíveis');
      expectCalcError(() => convertValue(1, kg, massKg), 'compatíveis'); // peso ≠ massa de fármaco
    });
  });

  group('diluição C1·V1 = C2·V2', () {
    test('resolve cada incógnita', () {
      // 100 mg/mL × 1 mL = 10 mg/mL × 10 mL
      expect(solveDilution(unknown: DilutionUnknown.v2, c1: 100, c1Unit: concMgMl, v1: 1, v1Unit: volMl, c2: 10, c2Unit: concMgMl, resultUnit: volMl), 10);
      expect(solveDilution(unknown: DilutionUnknown.v1, c1: 100, c1Unit: concMgMl, c2: 10, c2Unit: concMgMl, v2: 10, v2Unit: volMl, resultUnit: volMl), 1);
      expect(solveDilution(unknown: DilutionUnknown.c2, c1: 100, c1Unit: concMgMl, v1: 1, v1Unit: volMl, v2: 10, v2Unit: volMl, resultUnit: concMgMl), 10);
      expect(solveDilution(unknown: DilutionUnknown.c1, v1: 1, v1Unit: volMl, c2: 10, c2Unit: concMgMl, v2: 10, v2Unit: volMl, resultUnit: concMgMl), 100);
    });
    test('unidades diferentes entre si e resultado em outra unidade', () {
      // 10 % (=100 mg/mL) × 1 mL = 10 mg/mL × V2  -> V2 = 10 mL = 0,01 L
      expect(solveDilution(unknown: DilutionUnknown.v2, c1: 10, c1Unit: concPercent, v1: 1, v1Unit: volMl, c2: 10, c2Unit: concMgMl, resultUnit: volMl), 10);
      expect(solveDilution(unknown: DilutionUnknown.v2, c1: 10, c1Unit: concPercent, v1: 1, v1Unit: volMl, c2: 10, c2Unit: concMgMl, resultUnit: volL), 0.01);
      expect(solveDilution(unknown: DilutionUnknown.c2, c1: 10, c1Unit: concPercent, v1: 1, v1Unit: volMl, v2: 10, v2Unit: volMl, resultUnit: concPercent), 1);
    });
    test('valor faltando e unidades incompatíveis', () {
      expectCalcError(() => solveDilution(unknown: DilutionUnknown.v2, c1: 100, c1Unit: concMgMl, v1: 1, v1Unit: volMl, resultUnit: volMl), 'três valores');
      expectCalcError(() => solveDilution(unknown: DilutionUnknown.v2, c1: 100, c1Unit: concMgMl, v1: 1, v1Unit: massMg, c2: 10, c2Unit: concMgMl, resultUnit: volMl), 'compatíveis');
      expectCalcError(() => solveDilution(unknown: DilutionUnknown.v2, c1: 100, c1Unit: concMgMl, v1: 1, v1Unit: volMl, c2: 10, c2Unit: concMgMl, resultUnit: concMgMl), 'compatíveis');
    });
  });

  group('formatação', () {
    test('vírgula decimal, sem zeros sobrando e sem notação científica', () {
      expect(formatNumber(2), '2');
      expect(formatNumber(2.5), '2,5');
      expect(formatNumber(2.50), '2,5');
      expect(formatNumber(0.21), '0,21');
      expect(formatNumber(1 / 3), '0,333333');
      expect(formatNumber(1000), '1000');
      expect(formatNumber(1234567), '1234567');
      expect(formatNumber(100000000000000), '100000000000000');
      expect(formatNumber(0.000001), '0,000001');
      expect(formatNumber(12.3456789), '12,3457');
    });
    test('equivalente em outra unidade de massa', () {
      expect(massAlsoAs(1500), '1,5 g');
      expect(massAlsoAs(0.5), '500 µg');
      expect(massAlsoAs(50), isNull);
      expect(formatWithUnit(2, volMl), '2 mL');
    });
  });

  test('determinismo: mesma entrada, mesmo resultado', () {
    final a = totalDoseMg(weight: 7.3, weightUnit: kg, dose: 0.7, doseUnit: doseMgKg);
    final b = totalDoseMg(weight: 7.3, weightUnit: kg, dose: 0.7, doseUnit: doseMgKg);
    expect(a, b);
    expect(a, 5.11);
  });
}
