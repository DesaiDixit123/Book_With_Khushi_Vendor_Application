import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../../utils/snackbar_helper.dart';

class DashboardController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  final isLoading = true.obs;
  final stats = {}.obs;
  final membership = {}.obs;
  final graphs = {}.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    isLoading.value = true;
    try {
      final response = await _apiService.dio.get('/vendor/dashboard');
      if (response.data['status'] == true) {
        final data = response.data['data'];
        stats.value = data['statistics'];
        membership.value = data['membership'];
        graphs.value = data['graphs'];
        
        // Always refresh and sync FCM Token to Firestore when dashboard loads
        if (Get.isRegistered<NotificationService>()) {
          Get.find<NotificationService>().refreshFCMToken();
        }
      }
    } catch (e) {
      if (e is DioException) {
        final msg = e.response?.data['message'] ?? e.message ?? 'Failed to load dashboard data';
        SnackbarHelper.showError('Dashboard Error: $msg');
      } else {
        SnackbarHelper.showError('Dashboard Error: $e');
      }
    } finally {
      isLoading.value = false;
    }
  }
}
