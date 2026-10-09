import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio;
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../utils/snackbar_helper.dart';

class VendorReferralController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  final isLoading = false.obs;
  final isHistoryLoading = false.obs;
  final isWalletLoading = false.obs;
  final isSavingBank = false.obs;
  final isBankConfigured = false.obs;
  final passbookImageUrl = "".obs;
  final selectedPassbookImage = Rxn<File>();

  // Referral Stats
  var referralCode = "".obs;
  var shareMessage = "".obs;
  var isReferralEnabled = true.obs;
  var isRedemptionEnabled = true.obs;
  var minRedeemPoints = 500.obs;
  var pointValue = 1.0.obs;
  var totalReferrals = 0.obs;
  var successfulReferrals = 0.obs;
  var pendingReferrals = 0.obs;
  
  // Wallet Balances
  var totalEarned = 0.obs;
  var totalRedeemed = 0.obs;
  var availableBalance = 0.obs;
  var pendingBalance = 0.obs;

  // Lists
  var referralHistory = <Map<String, dynamic>>[].obs;
  var walletTransactions = <Map<String, dynamic>>[].obs;

  // Bank Form Controllers
  final accountHolderController = TextEditingController();
  final bankNameController = TextEditingController();
  final branchNameController = TextEditingController();
  final accountNumberController = TextEditingController();
  final confirmAccountNumberController = TextEditingController();
  final ifscCodeController = TextEditingController();
  final upiIdController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchReferralData();
    fetchReferralHistory();
    fetchWalletTransactions();
    fetchBankDetails();
  }

  Future<void> fetchReferralData() async {
    try {
      isLoading.value = true;
      final vId = await Get.find<StorageService>().getVendorId();
      final response = await _apiService.dio.get('/vendor/referral', queryParameters: {
        if (vId != null) 'vendor_id': vId,
      });
      if (response.data['status'] == true) {
        final data = response.data['data'];
        referralCode.value = data['referral_code'] ?? "";
        shareMessage.value = data['share_message'] ?? "";
        isReferralEnabled.value = data['is_referral_enabled'] ?? true;
        isRedemptionEnabled.value = data['is_redemption_enabled'] ?? true;
        minRedeemPoints.value = data['min_redeem_points'] ?? 500;
        pointValue.value = (data['point_value'] as num?)?.toDouble() ?? 1.0;
        totalReferrals.value = data['total_referrals'] ?? 0;
        successfulReferrals.value = data['successful_referrals'] ?? 0;
        pendingReferrals.value = data['pending_referrals'] ?? 0;
        
        // Balance
        totalEarned.value = data['bonus_points'] ?? 0;
        totalRedeemed.value = data['redeemed_points'] ?? 0;
        availableBalance.value = data['available_balance'] ?? 0;
        pendingBalance.value = data['pending_balance'] ?? 0;
      }
    } catch (e) {
      debugPrint("Error fetching referral data: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchReferralHistory() async {
    try {
      isHistoryLoading.value = true;
      final response = await _apiService.dio.get('/vendor/referral/history');
      if (response.data['status'] == true) {
        final List<dynamic> list = response.data['data'];
        referralHistory.assignAll(list.map((item) => Map<String, dynamic>.from(item)).toList());
      }
    } catch (e) {
      debugPrint("Error fetching referral history: $e");
    } finally {
      isHistoryLoading.value = false;
    }
  }

  Future<void> fetchWalletTransactions() async {
    try {
      isWalletLoading.value = true;
      final response = await _apiService.dio.get('/vendor/wallet/transactions');
      if (response.data['status'] == true) {
        final List<dynamic> list = response.data['data'];
        walletTransactions.assignAll(list.map((item) => Map<String, dynamic>.from(item)).toList());
      }
    } catch (e) {
      debugPrint("Error fetching wallet transactions: $e");
    } finally {
      isWalletLoading.value = false;
    }
  }

  Future<void> pickPassbookImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      selectedPassbookImage.value = File(image.path);
    }
  }

  Future<void> fetchBankDetails() async {
    try {
      final response = await _apiService.dio.get('/vendor/bank-details');
      if (response.data['status'] == true && response.data['data'] != null) {
        final bank = response.data['data'];
        accountHolderController.text = (bank['account_holder_name'] ?? "").toString().toUpperCase();
        bankNameController.text = (bank['bank_name'] ?? "").toString().toUpperCase();
        branchNameController.text = (bank['branch_name'] ?? "").toString().toUpperCase();
        accountNumberController.text = (bank['account_number'] ?? "").toString();
        confirmAccountNumberController.text = (bank['account_number'] ?? "").toString();
        ifscCodeController.text = (bank['ifsc_code'] ?? "").toString().toUpperCase();
        upiIdController.text = (bank['upi_id'] ?? "").toString().toUpperCase();
        isBankConfigured.value = accountNumberController.text.isNotEmpty;
        passbookImageUrl.value = bank['passbook_image'] ?? "";
        selectedPassbookImage.value = null; // Reset local selection
      } else {
        isBankConfigured.value = false;
        passbookImageUrl.value = "";
        selectedPassbookImage.value = null;
      }
    } catch (e) {
      debugPrint("Error fetching bank details: $e");
    }
  }

  Future<bool> saveBankDetails() async {
    if (accountNumberController.text != confirmAccountNumberController.text) {
      SnackbarHelper.showError("Account numbers do not match");
      return false;
    }

    try {
      isSavingBank.value = true;
      Map<String, dynamic> dataMap = {
        'account_holder_name': accountHolderController.text.trim(),
        'bank_name': bankNameController.text.trim(),
        'branch_name': branchNameController.text.trim(),
        'account_number': accountNumberController.text.trim(),
        'confirm_account_number': confirmAccountNumberController.text.trim(),
        'ifsc_code': ifscCodeController.text.trim(),
        'upi_id': upiIdController.text.trim(),
      };

      if (selectedPassbookImage.value != null) {
        dataMap['passbook_image'] = await dio.MultipartFile.fromFile(
          selectedPassbookImage.value!.path,
          filename: selectedPassbookImage.value!.path.split('/').last,
        );
      }

      final formData = dio.FormData.fromMap(dataMap);
      final response = await _apiService.dio.post('/vendor/bank-details', data: formData);

      if (response.data['status'] == true) {
        SnackbarHelper.showSuccess("Bank details saved successfully");
        isBankConfigured.value = true;
        // Reload fresh details to populate the image path
        await fetchBankDetails();
        return true;
      } else {
        SnackbarHelper.showError(response.data['message'] ?? "Failed to save bank details");
        return false;
      }
    } catch (e) {
      if (e is dio.DioException) {
        final msg = e.response?.data['message'] ?? e.message ?? 'Failed to save';
        SnackbarHelper.showError(msg);
      } else {
        SnackbarHelper.showError('Error: $e');
      }
      return false;
    } finally {
      isSavingBank.value = false;
    }
  }

  Future<bool> submitRedeemRequest(int points) async {
    try {
      isLoading.value = true;
      final response = await _apiService.dio.post('/vendor/redeem', data: {
        'redeem_points': points.toString(),
      });

      if (response.data['status'] == true) {
        SnackbarHelper.showSuccess("Redemption request submitted successfully");
        await fetchReferralData(); // Refresh balance
        await fetchWalletTransactions(); // Refresh transactions
        return true;
      } else {
        SnackbarHelper.showError(response.data['message'] ?? "Redemption failed");
        return false;
      }
    } catch (e) {
      if (e is dio.DioException) {
        final msg = e.response?.data['message'] ?? e.message ?? 'Failed to submit';
        SnackbarHelper.showError(msg);
      } else {
        SnackbarHelper.showError('Error: $e');
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    accountHolderController.dispose();
    bankNameController.dispose();
    branchNameController.dispose();
    accountNumberController.dispose();
    confirmAccountNumberController.dispose();
    ifscCodeController.dispose();
    upiIdController.dispose();
    super.onClose();
  }
}
