import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/api_service.dart';
import '../../../utils/snackbar_helper.dart';

class AddServiceController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  final isEditMode = false.obs;
  final isLoading = false.obs;

  late Map<String, dynamic> space;
  Map<String, dynamic>? service;

  // Form Fields
  final selectedStatus = '1'.obs; // 1 = Active, 0 = Inactive
  final serialNumController = TextEditingController();
  final hasVariants = false.obs; // Yes / No
  final selectedPriceType = 'fixed'.obs; // fixed / per person
  final priceController = TextEditingController();

  // Translations (English Language Default)
  final titleController = TextEditingController();
  final keywordsController = TextEditingController();
  final descController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    space = args['space'] as Map<String, dynamic>? ?? {};
    service = args['service'] as Map<String, dynamic>?;

    if (service != null) {
      isEditMode.value = true;
      _prefillData();
    }
  }

  void _prefillData() {
    selectedStatus.value = (service!['status'] ?? 1).toString();
    serialNumController.text = (service!['serial_number'] ?? '').toString();
    hasVariants.value = service!['has_sub_services'] == 1;
    selectedPriceType.value = service!['price_type'] ?? 'fixed';
    priceController.text = (service!['price'] ?? '').toString();
    titleController.text = service!['title'] ?? '';
    keywordsController.text = service!['meta_keywords'] ?? '';
    descController.text = service!['meta_description'] ?? '';
  }

  Future<void> submit() async {
    final titleText = titleController.text.trim();
    final serialText = serialNumController.text.trim();
    final priceText = priceController.text.trim();

    if (titleText.isEmpty) {
      SnackbarHelper.showError('Service title is required');
      return;
    }

    if (serialText.isEmpty) {
      SnackbarHelper.showError('Serial number is required');
      return;
    }

    if (!hasVariants.value && priceText.isEmpty) {
      SnackbarHelper.showError('Price is required when variants are disabled');
      return;
    }

    isLoading.value = true;

    final requestBody = {
      'status': int.tryParse(selectedStatus.value) ?? 1,
      'serial_number': int.tryParse(serialText) ?? 1,
      'has_sub_services': hasVariants.value ? 1 : 0,
      'price_type': selectedPriceType.value,
      'price': !hasVariants.value ? (double.tryParse(priceText) ?? 0.0) : 0.0,
      'title': titleText,
      'meta_keywords': keywordsController.text.trim(),
      'meta_description': descController.text.trim(),
    };

    try {
      final String url = isEditMode.value
          ? '/vendor/services/update/${service!['id']}'
          : '/vendor/spaces/${space['id']}/services';

      final response = await _apiService.dio.post(url, data: requestBody);

      if (response.data['status'] == true) {
        Get.back(result: true);
        SnackbarHelper.showSuccess(
          isEditMode.value ? 'Service updated successfully' : 'Service created successfully',
        );
      } else {
        SnackbarHelper.showError(response.data['message'] ?? 'Failed to save service');
      }
    } catch (e) {
      SnackbarHelper.showError('Failed to save service. Check your connection.');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    serialNumController.dispose();
    priceController.dispose();
    titleController.dispose();
    keywordsController.dispose();
    descController.dispose();
    super.onClose();
  }
}
