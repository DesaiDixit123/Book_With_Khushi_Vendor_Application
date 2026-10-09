import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../services/notification_service.dart';
import '../../routes/app_routes.dart';
import '../../utils/snackbar_helper.dart';
import '../profile/profile_controller.dart';

class MobileOtpController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final StorageService _storageService = Get.find<StorageService>();

  final isSendingOtp = false.obs;
  final isVerifying = false.obs;
  final otpSent = false.obs;
  final phoneNumber = ''.obs;

  final phoneController = TextEditingController();
  final otpController = TextEditingController();

  RxInt secondsRemaining = 0.obs;
  Timer? _timer;

  void startTimer() {
    secondsRemaining.value = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsRemaining.value > 0) {
        secondsRemaining.value--;
      } else {
        _timer?.cancel();
      }
    });
  }

  Future<void> sendOtp() async {
    final phone = phoneController.text.trim();
    if (phone.length != 10) {
      SnackbarHelper.showError('Please enter a valid 10-digit mobile number');
      return;
    }

    isSendingOtp.value = true;
    try {
      final response = await _apiService.dio.post('/vendor/send-otp', data: {
        'phone': phone,
      });

      if (response.data['status'] == true) {
        phoneNumber.value = phone;
        otpSent.value = true;
        startTimer();
        SnackbarHelper.showSuccess(response.data['message'] ?? 'OTP sent successfully');
      } else {
        SnackbarHelper.showError(response.data['message'] ?? 'Failed to send OTP');
      }
    } on DioException catch (e) {
      debugPrint('DioException caught in sendOtp: $e');
      debugPrint('Response data: ${e.response?.data}');
      debugPrint('Status code: ${e.response?.statusCode}');
      final message = e.response?.data['message'] ?? 'An error occurred while sending OTP.';
      SnackbarHelper.showError(message);
    } catch (e) {
      SnackbarHelper.showError('Something went wrong. Please try again.');
    } finally {
      isSendingOtp.value = false;
    }
  }

  Future<void> verifyOtp() async {
    final otp = otpController.text.trim();
    if (otp.length != 6) {
      SnackbarHelper.showError('Please enter the 6-digit OTP');
      return;
    }

    isVerifying.value = true;
    try {
      final response = await _apiService.dio.post('/vendor/verify-otp-login', data: {
        'phone': phoneNumber.value,
        'otp': otp,
      });

      if (response.data['status'] == true) {
        final token = response.data['data']['token'];
        final vendorName = response.data['data']['vendor']['username'] ?? 'User';
        final int vendorId = response.data['data']['vendor']['id'];
        await _storageService.saveToken(token);
        await _storageService.saveUserName(vendorName);
        await _storageService.saveVendorId(vendorId);

        // Fetch profile data immediately after login
        if (Get.isRegistered<ProfileController>()) {
          Get.find<ProfileController>().fetchProfile();
        }

        if (Get.isRegistered<NotificationService>()) {
          Get.find<NotificationService>().refreshFCMToken();
        }

        phoneController.clear();
        otpController.clear();

        Get.offAllNamed(AppRoutes.dashboard);
        SnackbarHelper.showSuccess(response.data['message'] ?? 'Login successful');
      } else {
        SnackbarHelper.showError(response.data['message'] ?? 'Invalid OTP');
      }
    } on DioException catch (e) {
      final message = e.response?.data['message'] ?? 'An error occurred during verification.';
      SnackbarHelper.showError(message);
    } catch (e) {
      SnackbarHelper.showError('Something went wrong. Please try again.');
    } finally {
      isVerifying.value = false;
    }
  }

  void resetToPhoneEntry() {
    otpSent.value = false;
    otpController.clear();
  }

  @override
  void onClose() {
    _timer?.cancel();
    phoneController.dispose();
    otpController.dispose();
    super.onClose();
  }
}
