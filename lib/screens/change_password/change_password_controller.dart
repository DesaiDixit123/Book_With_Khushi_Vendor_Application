import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio;
import '../../services/api_service.dart';
import '../../utils/snackbar_helper.dart';

class ChangePasswordController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  final formKey = GlobalKey<FormState>();
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final isLoading = false.obs;

  final isCurrentPasswordObscure = true.obs;
  final isNewPasswordObscure = true.obs;
  final isConfirmPasswordObscure = true.obs;

  Future<void> changePassword() async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;
    try {
      final response = await _apiService.dio.post(
        '/vendor/profile/password',
        data: {
          'current_password': currentPasswordController.text,
          'new_password': newPasswordController.text,
          'new_password_confirmation': confirmPasswordController.text,
        },
      );

      if (response.data['status'] == true) {
        SnackbarHelper.showSuccess(response.data['message'] ?? 'Password changed successfully!');
        currentPasswordController.clear();
        newPasswordController.clear();
        confirmPasswordController.clear();
        Get.back();
      } else {
        SnackbarHelper.showError(response.data['message'] ?? 'Failed to change password.');
      }
    } catch (e) {
      if (e is dio.DioException) {
        final msg = e.response?.data['message'] ?? e.message ?? 'An error occurred.';
        SnackbarHelper.showError(msg);
      } else {
        SnackbarHelper.showError('An error occurred: $e');
      }
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
