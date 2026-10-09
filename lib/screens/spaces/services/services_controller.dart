import 'package:get/get.dart';
import '../../../services/api_service.dart';
import '../../../utils/snackbar_helper.dart';
import '../../../routes/app_routes.dart';

class ServicesController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  final isLoading = true.obs;
  final servicesList = [].obs;
  late Map<String, dynamic> space;

  @override
  void onInit() {
    super.onInit();
    space = Get.arguments as Map<String, dynamic>? ?? {};
    fetchServices();
  }

  Future<void> fetchServices() async {
    if (space['id'] == null) {
      SnackbarHelper.showError('Invalid space identifier');
      isLoading.value = false;
      return;
    }

    isLoading.value = true;
    try {
      final response = await _apiService.dio.get('/vendor/spaces/${space['id']}/services');
      if (response.data['status'] == true) {
        servicesList.value = response.data['data'] ?? [];
      } else {
        SnackbarHelper.showError(response.data['message'] ?? 'Failed to load services');
      }
    } catch (e) {
      SnackbarHelper.showError('Failed to load services. Check your connection.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteService(int serviceId) async {
    try {
      final response = await _apiService.dio.post('/vendor/services/delete/$serviceId');
      if (response.data['status'] == true) {
        SnackbarHelper.showSuccess('Service deleted successfully');
        fetchServices();
      } else {
        SnackbarHelper.showError(response.data['message'] ?? 'Failed to delete service');
      }
    } catch (e) {
      SnackbarHelper.showError('Error deleting service. Check your connection.');
    }
  }

  Future<void> navigateToAddService() async {
    final result = await Get.toNamed(AppRoutes.addService, arguments: {
      'space': space,
      'service': null,
    });
    if (result == true) {
      fetchServices();
    }
  }

  Future<void> navigateToEditService(Map<String, dynamic> service) async {
    final result = await Get.toNamed(AppRoutes.addService, arguments: {
      'space': space,
      'service': service,
    });
    if (result == true) {
      fetchServices();
    }
  }
}
