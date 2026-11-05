import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

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
      // Google/Apple pelo fluxo NATIVO (o mesmo do login). reauthenticateWithProvider abre uma
      // página web do Firebase que no iPhone falha com "missing initial state".
      if (providers.contains('google.com')) {
        final googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) return false;
        final googleAuth = await googleUser.authentication;
        await user.reauthenticateWithCredential(GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        ));
        return true;
      }
      if (providers.contains('apple.com')) {
        final rawNonce = _nonce();
        final apple = await SignInWithApple.getAppleIDCredential(
          scopes: [AppleIDAuthorizationScopes.email],
          nonce: sha256.convert(utf8.encode(rawNonce)).toString(),
        );
        await user.reauthenticateWithCredential(OAuthProvider('apple.com').credential(
          idToken: apple.identityToken,
          accessToken: apple.authorizationCode,
          rawNonce: rawNonce,
        ));
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

  static String _nonce([int length = 32]) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._';
    final r = Random.secure();
    return List.generate(length, (_) => chars[r.nextInt(chars.length)]).join();
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
