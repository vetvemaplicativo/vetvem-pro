import 'package:flutter/material.dart';
import 'calc_engine.dart';
import 'calc_widgets.dart';

/// Volume a partir de uma quantidade e de uma concentração, ambas informadas pelo profissional.
class VolumePage extends StatefulWidget {
  const VolumePage({super.key});

  @override
  State<VolumePage> createState() => _VolumePageState();
}

class _VolumePageState extends State<VolumePage> {
  final _amount = TextEditingController();
  final _conc = TextEditingController();
  CalcUnit _amountUnit = massMg;
  CalcUnit _concUnit = concMgMl;
  String? _error;
  double? _ml;
  List<String> _steps = const [];

  @override
  void dispose() {
    _amount.dispose();
    _conc.dispose();
    super.dispose();
  }

  void _clear() => setState(() {
        _amount.clear();
        _conc.clear();
        _error = null;
        _ml = null;
        _steps = const [];
      });

  void _calculate() {
    FocusScope.of(context).unfocus();
    try {
      final a = parseInput(_amount.text, 'a quantidade desejada');
      final c = parseInput(_conc.text, 'a concentração');
      final ml = volumeMl(amount: a, amountUnit: _amountUnit, concentration: c, concUnit: _concUnit);
      setState(() {
        _error = null;
        _ml = ml;
        _steps = [
          'Quantidade informada: ${formatWithUnit(a, _amountUnit)}',
          'Concentração informada: ${formatWithUnit(c, _concUnit)}',
          'Volume matemático calculado: ${formatWithUnit(ml, volMl)}',
        ];
      });
    } on CalcException catch (e) {
      setState(() {
        _error = e.message;
        _ml = null;
        _steps = const [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CalcScaffold(
      title: 'Volume por concentração',
      children: [
        CalcField(
          label: 'Quantidade desejada',
          controller: _amount,
          units: massUnits,
          unit: _amountUnit,
          onUnit: (u) => setState(() => _amountUnit = u),
          hint: '0',
        ),
        CalcField(
          label: 'Concentração informada por você',
          controller: _conc,
          units: concUnits,
          unit: _concUnit,
          onUnit: (u) => setState(() => _concUnit = u),
          hint: '0',
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 14),
          child: Text('1 % equivale a 10 mg/mL.', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        ),
        CalcActions(onCalculate: _calculate, onClear: _clear),
        if (_error != null) CalcErrorBox(_error!),
        if (_ml != null) CalcResultBox(headlineLabel: 'Volume calculado', headline: formatWithUnit(_ml!, volMl), steps: _steps),
      ],
    );
  }
}
