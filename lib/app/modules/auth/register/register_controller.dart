import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_routes.dart';
import '../../../services/taxonomy_service.dart';
import '../../terms/terms_content.dart';
import '../../terms/terms_view.dart';

class RegisterController extends GetxController {
  final currentStep = 0.obs;
  static const totalSteps = 5;

  // Step 1 — Dados pessoais
  final nameCtrl     = TextEditingController();
  final cpfCtrl      = TextEditingController();
  final emailCtrl    = TextEditingController();
  final phoneCtrl    = TextEditingController();
  final passwordCtrl = TextEditingController();
  final obscure      = true.obs;

  // Step 2 — Dados profissionais (multi-categoria)
  final selectedCategories = <String>{}.obs;
  final selectedSpecies    = <String>{}.obs;
  final crmvCtrl = TextEditingController();
  final bioCtrl  = TextEditingController();

  // Vem do TaxonomyService (config/species no Firestore, editável pelo
  // painel admin) — sem lista fixa aqui.
  List<(String, String, String)> get allSpecies => Get.find<TaxonomyService>()
      .species
      .map((s) => (s.key, s.emoji, s.label))
      .toList();

  void toggleSpecies(String key) {
    if (selectedSpecies.contains(key)) {
      selectedSpecies.remove(key);
    } else {
      selectedSpecies.add(key);
    }
  }

  // Vem do TaxonomyService (config/specialties no Firestore) — sem lista
  // fixa aqui. defaultServices abaixo continua com chaves fixas de
  // propósito: são só sugestões de preenchimento, uma categoria nova sem
  // entrada aqui simplesmente começa sem sugestão (nada quebra).
  List<String> get categories => Get.find<TaxonomyService>().specialtyValues;

  static const defaultServices = <String, List<Map<String, String>>>{
    'Clínica Geral': [
      {'name': 'Consulta clínica', 'price': '', 'unit': 'consulta'},
      {'name': 'Check-up anual',   'price': '', 'unit': 'consulta'},
      {'name': 'Retorno',          'price': '', 'unit': 'consulta'},
    ],
    'Vacinação': [
      {'name': 'V8',              'price': '', 'unit': 'dose'},
      {'name': 'V10',             'price': '', 'unit': 'dose'},
      {'name': 'Antirrábica',     'price': '', 'unit': 'dose'},
      {'name': 'Tríplice felina', 'price': '', 'unit': 'dose'},
    ],
    'Acupuntura': [
      {'name': 'Sessão avulsa',         'price': '', 'unit': 'sessão'},
      {'name': 'Pacote 5 sessões',      'price': '', 'unit': 'pacote'},
      {'name': 'Avaliação integrativa', 'price': '', 'unit': 'consulta'},
    ],
    'Fisioterapia': [
      {'name': 'Sessão avulsa',    'price': '', 'unit': 'sessão'},
      {'name': 'Pacote 5 sessões', 'price': '', 'unit': 'pacote'},
      {'name': 'Avaliação',        'price': '', 'unit': 'consulta'},
    ],
    'Adestramento': [
      {'name': 'Sessão porte P', 'price': '', 'unit': 'hora'},
      {'name': 'Sessão porte M', 'price': '', 'unit': 'hora'},
      {'name': 'Sessão porte G', 'price': '', 'unit': 'hora'},
    ],
    'Banho & Tosa': [
      {'name': 'Banho porte P',  'price': '', 'unit': 'serviço'},
      {'name': 'Banho porte M',  'price': '', 'unit': 'serviço'},
      {'name': 'Banho porte G',  'price': '', 'unit': 'serviço'},
      {'name': 'Tosa higiênica', 'price': '', 'unit': 'serviço'},
    ],
  };

  void toggleCategory(String cat) {
    if (selectedCategories.contains(cat)) {
      selectedCategories.remove(cat);
      services.removeWhere((s) => s['_category'] == cat);
    } else {
      selectedCategories.add(cat);
      final defaults = defaultServices[cat] ?? [];
      for (final d in defaults) {
        services.add({...d, '_category': cat});
      }
    }
  }

  // Step 3 — Serviços
  final services = <Map<String, String>>[].obs;
  final serviceNameCtrl  = TextEditingController();
  final serviceDescCtrl  = TextEditingController();
  final servicePriceCtrl = TextEditingController();
  final serviceUnit      = 'consulta'.obs;

  static const units = ['consulta', 'sessão', 'hora', 'dose', 'serviço', 'pacote'];

  void addService() {
    final name  = serviceNameCtrl.text.trim();
    final price = servicePriceCtrl.text.trim();
    if (name.isEmpty || price.isEmpty) return;
    services.add({
      'name':  name,
      'desc':  serviceDescCtrl.text.trim(),
      'price': price,
      'unit':  serviceUnit.value,
    });
    serviceNameCtrl.clear();
    serviceDescCtrl.clear();
    servicePriceCtrl.clear();
  }

  void removeService(int index) => services.removeAt(index);

  void updateServiceName(int index, String value) {
    final s = Map<String, String>.from(services[index]);
    s['name'] = value;
    services[index] = s;
  }

  void updateServicePrice(int index, String value) {
    final s = Map<String, String>.from(services[index]);
    s['price'] = value;
    services[index] = s;
  }

  // Step 4 — Disponibilidade
  final selectedDays   = <String>{}.obs;
  final availableTimes = <String>[].obs;

  static const allDays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab', 'Dom'];
  static const periods = [
    ('Manhã', ['07:00','08:00','09:00','10:00','11:00']),
    ('Tarde', ['12:00','13:00','14:00','15:00','16:00','17:00']),
    ('Noite', ['18:00','19:00','20:00','21:00']),
  ];

  void toggleDay(String day) {
    if (selectedDays.contains(day)) {
      selectedDays.remove(day);
    } else {
      selectedDays.add(day);
    }
  }

  void toggleTime(String time) {
    if (availableTimes.contains(time)) {
      availableTimes.remove(time);
    } else {
      availableTimes.add(time);
    }
  }

  // Step 5 — Documentos e endereço
  final cepCtrl          = TextEditingController();
  final streetCtrl       = TextEditingController();
  final numberCtrl       = TextEditingController();
  final complementCtrl   = TextEditingController();
  final neighborhoodCtrl = TextEditingController();
  final cityCtrl         = TextEditingController();
  final stateCtrl        = TextEditingController();

  // Chave PIX
  final pixKeyCtrl  = TextEditingController();
  final pixKeyType  = 'CPF'.obs;
  static const pixKeyTypes = ['CPF', 'CNPJ', 'Celular', 'E-mail', 'Chave aleatória'];

  final docIdentityUploaded = false.obs;
  final docCrmvUploaded     = false.obs;
  final termsAccepted       = false.obs;

  void simulateUpload(String docType) {
    if (docType == 'identity') {
      docIdentityUploaded.value = true;
    } else {
      docCrmvUploaded.value = true;
    }
    _snack(
      title: 'Documento enviado',
      message: 'Será analisado em até 24h.',
      icon: Icons.check_circle_outline,
      color: const Color(0xFF22C55E),
    );
  }

  // Navegação
  void nextStep() async {
    if (!_validateStep()) return;
    if (currentStep.value < totalSteps - 1) {
      currentStep.value++;
    } else {
      // Aceite dos termos obrigatório antes de criar a conta
      final accepted = await Get.to<bool>(
            () => TermsView(
              onAccept: () => Get.back(result: true),
              onDecline: () => Get.back(result: false),
            ),
            fullscreenDialog: true,
          ) ??
          false;
      if (!accepted) return;
      _submit();
    }
  }

  void prevStep() {
    if (currentStep.value > 0) currentStep.value--;
  }

  bool _validateStep() {
    switch (currentStep.value) {
      case 0:
        if (nameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty ||
            passwordCtrl.text.isEmpty) {
          _warn('Preencha todos os campos obrigatórios');
          return false;
        }
      case 1:
        if (selectedCategories.isEmpty) {
          _warn('Selecione pelo menos uma categoria');
          return false;
        }
      case 2:
        if (services.isEmpty) {
          _warn('Adicione pelo menos um serviço');
          return false;
        }
      case 3:
        if (selectedDays.isEmpty || availableTimes.isEmpty) {
          _warn('Selecione dias e horários disponíveis');
          return false;
        }
      case 4:
        if (cepCtrl.text.trim().isEmpty || streetCtrl.text.trim().isEmpty ||
            numberCtrl.text.trim().isEmpty) {
          _warn('Preencha o endereço completo');
          return false;
        }
        if (!termsAccepted.value) {
          _warn('Aceite os Termos de Uso para continuar');
          return false;
        }
    }
    return true;
  }

  void _warn(String message) {
    _snack(
      title: 'Atenção',
      message: message,
      icon: Icons.info_outline_rounded,
      color: const Color(0xFFF59E0B),
    );
  }

  void _snack({
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

  Future<void> _submit() async {
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: passwordCtrl.text,
      );
      final uid = credential.user!.uid;
      await credential.user?.updateDisplayName(nameCtrl.text.trim());
      // Salva perfil do profissional no Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': nameCtrl.text.trim(),
        'email': emailCtrl.text.trim(),
        'role': 'professional',
        'phone': phoneCtrl.text.trim(),
        'crmv': crmvCtrl.text.trim(),
        'bio': bioCtrl.text.trim(),
        'categories': selectedCategories.toList(),
        'services': services.map((s) => {
          'name': s['name'],
          'price': s['price'],
          'unit': s['unit'],
        }).toList(),
        'availableDays': selectedDays.toList(),
        'availableTimes': availableTimes.toList(),
        'address': {
          'cep': cepCtrl.text.trim(),
          'street': streetCtrl.text.trim(),
          'number': numberCtrl.text.trim(),
          'complement': complementCtrl.text.trim(),
          'neighborhood': neighborhoodCtrl.text.trim(),
          'city': cityCtrl.text.trim(),
          'state': stateCtrl.text.trim(),
        },
        'animalSpecies': selectedSpecies.toList(),
        'pixKeys': pixKeyCtrl.text.trim().isNotEmpty
            ? [{'type': pixKeyType.value, 'key': pixKeyCtrl.text.trim()}]
            : [],
        'accountStatus': 'pending',
        'termos_aceitos': true,
        'termos_aceitos_em': FieldValue.serverTimestamp(),
        'termos_versao': termsVersion,
        'createdAt': FieldValue.serverTimestamp(),
      });
      Get.offAllNamed(Routes.home, arguments: {'services': services.toList()});
      // Novo cadastro: abre a definição da área de atuação por cima da home,
      // essencial para o profissional aparecer nas buscas dos tutores.
      Get.toNamed(Routes.serviceArea);
    } on FirebaseAuthException catch (e) {
      _snack(
        title: 'Erro no cadastro',
        message: _mapFirebaseError(e),
        icon: Icons.error_outline_rounded,
        color: const Color(0xFFEA4335),
      );
    } catch (_) {
      _snack(
        title: 'Erro',
        message: 'Sem conexão. Verifique sua internet.',
        icon: Icons.wifi_off_rounded,
        color: const Color(0xFFEA4335),
      );
    }
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado.';
      case 'weak-password':
        return 'A senha deve ter pelo menos 6 caracteres.';
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'network-request-failed':
        return 'Sem conexão. Verifique sua internet.';
      default:
        return 'Ocorreu um erro. Tente novamente.';
    }
  }

  @override
  void onClose() {
    for (final c in [
      nameCtrl, cpfCtrl, emailCtrl, phoneCtrl, passwordCtrl,
      crmvCtrl, bioCtrl, serviceNameCtrl, serviceDescCtrl, servicePriceCtrl,
      cepCtrl, streetCtrl, numberCtrl, complementCtrl,
      neighborhoodCtrl, cityCtrl, stateCtrl, pixKeyCtrl,
    ]) {
      c.dispose();
    }
    super.onClose();
  }
}
