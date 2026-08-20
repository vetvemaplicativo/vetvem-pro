import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../routes/app_routes.dart';
import '../terms/terms_view.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    Timer(const Duration(seconds: 2), _navigate);
  }

  Future<void> _navigate() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Get.offAllNamed(Routes.login);
      return;
    }
    // Sessão persistida: garante o aceite dos termos antes da home
    final ok = await TermsView.ensureAccepted();
    Get.offAllNamed(ok ? Routes.home : Routes.login);
  }
}
