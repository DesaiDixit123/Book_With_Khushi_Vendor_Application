import 'package:get/get.dart';
import '../../services/api_service.dart';
import '../../utils/snackbar_helper.dart';

class SubscriptionController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  final isLoading = true.obs;
  final currentMembership = Rxn<Map<String, dynamic>>();
  final packages = [].obs;
  final subscriptionGst = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchSubscriptionData();
  }

  Future<void> fetchSubscriptionData() async {
    isLoading.value = true;
    try {
      final response = await _apiService.dio.get('/vendor/subscription');
      if (response.data['status'] == true) {
        final data = response.data['data'];
        if (data['current_membership'] != null) {
          currentMembership.value = Map<String, dynamic>.from(data['current_membership']);
        } else {
          currentMembership.value = null;
        }
        packages.value = data['packages'] ?? [];
        
        final gstVal = data['subscription_gst'];
        if (gstVal != null) {
          subscriptionGst.value = double.tryParse(gstVal.toString()) ?? 0.0;
        }
      }
    } catch (e) {
      SnackbarHelper.showError('Failed to load subscription data');
    } finally {
      isLoading.value = false;
    }
  }
}
