import 'package:get/get.dart';
import '../../services/storage_service.dart';
import '../../routes/app_routes.dart';

class SplashController extends GetxController {
  final StorageService _storageService = Get.find<StorageService>();

  @override
  void onInit() {
    super.onInit();
    _checkAuth();
  }

  void _checkAuth() async {
    await Future.delayed(const Duration(seconds: 3)); // Simulate splash delay
    
    final token = await _storageService.getToken();
    if (token != null) {
      Get.offAllNamed(AppRoutes.dashboard);
    } else {
      Get.offAllNamed(AppRoutes.login);
    }
  }
}
