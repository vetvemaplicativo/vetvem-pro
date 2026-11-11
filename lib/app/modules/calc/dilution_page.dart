import 'package:flutter/material.dart';
import 'calc_engine.dart';
import 'calc_widgets.dart';

/// Diluição simples: C1 × V1 = C2 × V2. O profissional informa três valores e escolhe o quarto
/// a calcular. O app não sugere concentração, diluente nem preparo.
class DilutionPage extends StatefulWidget {
  const DilutionPage({super.key});

  @override
  State<DilutionPage> createState() => _DilutionPageState();
}

class _DilutionPageState extends State<DilutionPage> {
  final _c1 = TextEditingController();
  final _v1 = TextEditingController();
  final _c2 = TextEditingController();
  final _v2 = TextEditingController();
  CalcUnit _c1u = concMgMl, _c2u = concMgMl, _v1u = volMl, _v2u = volMl;
  DilutionUnknown _unknown = DilutionUnknown.v2;
  CalcUnit _resultUnit = volMl;
  String? _error;
  String? _note;
  double? _result;
  List<String> _steps = const [];

  @override
  void dispose() {
    for (final c in [_c1, _v1, _c2, _v2]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _unknownIsConc => _unknown == DilutionUnknown.c1 || _unknown == DilutionUnknown.c2;

  void _setUnknown(DilutionUnknown u) => setState(() {
        _unknown = u;
        _resultUnit = _unknownIsConc ? concMgMl : volMl;
        _result = null;
        _error = null;
        _note = null;
        _steps = const [];
      });

  void _clear() => setState(() {
        for (final c in [_c1, _v1, _c2, _v2]) {
          c.clear();
        }
        _error = null;
        _note = null;
        _result = null;
        _steps = const [];
      });

  void _calculate() {
    FocusScope.of(context).unfocus();
    try {
      double? c1, v1, c2, v2;
      final steps = <String>[];
      if (_unknown != DilutionUnknown.c1) {
        c1 = parseInput(_c1.text, 'C1 (concentração inicial)');
        steps.add('C1 informada: ${formatWithUnit(c1, _c1u)}');
      }
      if (_unknown != DilutionUnknown.v1) {
        v1 = parseInput(_v1.text, 'V1 (volume inicial)');
        steps.add('V1 informado: ${formatWithUnit(v1, _v1u)}');
      }
      if (_unknown != DilutionUnknown.c2) {
        c2 = parseInput(_c2.text, 'C2 (concentração final)');
        steps.add('C2 informada: ${formatWithUnit(c2, _c2u)}');
      }
      if (_unknown != DilutionUnknown.v2) {
        v2 = parseInput(_v2.text, 'V2 (volume final)');
        steps.add('V2 informado: ${formatWithUnit(v2, _v2u)}');
      }
      final r = solveDilution(
        unknown: _unknown,
        c1: c1, c1Unit: _c1u,
        v1: v1, v1Unit: _v1u,
        c2: c2, c2Unit: _c2u,
        v2: v2, v2Unit: _v2u,
        resultUnit: _resultUnit,
      );
      final name = switch (_unknown) {
        DilutionUnknown.c1 => 'C1',
        DilutionUnknown.v1 => 'V1',
        DilutionUnknown.c2 => 'C2',
        DilutionUnknown.v2 => 'V2',
      };
      steps.add('$name calculado: ${formatWithUnit(r, _resultUnit)}');
      String? note;
      if (_unknown == DilutionUnknown.v1 || _unknown == DilutionUnknown.v2) {
        // V1 maior que V2 é matematicamente possível, mas costuma indicar valores trocados.
        final v1Base = _unknown == DilutionUnknown.v1 ? _resultUnit.toBase(r) : _v1u.toBase(v1!);
        final v2Base = _unknown == DilutionUnknown.v2 ? _resultUnit.toBase(r) : _v2u.toBase(v2!);
        if (v1Base > v2Base) note = 'O volume inicial (V1) ficou maior que o final (V2). Confira se os valores não estão trocados.';
      }
      setState(() {
        _error = null;
        _note = note;
        _result = r;
        _steps = steps;
      });
    } on CalcException catch (e) {
      setState(() {
        _error = e.message;
        _note = null;
        _result = null;
        _steps = const [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final unknownLabel = {
      DilutionUnknown.v2: 'V2 (volume final)',
      DilutionUnknown.v1: 'V1 (volume inicial)',
      DilutionUnknown.c2: 'C2 (concentração final)',
      DilutionUnknown.c1: 'C1 (concentração inicial)',
    };
    return CalcScaffold(
      title: 'Diluição simples',
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text('Relação C1 × V1 = C2 × V2. Informe três valores e escolha qual calcular. '
              'As concentrações precisam estar em unidades de concentração e os volumes em unidades de volume.',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF6B7280), height: 1.4)),
        ),
        const Text('Calcular', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final e in unknownLabel.entries)
              ChoiceChip(label: Text(e.value), selected: _unknown == e.key, onSelected: (_) => _setUnknown(e.key)),
          ],
        ),
        const SizedBox(height: 16),
        if (_unknown != DilutionUnknown.c1)
          CalcField(label: 'C1 — concentração inicial', controller: _c1, units: concUnits, unit: _c1u, onUnit: (u) => setState(() => _c1u = u), hint: '0'),
        if (_unknown != DilutionUnknown.v1)
          CalcField(label: 'V1 — volume inicial', controller: _v1, units: volumeUnits, unit: _v1u, onUnit: (u) => setState(() => _v1u = u), hint: '0'),
        if (_unknown != DilutionUnknown.c2)
          CalcField(label: 'C2 — concentração final', controller: _c2, units: concUnits, unit: _c2u, onUnit: (u) => setState(() => _c2u = u), hint: '0'),
        if (_unknown != DilutionUnknown.v2)
          CalcField(label: 'V2 — volume final', controller: _v2, units: volumeUnits, unit: _v2u, onUnit: (u) => setState(() => _v2u = u), hint: '0'),
        const Text('Mostrar o resultado em', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final u in (_unknownIsConc ? concUnits : volumeUnits))
              ChoiceChip(label: Text(u.label), selected: _resultUnit == u, onSelected: (_) => setState(() => _resultUnit = u)),
          ],
        ),
        const SizedBox(height: 16),
        CalcActions(onCalculate: _calculate, onClear: _clear),
        if (_error != null) CalcErrorBox(_error!),
        if (_result != null) ...[
          if (_note != null) CalcErrorBox(_note!),
          CalcResultBox(
            headlineLabel: '${unknownLabel[_unknown]} calculado',
            headline: formatWithUnit(_result!, _resultUnit),
            steps: _steps,
          ),
        ],
      ],
    );
  }
}
