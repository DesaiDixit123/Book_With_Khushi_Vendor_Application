import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/api_service.dart';
import '../../utils/snackbar_helper.dart';
import 'reset_password_screen.dart';

class ForgotPasswordController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  final isLoading = false.obs;
  final forgotFormKey = GlobalKey<FormState>();
  final emailController = TextEditingController();

  Future<void> verifyEmail() async {
    if (!forgotFormKey.currentState!.validate()) return;

    isLoading.value = true;
    try {
      final response = await _apiService.dio.post(
        '/vendor/verify-email',
        data: {'email': emailController.text.trim()},
      );

      if (response.data['status'] == true) {
        final email = emailController.text.trim();
        emailController.clear();
        Get.to(() => VendorResetPasswordScreen(email: email));
      } else {
        SnackbarHelper.showError(
          response.data['message'] ?? 'Email not found',
        );
      }
    } on DioException catch (e) {
      final message = e.response?.data['message'] ?? 'Server error. Please try again.';
      SnackbarHelper.showError(message);
    } catch (e) {
      SnackbarHelper.showError('An unexpected error occurred.');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    super.onClose();
  }
}
