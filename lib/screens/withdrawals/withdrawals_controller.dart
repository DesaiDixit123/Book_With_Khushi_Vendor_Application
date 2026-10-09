import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../utils/snackbar_helper.dart';

class WithdrawalsController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final StorageService _storageService = Get.find<StorageService>();

  final isLoading = true.obs;
  final balance = 0.0.obs;
  final withdrawals = [].obs;
  final methods = <dynamic>[].obs;

  final amountController = TextEditingController();
  final referenceController = TextEditingController();
  final selectedMethodId = Rxn<int>();

  // Live calculation observables
  final payableAmount = 0.0.obs;
  final totalCharge = 0.0.obs;
  final remainingBalance = 0.0.obs;

  // Validation & submit state
  final isSubmitting = false.obs;
  final amountErrorText = ''.obs;
  final rxAmountText = ''.obs;

  Map<String, dynamic>? get selectedMethod {
    if (methods.isEmpty) return null;
    if (selectedMethodId.value != null) {
      final found = methods.firstWhere((m) => m['id'] == selectedMethodId.value, orElse: () => null);
      if (found != null) return Map<String, dynamic>.from(found);
    }
    return Map<String, dynamic>.from(methods.first);
  }

  bool get isSubmitEnabled {
    if (balance.value <= 0) return false;
    if (isSubmitting.value) return false;
    final text = rxAmountText.value.trim();
    if (text.isEmpty) return false;
    if (amountErrorText.value.isNotEmpty) return false;
    double amt = double.tryParse(text) ?? 0.0;
    if (amt <= 0 || amt > balance.value) return false;
    return true;
  }

  @override
  void onInit() {
    super.onInit();
    fetchWithdrawals();

    amountController.addListener(_onAmountChanged);
    selectedMethodId.listen((_) => _onAmountChanged());
  }

  void _onAmountChanged() {
    rxAmountText.value = amountController.text;
    _calculateLiveAmounts();
    _validateAmount();
  }

  void _validateAmount() {
    final text = amountController.text.trim();
    if (text.isEmpty) {
      amountErrorText.value = '';
      return;
    }

    double amt = double.tryParse(text) ?? -1.0;
    if (amt <= 0) {
      amountErrorText.value = 'Please enter a valid amount';
      return;
    }

    if (amt > balance.value) {
      amountErrorText.value = 'Amount exceeds your balance (₹${balance.value.toStringAsFixed(2)})';
      return;
    }

    final method = selectedMethod;
    if (method != null) {
      double minLimit = (method['min_limit'] ?? 0).toDouble();
      double maxLimit = (method['max_limit'] ?? 999999999).toDouble();

      if (amt < minLimit) {
        amountErrorText.value = 'Amount is below minimum limit of ₹${minLimit.toStringAsFixed(0)}';
        return;
      }
      if (amt > maxLimit) {
        amountErrorText.value = 'Amount exceeds maximum limit of ₹${maxLimit.toStringAsFixed(0)}';
        return;
      }
    }

    amountErrorText.value = '';
  }

  Future<void> fetchWithdrawals() async {
    isLoading.value = true;
    try {
      final response = await _apiService.dio.get('/vendor/withdrawals');
      if (response.data['status'] == true) {
        final data = response.data['data'];
        balance.value = (data['balance'] ?? 0).toDouble();
        withdrawals.value = data['withdrawals'];
        methods.value = data['methods'];
        if (methods.isNotEmpty && selectedMethodId.value == null) {
          selectedMethodId.value = methods.first['id'];
        }
        _onAmountChanged();
      }
    } catch (e) {
      SnackbarHelper.showError('Failed to load withdrawals data');
    } finally {
      isLoading.value = false;
    }
  }

  void _calculateLiveAmounts() {
    double amount = double.tryParse(amountController.text) ?? 0.0;
    final method = selectedMethod;
    
    if (method == null || amount <= 0) {
      payableAmount.value = 0.0;
      totalCharge.value = 0.0;
      remainingBalance.value = balance.value;
      return;
    }

    double fixedCharge = (method['fixed_charge'] ?? 0).toDouble();
    double percentageCharge = (method['percentage_charge'] ?? 0).toDouble();
    
    double charge = fixedCharge + ((amount * percentageCharge) / 100);
    totalCharge.value = charge;
    payableAmount.value = amount - charge;
    remainingBalance.value = balance.value - amount;
  }

  Future<void> requestWithdrawal() async {
    if (!isSubmitEnabled) return;

    final method = selectedMethod;
    if (method == null) {
      SnackbarHelper.showError('No withdrawal method available');
      return;
    }

    final methodId = method['id'];
    isSubmitting.value = true;

    try {
      final vId = await _storageService.getVendorId();
      final response = await _apiService.dio.post('/vendor/withdrawals', data: {
        'method_id': methodId,
        'amount': amountController.text.trim(),
        'additional_reference': referenceController.text.trim(),
        if (vId != null) 'vendor_id': vId,
      });

      if (response.data['status'] == true) {
        SnackbarHelper.showSuccess(response.data['message']);
        amountController.clear();
        referenceController.clear();
        Get.back(); // return to list screen
        fetchWithdrawals(); // refresh list
      } else {
        SnackbarHelper.showError(response.data['message']);
      }
    } catch (e) {
      String errorMsg = 'Failed to submit withdrawal request.';
      if (e is DioException && e.response != null && e.response?.data is Map) {
        errorMsg = e.response?.data['message'] ?? errorMsg;
      }
      SnackbarHelper.showError(errorMsg);
    } finally {
      isSubmitting.value = false;
    }
  }

  @override
  void onClose() {
    amountController.dispose();
    referenceController.dispose();
    super.onClose();
  }
}
