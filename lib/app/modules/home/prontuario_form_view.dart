import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../theme/app_theme.dart';
import 'home_controller.dart';

// Modelos locais (espelham os do cliente — unificados no Firebase depois)
class _Vacina {
  String nome;
  String proximaDose;
  _Vacina({this.nome = '', this.proximaDose = ''});
}

class _Medicamento {
  String nome;
  String dosagem;
  String frequencia;
  String duracao;
  _Medicamento({this.nome = '', this.dosagem = '', this.frequencia = '', this.duracao = ''});
}

class ProntuarioFormView extends StatefulWidget {
  const ProntuarioFormView({super.key});

  @override
  State<ProntuarioFormView> createState() => _ProntuarioFormViewState();
}

class _ProntuarioFormViewState extends State<ProntuarioFormView> {
  late final Map<String, String> appt;
  late final String _mode; // 'create' | 'edit' | 'complement'
  final _pesoCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();
  final _complementoCtrl = TextEditingController();
  final _vacinas = <_Vacina>[];
  final _medicamentos = <_Medicamento>[];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>;
    appt = Map<String, String>.from(args['appt'] as Map);
    _mode = args['mode'] as String? ?? 'create';

    if (_mode == 'edit') {
      final existing = args['prontuario'] as Map<String, dynamic>? ?? {};
      _pesoCtrl.text = existing['peso']?.toString() ?? '';
      _obsCtrl.text = existing['observacoes']?.toString() ?? '';
      for (final v in List<Map<String, dynamic>>.from(existing['vacinas'] ?? [])) {
        _vacinas.add(_Vacina(nome: v['nome'] ?? '', proximaDose: v['proximaDose'] ?? ''));
      }
      for (final m in List<Map<String, dynamic>>.from(existing['medicamentos'] ?? [])) {
        _medicamentos.add(_Medicamento(
          nome: m['nome'] ?? '',
          dosagem: m['dosagem'] ?? '',
          frequencia: m['frequencia'] ?? '',
          duracao: m['duracao'] ?? '',
        ));
      }
    }
  }

  @override
  void dispose() {
    _pesoCtrl.dispose();
    _obsCtrl.dispose();
    _complementoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          Material(
            color: AppColors.primary,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 20),
                      onPressed: () => Get.back(),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _mode == 'complement'
                                ? 'Adicionar complemento'
                                : _mode == 'edit'
                                    ? 'Editar prontuário'
                                    : 'Registro de prontuário',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins')),
                          Text('${appt['pet']} · ${appt['service']}',
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontFamily: 'Poppins')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info da consulta
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.pets_rounded,
                            color: AppColors.primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${appt['pet']} · Tutor: ${appt['owner']}',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Aviso de edição
                  if (_mode == 'edit')
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFFF59E0B)
                                .withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 16, color: Color(0xFFD97706)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'A edição ficará registrada para o cliente como "prontuário atualizado".',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF92400E)),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (_mode == 'complement') ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F3FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFF8B5CF6)
                                .withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add_comment_rounded,
                              size: 16, color: Color(0xFF8B5CF6)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'O complemento é anexado ao prontuário original sem alterá-lo.',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF5B21B6)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const _SectionLabel('Texto do complemento'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _complementoCtrl,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        hintText:
                            'Escreva aqui a informação complementar (ex: novo medicamento, ajuste de dosagem, resultado de exame)...',
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  if (_mode != 'complement') ...[
                  const SizedBox(height: 12),

                  // Peso
                  _SectionLabel('Peso (kg)'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _pesoCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
                    ],
                    decoration: const InputDecoration(
                      hintText: 'Ex: 9.5',
                      prefixIcon: Icon(Icons.monitor_weight_outlined,
                          color: AppColors.textLight, size: 20),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Vacinas
                  Row(
                    children: [
                      const Expanded(child: _SectionLabel('Vacinas aplicadas')),
                      TextButton.icon(
                        onPressed: () =>
                            setState(() => _vacinas.add(_Vacina())),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Adicionar'),
                        style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: EdgeInsets.zero),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_vacinas.isEmpty)
                    _EmptyHint('Nenhuma vacina aplicada nesta consulta'),
                  ..._vacinas.asMap().entries.map((e) =>
                      _VacinaForm(
                        key: ValueKey('v${e.key}'),
                        vacina: e.value,
                        onRemove: () => setState(() => _vacinas.removeAt(e.key)),
                      )),
                  const SizedBox(height: 24),

                  // Medicamentos
                  Row(
                    children: [
                      const Expanded(
                          child: _SectionLabel('Medicamentos prescritos')),
                      TextButton.icon(
                        onPressed: () =>
                            setState(() => _medicamentos.add(_Medicamento())),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Adicionar'),
                        style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: EdgeInsets.zero),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_medicamentos.isEmpty)
                    _EmptyHint('Nenhum medicamento prescrito'),
                  ..._medicamentos.asMap().entries.map((e) =>
                      _MedicamentoForm(
                        key: ValueKey('m${e.key}'),
                        med: e.value,
                        onRemove: () =>
                            setState(() => _medicamentos.removeAt(e.key)),
                      )),
                  const SizedBox(height: 24),

                  // Observações
                  const _SectionLabel('Observações clínicas'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _obsCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText:
                          'Descreva o estado clínico, diagnóstico, recomendações...',
                    ),
                  ),
                  const SizedBox(height: 32),
                  ], // end if (_mode != 'complement')
                ],
              ),
            ),
          ),

          // Botões
          Container(
            padding: EdgeInsets.fromLTRB(
                20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: _mode == 'complement'
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton.icon(
                        onPressed:
                            _saving ? null : () => _save(sendToClient: true),
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.send_rounded, size: 18),
                        label: Text(_saving
                            ? 'Salvando...'
                            : 'Enviar complemento ao cliente'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _saving
                            ? null
                            : () => _save(sendToClient: false),
                        icon: const Icon(Icons.save_outlined, size: 18),
                        label: const Text('Salvar sem enviar'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          foregroundColor: const Color(0xFF8B5CF6),
                          side:
                              const BorderSide(color: Color(0xFF8B5CF6)),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _saving
                            ? null
                            : () => _save(sendToClient: true),
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.send_rounded, size: 18),
                        label: Text(_saving
                            ? 'Salvando...'
                            : _mode == 'edit'
                                ? 'Salvar edição e enviar ao cliente'
                                : 'Salvar e enviar ao cliente'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _saving
                            ? null
                            : () => _save(sendToClient: false),
                        icon: const Icon(Icons.save_outlined, size: 18),
                        label: Text(_mode == 'edit'
                            ? 'Salvar edição sem enviar'
                            : 'Salvar sem enviar'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _save({required bool sendToClient}) async {
    setState(() => _saving = true);
    final ctrl = Get.find<HomeController>();
    try {
      if (_mode == 'complement') {
        final texto = _complementoCtrl.text.trim();
        if (texto.isEmpty) {
          setState(() => _saving = false);
          return;
        }
        await FirebaseFirestore.instance
            .collection('appointments')
            .doc(appt['id'])
            .update({
          'complementos': FieldValue.arrayUnion([
            {
              'texto': texto,
              'addedAt': DateTime.now().toIso8601String(),
            }
          ]),
          if (sendToClient) 'sentToClient': true,
        });
        Get.back();
        final ctrl = Get.find<HomeController>();
        ctrl.snack(
          title: 'Complemento adicionado!',
          message: sendToClient
              ? 'O cliente já pode ver o complemento de ${appt['pet']}.'
              : 'Complemento salvo sem enviar ao cliente.',
          icon: Icons.add_comment_rounded,
          color: const Color(0xFF8B5CF6),
        );
        return;
      }

      final prontuarioData = {
        'peso': _pesoCtrl.text.trim(),
        'vacinas': _vacinas
            .map((v) => {'nome': v.nome, 'proximaDose': v.proximaDose})
            .toList(),
        'medicamentos': _medicamentos
            .map((m) => {
                  'nome': m.nome,
                  'dosagem': m.dosagem,
                  'frequencia': m.frequencia,
                  'duracao': m.duracao,
                })
            .toList(),
        'observacoes': _obsCtrl.text.trim(),
        'savedAt': FieldValue.serverTimestamp(),
        if (_mode == 'edit') 'editedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appt['id'])
          .update({
        'prontuario': prontuarioData,
        'sentToClient': sendToClient,
        'status': 'completed',
        // paymentStatus NÃO é setado aqui de propósito: as rules já
        // bloqueiam esse campo pro cliente, e se o pagamento ainda não
        // tivesse sido aprovado pelo webhook do Mercado Pago neste momento,
        // o update inteiro falhava silenciosamente (catch abaixo engolia o
        // erro) e a consulta nunca virava "completed". Status de pagamento
        // é sempre responsabilidade do gateway/webhook, nunca do client.
        'completedAt': FieldValue.serverTimestamp(),
        'vetCrmv': ctrl.professionalCrmv.value,
      });
    } catch (_) {}

    // edit/complement: só fecha o form, volta ao detalhe
    if (_mode == 'edit') {
      Get.back();
    } else {
      Get.close(2);
    }

    final isEdit = _mode == 'edit';
    ctrl.snack(
      title: isEdit
          ? (sendToClient ? 'Prontuário atualizado e enviado!' : 'Prontuário atualizado!')
          : (sendToClient ? 'Prontuário enviado!' : 'Prontuário salvo!'),
      message: sendToClient
          ? 'O cliente já pode visualizar o registro de ${appt['pet']}.'
          : isEdit
              ? 'Edição salva. Cliente verá como "atualizado".'
              : 'Registro salvo. Você pode enviar ao cliente depois.',
      icon: sendToClient ? Icons.send_rounded : Icons.save_rounded,
      color: const Color(0xFF22C55E),
    );
  }
}

// ─── Formulário de vacina ─────────────────────────────────────────────────────

class _VacinaForm extends StatefulWidget {
  final _Vacina vacina;
  final VoidCallback onRemove;
  const _VacinaForm({super.key, required this.vacina, required this.onRemove});

  @override
  State<_VacinaForm> createState() => _VacinaFormState();
}

class _VacinaFormState extends State<_VacinaForm> {
  late final TextEditingController _nomeCtrl;
  late final TextEditingController _doseCtrl;

  @override
  void initState() {
    super.initState();
    _nomeCtrl = TextEditingController(text: widget.vacina.nome);
    _doseCtrl = TextEditingController(text: widget.vacina.proximaDose);
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _doseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: const Color(0xFF22C55E).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.vaccines_outlined,
                  color: Color(0xFF22C55E), size: 16),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Vacina',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF22C55E))),
              ),
              GestureDetector(
                  onTap: widget.onRemove,
                  child: const Icon(Icons.close,
                      size: 18, color: AppColors.textLight)),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nomeCtrl,
            onChanged: (v) => widget.vacina.nome = v,
            decoration: const InputDecoration(hintText: 'Nome da vacina (ex: V10)'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _doseCtrl,
            onChanged: (v) => widget.vacina.proximaDose = v,
            decoration: const InputDecoration(
                hintText: 'Próxima dose (ex: 10/06/2027)'),
          ),
        ],
      ),
    );
  }
}

// ─── Formulário de medicamento ────────────────────────────────────────────────

class _MedicamentoForm extends StatefulWidget {
  final _Medicamento med;
  final VoidCallback onRemove;
  const _MedicamentoForm(
      {super.key, required this.med, required this.onRemove});

  @override
  State<_MedicamentoForm> createState() => _MedicamentoFormState();
}

class _MedicamentoFormState extends State<_MedicamentoForm> {
  late final TextEditingController _nomeCtrl;
  late final TextEditingController _dosagemCtrl;
  late final TextEditingController _freqCtrl;
  late final TextEditingController _durCtrl;

  @override
  void initState() {
    super.initState();
    _nomeCtrl = TextEditingController(text: widget.med.nome);
    _dosagemCtrl = TextEditingController(text: widget.med.dosagem);
    _freqCtrl = TextEditingController(text: widget.med.frequencia);
    _durCtrl = TextEditingController(text: widget.med.duracao);
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _dosagemCtrl.dispose();
    _freqCtrl.dispose();
    _durCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.medication_outlined,
                  color: Color(0xFF3B82F6), size: 16),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Medicamento',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3B82F6))),
              ),
              GestureDetector(
                  onTap: widget.onRemove,
                  child: const Icon(Icons.close,
                      size: 18, color: AppColors.textLight)),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nomeCtrl,
            onChanged: (v) => widget.med.nome = v,
            decoration: const InputDecoration(hintText: 'Nome (ex: Apoquel)'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _dosagemCtrl,
                  onChanged: (v) => widget.med.dosagem = v,
                  decoration:
                      const InputDecoration(hintText: 'Dosagem (ex: 5mg)'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _freqCtrl,
                  onChanged: (v) => widget.med.frequencia = v,
                  decoration:
                      const InputDecoration(hintText: 'Freq. (ex: 2x/dia)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _durCtrl,
            onChanged: (v) => widget.med.duracao = v,
            decoration:
                const InputDecoration(hintText: 'Duração (ex: 10 dias)'),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textMedium));
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                fontSize: 12,
                color: AppColors.textLight,
                fontStyle: FontStyle.italic)),
      );
}
