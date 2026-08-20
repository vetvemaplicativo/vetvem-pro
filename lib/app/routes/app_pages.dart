import 'package:get/get.dart';
import '../modules/splash/splash_binding.dart';
import '../modules/splash/splash_view.dart';
import '../modules/auth/login/login_binding.dart';
import '../modules/auth/login/login_view.dart';
import '../modules/auth/register/register_binding.dart';
import '../modules/auth/register/register_view.dart';
import '../modules/home/home_binding.dart';
import '../modules/home/home_view.dart';
import '../modules/home/appointment_detail_view.dart';
import '../modules/home/prontuario_form_view.dart';
import '../modules/service_area/service_area_binding.dart';
import '../modules/service_area/service_area_view.dart';
import 'app_routes.dart';

class AppPages {
  static const initial = Routes.splash;

  static final routes = [
    GetPage(
      name: Routes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: Routes.login,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: Routes.register,
      page: () => const RegisterView(),
      binding: RegisterBinding(),
    ),
    GetPage(
      name: Routes.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: Routes.appointmentDetail,
      page: () => const AppointmentDetailView(),
    ),
    GetPage(
      name: Routes.prontuarioForm,
      page: () => const ProntuarioFormView(),
    ),
    GetPage(
      name: Routes.serviceArea,
      page: () => const ServiceAreaView(),
      binding: ServiceAreaBinding(),
    ),
  ];
}
