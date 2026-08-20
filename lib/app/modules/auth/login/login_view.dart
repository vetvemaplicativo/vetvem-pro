import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_theme.dart';
import 'login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header azul
            Container(
              width: double.infinity,
              color: AppColors.primary,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                              image: const DecorationImage(
                                image: AssetImage('assets/icons/icon_dark.png'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'VetVem Pro',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Bem-vindo de volta!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Entre para gerenciar seus atendimentos',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 14,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Formulário
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _Label('E-mail profissional'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: controller.emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'seu@email.com',
                      prefixIcon: Icon(Icons.email_outlined,
                          color: AppColors.textLight, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _Label('Senha'),
                  const SizedBox(height: 6),
                  Obx(() => TextField(
                        controller: controller.passwordCtrl,
                        obscureText: controller.obscure.value,
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline,
                              color: AppColors.textLight, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              controller.obscure.value
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.textLight,
                              size: 20,
                            ),
                            onPressed: () => controller.obscure.toggle(),
                          ),
                        ),
                      )),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: controller.forgotPassword,
                      child: const Text('Esqueci minha senha',
                          style: TextStyle(
                              color: AppColors.primary, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Obx(() => ElevatedButton(
                        onPressed: controller.isLoading.value
                            ? null
                            : controller.login,
                        child: controller.isLoading.value
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white),
                              )
                            : const Text('Entrar'),
                      )),
                  const SizedBox(height: 24),
                  Row(children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('ou', style: TextStyle(
                          color: AppColors.textLight, fontSize: 13)),
                    ),
                    const Expanded(child: Divider()),
                  ]),
                  const SizedBox(height: 16),
                  Obx(() => OutlinedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : controller.loginWithGoogle,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _GoogleLogo(),
                        const SizedBox(width: 10),
                        const Text('Continuar com Google',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark)),
                      ],
                    ),
                  )),
                  if (Platform.isIOS) ...[
                    const SizedBox(height: 12),
                    Obx(() => OutlinedButton(
                      onPressed: controller.isLoading.value
                          ? null
                          : controller.loginWithApple,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.black,
                        side: const BorderSide(color: Colors.black),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.apple, color: Colors.white, size: 20),
                          SizedBox(width: 10),
                          Text('Continuar com Apple',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                        ],
                      ),
                    )),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Ainda não tem conta?  ',
                          style: TextStyle(
                              color: AppColors.textMedium, fontSize: 14)),
                      GestureDetector(
                        onTap: () => Get.toNamed(Routes.register),
                        child: const Text(
                          'Cadastre-se',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textMedium),
      );
}

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;
    final r = w / 2;

    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
        -2.35, 1.57, false,
        Paint()..color = const Color(0xFFEA4335)..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.22..strokeCap = StrokeCap.butt);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
        -0.78, 1.57, false,
        Paint()..color = const Color(0xFF34A853)..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.22..strokeCap = StrokeCap.butt);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
        0.79, 1.2, false,
        Paint()..color = const Color(0xFFFBBC05)..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.22..strokeCap = StrokeCap.butt);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
        1.99, 1.18, false,
        Paint()..color = const Color(0xFF4285F4)..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.22..strokeCap = StrokeCap.butt);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx, cy - h * 0.12, w * 0.5, h * 0.24),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF4285F4)..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_GoogleLogoPainter oldDelegate) => false;
}
