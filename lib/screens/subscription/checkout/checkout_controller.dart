import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../services/api_service.dart';
import '../../../utils/snackbar_helper.dart';
import '../../../routes/app_routes.dart';

class CheckoutController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  final isLoading = false.obs;
  late Map<String, dynamic> package;
  final paymentMethod = 'Razorpay'.obs;

  // Razorpay keys from the Khushi web app
  static const String _razorpayKey = 'rzp_live_TizoH6DpiW0jl7';

  late Razorpay _razorpay;

  @override
  void onInit() {
    super.onInit();
    package = Get.arguments ?? {};
    _initRazorpay();
  }

  void _initRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  Future<void> checkout() async {
    if (paymentMethod.value == 'Razorpay') {
      _openRazorpay();
    } else {
      SnackbarHelper.showError('Please select Razorpay as the payment method.');
    }
  }

  void _openRazorpay() {
    final priceStr = package['price']?.toString() ?? '0';
    final priceDouble = double.tryParse(priceStr) ?? 0.0;
    
    final gstPercentage = double.tryParse(package['subscription_gst']?.toString() ?? '0') ?? 0.0;
    final taxAmount = (priceDouble * gstPercentage) / 100;
    final totalDouble = priceDouble + taxAmount;

    // Razorpay needs amount in paise (1 INR = 100 paise)
    final amountInPaise = (totalDouble * 100).round();

    final options = {
      'key': _razorpayKey,
      'amount': amountInPaise,
      'name': 'BookWithKhushi',
      'description': '${package['title'] ?? 'Membership'} Plan',
      'currency': 'INR',
      'prefill': {
        'contact': '',
        'email': '',
      },
      'theme': {
        'color': '#471D24', // App navyBlue/burgundy color
      },
      'modal': {
        'confirm_close': true,
        'animation': true,
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      SnackbarHelper.showError('Could not open payment gateway. Please try again.');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // Payment done on Razorpay side — now activate membership on backend
    isLoading.value = true;
    try {
      final priceStr = package['price']?.toString() ?? '0';
      final priceDouble = double.tryParse(priceStr) ?? 0.0;
      final gstPercentage = double.tryParse(package['subscription_gst']?.toString() ?? '0') ?? 0.0;
      final taxAmount = (priceDouble * gstPercentage) / 100;
      final totalDouble = priceDouble + taxAmount;

      final apiResponse = await _apiService.dio.post(
        '/vendor/subscription/purchase',
        data: {
          'package_id': package['id'],
          'payment_id': response.paymentId ?? '',
          'order_id': response.orderId ?? '',
          'signature': response.signature ?? '',
          'payment_method': 'Razorpay',
          'amount': totalDouble,
        },
      );

      if (apiResponse.data['status'] == true) {
        SnackbarHelper.showSuccess('🎉 Membership activated successfully!');
        Get.offAllNamed(AppRoutes.dashboard);
      } else {
        // Payment went through but server activation failed — inform user
        SnackbarHelper.showSuccess(
          'Payment successful! Payment ID: ${response.paymentId}. Contact support if membership is not activated.',
        );
        Get.offAllNamed(AppRoutes.dashboard);
      }
    } catch (e) {
      // API call failed but payment WAS successful — don't show error
      SnackbarHelper.showSuccess(
        'Payment received! ID: ${response.paymentId}. Your plan will activate shortly.',
      );
      Get.offAllNamed(AppRoutes.dashboard);
    } finally {
      isLoading.value = false;
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    final message = response.message ?? 'Payment was cancelled or failed.';
    if (response.code == Razorpay.PAYMENT_CANCELLED) {
      SnackbarHelper.showError('Payment cancelled.');
    } else {
      SnackbarHelper.showError('Payment failed: $message');
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    SnackbarHelper.showSuccess('External wallet selected: ${response.walletName}');
  }

  @override
  void onClose() {
    _razorpay.clear(); // Remove listeners to avoid memory leaks
    super.onClose();
  }
}
