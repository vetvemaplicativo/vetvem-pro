import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../theme/app_theme.dart';

// Adicionais durante o atendimento: o profissional lança procedimentos extras (curativo, medicação,
// vacina...) combinados com o tutor na hora e, no fim, gera UM QR PIX com o total. O tutor não
// aprova nada no app; só é avisado depois de pagar.
//
// Firestore: appointments/{id}/extras/{extraId}
//   status: draft (itens, gravado aqui) -> awaiting_payment -> paid | expired | cancelled
// Cobrança, PIX e status são só do servidor (extraCharge / extraCancel / webhook).

String _brl(num v) => 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

/// "45,50", "45.50", "1.200,50" -> 45.5 / 1200.5. Null se inválido.
double? parseMoney(String raw) {
  var s = raw.replaceAll('R\$', '').replaceAll(RegExp(r'\s'), '');
  if (s.isEmpty) return null;
  if (s.contains(',')) {
    s = s.replaceAll('.', '').replaceAll(',', '.');
  }
  final v = double.tryParse(s);
  if (v == null || v.isNaN || v.isInfinite || v <= 0) return null;
  return (v * 100).round() / 100;
}

class ExtrasApi {
  static const _base = 'https://southamerica-east1-vetvem-18bf4.cloudfunctions.net';

  static Future<String?> _call(String fn, String appointmentId, String extraId) async {
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null) return 'Faça login novamente.';
      final res = await http
          .post(
            Uri.parse('$_base/$fn'),
            headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
            body: jsonEncode({'appointmentId': appointmentId, 'extraId': extraId}),
          )
          .timeout(const Duration(seconds: 30));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && body['ok'] == true) return null;
      return (body['error'] ?? 'Não foi possível concluir. Tente novamente.').toString();
    } catch (_) {
      return 'Sem conexão. Verifique a internet e tente novamente.';
    }
  }

  /// Gera o PIX do total. Retorna null se deu certo (o PIX fica no próprio documento) ou o erro.
  static Future<String?> charge(String appointmentId, String extraId) =>
      _call('extraCharge', appointmentId, extraId);

  static Future<String?> cancel(String appointmentId, String extraId) =>
      _call('extraCancel', appointmentId, extraId);
}

void _toast(String title, String msg, {bool error = false}) {
  Get.snackbar(
    title,
    msg,
    snackPosition: SnackPosition.TOP,
    backgroundColor: error ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
    colorText: AppColors.textDark,
    margin: const EdgeInsets.all(12),
    duration: const Duration(seconds: 5),
  );
}

class ExtrasSection extends StatefulWidget {
  final String appointmentId;
  const ExtrasSection({super.key, required this.appointmentId});

  @override
  State<ExtrasSection> createState() => _ExtrasSectionState();
}

class _ExtrasSectionState extends State<ExtrasSection> {
  bool _busy = false;

  CollectionReference<Map<String, dynamic>> get _col => FirebaseFirestore.instance
      .collection('appointments')
      .doc(widget.appointmentId)
      .collection('extras');

  List<Map<String, dynamic>> _itemsOf(Map<String, dynamic> d) =>
      (d['items'] as List?)?.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() ?? [];

  double _sum(List<Map<String, dynamic>> items) =>
      items.fold<double>(0, (s, i) => s + ((i['value'] as num?)?.toDouble() ?? 0));

  Future<void> _addItem(QueryDocumentSnapshot<Map<String, dynamic>>? draft) async {
    final item = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _ItemDialog(),
    );
    if (item == null) return;
    try {
      if (draft == null) {
        await _col.add({
          'status': 'draft',
          'vetId': FirebaseAuth.instance.currentUser?.uid ?? '',
          'items': [item],
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await draft.reference.update({'items': [..._itemsOf(draft.data()), item]});
      }
    } catch (_) {
      _toast('Não foi possível adicionar', 'Verifique a internet e tente de novo.', error: true);
    }
  }

  Future<void> _removeItem(QueryDocumentSnapshot<Map<String, dynamic>> draft, int index) async {
    final items = _itemsOf(draft.data())..removeAt(index);
    try {
      if (items.isEmpty) {
        await draft.reference.delete();
      } else {
        await draft.reference.update({'items': items});
      }
    } catch (_) {
      _toast('Não foi possível remover', 'Verifique a internet e tente de novo.', error: true);
    }
  }

  Future<void> _charge(String extraId) async {
    if (_busy) return;
    setState(() => _busy = true);
    final err = await ExtrasApi.charge(widget.appointmentId, extraId);
    if (!mounted) return;
    setState(() => _busy = false);
    if (err != null) {
      _toast('Não foi possível gerar o PIX', err, error: true);
      return;
    }
    _showPix(extraId);
  }

  Future<void> _cancel(String extraId) async {
    final ok = await Get.dialog<bool>(AlertDialog(
      title: const Text('Cancelar adicionais?'),
      content: const Text('Os itens serão descartados. Se o tutor já tiver pago o PIX, '
          'o pagamento é reconhecido mesmo assim.'),
      actions: [
        TextButton(onPressed: () => Get.back(result: false), child: const Text('Voltar')),
        TextButton(
          onPressed: () => Get.back(result: true),
          child: const Text('Cancelar adicionais', style: TextStyle(color: AppColors.error)),
        ),
      ],
    ));
    if (ok != true) return;
    setState(() => _busy = true);
    final err = await ExtrasApi.cancel(widget.appointmentId, extraId);
    if (!mounted) return;
    setState(() => _busy = false);
    if (err != null) _toast('Não foi possível cancelar', err, error: true);
  }

  void _showPix(String extraId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PixSheet(appointmentId: widget.appointmentId, extraId: extraId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _col.snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        final paid = docs.where((d) => d.data()['status'] == 'paid').toList();
        // Só uma cobrança em aberto por vez (rascunho ou aguardando pagamento).
        QueryDocumentSnapshot<Map<String, dynamic>>? open;
        for (final d in docs) {
          final s = d.data()['status'];
          if (s == 'draft' || s == 'awaiting_payment' || s == 'expired') {
            open = d;
            break;
          }
        }
        final data = open?.data() ?? {};
        final status = (data['status'] ?? '').toString();
        final items = _itemsOf(data);
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        final pixValid = status == 'awaiting_payment' &&
            ((data['pixExpiresAt'] as num?)?.toInt() ?? 0) > nowMs;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add_task_rounded, color: AppColors.accent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Adicionais da consulta',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Procedimentos extras combinados com o tutor (curativo, medicação, vacina...). '
                'Lance os itens e, no fim, gere um único QR PIX com o total.',
                style: TextStyle(fontSize: 12, height: 1.4, color: AppColors.textMedium),
              ),

              // Já pagos
              for (final d in paid) ...[
                const SizedBox(height: 12),
                _PaidBlock(items: _itemsOf(d.data()), total: (d.data()['total'] as num?)?.toDouble() ?? 0),
              ],

              // Em aberto
              if (open != null) ...[
                const SizedBox(height: 12),
                if (status == 'draft') ...[
                  for (var i = 0; i < items.length; i++)
                    _ItemRow(item: items[i], onRemove: _busy ? null : () => _removeItem(open!, i)),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _busy ? null : () => _addItem(open),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Adicionar item'),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _chargeButton(open.id, 'Gerar QR PIX · ${_brl(_sum(items))}'),
                ] else if (pixValid) ...[
                  for (final it in items) _ItemRow(item: it),
                  const SizedBox(height: 8),
                  Text('Aguardando pagamento · ${_brl((data['total'] as num?)?.toDouble() ?? _sum(items))}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFD97706))),
                  const SizedBox(height: 10),
                  _chargeButton(open.id, 'Mostrar QR PIX', show: true),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: _busy ? null : () => _cancel(open!.id),
                    child: const Text('Cancelar cobrança', style: TextStyle(color: AppColors.error)),
                  ),
                ] else ...[
                  // PIX vencido (ou cancelado no MP): os itens continuam, é só gerar outro QR.
                  for (final it in items) _ItemRow(item: it),
                  const SizedBox(height: 8),
                  const Text('O PIX anterior venceu sem pagamento.',
                      style: TextStyle(fontSize: 12, color: AppColors.textMedium)),
                  const SizedBox(height: 10),
                  _chargeButton(open.id, 'Gerar novo QR PIX · ${_brl(_sum(items))}'),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: _busy ? null : () => _cancel(open!.id),
                    child: const Text('Descartar itens', style: TextStyle(color: AppColors.error)),
                  ),
                ],
              ] else ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : () => _addItem(null),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(paid.isEmpty ? 'Adicionar procedimento' : 'Adicionar outro procedimento'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _chargeButton(String extraId, String label, {bool show = false}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _busy ? null : () => show ? _showPix(extraId) : _charge(extraId),
        icon: _busy
            ? const SizedBox(
                width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.qr_code_2_rounded, size: 20),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback? onRemove;
  const _ItemRow({required this.item, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text((item['name'] ?? '').toString(),
                style: const TextStyle(fontSize: 13, color: AppColors.textDark)),
          ),
          Text(_brl((item['value'] as num?) ?? 0),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
          if (onRemove != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Remover',
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMedium),
            ),
        ],
      ),
    );
  }
}

class _PaidBlock extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final double total;
  const _PaidBlock({required this.items, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
              const SizedBox(width: 6),
              Text('Pago · ${_brl(total)}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF16A34A))),
            ],
          ),
          const SizedBox(height: 4),
          for (final it in items) _ItemRow(item: it),
        ],
      ),
    );
  }
}

class _ItemDialog extends StatefulWidget {
  const _ItemDialog();

  @override
  State<_ItemDialog> createState() => _ItemDialogState();
}

class _ItemDialogState extends State<_ItemDialog> {
  final _name = TextEditingController();
  final _value = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _value.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    final value = parseMoney(_value.text);
    if (name.isEmpty) return setState(() => _error = 'Informe o procedimento.');
    if (value == null) return setState(() => _error = 'Informe um valor válido, maior que zero.');
    Navigator.of(context).pop({'name': name, 'value': value});
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar procedimento'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            maxLength: 80,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Procedimento', hintText: 'Ex.: Curativo na orelha'),
          ),
          TextField(
            controller: _value,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Valor (R\$)', hintText: 'Ex.: 45,00'),
            onSubmitted: (_) => _submit(),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
            ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        ElevatedButton(onPressed: _submit, child: const Text('Adicionar')),
      ],
    );
  }
}

/// Folha com o QR PIX do total. Acompanha o documento ao vivo: quando o tutor paga, vira "Pago".
class _PixSheet extends StatefulWidget {
  final String appointmentId;
  final String extraId;
  const _PixSheet({required this.appointmentId, required this.extraId});

  @override
  State<_PixSheet> createState() => _PixSheetState();
}

class _PixSheetState extends State<_PixSheet> {
  Timer? _tick;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('appointments')
        .doc(widget.appointmentId)
        .collection('extras')
        .doc(widget.extraId)
        .snapshots();
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snap) {
        final d = snap.data?.data();
        if (d == null) {
          return const SizedBox(height: 220, child: Center(child: CircularProgressIndicator()));
        }
        final total = (d['total'] as num?)?.toDouble() ?? 0;
        if (d['status'] == 'paid') return _paid(total);

        final expiresAt = (d['pixExpiresAt'] as num?)?.toInt() ?? 0;
        final left = Duration(milliseconds: expiresAt - DateTime.now().millisecondsSinceEpoch);
        final expired = left.inSeconds <= 0 || d['status'] != 'awaiting_payment';
        final b64 = (d['pixQrCodeBase64'] ?? '').toString();
        final code = (d['pixCopyPaste'] ?? '').toString();
        final mm = left.inMinutes.toString().padLeft(2, '0');
        final ss = (left.inSeconds % 60).toString().padLeft(2, '0');

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + MediaQuery.of(context).padding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              const Text('Adicionais da consulta',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              const SizedBox(height: 4),
              Text(_brl(total),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textDark)),
              const SizedBox(height: 14),
              if (expired)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('Este PIX venceu. Feche e gere um novo QR.',
                      textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMedium)),
                )
              else ...[
                if (b64.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Image.memory(base64Decode(b64), width: 230, height: 230, gaplessPlayback: true),
                  ),
                const SizedBox(height: 10),
                const Text('Peça ao tutor para ler o QR com o app do banco.',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.textMedium)),
                const SizedBox(height: 4),
                Text('Vence em $mm:$ss',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFD97706))),
                const SizedBox(height: 14),
                if (code.isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: code));
                        if (mounted) setState(() => _copied = true);
                      },
                      icon: Icon(_copied ? Icons.check_rounded : Icons.copy_rounded, size: 18),
                      label: Text(_copied ? 'Código copiado' : 'Copiar código PIX (copia e cola)'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 8),
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fechar')),
            ],
          ),
        );
      },
    );
  }

  Widget _paid(double total) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 32, 24, 24 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 72),
          const SizedBox(height: 12),
          const Text('Pago ✅',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF16A34A))),
          const SizedBox(height: 6),
          Text('${_brl(total)} recebidos. O repasse segue o prazo D+2 a partir de hoje.',
              textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMedium)),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Concluir'),
            ),
          ),
        ],
      ),
    );
  }
}
