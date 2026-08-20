import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/service_area_model.dart';
import '../../routes/app_routes.dart';
import '../../services/notification_service.dart';
import 'package:flutter/material.dart'
    show
      BoxDecoration,
      BoxShadow,
      BoxShape,
      Color,
      Colors,
      Container,
      EdgeInsets,
      Icon,
      IconData,
      Icons,
      Offset;
import 'package:get/get.dart';

class HomeController extends GetxController {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final currentTab = 0.obs;

  // Dados do profissional carregados do Firestore
  final professionalName = ''.obs;
  final professionalPhotoUrl = ''.obs;
  final professionalEmail = ''.obs;
  final professionalPhone = ''.obs;
  final professionalCrmv = ''.obs;
  final professionalBio = ''.obs;
  final professionalCategories = <String>[].obs;
  final professionalDays = <String>[].obs;
  final professionalTimes = <String>[].obs;
  final animalSpecies = <String>[].obs;
  final isLoadingProfile = true.obs;
  final isLoadingData = true.obs;

  final upcomingAppointments = <Map<String, String>>[].obs;
  final allAppointments = <Map<String, String>>[].obs; // todos, para o calendário

  // Status da conta: 'pending' | 'active' | 'suspended'
  final accountStatus = 'pending'.obs;

  // Recebimento de novos pedidos pausado a pedido do próprio profissional
  // (não confundir com accountStatus/blocked, que são controlados pelo admin).
  final isAvailable = true.obs;

  Future<void> toggleAvailability() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final next = !isAvailable.value;
    isAvailable.value = next; // otimista: instantâneo na UI
    try {
      await _firestore.collection('users').doc(uid).update({'isAvailable': next});
    } catch (_) {
      isAvailable.value = !next; // desfaz se a escrita falhar
      snack(
        title: 'Não foi possível atualizar',
        message: 'Verifique sua conexão e tente novamente.',
        icon: Icons.error_outline_rounded,
        color: const Color(0xFFEF4444),
      );
    }
  }

  // Serviços do profissional
  final services = <Map<String, String>>[].obs;

  Future<void> addService(String name, String price, String unit) async {
    services.add({'name': name, 'price': price, 'unit': unit});
    await _saveServices();
  }

  Future<void> removeService(int index) async {
    services.removeAt(index);
    await _saveServices();
  }

  Future<void> _saveServices() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).update({
      'services': services.toList(),
    });
  }

  // Chaves PIX
  final pixKeys = <Map<String, String>>[].obs;

  // Área de atuação (resumo exibido no perfil; vazio = não configurada)
  final areaAtuacaoResumo = ''.obs;

  Future<void> reloadAreaAtuacao() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final area = AreaAtuacao.fromMap(
          (doc.data()?['area_atuacao'] as Map?)?.cast<String, dynamic>());
      areaAtuacaoResumo.value = area.isEmpty ? '' : area.resumo;
    } catch (_) {}
  }

  Future<void> updateProfile({
    required String name,
    required String phone,
    required String bio,
    required String crmv,
    List<String>? species,
    List<String>? categories,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).update({
      'name': name,
      'phone': phone,
      'bio': bio,
      'crmv': crmv,
      if (species != null) 'animalSpecies': species,
      if (categories != null) 'categories': categories,
    });
    if (name.isNotEmpty) await _auth.currentUser?.updateDisplayName(name);
    professionalName.value = name;
    professionalPhone.value = phone;
    professionalBio.value = bio;
    professionalCrmv.value = crmv;
    if (species != null) animalSpecies.value = species;
    if (categories != null) professionalCategories.value = categories;
  }

  final isUploadingPhoto = false.obs;

  Future<void> pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 256,
      maxHeight: 256,
      imageQuality: 75,
    );
    if (picked == null) return;

    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    isUploadingPhoto.value = true;
    try {
      final bytes = await File(picked.path).readAsBytes();
      final base64Str = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      await _firestore.collection('users').doc(uid).update({'photoBase64': base64Str});
      professionalPhotoUrl.value = base64Str;
      snack(
        title: 'Foto atualizada',
        message: 'Sua foto de perfil foi salva.',
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF22C55E),
      );
    } catch (_) {
      snack(
        title: 'Erro',
        message: 'Não foi possível salvar a foto.',
        icon: Icons.error_outline_rounded,
        color: const Color(0xFFEF4444),
      );
    } finally {
      isUploadingPhoto.value = false;
    }
  }

  // ── Documentos (RG/CNH, CRMV) — verificados no painel admin ────────
  // status por tipo: '' (não enviado) | submitted | approved | rejected
  final docStatuses = <String, String>{}.obs;
  final isUploadingDoc = false.obs;

  void _listenDocuments() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    _firestore
        .collection('users').doc(uid).collection('documents')
        .snapshots()
        .listen((snap) {
      final map = <String, String>{};
      for (final doc in snap.docs) {
        map[doc.id] = doc.data()['status'] as String? ?? 'submitted';
      }
      docStatuses.assignAll(map);
    });
  }

  /// Envia foto do documento (docType: 'rg' | 'crmv') via câmera/galeria.
  Future<void> uploadDocument(String docType, ImageSource source) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1280,
      imageQuality: 70,
    );
    if (picked == null) return;
    isUploadingDoc.value = true;
    try {
      final bytes = await File(picked.path).readAsBytes();
      await _firestore
          .collection('users').doc(uid)
          .collection('documents').doc(docType)
          .set({
        'image': 'data:image/jpeg;base64,${base64Encode(bytes)}',
        'status': 'submitted',
        'sentAt': FieldValue.serverTimestamp(),
      });
      snack(
        title: 'Documento enviado',
        message: 'Será analisado pela nossa equipe em até 24h.',
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF22C55E),
      );
    } catch (_) {
      snack(
        title: 'Erro',
        message: 'Não foi possível enviar. Tente novamente.',
        icon: Icons.error_outline_rounded,
        color: const Color(0xFFEF4444),
      );
    } finally {
      isUploadingDoc.value = false;
    }
  }

  Future<void> addPixKey(String type, String key) async {
    pixKeys.add({'type': type, 'key': key});
    await _savePixKeys();
  }

  Future<void> removePixKey(int index) async {
    pixKeys.removeAt(index);
    await _savePixKeys();
  }

  Future<void> _savePixKeys() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).update({
      'pixKeys': pixKeys.toList(),
    });
  }

  // ── Taxa regressiva por volume ─────────────────────────────────────
  // Consultas concluídas E pagas no mês anterior definem a taxa do mês
  // atual. Faixas vêm de config/fees (editável no painel admin) — a
  // dailyPayouts lê o mesmo doc, então app e repasse ficam sincronizados.
  final paidLastMonth = 0.obs; // define a taxa deste mês
  final paidThisMonth = 0.obs; // define a taxa do mês que vem

  // Faixas ordenadas por min crescente; default = fallback da function
  final feeTiers = <Map<String, int>>[
    {'min': 0, 'pct': 15},
    {'min': 10, 'pct': 12},
    {'min': 20, 'pct': 10},
  ].obs;

  // Isenção/taxa personalizada definida no painel (prazo opcional)
  final feeOverride = RxnInt();
  final feeOverrideUntil = Rxn<DateTime>();

  bool get hasActiveOverride =>
      feeOverride.value != null &&
      (feeOverrideUntil.value == null ||
          DateTime.now().isBefore(feeOverrideUntil.value!));

  int feePercentFor(int completed) {
    var pct = feeTiers.first['pct']!;
    for (final t in feeTiers) {
      if (completed >= t['min']!) pct = t['pct']!;
    }
    return pct;
  }

  int get currentFeePercent => hasActiveOverride
      ? feeOverride.value!
      : feePercentFor(paidLastMonth.value);

  /// Próxima meta de consultas deste mês (null = já está na taxa mínima)
  int? get nextTierTarget {
    for (final t in feeTiers) {
      if (paidThisMonth.value < t['min']!) return t['min'];
    }
    return null;
  }

  /// Taxa que o vet garante no mês que vem se bater a próxima meta
  int get nextTierPercent {
    for (final t in feeTiers) {
      if (paidThisMonth.value < t['min']!) return t['pct']!;
    }
    return feeTiers.last['pct']!;
  }

  /// Rótulo das faixas para o card, ex.: "1–9 → 15% · 10–19 → 12% · 20+ → 10%"
  String get tiersLabel {
    final parts = <String>[];
    for (var i = 0; i < feeTiers.length; i++) {
      final min = feeTiers[i]['min']!;
      final pct = feeTiers[i]['pct']!;
      final isLast = i == feeTiers.length - 1;
      final start = min == 0 ? 1 : min;
      final label = isLast
          ? '$start+'
          : '$start–${feeTiers[i + 1]['min']! - 1}';
      parts.add('$label → $pct%');
    }
    return parts.join(' · ');
  }

  Future<void> _loadFeeConfig(Map<String, dynamic> userData) async {
    try {
      final cfg = await _firestore.collection('config').doc('fees').get();
      final raw = cfg.data()?['tiers'] as List?;
      if (raw != null && raw.isNotEmpty) {
        final tiers = raw
            .map((t) => {
                  'min': ((t['min'] ?? 0) as num).toInt(),
                  'pct': ((t['pct'] ?? 15) as num).toInt(),
                })
            .toList()
          ..sort((a, b) => a['min']!.compareTo(b['min']!));
        feeTiers.assignAll(tiers);
      }
    } catch (_) {}
    feeOverride.value = (userData['feeOverride'] as num?)?.toInt();
    final ts = userData['feeOverrideUntil'];
    feeOverrideUntil.value = ts is Timestamp ? ts.toDate() : null;
  }

  final weekEarnings = 0.0.obs;
  final monthEarnings = 0.0.obs;
  final pendingEarnings = 0.0.obs;
  final weekCount = 0.obs;
  final monthCount = 0.obs;
  final pendingCount = 0.obs;
  final rating = 0.0.obs;
  final totalReviews = 0.obs;
  final recentTransactions = <Map<String, dynamic>>[].obs;
  final weekTransactions = <Map<String, dynamic>>[].obs;
  final monthTransactions = <Map<String, dynamic>>[].obs;
  final pendingTransactions = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    // Aguarda o uid estar disponível antes de iniciar as notificações
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        Future.delayed(const Duration(seconds: 1), () => NotificationService.init());
      } else {
        NotificationService.dispose();
      }
    });
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null && args['services'] != null) {
      services.assignAll(
          List<Map<String, String>>.from(
              (args['services'] as List).map((e) => Map<String, String>.from(e))));
    }
    _loadProfile();
    _listenAppointments();
    _listenDocuments();

    // Deep-link: push chegou antes deste controller existir
    final pendingId = NotificationService.pendingAppointmentId;
    if (pendingId != null) {
      NotificationService.pendingAppointmentId = null;
      openAppointmentDetail(pendingId);
    }
  }

  double _parseValue(String s) {
    final cleaned = s
        .replaceAll('R\$', '')
        .replaceAll(' ', '')
        .replaceAll('.', '')
        .replaceAll(',', '.');
    return double.tryParse(cleaned) ?? 0;
  }

  // "23/06/2026" → DateTime
  DateTime? _parseApptDate(String s) {
    final p = s.split('/');
    if (p.length < 3) return null;
    return DateTime.tryParse('${p[2]}-${p[1].padLeft(2, '0')}-${p[0].padLeft(2, '0')}');
  }

  // "recebido" = completado há mais de 2 dias
  // "a_receber" = confirmado (futuro) OU completado nos últimos 2 dias (D+2)
  String _txStatus(String status, DateTime? apptDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (status == 'confirmed') return 'a_receber';
    if (status == 'completed') {
      if (apptDate == null) return 'recebido';
      final diff = today.difference(DateTime(apptDate.year, apptDate.month, apptDate.day)).inDays;
      return diff <= 2 ? 'a_receber' : 'recebido';
    }
    return 'outro';
  }

  Map<String, dynamic> _buildTx(String id, Map<String, dynamic> d, DateTime? apptDate) {
    final status = d['status'] as String? ?? '';
    return {
      'id': id,
      'name': '${d['serviceName'] ?? ''} · ${d['petName'] ?? ''}',
      'serviceName': d['serviceName'] ?? '',
      'date': d['date'] ?? '',
      'time': d['time'] ?? '',
      'value': d['value'] ?? '',
      'valueNum': _parseValue(d['value']?.toString() ?? ''),
      'status': status,
      'txStatus': _txStatus(status, apptDate),
    };
  }

  void _listenAppointments() {
    _firestore
        .collection('appointments')
        .where('vetName', isEqualTo: _auth.currentUser?.displayName ?? '')
        .snapshots()
        .listen((snap) {
      final docs = snap.docs.toList()
        ..sort((a, b) {
          final at = a.data()['createdAt'];
          final bt = b.data()['createdAt'];
          if (at == null || bt == null) return 0;
          return bt.compareTo(at);
        });

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      // "Semana" = janela móvel dos últimos 7 dias (hoje incluso)
      final weekStart = today.subtract(const Duration(days: 6));
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 1);
      final lookback30 = today.subtract(const Duration(days: 30));

      final prevMonthStart = DateTime(now.year, now.month - 1, 1);

      double wEarnings = 0, mEarnings = 0, pEarnings = 0;
      int wCount = 0, mCount = 0, pCount = 0;
      int paidLast = 0, paidThis = 0;
      double ratingSum = 0;
      int ratingCount = 0;

      final allTx = <Map<String, dynamic>>[];
      final wTx = <Map<String, dynamic>>[];
      final mTx = <Map<String, dynamic>>[];
      final pTx = <Map<String, dynamic>>[];

      // 1ª passada: conta consultas pagas por mês para definir a taxa vigente
      for (final doc in docs) {
        final d = doc.data();
        if (d['status'] != 'completed' ||
            d['paymentStatus'] != 'approved') continue;
        final apptDate = _parseApptDate(d['date'] ?? '');
        if (apptDate == null) continue;
        if (!apptDate.isBefore(prevMonthStart) &&
            apptDate.isBefore(monthStart)) paidLast++;
        if (!apptDate.isBefore(monthStart) &&
            apptDate.isBefore(monthEnd)) paidThis++;
      }
      final feePct =
          hasActiveOverride ? feeOverride.value! : feePercentFor(paidLast);

      // 2ª passada: soma valores LÍQUIDOS (o que o vet de fato recebe).
      // Repasses já processados usam o payoutNet exato; futuros são
      // estimados com a taxa vigente.
      for (final doc in docs) {
        final d = doc.data();
        final status = d['status'] as String? ?? '';
        final value = _parseValue(d['value']?.toString() ?? '');
        final apptDate = _parseApptDate(d['date'] ?? '');

        final payoutNet = (d['payoutNet'] as num?)?.toDouble();
        final net = payoutNet ?? value * (1 - feePct / 100);
        final tx = _buildTx(doc.id, d, apptDate);
        tx['gross'] = value;
        tx['net'] = net;
        tx['feePct'] = payoutNet != null && value > 0
            ? ((value - net) / value * 100).round()
            : feePct;

        // Esta semana / Este mês: conta todos completados no período
        if (status == 'completed' && apptDate != null) {
          if (!apptDate.isBefore(weekStart) && apptDate.isBefore(today.add(const Duration(days: 1)))) {
            wEarnings += net;
            wCount++;
            wTx.add(tx);
          }
          if (!apptDate.isBefore(monthStart) && apptDate.isBefore(monthEnd)) {
            mEarnings += net;
            mCount++;
            mTx.add(tx);
          }
        }

        // A receber: confirmados (futuros) + completados D+2 (últimos 2 dias)
        final isAReceber = tx['txStatus'] == 'a_receber';
        if (isAReceber && (apptDate == null || !apptDate.isBefore(lookback30))) {
          pEarnings += net;
          pCount++;
          pTx.add(tx);
        }

        final r = d['rating'];
        if (r != null) {
          ratingSum += (r as num).toDouble();
          ratingCount++;
        }

        if (allTx.length < 30 &&
            status != 'cancelled' &&
            status != 'rejected') allTx.add(tx);
      }

      paidLastMonth.value = paidLast;
      paidThisMonth.value = paidThis;
      weekEarnings.value = wEarnings;
      monthEarnings.value = mEarnings;
      pendingEarnings.value = pEarnings;
      weekCount.value = wCount;
      monthCount.value = mCount;
      pendingCount.value = pCount;
      rating.value = ratingCount > 0
          ? double.parse((ratingSum / ratingCount).toStringAsFixed(1))
          : 0.0;
      totalReviews.value = ratingCount;
      recentTransactions.value = allTx;
      weekTransactions.value = wTx;
      monthTransactions.value = mTx;
      pendingTransactions.value = pTx;

      // Próximos atendimentos: pendentes ou confirmados, data hoje em diante
      final upcoming = docs.where((doc) {
        final d = doc.data();
        final status = d['status'] as String? ?? '';
        if (status != 'pending_confirmation' && status != 'confirmed') return false;
        final apptDate = _parseApptDate(d['date'] ?? '');
        if (apptDate == null) return true;
        return !apptDate.isBefore(today);
      }).map((doc) => _apptToMap(doc.id, doc.data())).toList();

      // Ordena por data ASC, depois hora ASC
      upcoming.sort((a, b) {
        final da = _parseApptDate(a['date'] ?? '');
        final db = _parseApptDate(b['date'] ?? '');
        if (da == null && db == null) return (a['time'] ?? '').compareTo(b['time'] ?? '');
        if (da == null) return 1;
        if (db == null) return -1;
        final dateCmp = da.compareTo(db);
        if (dateCmp != 0) return dateCmp;
        return (a['time'] ?? '').compareTo(b['time'] ?? '');
      });

      upcomingAppointments.value = upcoming;

      // Todos os agendamentos (para o calendário e histórico)
      allAppointments.value =
          docs.map((doc) => _apptToMap(doc.id, doc.data())).toList();

      isLoadingData.value = false;
    });
  }

  // Monta o Map<String,String> usado pelas telas a partir do doc bruto do
  // Firestore. Centralizado aqui (antes duplicado em 2 pontos) para não
  // divergir — inclusive corrige um bug real: completedAt/createdAt são
  // Timestamp no Firestore, e `.toString()` direto produz algo ilegível
  // tipo "Timestamp(seconds=..., nanoseconds=...)"; convertemos para ISO8601.
  Map<String, String> _apptToMap(String id, Map<String, dynamic> d) {
    final completedAt = d['completedAt'];
    final createdAt = d['createdAt'];
    return <String, String>{
      'id': id,
      'time': d['time'] ?? '',
      'pet': d['petName'] ?? '',
      'petBreed': d['petBreed'] ?? '',
      'petSpecies': d['petSpecies'] ?? 'dog',
      'petSex': d['petSex'] ?? '',
      'petAge': d['petAge'] ?? '',
      'petCastrated': d['petCastrated']?.toString() ?? 'false',
      'owner': d['tutorName'] ?? '',
      'clientPhone': '',
      'service': d['serviceName'] ?? '',
      'value': d['value'] ?? '',
      'address': d['address'] ?? '',
      'date': d['date'] ?? '',
      'status': d['status'] ?? 'pending_confirmation',
      'rating': d['rating']?.toString() ?? '',
      'comment': d['comment'] ?? '',
      'paymentMethod': d['paymentMethod'] ?? 'card',
      'paymentStatus': d['paymentStatus'] ?? '',
      'completedAt':
          completedAt is Timestamp ? completedAt.toDate().toIso8601String() : '',
      'createdAt':
          createdAt is Timestamp ? createdAt.toDate().toIso8601String() : '',
    };
  }

  // Deep-link do push: busca o doc direto por id (não depende do listener
  // por vetName) e abre a tela de detalhe.
  Future<void> openAppointmentDetail(String id) async {
    try {
      final doc = await _firestore.collection('appointments').doc(id).get();
      if (!doc.exists) return;
      await Get.toNamed(Routes.appointmentDetail,
          arguments: _apptToMap(doc.id, doc.data()!));
    } catch (_) {}
  }

  Future<void> _loadProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) { isLoadingProfile.value = false; return; }
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data() ?? {};
      professionalName.value = data['name'] ?? _auth.currentUser?.displayName ?? '';
      professionalPhotoUrl.value = data['photoBase64'] ?? data['photoUrl'] ?? _auth.currentUser?.photoURL ?? '';
      professionalEmail.value = data['email'] ?? _auth.currentUser?.email ?? '';
      professionalPhone.value = data['phone'] ?? '';
      professionalCrmv.value = data['crmv'] ?? '';
      professionalBio.value = data['bio'] ?? '';
      professionalCategories.value = List<String>.from(data['categories'] ?? []);
      animalSpecies.value = List<String>.from(data['animalSpecies'] ?? []);
      professionalDays.value = List<String>.from(data['availableDays'] ?? []);
      professionalTimes.value = List<String>.from(data['availableTimes'] ?? []);

      // Área de atuação (resumo para o card do perfil)
      final area = AreaAtuacao.fromMap(
          (data['area_atuacao'] as Map?)?.cast<String, dynamic>());
      areaAtuacaoResumo.value = area.isEmpty ? '' : area.resumo;

      // Carrega chaves PIX
      final keys = List<Map<String, dynamic>>.from(data['pixKeys'] ?? []);
      pixKeys.value = keys.map((k) => {
        'type': k['type']?.toString() ?? '',
        'key': k['key']?.toString() ?? '',
      }).toList();

      // Carrega serviços se não vieram via arguments
      if (services.isEmpty && data['services'] != null) {
        final srvs = List<Map<String, dynamic>>.from(data['services']);
        services.assignAll(srvs.map((s) => {
          'name': s['name']?.toString() ?? '',
          'price': s['price']?.toString() ?? '',
          'unit': s['unit']?.toString() ?? '',
        }).toList());
      }

      if (data['accountStatus'] != null) {
        accountStatus.value = data['accountStatus'];
      }
      isAvailable.value = data['isAvailable'] != false;

      await _loadFeeConfig(data);
    } catch (_) {
      professionalName.value = _auth.currentUser?.displayName ?? '';
      professionalEmail.value = _auth.currentUser?.email ?? '';
    } finally {
      isLoadingProfile.value = false;
    }
  }

  void changeTab(int index) => currentTab.value = index;

  Future<void> confirmAppointment(String id) async {
    final doc = await _firestore.collection('appointments').doc(id).get();
    final d = doc.data() ?? {};
    final updates = <String, dynamic>{
      'status': 'confirmed',
      // Prazo de pagamento: cancelUnpaid (function) cancela após 12h sem pagar
      'confirmedAt': FieldValue.serverTimestamp(),
    };
    // Agendamentos já pagos (ex.: portal web, onde o PIX é pago antes da
    // confirmação) chegam com paymentStatus 'approved' — as regras do
    // Firestore bloqueiam qualquer alteração desse campo pelo cliente, então
    // só definimos 'pending_payment' quando o pagamento ainda não ocorreu.
    if (d['paymentStatus'] != 'approved') {
      updates['paymentStatus'] = 'pending_payment';
    }
    await _firestore.collection('appointments').doc(id).update(updates);
    final tutorId = d['tutorId'] as String?;
    if (tutorId != null) {
      await NotificationService.sendTo(
        toUid: tutorId,
        title: '✅ Consulta confirmada!',
        body: '${professionalName.value} confirmou a consulta de ${d['petName'] ?? 'seu pet'}. Você tem 12 horas para efetuar o pagamento e garantir seu horário — depois disso a consulta é cancelada automaticamente.',
      );
    }
    snack(
      title: 'Consulta confirmada!',
      message: 'O tutor foi notificado para efetuar o pagamento.',
      icon: Icons.check_circle_rounded,
      color: const Color(0xFF22C55E),
    );
  }

  Future<void> rejectAppointment(String id) async {
    final doc = await _firestore.collection('appointments').doc(id).get();
    final d = doc.data() ?? {};
    await _firestore.collection('appointments').doc(id).update({
      'status': 'rejected',
      'rejectedAt': FieldValue.serverTimestamp(),
    });
    final tutorId = d['tutorId'] as String?;
    if (tutorId != null) {
      await NotificationService.sendTo(
        toUid: tutorId,
        title: 'Consulta não confirmada',
        body: '${professionalName.value} não pôde confirmar a consulta de ${d['petName'] ?? 'seu pet'}. Busque outro profissional.',
      );
    }
    snack(
      title: 'Consulta recusada',
      message: 'O cliente foi notificado.',
      icon: Icons.cancel_rounded,
      color: const Color(0xFFEF4444),
    );
  }

  Future<void> cancelAppointment(String id) async {
    await _firestore.collection('appointments').doc(id).update({
      'status': 'cancelled',
      'cancelledBy': 'profissional',
      'cancelledAt': FieldValue.serverTimestamp(),
    });
    snack(
      title: 'Atendimento cancelado',
      message: 'A consulta foi cancelada da agenda.',
      icon: Icons.event_busy_rounded,
      color: const Color(0xFF6B7280),
    );
  }

  void snack({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.white,
      colorText: const Color(0xFF111827),
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      duration: const Duration(seconds: 3),
      icon: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Future<void> completeAppointment(String id) async {
    final doc = await _firestore.collection('appointments').doc(id).get();
    final d = doc.data() ?? {};
    await _firestore.collection('appointments').doc(id).update({
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
    });
    // Notifica o próprio veterinário sobre o repasse D+2
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await NotificationService.sendTo(
        toUid: uid,
        title: '💰 Pagamento confirmado!',
        body: 'O valor da consulta de ${d['petName'] ?? 'seu pet'} será repassado em até 2 dias úteis.',
      );
    }
    // Notifica o tutor que a consulta foi concluída
    final tutorId = d['tutorId'] as String?;
    if (tutorId != null) {
      await NotificationService.sendTo(
        toUid: tutorId,
        title: '🐾 Consulta concluída!',
        body: 'A consulta de ${d['petName'] ?? 'seu pet'} foi concluída. Que tal avaliar o atendimento?',
      );
    }
    snack(
      title: 'Atendimento concluído',
      message: 'O pagamento será repassado em D+2.',
      icon: Icons.check_circle_rounded,
      color: const Color(0xFF22C55E),
    );
  }
}
