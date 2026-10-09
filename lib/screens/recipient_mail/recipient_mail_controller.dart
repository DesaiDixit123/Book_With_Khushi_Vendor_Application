import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio;
import '../../services/api_service.dart';
import '../../utils/snackbar_helper.dart';
import '../profile/profile_controller.dart';

class RecipientMailController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  final formKey = GlobalKey<FormState>();
  final mailController = TextEditingController();

  final isLoading = false.obs;
  final isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchRecipientMail();
  }

  Future<void> fetchRecipientMail() async {
    isLoading.value = true;
    try {
      final response = await _apiService.dio.get('/vendor/profile');
      if (response.data['status'] == true) {
        mailController.text = response.data['data']['recipient_mail'] ?? '';
      }
    } catch (e) {
      print("Error fetching recipient mail: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateRecipientMail() async {
    if (!formKey.currentState!.validate()) return;

    isSaving.value = true;
    try {
      final response = await _apiService.dio.post(
        '/vendor/profile/recipient-mail',
        data: {
          'recipient_mail': mailController.text.trim(),
        },
      );

      if (response.data['status'] == true) {
        SnackbarHelper.showSuccess(response.data['message'] ?? 'Recipient mail updated successfully!');
        // Refresh profile controller so cached values are updated
        if (Get.isRegistered<ProfileController>()) {
          Get.find<ProfileController>().fetchProfile();
        }
        Get.back();
      } else {
        SnackbarHelper.showError(response.data['message'] ?? 'Failed to update recipient mail.');
      }
    } catch (e) {
      if (e is dio.DioException) {
        final msg = e.response?.data['message'] ?? e.message ?? 'An error occurred.';
        SnackbarHelper.showError(msg);
      } else {
        SnackbarHelper.showError('An error occurred: $e');
      }
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    mailController.dispose();
    super.onClose();
  }
}
