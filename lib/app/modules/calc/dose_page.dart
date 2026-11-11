import 'package:flutter/material.dart';
import 'calc_engine.dart';
import 'calc_widgets.dart';

/// Texto pronto para o prontuário (usado quando a calculadora é aberta de dentro dele).
class CalcRecordResult {
  final String dosagem; // ex.: "2 mL (50 mg) — 5 mg/kg × 10 kg ÷ 25 mg/mL"
  final String pesoKg; // peso em kg, formatado ("10")
  const CalcRecordResult({required this.dosagem, required this.pesoKg});
}

/// Dose por peso: peso × dose informada = quantidade total; com concentração, também o volume.
/// Com [pickMode] aparece o botão "Usar no prontuário", que devolve [CalcRecordResult].
class DosePage extends StatefulWidget {
  final bool pickMode;
  const DosePage({super.key, this.pickMode = false});

  @override
  State<DosePage> createState() => _DosePageState();
}

class _DosePageState extends State<DosePage> {
  final _weight = TextEditingController();
  final _dose = TextEditingController();
  final _conc = TextEditingController();
  CalcUnit _weightUnit = kg;
  CalcUnit _doseUnit = doseMgKg;
  CalcUnit _concUnit = concMgMl;

  String? _error;
  double? _mg;
  double? _ml;
  List<String> _steps = const [];
  CalcRecordResult? _record;

  @override
  void dispose() {
    _weight.dispose();
    _dose.dispose();
    _conc.dispose();
    super.dispose();
  }

  void _clear() {
    setState(() {
      _weight.clear();
      _dose.clear();
      _conc.clear();
      _error = null;
      _mg = null;
      _ml = null;
      _steps = const [];
      _record = null;
    });
  }

  void _calculate() {
    FocusScope.of(context).unfocus();
    try {
      final w = parseInput(_weight.text, 'o peso do paciente');
      final d = parseInput(_dose.text, 'a dose informada');
      final mg = totalDoseMg(weight: w, weightUnit: _weightUnit, dose: d, doseUnit: _doseUnit);
      final steps = <String>[
        'Peso informado: ${formatWithUnit(w, _weightUnit)}',
        'Dose informada: ${formatWithUnit(d, _doseUnit)}',
        'Quantidade total calculada: ${formatWithUnit(mg, massMg)}',
      ];
      double? ml;
      var dosagem = '${formatWithUnit(mg, massMg)} — ${formatNumber(d)} ${_doseUnit.label} × ${formatWithUnit(w, _weightUnit)}';
      if (_conc.text.trim().isNotEmpty) {
        final c = parseInput(_conc.text, 'a concentração');
        ml = volumeMl(amount: mg, amountUnit: massMg, concentration: c, concUnit: _concUnit);
        steps.add('Concentração informada: ${formatWithUnit(c, _concUnit)}');
        steps.add('Volume matemático calculado: ${formatWithUnit(ml, volMl)}');
        dosagem = '${formatWithUnit(ml, volMl)} (${formatWithUnit(mg, massMg)}) — '
            '${formatNumber(d)} ${_doseUnit.label} × ${formatWithUnit(w, _weightUnit)} ÷ ${formatWithUnit(c, _concUnit)}';
      }
      setState(() {
        _error = null;
        _mg = mg;
        _ml = ml;
        _steps = steps;
        _record = CalcRecordResult(dosagem: dosagem, pesoKg: formatNumber(convertValue(w, _weightUnit, kg)));
      });
    } on CalcException catch (e) {
      setState(() {
        _error = e.message;
        _mg = null;
        _ml = null;
        _steps = const [];
        _record = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CalcScaffold(
      title: 'Dose por peso',
      children: [
        CalcField(
          label: 'Peso do paciente',
          controller: _weight,
          units: weightUnits,
          unit: _weightUnit,
          onUnit: (u) => setState(() => _weightUnit = u),
          hint: '0',
        ),
        CalcField(
          label: 'Dose informada por você',
          controller: _dose,
          units: doseUnits,
          unit: _doseUnit,
          onUnit: (u) => setState(() => _doseUnit = u),
          hint: '0',
        ),
        CalcField(
          label: 'Concentração do frasco',
          controller: _conc,
          units: concUnits,
          unit: _concUnit,
          onUnit: (u) => setState(() => _concUnit = u),
          hint: '0',
          optional: true,
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 14),
          child: Text(
            'Preencha a concentração se quiser também o volume a aplicar. 1 % equivale a 10 mg/mL.',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
        ),
        CalcActions(onCalculate: _calculate, onClear: _clear),
        if (_error != null) CalcErrorBox(_error!),
        if (_mg != null)
          CalcResultBox(
            headlineLabel: _ml != null ? 'Volume calculado' : 'Quantidade total calculada',
            headline: _ml != null ? formatWithUnit(_ml!, volMl) : formatWithUnit(_mg!, massMg),
            alsoAs: _ml != null ? 'dose total ${formatWithUnit(_mg!, massMg)}' : massAlsoAs(_mg!),
            steps: _steps,
          ),
        if (widget.pickMode && _record != null) ...[
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(_record),
            icon: const Icon(Icons.playlist_add_check),
            label: const Text('Usar no prontuário'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: const Color(0xFFFF6B2B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ],
    );
  }
}
