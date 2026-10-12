import 'package:http/http.dart' as http;
import 'dart:convert';

/// Pede ao servidor o e-mail de redefinição de senha com a marca VetVem
/// (logo, "Equipe VetVem"). O servidor responde igual exista ou não a conta,
/// por isso o app nunca revela se um e-mail está cadastrado.
class PasswordResetService {
  static const _url =
      'https://southamerica-east1-vetvem-18bf4.cloudfunctions.net/sendBrandedPasswordReset';

  /// true se o pedido foi aceito pelo servidor.
  static Future<bool> send(String email) async {
    try {
      final res = await http
          .post(
            Uri.parse(_url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email.trim()}),
          )
          .timeout(const Duration(seconds: 20));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
