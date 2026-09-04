import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../../routes/app_routes.dart';
import '../../../services/analytics_service.dart';
import '../../../theme/app_theme.dart';
import '../../terms/terms_view.dart';

class LoginController extends GetxController {
  final _firebase = FirebaseAuth.instance;
  final _analytics = Get.find<AnalyticsService>();

  final emailCtrl    = TextEditingController();
  final passwordCtrl = TextEditingController();
  final isLoading    = false.obs;
  final obscure      = true.obs;

  Future<void> login() async {
    final email = emailCtrl.text.trim();
    final pass  = passwordCtrl.text;
    if (email.isEmpty || pass.isEmpty) {
      _snackWarn('Preencha e-mail e senha');
      return;
    }
    isLoading.value = true;
    try {
      final credential = await _firebase.signInWithEmailAndPassword(
          email: email, password: pass);
      // Verifica se é profissional — bloqueia tutores tentando logar aqui
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .get();
      if (doc.exists && doc.data()?['role'] != 'professional') {
        await _firebase.signOut();
        _snackError('Esta conta é de um tutor. Use o app VetVem.');
        return;
      }
      if (doc.data()?['blocked'] == true) {
        await _firebase.signOut();
        _snackError('Conta bloqueada. Entre em contato com o suporte.');
        return;
      }
      if (!await TermsView.ensureAccepted()) {
        await _firebase.signOut();
        _snackError('É necessário aceitar os Termos de Uso para usar o app.');
        return;
      }
      _analytics.logLogin('email');
      Get.offAllNamed(Routes.home);
    } on FirebaseAuthException catch (e) {
      _snackError(_mapError(e));
    } catch (_) {
      _snackError('Sem conexão. Verifique sua internet.');
    } finally {
      isLoading.value = false;
    }
  }

  void forgotPassword() {
    final ctrl = TextEditingController(text: emailCtrl.text.trim());
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Recuperar senha',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Informe seu e-mail e enviaremos um link para redefinir sua senha.',
                style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'seu@email.com',
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar',
                style: TextStyle(color: Color(0xFF6B7280))),
          ),
          Obx(() => TextButton(
            onPressed: isLoading.value
                ? null
                : () => _sendResetEmail(ctrl.text.trim()),
            child: isLoading.value
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Enviar',
                    style: TextStyle(fontWeight: FontWeight.bold)),
          )),
        ],
      ),
    );
  }

  Future<void> _sendResetEmail(String email) async {
    if (email.isEmpty) {
      _snackError('Informe seu e-mail.');
      return;
    }
    isLoading.value = true;
    try {
      await _firebase.sendPasswordResetEmail(email: email);
      Get.back();
      Get.snackbar('Pronto!', 'E-mail enviado! Verifique sua caixa de entrada.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xFF22C55E),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          duration: const Duration(seconds: 4),
          icon: const Icon(Icons.check_circle_outline, color: Colors.white));
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _snackError('Nenhuma conta encontrada com este e-mail.');
      } else {
        _snackError('Erro ao enviar e-mail. Tente novamente.');
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loginWithGoogle() async {
    isLoading.value = true;
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebase.signInWithCredential(credential);
      final user = userCredential.user!;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      // Bloqueia tutores tentando logar aqui
      if (doc.exists && doc.data()?['role'] == 'tutor') {
        await _firebase.signOut();
        await GoogleSignIn().signOut();
        _snackError('Esta conta é de um tutor. Use o app VetVem.');
        return;
      }
      if (doc.data()?['blocked'] == true) {
        await _firebase.signOut();
        await GoogleSignIn().signOut();
        _snackError('Conta bloqueada. Entre em contato com o suporte.');
        return;
      }
      if (!await TermsView.ensureAccepted()) {
        await _firebase.signOut();
        await GoogleSignIn().signOut();
        _snackError('É necessário aceitar os Termos de Uso para usar o app.');
        return;
      }

      // Primeiro login — cria documento como profissional
      if (!doc.exists) {
        // merge: preserva o aceite dos termos gravado pelo gate acima
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'name': user.displayName ?? '',
          'email': user.email ?? '',
          'role': 'professional',
          'accountStatus': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      _analytics.logLogin('google');
      Get.offAllNamed(Routes.home);
    } catch (_) {
      _snackError('Não foi possível entrar com Google. Tente novamente.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loginWithApple() async {
    isLoading.value = true;
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
        rawNonce: rawNonce,
      );

      final userCredential = await _firebase.signInWithCredential(oauthCredential);
      final user = userCredential.user!;

      // A Apple só envia o nome no primeiro login — salva se disponível
      final appleName = [
        appleCredential.givenName,
        appleCredential.familyName,
      ].where((s) => s != null && s.isNotEmpty).join(' ');
      if (appleName.isNotEmpty && (user.displayName ?? '').isEmpty) {
        await user.updateDisplayName(appleName);
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      // Bloqueia tutores tentando logar aqui
      if (doc.exists && doc.data()?['role'] == 'tutor') {
        await _firebase.signOut();
        _snackError('Esta conta é de um tutor. Use o app VetVem.');
        return;
      }
      if (doc.data()?['blocked'] == true) {
        await _firebase.signOut();
        _snackError('Conta bloqueada. Entre em contato com o suporte.');
        return;
      }
      if (!await TermsView.ensureAccepted()) {
        await _firebase.signOut();
        _snackError('É necessário aceitar os Termos de Uso para usar o app.');
        return;
      }

      // Primeiro login — cria documento como profissional
      if (!doc.exists) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'name': user.displayName ?? appleName,
          'email': user.email ?? '',
          'role': 'professional',
          'accountStatus': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      _analytics.logLogin('apple');
      Get.offAllNamed(Routes.home);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code != AuthorizationErrorCode.canceled) {
        _snackError('Não foi possível entrar com Apple. Tente novamente.');
      }
    } catch (_) {
      _snackError('Não foi possível entrar com Apple. Tente novamente.');
    } finally {
      isLoading.value = false;
    }
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  String _sha256ofString(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }

  String _mapError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-mail ou senha incorretos.';
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'network-request-failed':
        return 'Sem conexão. Verifique sua internet.';
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde alguns minutos.';
      default:
        return 'Ocorreu um erro. Tente novamente.';
    }
  }

  void _snackWarn(String message) {
    Get.snackbar(
      'Atenção', message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.white,
      colorText: const Color(0xFF111827),
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      duration: const Duration(seconds: 3),
      icon: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.info_outline_rounded,
            color: Color(0xFFF59E0B), size: 20),
      ),
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 16, offset: const Offset(0, 4),
        ),
      ],
    );
  }

  void _snackError(String message) {
    Get.snackbar(
      'Erro', message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.white,
      colorText: const Color(0xFF111827),
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      duration: const Duration(seconds: 3),
      icon: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.error_outline_rounded,
            color: AppColors.error, size: 20),
      ),
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 16, offset: const Offset(0, 4),
        ),
      ],
    );
  }

  @override
  void onClose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    super.onClose();
  }
}
