import 'package:get/get.dart';
import '../../services/api_service.dart';
import '../../utils/snackbar_helper.dart';

class PrivacyController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  final pageContent = ''.obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchPrivacyPolicy();
  }

  Future<void> fetchPrivacyPolicy() async {
    isLoading.value = true;
    try {
      final response = await _apiService.dio.get('/pages/privacy-policy');
      if (response.data['status'] == 'success') {
        pageContent.value = response.data['data']['content'] ?? 'No content available.';
      } else {
        SnackbarHelper.showError('Failed to load privacy policy.');
      }
    } catch (e) {
      SnackbarHelper.showError('Error loading privacy policy.');
    } finally {
      isLoading.value = false;
    }
  }
}
