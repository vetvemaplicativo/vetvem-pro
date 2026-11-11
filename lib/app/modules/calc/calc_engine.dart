/// VetVem Calc — motor de cálculo (Dart puro, sem Flutter, sem rede, sem dados de ninguém).
///
/// O módulo é ESTRITAMENTE DETERMINÍSTICO: o veterinário informa todos os parâmetros e o app só
/// faz aritmética. Não escolhe medicamento, não sugere dose, não interpreta o resultado.
///
/// PRECISÃO: todos os fatores de unidade são razões inteiras (num/den) e o cálculo faz
/// `valor * num / den` (uma divisão correta em vez de multiplicar por 0,001 em ponto flutuante).
/// Depois de cada operação o resultado é limpo para 12 algarismos significativos
/// (evita 0.30000000000000004). A exibição usa até 6 algarismos significativos, sem notação
/// científica, com vírgula decimal. Nada é arredondado entre etapas além dessa limpeza.
///
/// LIMITES: os limites abaixo são VALIDAÇÕES DE ENTRADA DO SOFTWARE (evitar digitação
/// acidental absurda e overflow). NÃO são limites clínicos.
///
/// REVISÃO VETERINÁRIA: antes de uso clínico em produção, calculadoras, unidades, fórmulas e
/// textos devem ser revisados e aprovados por médicos-veterinários responsáveis pelo produto.
library;

import 'dart:math' as math;

/// Erro de validação/cálculo com mensagem pronta para o usuário.
class CalcException implements Exception {
  final String message;
  const CalcException(this.message);
  @override
  String toString() => message;
}

/// Unidade como razão inteira em relação à unidade base da sua dimensão.
/// `base = valor * num / den`.
class CalcUnit {
  final String id;
  final String label;
  final String dimension; // weight | mass | volume | conc | dose
  final int num;
  final int den;
  const CalcUnit(this.id, this.label, this.dimension, this.num, this.den);

  double toBase(double v) => _clean(v * num / den);
  double fromBase(double b) => _clean(b * den / num);

  @override
  String toString() => label;
}

// Peso do paciente — base: kg.
const kg = CalcUnit('kg', 'kg', 'weight', 1, 1);
const gWeight = CalcUnit('g_w', 'g', 'weight', 1, 1000);
const weightUnits = [kg, gWeight];

// Massa de fármaco — base: mg.
const massKg = CalcUnit('kg_m', 'kg', 'mass', 1000000, 1);
const massG = CalcUnit('g_m', 'g', 'mass', 1000, 1);
const massMg = CalcUnit('mg', 'mg', 'mass', 1, 1);
const massUg = CalcUnit('ug', 'µg', 'mass', 1, 1000);
const massUnits = [massG, massMg, massUg, massKg];

// Volume — base: mL.
const volL = CalcUnit('L', 'L', 'volume', 1000, 1);
const volMl = CalcUnit('mL', 'mL', 'volume', 1, 1);
const volumeUnits = [volMl, volL];

// Concentração — base: mg/mL. "%" é peso/volume: 1 % = 1 g/100 mL = 10 mg/mL.
const concMgMl = CalcUnit('mg/mL', 'mg/mL', 'conc', 1, 1);
const concUgMl = CalcUnit('ug/mL', 'µg/mL', 'conc', 1, 1000);
const concGMl = CalcUnit('g/mL', 'g/mL', 'conc', 1000, 1);
const concGL = CalcUnit('g/L', 'g/L', 'conc', 1, 1);
const concPercent = CalcUnit('%', '%', 'conc', 10, 1);
const concUnits = [concMgMl, concPercent, concUgMl, concGMl, concGL];

// Dose por kg — base: mg/kg.
const doseMgKg = CalcUnit('mg/kg', 'mg/kg', 'dose', 1, 1);
const doseUgKg = CalcUnit('ug/kg', 'µg/kg', 'dose', 1, 1000);
const doseGKg = CalcUnit('g/kg', 'g/kg', 'dose', 1000, 1);
const doseUnits = [doseMgKg, doseUgKg, doseGKg];

// ── Limites técnicos de ENTRADA (não clínicos) ──────────────────────────────
const double maxInput = 10000000; // 1e7
const int maxDecimals = 6;
const double _maxResult = 1e15;

double _clean(double v) => v == 0 || !v.isFinite ? v : double.parse(v.toStringAsPrecision(12));

/// Converte o texto digitado em número positivo. Aceita "2,5" e "2.5"; recusa vazio, texto,
/// negativo, zero, notação científica, separador de milhar e valores acima do limite técnico.
double parseInput(String raw, String fieldName) {
  final s = raw.trim().replaceAll(RegExp(r'\s'), '');
  if (s.isEmpty) throw CalcException('Informe $fieldName.');
  if (!RegExp(r'^\d+([.,]\d+)?$').hasMatch(s)) {
    throw CalcException('$fieldName: use apenas números, com vírgula para decimais (ex.: 2,5).');
  }
  final decimals = s.contains(RegExp(r'[.,]')) ? s.split(RegExp(r'[.,]')).last.length : 0;
  if (decimals > maxDecimals) {
    throw CalcException('$fieldName: use no máximo $maxDecimals casas decimais.');
  }
  final v = double.parse(s.replaceAll(',', '.'));
  if (!v.isFinite) throw CalcException('$fieldName: valor inválido.');
  if (v <= 0) throw CalcException('$fieldName precisa ser maior que zero.');
  if (v > maxInput) {
    throw CalcException('$fieldName está acima do que o app aceita digitar. Confira o valor (validação do software, não é limite clínico).');
  }
  return v;
}

double _checkResult(double v) {
  if (!v.isFinite || v <= 0 || v > _maxResult) {
    throw const CalcException('Não foi possível calcular com os valores informados.');
  }
  return _clean(v);
}

void _need(CalcUnit u, String dimension) {
  if (u.dimension != dimension) {
    throw const CalcException('Verifique se as unidades são compatíveis.');
  }
}

// ── Cálculos ────────────────────────────────────────────────────────────────

/// Dose total em mg = peso (kg) × dose informada (mg/kg).
double totalDoseMg({
  required double weight,
  required CalcUnit weightUnit,
  required double dose,
  required CalcUnit doseUnit,
}) {
  _need(weightUnit, 'weight');
  _need(doseUnit, 'dose');
  return _checkResult(weightUnit.toBase(weight) * doseUnit.toBase(dose));
}

/// Volume em mL = quantidade (mg) ÷ concentração (mg/mL).
double volumeMl({
  required double amount,
  required CalcUnit amountUnit,
  required double concentration,
  required CalcUnit concUnit,
}) {
  _need(amountUnit, 'mass');
  _need(concUnit, 'conc');
  final c = concUnit.toBase(concentration);
  if (c <= 0) throw const CalcException('A concentração precisa ser maior que zero.');
  return _checkResult(amountUnit.toBase(amount) / c);
}

/// Converte [value] de [from] para [to] (mesma dimensão).
double convertValue(double value, CalcUnit from, CalcUnit to) {
  if (from.dimension != to.dimension) {
    throw const CalcException('Verifique se as unidades são compatíveis.');
  }
  return _checkResult(to.fromBase(from.toBase(value)));
}

/// Qual grandeza da relação C1 × V1 = C2 × V2 será calculada.
enum DilutionUnknown { c1, v1, c2, v2 }

/// Resolve C1·V1 = C2·V2 para a grandeza [unknown], dados os outros três valores
/// (cada um com a sua unidade). O resultado vem na unidade [resultUnit].
/// Concentrações são comparadas em mg/mL e volumes em mL, então unidades diferentes são aceitas
/// desde que da mesma dimensão.
double solveDilution({
  required DilutionUnknown unknown,
  double? c1, CalcUnit? c1Unit,
  double? v1, CalcUnit? v1Unit,
  double? c2, CalcUnit? c2Unit,
  double? v2, CalcUnit? v2Unit,
  required CalcUnit resultUnit,
}) {
  double conc(double? v, CalcUnit? u) {
    if (v == null || u == null) throw const CalcException('Preencha os três valores conhecidos.');
    _need(u, 'conc');
    return u.toBase(v);
  }

  double vol(double? v, CalcUnit? u) {
    if (v == null || u == null) throw const CalcException('Preencha os três valores conhecidos.');
    _need(u, 'volume');
    return u.toBase(v);
  }

  double r;
  switch (unknown) {
    case DilutionUnknown.c1:
      _need(resultUnit, 'conc');
      r = conc(c2, c2Unit) * vol(v2, v2Unit) / vol(v1, v1Unit);
    case DilutionUnknown.v1:
      _need(resultUnit, 'volume');
      r = conc(c2, c2Unit) * vol(v2, v2Unit) / conc(c1, c1Unit);
    case DilutionUnknown.c2:
      _need(resultUnit, 'conc');
      r = conc(c1, c1Unit) * vol(v1, v1Unit) / vol(v2, v2Unit);
    case DilutionUnknown.v2:
      _need(resultUnit, 'volume');
      r = conc(c1, c1Unit) * vol(v1, v1Unit) / conc(c2, c2Unit);
  }
  return resultUnit.fromBase(_checkResult(r));
}

// ── Formatação ──────────────────────────────────────────────────────────────

/// Até 6 algarismos significativos, sem notação científica, vírgula decimal, sem zeros à direita.
/// 2 → "2"; 2.5 → "2,5"; 0.30000000000000004 → "0,3".
String formatNumber(double v) {
  final c = _clean(v);
  if (c == 0) return '0';
  final magnitude = (math.log(c.abs()) / math.ln10).floor();
  final decimals = (5 - magnitude).clamp(0, 12);
  var s = c.toStringAsFixed(decimals);
  if (s.contains('.')) {
    s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }
  return s.replaceAll('.', ',');
}

String formatWithUnit(double v, CalcUnit u) => '${formatNumber(v)} ${u.label}';

/// Equivalente em outra unidade de massa quando faz sentido ler de outro jeito (≥ 1000 mg → g;
/// < 1 mg → µg). Só exibição; devolve null quando não há equivalente útil.
String? massAlsoAs(double mg) {
  if (mg >= 1000) return formatWithUnit(massG.fromBase(massMg.toBase(mg)), massG);
  if (mg < 1) return formatWithUnit(massUg.fromBase(massMg.toBase(mg)), massUg);
  return null;
}
