import 'package:url_launcher/url_launcher.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio;
import '../../../../services/api_service.dart';
import '../../../../utils/snackbar_helper.dart';

class SubscriptionLogController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  final logs = [].obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchLogs();
  }

  Future<void> fetchLogs() async {
    isLoading.value = true;
    try {
      final response = await _apiService.dio.get('/vendor/subscription-logs');
      if (response.data['status'] == true) {
        logs.value = response.data['data'];
      } else {
        SnackbarHelper.showError(response.data['message']);
      }
    } catch (e) {
      if (e is dio.DioException) {
        final msg = e.response?.data['message'] ?? e.message ?? 'Failed to load logs';
        SnackbarHelper.showError('Error: $msg');
      } else {
        SnackbarHelper.showError('Error: $e');
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> downloadInvoice(String? url) async {
    if (url == null || url.isEmpty) {
      SnackbarHelper.showError('Invoice is not available for this subscription');
      return;
    }
    try {
      final Uri uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        SnackbarHelper.showError('Could not launch invoice URL');
      }
    } catch (e) {
      SnackbarHelper.showError('Error opening invoice: $e');
    }
  }
}
