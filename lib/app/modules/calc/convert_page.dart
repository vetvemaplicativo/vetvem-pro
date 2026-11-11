import 'package:flutter/material.dart';
import 'calc_engine.dart';
import 'calc_widgets.dart';

enum _Group { weight, mass, volume, conc }

/// Conversão entre unidades compatíveis (peso do paciente, massa, volume e concentração).
class ConvertPage extends StatefulWidget {
  const ConvertPage({super.key});

  @override
  State<ConvertPage> createState() => _ConvertPageState();
}

class _ConvertPageState extends State<ConvertPage> {
  final _value = TextEditingController();
  _Group _group = _Group.mass;
  late CalcUnit _from = massMg;
  late CalcUnit _to = massG;
  String? _error;
  double? _result;
  List<String> _steps = const [];

  List<CalcUnit> get _units => switch (_group) {
        _Group.weight => weightUnits,
        _Group.mass => massUnits,
        _Group.volume => volumeUnits,
        _Group.conc => concUnits,
      };

  static String _groupLabel(_Group g) => switch (g) {
        _Group.weight => 'Peso do paciente',
        _Group.mass => 'Massa',
        _Group.volume => 'Volume',
        _Group.conc => 'Concentração',
      };

  void _setGroup(_Group g) {
    setState(() {
      _group = g;
      final u = _units;
      _from = u.first;
      _to = u.length > 1 ? u[1] : u.first;
      _result = null;
      _error = null;
      _steps = const [];
    });
  }

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  void _clear() => setState(() {
        _value.clear();
        _error = null;
        _result = null;
        _steps = const [];
      });

  void _calculate() {
    FocusScope.of(context).unfocus();
    try {
      final v = parseInput(_value.text, 'o valor');
      final r = convertValue(v, _from, _to);
      setState(() {
        _error = null;
        _result = r;
        _steps = ['Valor informado: ${formatWithUnit(v, _from)}', 'Convertido para: ${formatWithUnit(r, _to)}'];
      });
    } on CalcException catch (e) {
      setState(() {
        _error = e.message;
        _result = null;
        _steps = const [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CalcScaffold(
      title: 'Conversão de unidades',
      children: [
        const Text('Tipo de grandeza', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final g in _Group.values)
              ChoiceChip(label: Text(_groupLabel(g)), selected: _group == g, onSelected: (_) => _setGroup(g)),
          ],
        ),
        const SizedBox(height: 16),
        CalcField(
          label: 'Valor',
          controller: _value,
          units: _units,
          unit: _from,
          onUnit: (u) => setState(() => _from = u),
          hint: '0',
        ),
        const Text('Converter para', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final u in _units)
              ChoiceChip(label: Text(u.label), selected: _to == u, onSelected: (_) => setState(() => _to = u)),
          ],
        ),
        const SizedBox(height: 16),
        CalcActions(onCalculate: _calculate, onClear: _clear, calculateLabel: 'Converter'),
        if (_error != null) CalcErrorBox(_error!),
        if (_result != null) CalcResultBox(headlineLabel: 'Resultado da conversão', headline: formatWithUnit(_result!, _to), steps: _steps),
      ],
    );
  }
}
