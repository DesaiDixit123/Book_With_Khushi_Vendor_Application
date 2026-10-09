import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../../../services/api_service.dart';
import '../../../utils/snackbar_helper.dart';

class CheckLimitController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  final isLoading = true.obs;
  final packageName = ''.obs;
  final limitsData = {}.obs;

  @override
  void onInit() {
    super.onInit();
    fetchLimits();
  }

  Future<void> fetchLimits() async {
    isLoading.value = true;
    try {
      final response = await _apiService.dio.get('/vendor/check-limit');
      if (response.data['status'] == true) {
        packageName.value = response.data['data']['package_name'] ?? 'Unknown';
        limitsData.value = response.data['data']['limits'] ?? {};
      } else {
        SnackbarHelper.showError(response.data['message'] ?? 'Failed to fetch limits');
      }
    } catch (e) {
      if (e is DioException) {
        final msg = e.response?.data['message'] ?? e.message ?? 'Failed to load limits';
        SnackbarHelper.showError('Error: $msg');
      } else {
        SnackbarHelper.showError('Error: $e');
      }
    } finally {
      isLoading.value = false;
    }
  }
}
