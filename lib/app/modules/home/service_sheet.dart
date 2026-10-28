import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../theme/app_theme.dart';
import 'home_controller.dart';

/// Dados de um serviço vindos do formulário (valores em texto, como o app guarda).
class ServiceInput {
  final String name, price, unit;
  final bool perAnimal; // "desconto nos animais adicionais"
  final String additionalPrice; // só vale com perAnimal
  final String travelFee; // taxa de deslocamento fixa ('' = sem taxa)
  final bool travelByKm; // cobra deslocamento por km neste serviço (modelo por km)
  final String instructions; // orientações ao tutor ('' = sem orientações)
  const ServiceInput({
    required this.name,
    required this.price,
    required this.unit,
    this.perAnimal = false,
    this.additionalPrice = '',
    this.travelFee = '',
    this.travelByKm = false,
    this.instructions = '',
  });
}

typedef ServiceSave = void Function(ServiceInput input);

/// Cadastro/edição de serviço. Todo serviço aceita vários animais no mesmo
/// pedido e, por padrão, cada animal paga o preço cheio; a chave de desconto
/// permite cobrar menos a partir do 2º animal. Opcionalmente o serviço cobra uma
/// taxa de deslocamento FIXA por visita e/ou envia orientações ao tutor (ex.:
/// jejum). O servidor calcula o total: preço no 1º animal + (animais - 1) x
/// adicional + taxa de deslocamento (uma vez só).
class ServiceSheet extends StatefulWidget {
  final Map<String, String>? initial; // != null: editando
  final ServiceSave onSave;
  const ServiceSheet({super.key, this.initial, required this.onSave});

  @override
  State<ServiceSheet> createState() => _ServiceSheetState();
}

class _ServiceSheetState extends State<ServiceSheet> {
  static const _units = ['consulta', 'sessão', 'hora', 'dose', 'serviço', 'pacote'];
  static const _maxInstructions = 240;

  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _extra;
  late final TextEditingController _travel;
  late final TextEditingController _instructions;
  late String _unit;
  late bool _perAnimal;
  late bool _travelOn;
  // Perfil > Taxa de deslocamento: por km (o valor sai da distância; sem campo de valor)
  late final bool _byKm = Get.isRegistered<HomeController>() &&
      Get.find<HomeController>().travelModel.value == 'per_km';
  late bool _instructionsOn;

  @override
  void initState() {
    super.initState();
    final s = widget.initial;
    _name = TextEditingController(text: s?['name'] ?? '');
    _price = TextEditingController(text: s?['price'] ?? '');
    _extra = TextEditingController(text: s?['additionalPrice'] ?? '');
    _travel = TextEditingController(text: s?['travelFee'] ?? '');
    _instructions = TextEditingController(text: s?['instructions'] ?? '');
    _unit = _units.contains(s?['unit']) ? s!['unit']! : 'consulta';
    _perAnimal = s?['perAnimal'] == '1';
    _travelOn = _byKm ? (s?['travelByKm'] == '1') : ((s?['travelFee'] ?? '').isNotEmpty);
    _instructionsOn = (s?['instructions'] ?? '').isNotEmpty;
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _extra.dispose();
    _travel.dispose();
    _instructions.dispose();
    super.dispose();
  }

  /// Lê valores digitados do jeito brasileiro: "150", "150,5", "1.000,00", "R$ 1000.50".
  /// Devolve null se o texto não for um valor válido. Ponto sozinho só é milhar
  /// quando seguido de exatamente 3 dígitos ("1.000" = 1000; "12.50" = 12,5).
  static double? _num(String t) {
    var s = t.replaceAll('R\$', '').replaceAll(RegExp(r'\s'), '');
    if (s.isEmpty || !RegExp(r'^[0-9.,]+$').hasMatch(s)) return null;
    final lastComma = s.lastIndexOf(',');
    final lastDot = s.lastIndexOf('.');
    if (lastComma >= 0 && lastDot >= 0) {
      final dec = lastComma > lastDot ? ',' : '.';
      final th = dec == ',' ? '.' : ',';
      s = s.replaceAll(th, '').replaceAll(dec, '.');
    } else if (lastComma >= 0) {
      if (s.indexOf(',') != lastComma) return null;
      s = s.replaceAll(',', '.');
    } else if (lastDot >= 0) {
      final multi = s.indexOf('.') != lastDot;
      final after = s.length - lastDot - 1;
      if (multi || after == 3) {
        if (!RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(s)) return null;
        s = s.replaceAll('.', '');
      }
    }
    final v = double.tryParse(s);
    return (v == null || v.isNaN || v.isInfinite || v < 0 || v > 100000) ? null : v;
  }

  /// Forma que o app guarda e o servidor lê: "1000,50" (vírgula, sem milhar).
  static String _canon(double v) => v.toStringAsFixed(2).replaceAll('.', ',');

  static String _money(double v) =>
      'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  String get _example {
    final price = _num(_price.text);
    if (price == null || price <= 0) {
      return 'Preencha o preço acima para ver um exemplo.';
    }
    double extra = price;
    if (_perAnimal) {
      final e = _num(_extra.text);
      if (e == null || _extra.text.trim().isEmpty) {
        return 'Informe o valor de cada animal adicional para ver o exemplo.';
      }
      extra = e;
    }
    final travel = _travelOn && !_byKm ? (_num(_travel.text) ?? 0) : 0.0;
    final animals = price + 2 * extra;
    final total = animals + travel;
    final head = _perAnimal
        ? '${_money(price)} + 2 × ${_money(extra)}'
        : '3 × ${_money(price)}';
    final tail = travel > 0 ? ' + deslocamento ${_money(travel)}' : '';
    return 'Exemplo com 3 animais: $head$tail = ${_money(total)}';
  }

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.attach_money,
            size: 20, color: AppColors.textLight),
      );

  Widget _hint(String text) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 8, bottom: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text,
            style: const TextStyle(
                fontSize: 11, height: 1.4, color: AppColors.textMedium)),
      );

  @override
  Widget build(BuildContext context) {
    final editing = widget.initial != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(editing ? 'Editar serviço' : 'Novo serviço',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark)),
              const SizedBox(height: 16),
              TextField(
                controller: _name,
                decoration: const InputDecoration(
                    hintText: 'Nome do serviço',
                    prefixIcon: Icon(Icons.medical_services_outlined,
                        size: 20, color: AppColors.textLight)),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _price,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                      decoration: _dec('Preço (R\$)'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _unit,
                          isExpanded: true,
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textDark,
                              fontFamily: 'Poppins'),
                          items: _units
                              .map((u) =>
                                  DropdownMenuItem(value: u, child: Text(u)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _unit = v ?? 'consulta'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ── Desconto nos animais adicionais ─────────────────────────
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _perAnimal,
                activeThumbColor: AppColors.primary,
                onChanged: (v) => setState(() => _perAnimal = v),
                title: const Text('Dar desconto nos animais adicionais',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text(
                  'Por padrão, cada animal paga o preço cheio do serviço. Ative para cobrar menos a partir do 2º animal.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMedium),
                ),
              ),
              if (_perAnimal)
                TextField(
                  controller: _extra,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: _dec('Valor de cada animal adicional (R\$)'),
                ),

              // ── Taxa de deslocamento ────────────────────────────────────
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _travelOn,
                activeThumbColor: AppColors.primary,
                onChanged: (v) => setState(() => _travelOn = v),
                title: const Text('Cobrar taxa de deslocamento',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: Text(
                  _byKm
                      ? 'Soma ao serviço o deslocamento calculado pela distância até o tutor.'
                      : 'Soma ao serviço um valor para o seu deslocamento até o tutor.',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
                ),
              ),
              if (_travelOn && !_byKm) ...[
                TextField(
                  controller: _travel,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: _dec('Valor da taxa de deslocamento (R\$)'),
                ),
                _hint(
                  'Cobrado uma vez por visita, mesmo com vários animais. '
                  'O tutor vê a taxa separada do serviço, e a comissão do VetVem incide sobre o valor total.',
                ),
              ],

              // ── Orientações ao tutor ────────────────────────────────────
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _instructionsOn,
                activeThumbColor: AppColors.primary,
                onChanged: (v) => setState(() => _instructionsOn = v),
                title: const Text('Orientar o tutor antes da consulta',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text(
                  'Aparece para o tutor antes de pagar e é enviado quando você confirmar o pedido (ex.: jejum, medicamentos).',
                  style: TextStyle(fontSize: 12, color: AppColors.textMedium),
                ),
              ),
              if (_instructionsOn)
                TextField(
                  controller: _instructions,
                  maxLength: _maxInstructions,
                  maxLines: 4,
                  minLines: 3,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText:
                        'Ex.: Mantenha o animal em jejum de 6 horas antes do exame. Água à vontade.',
                  ),
                ),

              // ── Exemplo ─────────────────────────────────────────────────
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_example,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    const Text(
                      'O tutor pode incluir vários animais no mesmo pedido. '
                      'Acima de 10 animais, o app sugere ao tutor pedir um orçamento.',
                      style: TextStyle(
                          fontSize: 11, height: 1.4, color: AppColors.textMedium),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _save,
                child: const Text('Salvar serviço'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    final name = _name.text.trim();
    final price = _price.text.trim();
    void warn(String t, String m) =>
        Get.snackbar(t, m, snackPosition: SnackPosition.BOTTOM);
    if (name.isEmpty || price.isEmpty) {
      warn('Campos obrigatórios', 'Informe o nome e o preço.');
      return;
    }
    final priceV = _num(price);
    if (priceV == null || priceV <= 0) {
      warn('Preço inválido', 'Digite só números, por exemplo 150 ou 150,50.');
      return;
    }
    final extraV = _perAnimal ? _num(_extra.text) : null;
    if (_perAnimal && extraV == null) {
      warn('Valor adicional inválido',
          'Digite o valor de cada animal adicional (ex.: 100,00) ou desligue o desconto.');
      return;
    }
    final travelV = _travelOn && !_byKm ? _num(_travel.text) : null;
    if (_travelOn && !_byKm && (travelV == null || travelV <= 0)) {
      warn('Taxa de deslocamento inválida',
          'Digite um valor maior que zero (ex.: 30,00) ou desligue a taxa.');
      return;
    }
    if (_instructionsOn && _instructions.text.trim().isEmpty) {
      warn('Escreva a orientação',
          'Digite o texto para o tutor ou desligue as orientações.');
      return;
    }
    widget.onSave(ServiceInput(
      name: name,
      price: _canon(priceV),
      unit: _unit,
      perAnimal: _perAnimal,
      additionalPrice: extraV != null ? _canon(extraV) : '',
      travelFee: travelV != null ? _canon(travelV) : '',
      travelByKm: _byKm && _travelOn,
      instructions: _instructionsOn ? _instructions.text.trim() : '',
    ));
    Get.back();
  }
}
