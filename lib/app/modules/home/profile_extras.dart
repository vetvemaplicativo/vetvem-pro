import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../theme/app_theme.dart';
import 'home_controller.dart';

BoxDecoration _cardDecoration() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE5E7EB)),
    );

/// Segurança da conta: troca de senha por e-mail de redefinição.
class ProfileSecurityCard extends StatelessWidget {
  const ProfileSecurityCard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<HomeController>();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          const Icon(Icons.lock_outline_rounded,
              size: 20, color: AppColors.textMedium),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Senha de acesso',
                style: TextStyle(fontSize: 13, color: AppColors.textDark)),
          ),
          TextButton(
            onPressed: c.requestPasswordReset,
            child: const Text('Alterar senha',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
