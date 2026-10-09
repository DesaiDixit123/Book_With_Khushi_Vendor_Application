import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../../services/api_service.dart';
import '../../utils/snackbar_helper.dart';
import '../../routes/app_routes.dart';

class HolidaysController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  final isLoading = true.obs;
  final isSaving = false.obs;
  final holidaysList = <Map<String, dynamic>>[].obs;

  final startDate = Rxn<DateTime>();
  final endDate = Rxn<DateTime>();

  @override
  void onInit() {
    super.onInit();
    fetchHolidays();
  }

  Future<void> fetchHolidays() async {
    isLoading.value = true;
    try {
      Map<String, dynamic> queryParameters = {};
      if (startDate.value != null && endDate.value != null) {
        queryParameters['start_date'] = startDate.value!.toIso8601String().split('T')[0];
        queryParameters['end_date'] = endDate.value!.toIso8601String().split('T')[0];
      }

      final response = await _apiService.dio.get('/vendor/holidays', queryParameters: queryParameters);
      if (response.data['status'] == true) {
        holidaysList.value =
            List<Map<String, dynamic>>.from(response.data['data']);
      } else {
        SnackbarHelper.showError(
            response.data['message'] ?? 'Failed to load holidays');
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ??
          e.response?.data?.toString() ??
          e.message ??
          'Failed to load holidays';
      SnackbarHelper.showError(msg);
    } catch (e) {
      SnackbarHelper.showError('Failed to load holidays');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addHoliday(String date) async {
    isSaving.value = true;
    try {
      final response = await _apiService.dio.post(
        '/vendor/holidays',
        data: {'date': date},
      );
      if (response.data['status'] == true) {
        SnackbarHelper.showSuccess('Holiday added successfully!');
        await fetchHolidays();
        Get.offNamed(AppRoutes.holidays); // go back to list
      } else {
        SnackbarHelper.showError(
            response.data['message'] ?? 'Failed to add holiday');
      }
    } catch (e) {
      SnackbarHelper.showError('Failed to add holiday');
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> deleteHoliday(int id) async {
    try {
      final response =
          await _apiService.dio.delete('/vendor/holidays/$id');
      if (response.data['status'] == true) {
        SnackbarHelper.showSuccess('Holiday deleted successfully!');
        holidaysList.removeWhere((h) => h['id'] == id);
      } else {
        SnackbarHelper.showError('Failed to delete holiday');
      }
    } catch (e) {
      SnackbarHelper.showError('Failed to delete holiday');
    }
  }

  Future<void> selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: startDate.value != null && endDate.value != null
          ? DateTimeRange(start: startDate.value!, end: endDate.value!)
          : null,
    );

    if (picked != null) {
      startDate.value = picked.start;
      endDate.value = picked.end;
      fetchHolidays();
    }
  }

  void clearFilter() {
    startDate.value = null;
    endDate.value = null;
    fetchHolidays();
  }
}
