import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../theme/app_theme.dart';
import 'home_controller.dart';

BoxDecoration _cardDecoration() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE5E7EB)),
    );

/// Endereço do profissional, editável depois do cadastro.
class ProfileAddressCard extends StatelessWidget {
  const ProfileAddressCard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<HomeController>();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Obx(() {
        final a = c.professionalAddress;
        final line = [
          [a['street'], a['number']].where((s) => (s ?? '').isNotEmpty).join(', '),
          a['complement'],
          a['neighborhood'],
          [a['city'], a['state']].where((s) => (s ?? '').isNotEmpty).join(' - '),
        ].where((s) => (s ?? '').isNotEmpty).join(' · ');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Endereço',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark)),
                ),
                TextButton(
                  onPressed: () => _showSheet(context, c),
                  child: const Text('Editar',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            Text(
              line.isEmpty ? 'Nenhum endereço cadastrado.' : line,
              style: const TextStyle(fontSize: 13, color: AppColors.textMedium),
            ),
          ],
        );
      }),
    );
  }

  void _showSheet(BuildContext context, HomeController c) {
    final a = c.professionalAddress;
    const labels = {
      'cep': 'CEP',
      'street': 'Rua',
      'number': 'Número',
      'complement': 'Complemento',
      'neighborhood': 'Bairro',
      'city': 'Cidade',
      'state': 'UF',
    };
    final fields = <String, TextEditingController>{
      for (final k in labels.keys) k: TextEditingController(text: a[k] ?? ''),
    };
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Editar endereço',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text(
                  'Este é o seu endereço cadastral. Para mudar onde você atende, use "Área de atuação".',
                  style: TextStyle(fontSize: 12, color: AppColors.textMedium),
                ),
                const SizedBox(height: 14),
                for (final k in labels.keys)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TextField(
                      controller: fields[k],
                      textCapitalization: k == 'state'
                          ? TextCapitalization.characters
                          : TextCapitalization.words,
                      keyboardType: (k == 'cep' || k == 'number')
                          ? TextInputType.number
                          : TextInputType.text,
                      maxLength: k == 'state' ? 2 : null,
                      decoration: InputDecoration(
                        labelText: labels[k],
                        counterText: '',
                      ),
                    ),
                  ),
                const SizedBox(height: 6),
                ElevatedButton(
                  onPressed: () async {
                    final v = {
                      for (final e in fields.entries) e.key: e.value.text.trim()
                    };
                    if (v['street']!.length < 3 ||
                        v['neighborhood']!.isEmpty ||
                        v['city']!.isEmpty ||
                        v['state']!.length != 2) {
                      c.snack(
                        title: 'Endereço incompleto',
                        message: 'Informe rua, bairro, cidade e UF.',
                        icon: Icons.error_outline_rounded,
                        color: const Color(0xFFEF4444),
                      );
                      return;
                    }
                    v['state'] = v['state']!.toUpperCase();
                    Navigator.of(ctx).pop();
                    await c.updateAddress(v);
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Salvar endereço'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
