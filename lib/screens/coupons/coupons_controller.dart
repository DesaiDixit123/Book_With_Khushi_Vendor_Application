import 'package:get/get.dart';
import '../../services/api_service.dart';
import '../../utils/snackbar_helper.dart';

class CouponsController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  final isLoading = true.obs;
  final isSaving = false.obs;
  final couponsList = [].obs;

  // Prerequisites
  final isLoadingPrerequisites = false.obs;
  final spacesPrerequisites = [].obs;

  @override
  void onInit() {
    super.onInit();
    fetchCoupons();
    fetchPrerequisites();
  }

  Future<void> fetchCoupons() async {
    isLoading.value = true;
    try {
      final response = await _apiService.dio.get('/vendor/coupons');
      if (response.data['status'] == true) {
        couponsList.value = response.data['data'];
      }
    } catch (e) {
      SnackbarHelper.showError('Failed to load coupons');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchPrerequisites() async {
    isLoadingPrerequisites.value = true;
    try {
      final response = await _apiService.dio.get('/vendor/coupons/prerequisites');
      if (response.data['status'] == true) {
        spacesPrerequisites.value = response.data['spaces'];
      }
    } catch (e) {
      SnackbarHelper.showError('Failed to load spaces list');
    } finally {
      isLoadingPrerequisites.value = false;
    }
  }

  Future<void> addCoupon({
    required String name,
    required String code,
    required String type,
    required double value,
    required String startDate,
    required String endDate,
    required String spaceType,
    required int serialNumber,
    required List<int> spaces,
  }) async {
    isSaving.value = true;
    try {
      final response = await _apiService.dio.post('/vendor/coupons', data: {
        'name': name,
        'code': code,
        'coupon_type': type,
        'value': value,
        'start_date': startDate,
        'end_date': endDate,
        'space_type': spaceType,
        'serial_number': serialNumber,
        'spaces': spaces,
      });

      if (response.data['status'] == true) {
        Get.back(); // Redirect back to list screen first (closes add form)
        SnackbarHelper.showSuccess('Coupon added successfully!');
        fetchCoupons(); // Reload the coupons list
      } else {
        SnackbarHelper.showError(response.data['message'] ?? 'Failed to add coupon');
      }
    } catch (e) {
      SnackbarHelper.showError('Failed to save coupon');
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> editCoupon({
    required int id,
    required String name,
    required String code,
    required String type,
    required double value,
    required String startDate,
    required String endDate,
    required String spaceType,
    required int serialNumber,
    required List<int> spaces,
  }) async {
    isSaving.value = true;
    try {
      final response = await _apiService.dio.post('/vendor/coupons/$id', data: {
        'name': name,
        'code': code,
        'coupon_type': type,
        'value': value,
        'start_date': startDate,
        'end_date': endDate,
        'space_type': spaceType,
        'serial_number': serialNumber,
        'spaces': spaces,
      });

      if (response.data['status'] == true) {
        Get.back(); // Redirect back to list screen first (closes edit form)
        SnackbarHelper.showSuccess('Coupon updated successfully!');
        fetchCoupons(); // Reload the coupons list
      } else {
        SnackbarHelper.showError(response.data['message'] ?? 'Failed to update coupon');
      }
    } catch (e) {
      SnackbarHelper.showError('Failed to update coupon');
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> deleteCoupon(int id) async {
    try {
      final response = await _apiService.dio.delete('/vendor/coupons/$id');
      if (response.data['status'] == true) {
        SnackbarHelper.showSuccess('Coupon deleted successfully!');
        await fetchCoupons();
      } else {
        SnackbarHelper.showError(response.data['message'] ?? 'Failed to delete coupon');
      }
    } catch (e) {
      SnackbarHelper.showError('Failed to delete coupon');
    }
  }
}
