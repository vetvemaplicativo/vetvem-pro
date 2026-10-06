import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Confirma a identidade de quem está logado antes de ações sensíveis
/// (ex.: trocar a chave PIX). E-mail/senha pede a senha; Google/Apple
/// repetem o login do provedor. Retorna true se confirmou.
class ReauthService {
  static Future<bool> confirm() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final providers = user.providerData.map((p) => p.providerId).toSet();
    try {
      if (providers.contains('password') && user.email != null) {
        final pass = await _askPassword();
        if (pass == null || pass.isEmpty) return false;
        await user.reauthenticateWithCredential(
            EmailAuthProvider.credential(email: user.email!, password: pass));
        return true;
      }
      if (providers.contains('google.com')) {
        await user.reauthenticateWithProvider(GoogleAuthProvider());
        return true;
      }
      if (providers.contains('apple.com')) {
        await user.reauthenticateWithProvider(AppleAuthProvider());
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      final wrong = e.code == 'wrong-password' || e.code == 'invalid-credential';
      Get.snackbar(
        'Não foi possível confirmar',
        wrong ? 'Senha incorreta.' : 'Tente novamente.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> _askPassword() {
    final ctrl = TextEditingController();
    return Get.dialog<String>(
      AlertDialog(
        title: const Text('Confirme sua senha'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Por segurança, digite sua senha para alterar a chave PIX.'),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Senha'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Get.back(), child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Get.back(result: ctrl.text),
              child: const Text('Confirmar')),
        ],
      ),
    );
  }
}
