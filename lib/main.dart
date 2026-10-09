import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart';
import 'services/connectivity_service.dart';
import 'services/notification_service.dart';
import 'themes/app_theme.dart';
import 'screens/auth/auth_controller.dart';
import 'screens/profile/profile_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Edge-to-edge: system nav bar transparent, app draws behind it
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    statusBarColor: Colors.transparent,
  ));
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  bool isFirebaseInitialized = false;
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
    isFirebaseInitialized = true;
  } catch (e) {
    debugPrint('Firebase init check: $e');
    isFirebaseInitialized = Firebase.apps.isNotEmpty;
  }

  // Initialize Core Services
  try {
    await initServices(isFirebaseInitialized);
  } catch (e) {
    debugPrint('Error initializing services: $e');
  }

  runApp(const KhushiVendorApp());
}

Future<void> initServices(bool isFirebaseInitialized) async {
  debugPrint('Starting services initialization...');
  await Get.putAsync(() => StorageService().init());
  await Get.putAsync(() => ApiService().init());
  await Get.putAsync(() => ConnectivityService().init());
  await Get.putAsync(() => NotificationService().init(isFirebaseInitialized));
  // Register permanent controllers — available throughout the whole app lifecycle
  Get.put(AuthController(), permanent: true);
  Get.put(ProfileController(), permanent: true);
  debugPrint('All services started...');
}

class KhushiVendorApp extends StatelessWidget {
  const KhushiVendorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'BookWithKhushi Partner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light, // Strictly use the logo colors, ignore dark mode
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,
      defaultTransition: Transition.cupertino,
      builder: (context, child) {
        return SafeArea(
          top: false,
          bottom: true,
          child: child!,
        );
      },
    );
  }
}
