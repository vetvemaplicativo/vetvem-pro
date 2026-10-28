import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../theme/app_theme.dart';
import 'home_controller.dart';

/// Taxa de deslocamento do profissional: fixa (definida em cada serviço) ou por
/// quilômetro. No modo por km o servidor calcula a distância entre o CEP de
/// partida e o CEP do tutor, aplica os tetos do VetVem e cobra no pagamento.
class TravelSettingsView extends StatefulWidget {
  const TravelSettingsView({super.key});

  @override
  State<TravelSettingsView> createState() => _TravelSettingsViewState();
}

class _CepResult {
  final String cep; // 8 dígitos
  final String street;
  final String neighborhood;
  final String city;
  final String uf;
  const _CepResult(this.cep, this.street, this.neighborhood, this.city, this.uf);

  String get cepMasked => '${cep.substring(0, 5)}-${cep.substring(5)}';
  String get title => street.isNotEmpty ? street : 'CEP geral de $city';
  String get subtitle => [
        if (neighborhood.isNotEmpty) neighborhood,
        '$city - $uf',
      ].join(' · ');
  String get label => [if (street.isNotEmpty) street, subtitle].join(' · ');
}

class _TravelSettingsViewState extends State<TravelSettingsView> {
  static const _suggestedPerKm = 2.0;
  static const _defaultMaxPerKm = 3.0;
  static const _defaultMaxTotal = 80.0;
  static const _defaultMaxKm = 30;

  final _db = FirebaseFirestore.instance;
  final _cepCtrl = TextEditingController();
  final _perKmCtrl = TextEditingController();
  final _maxKmCtrl = TextEditingController(text: '$_defaultMaxKm');

  bool _loading = true;
  bool _saving = false;
  bool _lookingUp = false;
  String _model = 'fixed'; // 'fixed' | 'per_km'
  bool _roundTrip = true;
  _CepResult? _found; // resultado da busca, aguardando confirmação
  bool _confirmed = false;
  String _savedCep = '';
  String _savedLabel = '';
  String? _cepError;
  double _maxPerKm = _defaultMaxPerKm;
  double _maxTotal = _defaultMaxTotal;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _cepCtrl.dispose();
    _perKmCtrl.dispose();
    _maxKmCtrl.dispose();
    super.dispose();
  }

  double? _num(String t) =>
      double.tryParse(t.trim().replaceAll('.', '').replaceAll(',', '.')) ??
      double.tryParse(t.trim().replaceAll(',', '.'));

  String _money(double v) => v.toStringAsFixed(2).replaceAll('.', ',');

  Future<void> _load() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final rules = await _db.collection('config').doc('travel_rules').get();
      final r = rules.data() ?? {};
      final mpk = (r['maxPerKm'] as num?)?.toDouble();
      final mt = (r['maxTotal'] as num?)?.toDouble();
      if (mpk != null && mpk > 0) _maxPerKm = mpk;
      if (mt != null && mt > 0) _maxTotal = mt;
    } catch (_) {}
    try {
      final d = (await _db.collection('users').doc(uid).get()).data() ?? {};
      _model = d['travelModel'] == 'per_km' ? 'per_km' : 'fixed';
      _roundTrip = d['travelRoundTrip'] != false;
      final pk = (d['travelPerKm'] as num?)?.toDouble() ??
          double.tryParse('${d['travelPerKm'] ?? ''}'.replaceAll(',', '.'));
      if (pk != null && pk > 0) _perKmCtrl.text = _money(pk);
      final mk = (d['travelMaxKm'] as num?)?.toInt();
      if (mk != null && mk > 0) _maxKmCtrl.text = '$mk';
      _savedCep = '${d['originCep'] ?? ''}'.replaceAll(RegExp(r'\D'), '');
      _savedLabel = '${d['originLabel'] ?? ''}';
      _savedOriginCepInDb = _savedCep;
      if (_savedCep.length == 8) {
        _cepCtrl.text = '${_savedCep.substring(0, 5)}-${_savedCep.substring(5)}';
        _confirmed = true;
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  // ── CEP ────────────────────────────────────────────────────────────────────
  void _onCepChanged(String v) {
    final digits = v.replaceAll(RegExp(r'\D'), '');
    setState(() {
      _cepError = null;
      _found = null;
      _confirmed = digits.length == 8 && digits == _savedCep && _savedLabel.isNotEmpty;
    });
    if (digits.length == 8 && !_confirmed) _lookup(digits);
  }

  Future<void> _lookup(String cep) async {
    setState(() => _lookingUp = true);
    try {
      final res = await http
          .get(Uri.parse('https://viacep.com.br/ws/$cep/json/'))
          .timeout(const Duration(seconds: 8));
      if (!mounted) return;
      final data = res.statusCode == 200 ? jsonDecode(res.body) : null;
      if (data is! Map || data['erro'] != null || '${data['localidade'] ?? ''}'.isEmpty) {
        setState(() => _cepError = 'CEP não encontrado. Confira os números.');
      } else {
        setState(() => _found = _CepResult(
              cep,
              '${data['logradouro'] ?? ''}',
              '${data['bairro'] ?? ''}',
              '${data['localidade'] ?? ''}',
              '${data['uf'] ?? ''}',
            ));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _cepError = 'Não foi possível buscar o CEP agora. Verifique a conexão.');
      }
    } finally {
      if (mounted) setState(() => _lookingUp = false);
    }
  }

  void _confirmFound() {
    final f = _found;
    if (f == null) return;
    setState(() {
      _confirmed = true;
      _savedLabel = f.label;
      _savedCep = f.cep;
      _found = null;
    });
  }

  // ── Salvar ─────────────────────────────────────────────────────────────────
  void _warn(String title, String msg) => Get.find<HomeController>().snack(
        title: title,
        message: msg,
        icon: Icons.error_outline_rounded,
        color: const Color(0xFFEF4444),
      );

  Future<void> _save() async {
    final uid = _uid;
    if (uid == null || _saving) return;
    FocusScope.of(context).unfocus();

    if (_model == 'fixed') {
      setState(() => _saving = true);
      try {
        await _db.collection('users').doc(uid).update({'travelModel': 'fixed'});
        final n = await Get.find<HomeController>().convertServicesForTravelModel('fixed');
        if (n > 0) {
          Get.find<HomeController>().snack(
            title: 'Informe o valor da taxa fixa',
            message: 'Em $n serviço(s) o deslocamento foi desligado. Ative de novo e informe o valor.',
            icon: Icons.info_outline_rounded,
            color: AppColors.primary,
          );
        }
        await _afterSave();
        if (mounted) Get.back();
      } catch (_) {
        _warn('Não foi possível salvar', 'Verifique sua conexão e tente novamente.');
      } finally {
        if (mounted) setState(() => _saving = false);
      }
      return;
    }

    final cepDigits = _cepCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (!_confirmed || cepDigits.length != 8) {
      _warn('Confirme o CEP', 'Digite o CEP e toque no nome da rua para confirmar.');
      return;
    }
    final perKm = _num(_perKmCtrl.text);
    if (perKm == null || perKm <= 0) {
      _warn('Valor por km', 'Informe quanto você cobra por quilômetro.');
      return;
    }
    if (perKm > _maxPerKm + 0.0001) {
      _warn('Valor acima do limite',
          'O VetVem permite até R\$ ${_money(_maxPerKm)} por km.');
      return;
    }
    final maxKm = int.tryParse(_maxKmCtrl.text.trim());
    if (maxKm == null || maxKm < 1 || maxKm > 100) {
      _warn('Distância máxima', 'Informe uma distância entre 1 e 100 km.');
      return;
    }

    setState(() => _saving = true);
    try {
      final cepChanged = cepDigits != _savedOriginCepInDb;
      await _db.collection('users').doc(uid).update({
        'travelModel': 'per_km',
        'travelPerKm': perKm,
        'travelRoundTrip': _roundTrip,
        'travelMaxKm': maxKm,
        'originCep': cepDigits,
        'originLabel': _savedLabel,
        // o servidor refaz a checagem do mapa quando o CEP muda
        if (cepChanged) 'originGeoStatus': FieldValue.delete(),
      });
      _savedOriginCepInDb = cepDigits;
      await Get.find<HomeController>().convertServicesForTravelModel('per_km');
      await _afterSave();
      final status = cepChanged ? await _waitGeoStatus(uid) : 'ok';
      if (!mounted) return;
      if (status == 'not_found' || status == 'invalid') {
        _warn('CEP não localizado no mapa',
            'Salvamos, mas não conseguimos achar esse CEP no mapa. Confira o CEP.');
        return;
      }
      Get.back();
      Get.find<HomeController>().snack(
        title: 'Deslocamento por km salvo',
        message: 'Os tutores já verão o valor calculado pela distância.',
        icon: Icons.check_circle_outline_rounded,
        color: AppColors.success,
      );
    } catch (_) {
      _warn('Não foi possível salvar', 'Verifique sua conexão e tente novamente.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _savedOriginCepInDb = '';

  Future<void> _afterSave() async {
    final c = Get.find<HomeController>();
    await c.reloadTravel();
  }

  // O servidor localiza o CEP no mapa em segundos; espera um pouco pelo resultado.
  Future<String> _waitGeoStatus(String uid) async {
    for (var i = 0; i < 6; i++) {
      await Future.delayed(const Duration(milliseconds: 1200));
      try {
        final s = (await _db.collection('users').doc(uid).get()).data()?['originGeoStatus'];
        if (s != null) return '$s';
      } catch (_) {}
    }
    return 'pending';
  }

  // ── UI ─────────────────────────────────────────────────────────────────────
  Widget _modeCard(String value, String title, String desc, IconData icon) {
    final on = _model == value;
    return InkWell(
      onTap: () => setState(() => _model = value),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: on ? AppColors.primary.withValues(alpha: 0.07) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: on ? AppColors.primary : const Color(0xFFE5E7EB), width: on ? 1.6 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: on ? AppColors.primary : AppColors.textMedium),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                  const SizedBox(height: 2),
                  Text(desc,
                      style: const TextStyle(
                          fontSize: 12, height: 1.35, color: AppColors.textMedium)),
                ],
              ),
            ),
            Icon(on ? Icons.radio_button_checked : Icons.radio_button_off,
                color: on ? AppColors.primary : AppColors.textLight),
          ],
        ),
      ),
    );
  }

  Widget _note(String text, {IconData icon = Icons.info_outline_rounded}) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 12, height: 1.4, color: AppColors.textMedium)),
            ),
          ],
        ),
      );

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 8),
        child: Text(t,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
      );

  Widget _chip(String text, bool on, VoidCallback onTap) => Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 13),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: on ? AppColors.primary : const Color(0xFFE5E7EB)),
            ),
            child: Text(text,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: on ? Colors.white : AppColors.textDark)),
          ),
        ),
      );

  Widget _cepSection() {
    final digits = _cepCtrl.text.replaceAll(RegExp(r'\D'), '');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('CEP de partida'),
        TextField(
          controller: _cepCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [_CepFormatter()],
          onChanged: _onCepChanged,
          decoration: InputDecoration(
            hintText: '00000-000',
            prefixIcon: const Icon(Icons.pin_drop_outlined, size: 20, color: AppColors.textLight),
            suffixIcon: _lookingUp
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : null,
            errorText: _cepError,
          ),
        ),
        if (_found != null && digits.length == 8)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: InkWell(
              onTap: _confirmFound,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary, width: 1.4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_found!.title,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(_found!.subtitle,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textMedium)),
                          const SizedBox(height: 6),
                          const Text('Toque para confirmar',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (_confirmed && _savedLabel.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, size: 20, color: AppColors.success),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_savedLabel,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
        _note('Este CEP é só uma referência para calcular a taxa de deslocamento até o tutor, '
            'nos atendimentos em que você vai até ele. O tutor não vê o seu CEP nem a sua rua.',
            icon: Icons.lock_outline_rounded),
      ],
    );
  }

  Widget _example() {
    final pk = _num(_perKmCtrl.text);
    if (pk == null || pk <= 0 || pk > _maxPerKm + 0.0001) return const SizedBox.shrink();
    double fee(double km) {
      final v = km * (_roundTrip ? 2 : 1) * pk;
      return v > _maxTotal ? _maxTotal : v;
    }
    final tutorKm = 10.0;
    return _note(
        'Exemplo: tutor a ${tutorKm.toStringAsFixed(0)} km de você → deslocamento de '
        'R\$ ${_money(fee(tutorKm))}'
        '${_roundTrip ? ' (ida e volta: 20 km)' : ' (só ida)'}.\n'
        'O deslocamento nunca passa de R\$ ${_money(_maxTotal)} por atendimento.',
        icon: Icons.calculate_outlined);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Taxa de deslocamento')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Como você quer cobrar o deslocamento?',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  Container(
                    margin: const EdgeInsets.only(top: 14, bottom: 18),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded, size: 20, color: AppColors.primary),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Aqui você escolhe o seu jeito de cobrar. Depois, em cada serviço, '
                            'você decide se cobra deslocamento ou não.',
                            style: TextStyle(
                                fontSize: 13, height: 1.45, color: AppColors.textDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _modeCard('fixed', 'Taxa fixa',
                      'Um valor fixo por visita, definido em cada serviço.', Icons.sell_outlined),
                  const SizedBox(height: 10),
                  _modeCard('per_km', 'Por quilômetro',
                      'O valor é calculado pela distância até o tutor.', Icons.route_outlined),
                  if (_model == 'per_km') ...[
                    _cepSection(),
                    _label('Como você conta o deslocamento?'),
                    Row(children: [
                      _chip('Só ida', !_roundTrip, () => setState(() => _roundTrip = false)),
                      const SizedBox(width: 10),
                      _chip('Ida e volta', _roundTrip, () => setState(() => _roundTrip = true)),
                    ]),
                    _note(_roundTrip
                        ? 'Cobra a distância da ida e a da volta (o dobro dos km até o tutor).'
                        : 'Cobra só a distância da ida até o tutor.'),
                    _label('Valor por quilômetro (R\$)'),
                    TextField(
                      controller: _perKmCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: '2,00',
                        prefixIcon:
                            Icon(Icons.attach_money, size: 20, color: AppColors.textLight),
                      ),
                    ),
                    _note(
                        'Sugestão VetVem: R\$ ${_money(_suggestedPerKm)} por km. É um valor de referência, '
                        'parecido com o que carros de aplicativo (Uber/99) cobram por km rodado no Rio e em São Paulo. '
                        'Se você conta só a ida, pode valer cobrar um pouco mais. '
                        'O máximo permitido é R\$ ${_money(_maxPerKm)} por km.',
                        icon: Icons.lightbulb_outline_rounded),
                    _label('Distância máxima que você atende (km)'),
                    TextField(
                      controller: _maxKmCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        hintText: '30',
                        prefixIcon:
                            Icon(Icons.social_distance_outlined, size: 20, color: AppColors.textLight),
                      ),
                    ),
                    _note('Até quantos km do seu CEP você aceita ir. Pedidos de tutores mais '
                        'longe que isso não chegam até você.'),
                    _example(),
                  ] else
                    _note('Com taxa fixa, o valor continua sendo definido dentro de cada serviço '
                        '(“Cobrar taxa de deslocamento”).'),
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: ElevatedButton(
            onPressed: _saving || _loading ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Text('Salvar'),
          ),
        ),
      ),
    );
  }
}

/// Máscara 00000-000.
class _CepFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var d = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (d.length > 8) d = d.substring(0, 8);
    final out = d.length > 5 ? '${d.substring(0, 5)}-${d.substring(5)}' : d;
    return TextEditingValue(text: out, selection: TextSelection.collapsed(offset: out.length));
  }
}
