import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'app/routes/app_pages.dart';
import 'app/services/analytics_service.dart';
import 'app/services/ibge_service.dart';
import 'app/services/taxonomy_service.dart';
import 'app/theme/app_theme.dart';
import 'app/widgets/offline_banner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Get.putAsync(() async => AnalyticsService());
  await Get.putAsync(() => IbgeService().init());
  await Get.putAsync(() => TaxonomyService().init());
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const VetVemProApp());
}

class VetVemProApp extends StatelessWidget {
  const VetVemProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'VetVem Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildAppTheme(),
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      navigatorObservers: [Get.find<AnalyticsService>().observer],
      builder: (context, child) => OfflineBanner(child: child!),
    );
  }
}
