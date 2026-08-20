import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import 'home_controller.dart';

class AppointmentDetailView extends StatefulWidget {
  const AppointmentDetailView({super.key});

  @override
  State<AppointmentDetailView> createState() => _AppointmentDetailViewState();
}

class _AppointmentDetailViewState extends State<AppointmentDetailView> {
  late Map<String, String> appt;
  late HomeController ctrl;

  // Countdown — 30 minutos para responder, calculado a partir de createdAt
  // (não mais fixo em 30:00 a cada abertura de tela).
  int _secondsLeft = 30 * 60;
  Timer? _timer;
  bool _expired = false;

  Map<String, dynamic>? _prontuarioData;
  List<Map<String, dynamic>> _complementos = [];
  bool _prontuarioLoaded = false;

  @override
  void initState() {
    super.initState();
    appt = Map<String, String>.from(Get.arguments as Map);
    ctrl = Get.find<HomeController>();
    _loadProntuario();
  }

  Future<void> _loadProntuario() async {
    final id = appt['id'];
    if (id == null) return;
    final docRef =
        FirebaseFirestore.instance.collection('appointments').doc(id);
    final doc = await docRef.get();
    final data = doc.data();
    if (!mounted) return;
    setState(() {
      _prontuarioData = data?['prontuario'] as Map<String, dynamic>?;
      _complementos = List<Map<String, dynamic>>.from(data?['complementos'] ?? []);
      _prontuarioLoaded = true;
      if (data?['status'] != null) appt['status'] = data!['status'];
    });

    final status = data?['status'] as String? ?? '';
    if (status == 'pending_confirmation') {
      // Countdown real a partir do createdAt do servidor.
      final created = (data?['createdAt'] as Timestamp?)?.toDate();
      if (created != null) {
        final left =
            const Duration(minutes: 30) - DateTime.now().difference(created);
        if (left.inSeconds <= 0) {
          if (mounted) setState(() => _expired = true);
        } else {
          _secondsLeft = left.inSeconds;
          _startTimer();
        }
      }
      // "Visualizado": grava uma única vez (rules também garantem isso).
      if (data?['viewedAt'] == null) {
        docRef.update({'viewedAt': FieldValue.serverTimestamp()})
            .catchError((_) {});
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft <= 0) {
        _timer?.cancel();
        // Não rejeita mais localmente — a Cloud Function expireUnanswered é
        // a única fonte de verdade pra expiração (evita corrida com o
        // servidor). Aqui só atualiza a exibição.
        if (mounted) setState(() => _expired = true);
      } else {
        if (mounted) setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _timerLabel {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final status = appt['status'] ?? '';
    final isPending = status == 'pending' || status == 'pending_confirmation';
    final isConfirmed = status == 'confirmed';
    final isCompleted = status == 'completed';
    final isRejected = status == 'rejected' || status == 'cancelled';

    final statusColor = isPending
        ? const Color(0xFFF59E0B)
        : isConfirmed
            ? const Color(0xFF22C55E)
            : isCompleted
                ? AppColors.primary
                : AppColors.error;
    final statusLabel = isPending
        ? 'Aguardando confirmação'
        : isConfirmed
            ? 'Confirmado'
            : isCompleted
                ? 'Concluído'
                : isRejected
                    ? 'Recusado'
                    : 'Cancelado';
    final statusIcon = isPending
        ? Icons.schedule_rounded
        : isConfirmed
            ? Icons.check_circle_rounded
            : isCompleted
                ? Icons.task_alt_rounded
                : Icons.cancel_rounded;

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
                    const Expanded(
                      child: Text(
                        'Detalhe da consulta',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(statusLabel,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Conteúdo
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timer / aviso de prazo esgotado
                  if (isPending) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _expired
                            ? const Color(0xFFFEE2E2)
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: (_expired
                                    ? AppColors.error
                                    : const Color(0xFFF59E0B))
                                .withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                              _expired
                                  ? Icons.timer_off_outlined
                                  : Icons.timer_outlined,
                              color: _expired
                                  ? AppColors.error
                                  : const Color(0xFFD97706),
                              size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _expired
                                      ? 'Prazo esgotado'
                                      : 'Responda dentro do prazo',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _expired
                                          ? AppColors.error
                                          : const Color(0xFF92400E)),
                                ),
                                Text(
                                  _expired
                                      ? 'A solicitação foi recusada automaticamente por falta de resposta.'
                                      : 'Caso não responda, a consulta será recusada automaticamente.',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: (_expired
                                              ? AppColors.error
                                              : const Color(0xFF92400E))
                                          .withValues(alpha: 0.8)),
                                ),
                              ],
                            ),
                          ),
                          if (!_expired) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _timerLabel,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontFamily: 'Poppins'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Data e hora
                  _SectionCard(
                    child: Row(
                      children: [
                        _InfoIcon(Icons.access_time_rounded,
                            AppColors.primary),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Data e horário',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMedium)),
                            Text(
                              '${_dateLabel(appt['date']?.toString() ?? '')} às ${appt['time']}',
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Serviço e valor
                  _SectionCard(
                    child: Row(
                      children: [
                        _InfoIcon(Icons.medical_services_outlined,
                            AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Serviço',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMedium)),
                              Text(appt['service']!,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textDark)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Valor',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMedium)),
                            Text(
                              'R\$ ${appt['value'] ?? '--'}',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Pet
                  _SectionCard(
                    child: Row(
                      children: [
                        _InfoIcon(
                            appt['petSpecies'] == 'cat'
                                ? Icons.pets
                                : Icons.pets,
                            const Color(0xFFFF6B2B)),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Pet',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMedium)),
                            Text(appt['pet']!,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark)),
                            if (appt['petBreed'] != null)
                              Text(appt['petBreed']!,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMedium)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tutor
                  _SectionCard(
                    child: Row(
                      children: [
                        _InfoIcon(Icons.person_outline, AppColors.textMedium),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Tutor',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMedium)),
                              Text(appt['owner']!,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textDark)),
                              if (appt['clientPhone'] != null)
                                Text(appt['clientPhone']!,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textMedium)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Endereço
                  if (appt['address'] != null) ...[
                    _SectionCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InfoIcon(
                              Icons.location_on_outlined, AppColors.error),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Endereço de atendimento',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textMedium)),
                                Text(appt['address']!,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textDark)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Pagamento
                  Builder(builder: (context) {
                    final method = (appt['paymentMethod'] ?? '').toString();
                    final isPix = method == 'pix';
                    // Cartão grava a bandeira (master/visa/...) no campo
                    final methodLabel =
                        isPix ? 'PIX' : (method.isEmpty ? 'Pagamento' : 'Cartão');
                    final icon = isPix ? Icons.pix_rounded : Icons.credit_card_rounded;
                    final iconColor = isPix ? const Color(0xFF00B894) : const Color(0xFF6366F1);

                    // Calcula se D+2 já passou (consulta concluída + 2 dias)
                    bool doisDiasPassaram = false;
                    if (isCompleted) {
                      final completedAtStr = appt['completedAt'] ?? '';
                      DateTime? completedAt;
                      if (completedAtStr.isNotEmpty) {
                        try {
                          completedAt = DateTime.parse(completedAtStr);
                        } catch (_) {}
                      }
                      // Fallback: usa a data da consulta se não tiver completedAt
                      if (completedAt == null) {
                        final dateParts = (appt['date'] ?? '').split('/');
                        if (dateParts.length == 3) {
                          try {
                            completedAt = DateTime(
                              int.parse(dateParts[2]),
                              int.parse(dateParts[1]),
                              int.parse(dateParts[0]),
                            );
                          } catch (_) {}
                        }
                      }
                      if (completedAt != null) {
                        doisDiasPassaram = DateTime.now().isAfter(
                          completedAt.add(const Duration(days: 2)));
                      }
                    }

                    final String paymentLabel;
                    final String? subLabel;
                    final Color subColor;

                    if (!isCompleted && !isConfirmed) {
                      // Pendente ou rejeitado
                      paymentLabel = '$methodLabel — aguardando confirmação';
                      subLabel = null;
                      subColor = Colors.transparent;
                    } else if (isConfirmed) {
                      paymentLabel = '$methodLabel — pagamento confirmado';
                      subLabel = 'Repasse D+2 após conclusão da consulta';
                      subColor = const Color(0xFF22C55E);
                    } else if (doisDiasPassaram) {
                      paymentLabel = '$methodLabel — pagamento realizado';
                      subLabel = 'Repasse concluído';
                      subColor = const Color(0xFF22C55E);
                    } else {
                      paymentLabel = '$methodLabel — pagamento em processamento';
                      subLabel = 'Repasse em até D+2';
                      subColor = const Color(0xFFF59E0B);
                    }

                    return _SectionCard(
                      child: Row(
                        children: [
                          _InfoIcon(icon, iconColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Pagamento',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textMedium)),
                                Text(paymentLabel,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textDark)),
                                if (subLabel != null)
                                  Text(subLabel,
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: subColor)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Botões de ação
          if (isPending && !_expired)
            Container(
              padding: EdgeInsets.fromLTRB(
                  20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _onReject(context),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Recusar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _confirming ? null : () => _onConfirm(),
                      icon: _confirming
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check_rounded, size: 18),
                      label: Text(
                          _confirming ? 'Confirmando...' : 'Confirmar consulta'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF22C55E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (isConfirmed)
            Container(
              padding: EdgeInsets.fromLTRB(
                  20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => Get.toNamed(
                      Routes.prontuarioForm,
                      arguments: {'appt': appt, 'mode': 'create'},
                )?.then((_) => _loadProntuario()),
                    icon: const Icon(Icons.history_edu_rounded, size: 18),
                    label: const Text('Concluir e preencher prontuário'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Voltar sem preencher',
                        style: TextStyle(color: AppColors.textMedium)),
                  ),
                ],
              ),
            ),

          if (isCompleted)
            Container(
              padding: EdgeInsets.fromLTRB(
                  20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: !_prontuarioLoaded
                  ? const SizedBox(
                      height: 48,
                      child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2)))
                  : _prontuarioData == null
                      ? ElevatedButton.icon(
                          onPressed: () => Get.toNamed(
                            Routes.prontuarioForm,
                            arguments: {'appt': appt, 'mode': 'create'},
                      )?.then((_) => _loadProntuario()),
                          icon: const Icon(Icons.history_edu_rounded, size: 18),
                          label: const Text('Preencher prontuário'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () =>
                                  _showProntuarioSheet(context),
                              icon: const Icon(Icons.visibility_rounded,
                                  size: 18),
                              label: const Text('Ver prontuário'),
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => Get.toNamed(
                                      Routes.prontuarioForm,
                                      arguments: {
                                        'appt': appt,
                                        'mode': 'edit',
                                        'prontuario': _prontuarioData,
                                      },
                                )?.then((_) => _loadProntuario()),
                                    icon: const Icon(Icons.edit_rounded,
                                        size: 16),
                                    label: const Text('Editar'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      foregroundColor: AppColors.primary,
                                      side: const BorderSide(
                                          color: AppColors.primary),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => Get.toNamed(
                                      Routes.prontuarioForm,
                                      arguments: {
                                        'appt': appt,
                                        'mode': 'complement',
                                      },
                                )?.then((_) => _loadProntuario()),
                                    icon: const Icon(Icons.add_comment_rounded,
                                        size: 16),
                                    label: const Text('Complemento'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      foregroundColor:
                                          const Color(0xFFF59E0B),
                                      side: const BorderSide(
                                          color: Color(0xFFF59E0B)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
            ),
        ],
      ),
    );
  }

  bool _confirming = false;

  Future<void> _onConfirm() async {
    if (_confirming) return;
    setState(() => _confirming = true);
    try {
      // Espera a escrita real no Firestore antes de mudar a tela — confirmar
      // sem aguardar deixava falhas (permissão, rede) invisíveis: a tela
      // mostrava "Confirmado" mesmo quando nada foi salvo, e a consulta
      // acabava expirando sozinha 30 min depois sem o profissional perceber.
      await ctrl.confirmAppointment(appt['id']!);
      _timer?.cancel();
      if (mounted) setState(() => appt['status'] = 'confirmed');
    } catch (_) {
      if (mounted) {
        Get.snackbar(
          'Não foi possível confirmar',
          'Verifique sua conexão e tente novamente.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          duration: const Duration(seconds: 4),
        );
      }
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  void _showProntuarioSheet(BuildContext context) {
    final p = _prontuarioData ?? {};
    final peso = p['peso']?.toString() ?? '';
    final vacinas =
        List<Map<String, dynamic>>.from(p['vacinas'] ?? []);
    final medicamentos =
        List<Map<String, dynamic>>.from(p['medicamentos'] ?? []);
    final observacoes = p['observacoes']?.toString() ?? '';
    final editedAt = p['editedAt'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    const Icon(Icons.history_edu_rounded,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Prontuário — ${appt['pet']}',
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark),
                          ),
                          if (editedAt != null)
                            const Text(
                              'Editado após envio ao cliente',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFF59E0B),
                                  fontWeight: FontWeight.w600),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (peso.isNotEmpty)
                      _ProSheet('Peso', '$peso kg',
                          Icons.monitor_weight_outlined,
                          AppColors.textMedium),
                    if (vacinas.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _ProSheetTitle('Vacinas aplicadas',
                          Icons.vaccines_outlined,
                          const Color(0xFF22C55E)),
                      ...vacinas.map((v) => Padding(
                            padding:
                                const EdgeInsets.only(top: 6),
                            child: Row(children: [
                              const Icon(
                                  Icons.check_circle_rounded,
                                  size: 14,
                                  color: Color(0xFF22C55E)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(v['nome'] ?? '',
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight:
                                                FontWeight.w600,
                                            color:
                                                AppColors.textDark)),
                                    if ((v['proximaDose'] ?? '')
                                        .isNotEmpty)
                                      Text(
                                          'Próxima dose: ${v['proximaDose']}',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors
                                                  .textMedium)),
                                  ],
                                ),
                              ),
                            ]),
                          )),
                    ],
                    if (medicamentos.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _ProSheetTitle('Medicamentos prescritos',
                          Icons.medication_outlined,
                          const Color(0xFF3B82F6)),
                      ...medicamentos.map((m) => Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6)
                                  .withValues(alpha: 0.06),
                              borderRadius:
                                  BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(m['nome'] ?? '',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textDark)),
                                Text(
                                    [
                                      m['dosagem'],
                                      m['frequencia'],
                                      m['duracao']
                                    ]
                                        .where((x) =>
                                            x != null &&
                                            x.toString().isNotEmpty)
                                        .join(' · '),
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color:
                                            AppColors.textMedium)),
                              ],
                            ),
                          )),
                    ],
                    if (observacoes.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _ProSheetTitle('Observações clínicas',
                          Icons.notes_rounded,
                          const Color(0xFFF59E0B)),
                      const SizedBox(height: 8),
                      Text(observacoes,
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textDark,
                              height: 1.6)),
                    ],
                    if (_complementos.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      _ProSheetTitle('Complementos adicionados',
                          Icons.add_comment_rounded,
                          const Color(0xFF8B5CF6)),
                      ..._complementos.map((c) => Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6)
                                  .withValues(alpha: 0.05),
                              borderRadius:
                                  BorderRadius.circular(10),
                              border: Border.all(
                                  color: const Color(0xFF8B5CF6)
                                      .withValues(alpha: 0.2)),
                            ),
                            child: Text(
                                c['texto']?.toString() ?? '',
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textDark,
                                    height: 1.5)),
                          )),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onReject(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Recusar consulta?',
            style: TextStyle(fontFamily: 'Poppins')),
        content: const Text(
            'O pagamento será estornado ao cliente automaticamente.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancelar',
                  style: TextStyle(color: AppColors.textMedium))),
          ElevatedButton(
            onPressed: () {
              _timer?.cancel();
              ctrl.rejectAppointment(appt['id']!);
              Get.close(2); // fecha dialog + tela de detalhe
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white),
            child: const Text('Recusar'),
          ),
        ],
      ),
    );
  }
}

/// "dd/MM/yyyy" → "Hoje" | "Amanhã" | "dd/MM/yyyy"
String _dateLabel(String date) {
  final p = date.split('/');
  if (p.length < 3) return date.isEmpty ? '—' : date;
  final d = DateTime.tryParse(
      '${p[2]}-${p[1].padLeft(2, '0')}-${p[0].padLeft(2, '0')}');
  if (d == null) return date;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final diff = DateTime(d.year, d.month, d.day).difference(today).inDays;
  if (diff == 0) return 'Hoje';
  if (diff == 1) return 'Amanhã';
  return date;
}

Widget _ProSheet(String title, String value, IconData icon, Color color) {
  return Row(
    children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 8),
      Text('$title: ',
          style:
              TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
      Text(value,
          style: const TextStyle(
              fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w600)),
    ],
  );
}

Widget _ProSheetTitle(String title, IconData icon, Color color) {
  return Row(
    children: [
      Icon(icon, size: 15, color: color),
      const SizedBox(width: 6),
      Text(title,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700, color: color)),
    ],
  );
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: child,
    );
  }
}

class _InfoIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _InfoIcon(this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
