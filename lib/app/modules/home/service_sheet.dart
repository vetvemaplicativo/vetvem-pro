import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../theme/app_theme.dart';

typedef ServiceSave = void Function(
    String name, String price, String unit, bool perAnimal, String additionalPrice);

/// Cadastro/edição de serviço. "Cobrar por animal" faz o tutor poder escolher
/// vários animais no mesmo pedido (vacina, vermífugo...). O servidor calcula o
/// total: preço no 1º animal + (animais - 1) x valor do adicional (se vazio,
/// o mesmo preço para todos).
class ServiceSheet extends StatefulWidget {
  final Map<String, String>? initial; // != null: editando
  final ServiceSave onSave;
  const ServiceSheet({super.key, this.initial, required this.onSave});

  @override
  State<ServiceSheet> createState() => _ServiceSheetState();
}

class _ServiceSheetState extends State<ServiceSheet> {
  static const _units = ['consulta', 'sessão', 'hora', 'dose', 'serviço', 'pacote'];

  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _extra;
  late String _unit;
  late bool _perAnimal;

  @override
  void initState() {
    super.initState();
    final s = widget.initial;
    _name = TextEditingController(text: s?['name'] ?? '');
    _price = TextEditingController(text: s?['price'] ?? '');
    _extra = TextEditingController(text: s?['additionalPrice'] ?? '');
    _unit = _units.contains(s?['unit']) ? s!['unit']! : 'consulta';
    _perAnimal = s?['perAnimal'] == '1';
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _extra.dispose();
    super.dispose();
  }

  static double? _num(String t) => double.tryParse(t.trim().replaceAll(',', '.'));

  static String _money(double v) =>
      'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  String get _example {
    final price = _num(_price.text);
    if (price == null || price <= 0) {
      return 'Preencha o preço acima para ver um exemplo.';
    }
    final extra = (_extra.text.trim().isEmpty ? null : _num(_extra.text)) ?? price;
    final total = price + 2 * extra;
    return 'Exemplo com 3 animais: ${_money(price)} + 2 × ${_money(extra)} = ${_money(total)}';
  }

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
                      decoration: const InputDecoration(
                          hintText: 'Preço (R\$)',
                          prefixIcon: Icon(Icons.attach_money,
                              size: 20, color: AppColors.textLight)),
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
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _perAnimal,
                activeThumbColor: AppColors.primary,
                onChanged: (v) => setState(() => _perAnimal = v),
                title: const Text('Cobrar por animal',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text(
                  'Use em serviços como vacina e vermífugo. O tutor poderá escolher vários animais no mesmo pedido.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMedium),
                ),
              ),
              if (_perAnimal) ...[
                const SizedBox(height: 6),
                TextField(
                  controller: _extra,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                      hintText: 'Valor de cada animal adicional (opcional)',
                      prefixIcon: Icon(Icons.attach_money,
                          size: 20, color: AppColors.textLight)),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
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
                        'O preço acima vale para o 1º animal. Se quiser dar desconto para os demais, informe o valor de cada animal adicional. '
                        'Deixe em branco para cobrar o mesmo valor em todos.\n'
                        'Acima de 10 animais, o app sugere ao tutor pedir um orçamento.',
                        style: TextStyle(
                            fontSize: 11,
                            height: 1.4,
                            color: AppColors.textMedium),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final name = _name.text.trim();
                  final price = _price.text.trim();
                  if (name.isEmpty || price.isEmpty) {
                    Get.snackbar('Campos obrigatórios', 'Informe o nome e o preço.',
                        snackPosition: SnackPosition.BOTTOM);
                    return;
                  }
                  if (_perAnimal &&
                      _extra.text.trim().isNotEmpty &&
                      _num(_extra.text) == null) {
                    Get.snackbar('Valor inválido',
                        'O valor do animal adicional precisa ser um número.',
                        snackPosition: SnackPosition.BOTTOM);
                    return;
                  }
                  widget.onSave(name, price, _unit, _perAnimal,
                      _perAnimal ? _extra.text.trim() : '');
                  Get.back();
                },
                child: const Text('Salvar serviço'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
