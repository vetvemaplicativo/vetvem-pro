import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../routes/app_routes.dart';

/// Quem entra com Google/Apple pula o cadastro em passos e cai numa conta "em análise" sem dados.
/// Este gate detecta o perfil incompleto (pendente e sem categorias/serviços) e leva a pessoa ao
/// cadastro em passos (modo "social": sem e-mail/senha, grava na conta que já existe).
class ProfileGate {
  static Future<bool> needsRegistration() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    try {
      final d = (await FirebaseFirestore.instance.collection('users').doc(uid).get()).data();
      if (d == null || d['role'] != 'professional') return false;
      if (d['accountStatus'] != 'pending') return false; // aprovados/bloqueados nunca são redirecionados
      bool empty(dynamic v) => v == null || (v is Iterable && v.isEmpty) || (v is String && v.isEmpty);
      return empty(d['categories']) && empty(d['services']) && empty(d['specialty']);
    } catch (_) {
      return false; // sem rede: não bloqueia
    }
  }

  /// Destino depois do login/abertura: cadastro em passos (se incompleto) ou home.
  static Future<void> goNext() async {
    if (await needsRegistration()) {
      Get.offAllNamed(Routes.register, arguments: {'social': true});
    } else {
      Get.offAllNamed(Routes.home);
    }
  }
}
