import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../services/api_service.dart';
import '../../utils/snackbar_helper.dart';
import '../../routes/app_routes.dart';

class VendorResetPasswordScreen extends StatefulWidget {
  final String email;
  const VendorResetPasswordScreen({super.key, required this.email});

  @override
  State<VendorResetPasswordScreen> createState() => _VendorResetPasswordScreenState();
}

class _VendorResetPasswordScreenState extends State<VendorResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _isLoading = false.obs;
  final _isObscureNew = true.obs;
  final _isObscureConfirm = true.obs;

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPasswordController.text != _confirmPasswordController.text) {
      SnackbarHelper.showError('Passwords do not match');
      return;
    }

    _isLoading.value = true;
    try {
      final apiService = Get.find<ApiService>();
      final response = await apiService.dio.post(
        '/vendor/reset-password-direct',
        data: {
          'email': widget.email,
          'password': _newPasswordController.text,
        },
      );

      if (response.data['status'] == true) {
        SnackbarHelper.showSuccess(
          response.data['message'] ?? 'Password reset successfully!',
        );
        Get.offAllNamed(AppRoutes.login);
      } else {
        SnackbarHelper.showError(
          response.data['message'] ?? 'Failed to reset password',
        );
      }
    } on DioException catch (e) {
      final message = e.response?.data['message'] ?? 'Server error. Please try again.';
      SnackbarHelper.showError(message);
    } catch (e) {
      SnackbarHelper.showError('An unexpected error occurred.');
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beigeCream,
      appBar: AppBar(
        backgroundColor: AppColors.navyBlue,
        foregroundColor: Colors.white,
        title: const Text(
          'New Password',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),
              // Icon
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.navyBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_open_rounded,
                    color: AppColors.golden,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Set New Password 🔐',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navyBlue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create a new password for\n${widget.email}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 40),
              // Form
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // New Password
                        const Text(
                          'New Password',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.navyBlue,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Obx(() => TextFormField(
                          controller: _newPasswordController,
                          obscureText: _isObscureNew.value,
                          decoration: InputDecoration(
                            hintText: 'Enter new password',
                            prefixIcon: const Icon(Icons.lock_outline, color: AppColors.navyBlue),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isObscureNew.value ? Icons.visibility_off : Icons.visibility,
                                color: AppColors.textGrey,
                              ),
                              onPressed: () => _isObscureNew.value = !_isObscureNew.value,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.golden, width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Please enter new password';
                            if (value.length < 6) return 'Password must be at least 6 characters';
                            return null;
                          },
                        )),
                        const SizedBox(height: 16),
                        // Confirm Password
                        const Text(
                          'Confirm Password',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.navyBlue,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Obx(() => TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _isObscureConfirm.value,
                          decoration: InputDecoration(
                            hintText: 'Confirm new password',
                            prefixIcon: const Icon(Icons.lock_outline, color: AppColors.navyBlue),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isObscureConfirm.value ? Icons.visibility_off : Icons.visibility,
                                color: AppColors.textGrey,
                              ),
                              onPressed: () => _isObscureConfirm.value = !_isObscureConfirm.value,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.golden, width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Please confirm your password';
                            return null;
                          },
                        )),
                        const SizedBox(height: 28),
                        Obx(() => ElevatedButton(
                          onPressed: _isLoading.value ? null : _resetPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.golden,
                            foregroundColor: AppColors.navyBlue,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: _isLoading.value
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: AppColors.navyBlue,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'RESET & LOGIN',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                        )),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
