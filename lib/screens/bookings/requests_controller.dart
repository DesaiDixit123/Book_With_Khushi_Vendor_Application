import 'package:get/get.dart';
import '../../services/api_service.dart';
import '../../utils/snackbar_helper.dart';

class RequestsController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  // Quote Requests states
  final isLoadingQuotes = false.obs;
  final quotesList = [].obs;
  final quoteFilter = 'all'.obs;

  // Tour Requests states
  final isLoadingTours = false.obs;
  final toursList = [].obs;
  final tourFilter = 'all'.obs;

  // Track status update progress
  final isUpdating = false.obs;

  Future<void> fetchQuotes() async {
    isLoadingQuotes.value = true;
    try {
      final response = await _apiService.dio.get('/vendor/quote-requests');
      if (response.data['status'] == true) {
        quotesList.value = response.data['data'];
      }
    } catch (e) {
      SnackbarHelper.showError('Failed to load quote requests');
    } finally {
      isLoadingQuotes.value = false;
    }
  }

  Future<void> updateQuoteStatus(int id, String status) async {
    isUpdating.value = true;
    try {
      final response = await _apiService.dio.post('/vendor/quote-requests/$id/status', data: {
        'status': status
      });
      if (response.data['status'] == true) {
        SnackbarHelper.showSuccess('Quote request status updated!');
        await fetchQuotes();
      } else {
        SnackbarHelper.showError(response.data['message']);
      }
    } catch (e) {
      SnackbarHelper.showError('Failed to update quote status');
    } finally {
      isUpdating.value = false;
    }
  }

  Future<void> fetchTours() async {
    isLoadingTours.value = true;
    try {
      final response = await _apiService.dio.get('/vendor/tour-requests');
      if (response.data['status'] == true) {
        toursList.value = response.data['data'];
      }
    } catch (e) {
      SnackbarHelper.showError('Failed to load tour requests');
    } finally {
      isLoadingTours.value = false;
    }
  }

  Future<void> updateTourStatus(int id, String status) async {
    isUpdating.value = true;
    try {
      final response = await _apiService.dio.post('/vendor/tour-requests/$id/status', data: {
        'status': status
      });
      if (response.data['status'] == true) {
        SnackbarHelper.showSuccess('Tour request status updated!');
        await fetchTours();
      } else {
        SnackbarHelper.showError(response.data['message']);
      }
    } catch (e) {
      SnackbarHelper.showError('Failed to update tour status');
    } finally {
      isUpdating.value = false;
    }
  }

  Future<void> deleteQuote(int id) async {
    isUpdating.value = true;
    try {
      final response = await _apiService.dio.delete('/vendor/quote-requests/$id');
      if (response.data['status'] == true) {
        SnackbarHelper.showSuccess('Quote request deleted successfully!');
        await fetchQuotes();
      } else {
        SnackbarHelper.showError(response.data['message']);
      }
    } catch (e) {
      SnackbarHelper.showError('Failed to delete quote request');
    } finally {
      isUpdating.value = false;
    }
  }

  Future<void> deleteTour(int id) async {
    isUpdating.value = true;
    try {
      final response = await _apiService.dio.delete('/vendor/tour-requests/$id');
      if (response.data['status'] == true) {
        SnackbarHelper.showSuccess('Tour request deleted successfully!');
        await fetchTours();
      } else {
        SnackbarHelper.showError(response.data['message']);
      }
    } catch (e) {
      SnackbarHelper.showError('Failed to delete tour request');
    } finally {
      isUpdating.value = false;
    }
  }
}
