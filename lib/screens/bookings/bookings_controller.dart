import 'package:get/get.dart';
import '../../services/api_service.dart';
import '../../utils/snackbar_helper.dart';

class BookingsController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  final isLoading = true.obs;
  final bookingsList = [].obs;
  final bookingFilter = 'all'.obs;

  @override
  void onInit() {
    super.onInit();
    fetchBookings();
  }

  Future<void> fetchBookings() async {
    isLoading.value = true;
    try {
      final response = await _apiService.dio.get('/vendor/bookings');
      if (response.data['status'] == true) {
        bookingsList.value = response.data['data'];
      }
    } catch (e) {
      SnackbarHelper.showError('Failed to load bookings');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateBookingStatus(int id, String status) async {
    try {
      final response = await _apiService.dio.post('/vendor/bookings/$id/status', data: {
        'status': status
      });
      if (response.data['status'] == true) {
        SnackbarHelper.showSuccess('Booking status updated!');
        fetchBookings(); // Refresh list
      } else {
        SnackbarHelper.showError(response.data['message']);
      }
    } catch (e) {
      SnackbarHelper.showError('Failed to update status');
    }
  }

  Future<void> deleteBooking(int id) async {
    isLoading.value = true;
    try {
      final response = await _apiService.dio.delete('/vendor/bookings/$id');
      if (response.data['status'] == true) {
        SnackbarHelper.showSuccess('Booking deleted successfully!');
        await fetchBookings();
      } else {
        SnackbarHelper.showError(response.data['message']);
      }
    } catch (e) {
      SnackbarHelper.showError('Failed to delete booking');
    } finally {
      isLoading.value = false;
    }
  }
}
