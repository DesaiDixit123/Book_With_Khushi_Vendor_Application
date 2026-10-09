import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart' as dio;
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../utils/snackbar_helper.dart';

class ProfileController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  final isLoading = false.obs; // Start false — don't block UI on first init
  final isSaving = false.obs;

  final username = ''.obs;
  final vendorName = ''.obs;
  final vendorId = RxnInt();

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final countryController = TextEditingController();
  final zipController = TextEditingController();
  final detailsController = TextEditingController();

  final profileImageUrl = RxnString();
  final selectedImage = Rxn<XFile>();

  // Track if we've loaded data at least once
  bool _hasLoaded = false;

  @override
  void onInit() {
    super.onInit();
    // Only fetch profile if user is already logged in (has token).
    // Do NOT block splash startup — check token first before making API call.
    _fetchProfileIfLoggedIn();
  }

  Future<void> _fetchProfileIfLoggedIn() async {
    try {
      final token = await Get.find<StorageService>().getToken();
      if (token != null) {
        fetchProfile();
      }
    } catch (e) {
      debugPrint('ProfileController: Could not check token on init: $e');
    }
  }

  void clearData() {
    username.value = '';
    vendorName.value = '';
    nameController.clear();
    phoneController.clear();
    addressController.clear();
    cityController.clear();
    stateController.clear();
    countryController.clear();
    zipController.clear();
    detailsController.clear();
    profileImageUrl.value = null;
    selectedImage.value = null;
    _hasLoaded = false;
  }

  Future<void> fetchProfile() async {
    // If already loading, skip
    if (isLoading.value) return;

    final token = await Get.find<StorageService>().getToken();
    if (token == null) return;

    isLoading.value = true;
    try {
      final response = await _apiService.dio.get('/vendor/profile');
      if (response.data['status'] == true) {
        final data = response.data['data'];
        final id = data['id'];
        if (id != null) {
          vendorId.value = id;
          Get.find<StorageService>().saveVendorId(id);
        }
        username.value = data['username'] ?? '';
        vendorName.value = data['name'] ?? '';
        nameController.text = data['name'] ?? '';
        phoneController.text = data['phone'] ?? '';
        addressController.text = data['address'] ?? '';
        cityController.text = data['city'] ?? '';
        stateController.text = data['state'] ?? '';
        countryController.text = data['country'] ?? '';
        zipController.text = data['zip_code'] ?? '';
        detailsController.text = data['details'] ?? '';
        profileImageUrl.value = data['photo'];
        _hasLoaded = true;
      }
    } catch (e) {
      if (e is dio.DioException) {
        final msg = e.response?.data['message'] ?? e.message ?? 'Failed to load profile';
        SnackbarHelper.showError('Profile Error: $msg');
      } else {
        SnackbarHelper.showError('Profile Error: $e');
      }
    } finally {
      isLoading.value = false;
    }
  }

  bool get hasLoaded => _hasLoaded;

  void pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      selectedImage.value = image;
    }
  }

  Future<void> updateProfile() async {
    if (nameController.text.trim().isEmpty || phoneController.text.trim().isEmpty) {
      SnackbarHelper.showError('Name and Phone are required');
      return;
    }

    isSaving.value = true;
    try {
      final vId = await Get.find<StorageService>().getVendorId();
      var formDataMap = <String, dynamic>{
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'address': addressController.text.trim(),
        'city': cityController.text.trim(),
        'state': stateController.text.trim(),
        'country': countryController.text.trim(),
        'zip_code': zipController.text.trim(),
        'details': detailsController.text.trim(),
      };
      if (vId != null && vId.toString().isNotEmpty) {
        formDataMap['vendor_id'] = vId;
      } else if (vendorId.value != null) {
        formDataMap['vendor_id'] = vendorId.value;
      }

      var formData = dio.FormData.fromMap(formDataMap);

      if (selectedImage.value != null) {
        formData.files.add(MapEntry(
          'photo',
          await dio.MultipartFile.fromFile(selectedImage.value!.path, filename: 'profile.jpg'),
        ));
      }

      final response = await _apiService.dio.post('/vendor/profile/update', data: formData);

      if (response.data['status'] == true) {
        SnackbarHelper.showSuccess(response.data['message'] ?? 'Profile updated successfully!');
        selectedImage.value = null;
        if (response.data['data'] != null && response.data['data']['photo'] != null) {
          profileImageUrl.value = response.data['data']['photo'];
        }
        await fetchProfile(); // Refresh data after save
      } else {
        SnackbarHelper.showError(response.data['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      String msg = 'Failed to update profile.';
      if (e is dio.DioException && e.response != null && e.response?.data is Map) {
        msg = e.response?.data['message'] ?? msg;
      }
      SnackbarHelper.showError(msg);
    } finally {
      isSaving.value = false;
    }
  }

  // NOTE: Do NOT dispose TextEditingControllers here.
  // This controller is permanent — disposing controllers would crash
  // the profile screen if it's re-opened after navigating away.
  @override
  void onClose() {
    super.onClose();
  }
}
