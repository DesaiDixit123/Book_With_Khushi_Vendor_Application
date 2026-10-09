import 'dart:io' show Platform;
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../services/notification_service.dart';
import '../../routes/app_routes.dart';
import '../../utils/snackbar_helper.dart';
import '../profile/profile_controller.dart';

class AuthController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final StorageService _storageService = Get.find<StorageService>();

  final isLoginLoading = false.obs;
  final isSignupLoading = false.obs;
  
  final isLoginPasswordObscure = true.obs;
  final isSignupPasswordObscure = true.obs;
  final isSignupConfirmPasswordObscure = true.obs;
  
  final loginFormKey = GlobalKey<FormState>();
  final signupFormKey = GlobalKey<FormState>();

  // Login Controllers
  final loginUsernameController = TextEditingController();
  final loginPasswordController = TextEditingController();

  // Signup Controllers
  final signupNameController = TextEditingController();
  final signupEmailController = TextEditingController();
  final signupPhoneController = TextEditingController();
  final signupUsernameController = TextEditingController();
  final signupPasswordController = TextEditingController();
  final signupConfirmPasswordController = TextEditingController();
  final signupReferralCodeController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    signupNameController.addListener(_onFullNameChanged);
    clearFields();
  }

  void _onFullNameChanged() {
    final name = signupNameController.text.trim();
    if (name.isNotEmpty) {
      signupUsernameController.text = _generateUsername(name);
    }
  }

  String _generateUsername(String fullName) {
    final parts = fullName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9 ]'), '')
        .split(' ')
        .where((p) => p.isNotEmpty)
        .toList();
    final base = parts.join('');
    final suffix = Random().nextInt(9000) + 1000; // 1000 - 9999
    return '$base$suffix';
  }

  void refreshUsername() {
    final name = signupNameController.text.trim();
    if (name.isNotEmpty) {
      signupUsernameController.text = _generateUsername(name);
    }
  }

  void clearFields() {
    loginUsernameController.clear();
    loginPasswordController.clear();
    signupNameController.clear();
    signupEmailController.clear();
    signupPhoneController.clear();
    signupUsernameController.clear();
    signupPasswordController.clear();
    signupConfirmPasswordController.clear();
    signupReferralCodeController.clear();
  }

  Future<void> login() async {
    if (!loginFormKey.currentState!.validate()) return;
    
    isLoginLoading.value = true;
    try {
      // Fetch FCM token BEFORE login so it can be saved atomically in the backend
      String? fcmToken;
      String deviceType = Platform.isIOS ? 'ios' : 'android';
      try {
        final notificationService = Get.find<NotificationService>();
        fcmToken = await notificationService.getFCMToken();
      } catch (_) {}

      final Map<String, dynamic> loginData = {
        'username': loginUsernameController.text.trim(),
        'password': loginPasswordController.text.trim(),
      };
      if (fcmToken != null) {
        loginData['fcm_token'] = fcmToken;
        loginData['device_type'] = deviceType ?? 'android';
      }

      final response = await _apiService.dio.post('/vendor/login', data: loginData);

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

        // Also trigger a token refresh in background (in case FCM token rotated)
        if (Get.isRegistered<NotificationService>()) {
          Get.find<NotificationService>().refreshFCMToken();
        }

        // Clear fields on successful login so they don't linger in memory
        clearFields();

        Get.offAllNamed(AppRoutes.dashboard);
        SnackbarHelper.showSuccess(response.data['message']);
      } else {
        SnackbarHelper.showError(response.data['message'] ?? 'Login failed');
      }
    } on DioException catch (e) {
      debugPrint('Login DioException: $e');
      if (e.response != null) {
        debugPrint('Login Error Response Data: ${e.response?.data}');
        debugPrint('Login Error Status Code: ${e.response?.statusCode}');
      }
      String message = 'An error occurred during login.';
      try {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          message = data['message'].toString();
        } else if (e.response?.statusCode == 401) {
          message = 'Incorrect username or password.';
        } else if (e.response?.statusCode == 403) {
          message = 'Account is deactivated or pending approval.';
        } else if (e.response?.statusCode == 500) {
          message = 'Server error. Please try again.';
        } else if (e.type == DioExceptionType.connectionTimeout || 
                   e.type == DioExceptionType.receiveTimeout) {
          message = 'Connection timed out. Please check your network.';
        } else if (e.type == DioExceptionType.connectionError) {
          message = 'Cannot connect to server. Please check your network.';
        }
      } catch (_) {}
      SnackbarHelper.showError(message);
    } catch (e, stackTrace) {
      debugPrint('Login unexpected error: $e\n$stackTrace');
      SnackbarHelper.showError('An unexpected error occurred during login.');
    } finally {
      isLoginLoading.value = false;
    }
  }

  Future<void> signup() async {
    if (!signupFormKey.currentState!.validate()) return;
    
    isSignupLoading.value = true;
    try {
      final response = await _apiService.dio.post('/vendor/signup', data: {
        'name': signupNameController.text.trim(),
        'email': signupEmailController.text.trim(),
        'phone': signupPhoneController.text.trim(),
        'username': signupUsernameController.text.trim(),
        'password': signupPasswordController.text,
        'password_confirmation': signupConfirmPasswordController.text,
        'referral_code': signupReferralCodeController.text.trim(),
      });

      if (response.data['status'] == true) {
        if (response.data['is_approved'] == false) {
          clearFields();
          Get.offAllNamed(AppRoutes.login);
          SnackbarHelper.showSuccess(response.data['message'] ?? 'Registration successful! Pending admin approval.');
          return;
        }

        final token = response.data['data']['token'];
        await _storageService.saveToken(token);
        
        // Fetch profile data immediately after signup
        if (Get.isRegistered<ProfileController>()) {
          Get.find<ProfileController>().fetchProfile();
        }

        if (Get.isRegistered<NotificationService>()) {
          Get.find<NotificationService>().refreshFCMToken();
        }

        // Clear fields on successful signup
        clearFields();

        Get.offAllNamed(AppRoutes.dashboard);
        SnackbarHelper.showSuccess(response.data['message']);
      } else {
        SnackbarHelper.showError(response.data['message'] ?? 'Registration failed');
      }
    } on DioException catch (e) {
      final message = e.response?.data['message'] ?? 'An error occurred during registration.';
      SnackbarHelper.showError(message);
    } finally {
      isSignupLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.dio.post('/vendor/logout');
    } catch (e) {
      // Ignore API errors on logout, just clear local session
    }
    await _storageService.removeToken();
    
    // Clear profile data so next user gets a clean state
    if (Get.isRegistered<ProfileController>()) {
      Get.find<ProfileController>().clearData();
    }

    // Clear login/signup input fields on logout
    clearFields();
    
    Get.offAllNamed(AppRoutes.login);
  }

  @override
  void onClose() {
    signupNameController.removeListener(_onFullNameChanged);
    // We are deliberately not disposing the TextEditingControllers here
    // because AuthController is used across multiple screens (Login, Signup, Drawer)
    // and GetX might dispose it when a route pops, causing the "used after being disposed" error.
    super.onClose();
  }
}
