import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../services/api_service.dart';
import '../../utils/snackbar_helper.dart';
import '../../routes/app_routes.dart';

class SpacesController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  final isLoading = true.obs;
  final spacesList = [].obs;
  final allSpaces = [].obs;
  final categories = [].obs;

  final searchQuery = ''.obs;
  final selectedCategory = 'All Categories'.obs;
  final selectedType = 'All Types'.obs;
  final selectedSort = 'Latest'.obs; // Latest, Oldest, Name A-Z, Name Z-A
  final hasError = false.obs;

  // Featuring Space State Variables
  final isFeaturePrereqLoading = false.obs;
  final featureCharges = [].obs;
  final paymentGateways = [].obs;
  final selectedChargeId = RxnInt();
  final selectedGatewayName = 'Select a Payment Method'.obs;
  final isCheckoutLoading = false.obs;

  late Razorpay _razorpay;
  int? _checkoutSpaceId;

  @override
  void onInit() {
    super.onInit();
    fetchSpaces();
    _initRazorpay();
  }

  Future<void> fetchSpaces() async {
    isLoading.value = true;
    hasError.value = false;
    try {
      // Fetch both spaces and prerequisites in parallel
      final results = await Future.wait([
        _apiService.dio.get('/vendor/spaces'),
        _apiService.dio.get('/vendor/space/prerequisites'),
      ]);

      final spaceResponse = results[0];
      final prereqResponse = results[1];

      if (prereqResponse.data['status'] == true) {
        final List cats = prereqResponse.data['data']['categories'] ?? [];
        categories.value = cats;
      }

      if (spaceResponse.data['status'] == true) {
        allSpaces.value = spaceResponse.data['data'];
        applyFilters();
      }
    } catch (e) {
      hasError.value = true;
      SnackbarHelper.showError('Failed to load spaces or filters');
    } finally {
      isLoading.value = false;
    }
  }

  void applyFilters() {
    var filtered = allSpaces.toList();
    
    // Filter by search text (title, address, city)
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      filtered = filtered.where((space) {
        final title = (space['title'] ?? '').toString().toLowerCase();
        final address = (space['address'] ?? '').toString().toLowerCase();
        final city = (space['city'] ?? '').toString().toLowerCase();
        return title.contains(query) || address.contains(query) || city.contains(query);
      }).toList();
    }
    
    // Filter by category
    if (selectedCategory.value != 'All Categories') {
      filtered = filtered.where((space) {
        final cat = categories.firstWhere((c) => c['name'] == selectedCategory.value, orElse: () => null);
        if (cat != null) {
          return space['space_category_id'] == cat['id'] || space['category_id'] == cat['id'];
        }
        return true;
      }).toList();
    }

    // Filter by status (Type)
    if (selectedType.value != 'All Types') {
      filtered = filtered.where((space) {
        if (selectedType.value == 'Active') return space['space_status'] == 1;
        if (selectedType.value == 'Inactive') return space['space_status'] != 1;
        return true;
      }).toList();
    }

    // Sort By logic
    switch (selectedSort.value) {
      case 'Oldest':
        filtered.sort((a, b) {
          final idA = int.tryParse(a['id']?.toString() ?? '0') ?? 0;
          final idB = int.tryParse(b['id']?.toString() ?? '0') ?? 0;
          return idA.compareTo(idB);
        });
        break;
      case 'Name A-Z':
        filtered.sort((a, b) {
          final nameA = (a['title'] ?? '').toString().toLowerCase();
          final nameB = (b['title'] ?? '').toString().toLowerCase();
          return nameA.compareTo(nameB);
        });
        break;
      case 'Name Z-A':
        filtered.sort((a, b) {
          final nameA = (a['title'] ?? '').toString().toLowerCase();
          final nameB = (b['title'] ?? '').toString().toLowerCase();
          return nameB.compareTo(nameA);
        });
        break;
      case 'Latest':
      default:
        filtered.sort((a, b) {
          final idA = int.tryParse(a['id']?.toString() ?? '0') ?? 0;
          final idB = int.tryParse(b['id']?.toString() ?? '0') ?? 0;
          return idB.compareTo(idA);
        });
        break;
    }
    
    spacesList.value = filtered;
  }

  void updateSearch(String query) {
    searchQuery.value = query;
    applyFilters();
  }

  void updateCategory(String category) {
    selectedCategory.value = category;
    applyFilters();
  }

  void updateType(String type) {
    selectedType.value = type;
    applyFilters();
  }

  void updateSort(String sortOption) {
    selectedSort.value = sortOption;
    applyFilters();
  }

  Future<void> checkMembershipAndAddSpace() async {
    try {
      SnackbarHelper.showSuccess('Checking membership status...');
      final subResponse = await _apiService.dio.get('/vendor/subscription');
      if (subResponse.data['status'] == true) {
        final membership = subResponse.data['data']['current_membership'];
        if (membership == null) {
          // No active membership
          Get.toNamed(AppRoutes.subscription);
        } else {
          // Check if space limit is reached
          final isLimitReached = membership['is_space_limit_reached'] ?? false;
          if (isLimitReached) {
            SnackbarHelper.showError('Your package limit for adding spaces is over or downgraded. Please upgrade your package to add more spaces.');
          } else {
            // Active membership
            final result = await Get.toNamed(AppRoutes.addSpace);
            if (result == true) {
              fetchSpaces();
            }
          }
        }
      }
    } catch (e) {
      SnackbarHelper.showError('Failed to verify membership');
    }
  }

  Future<void> deleteSpace(int id) async {
    try {
      final response = await _apiService.dio.post('/vendor/space/delete/$id');
      if (response.data['status'] == true) {
        SnackbarHelper.showSuccess('Space deleted successfully');
        fetchSpaces();
      } else {
        SnackbarHelper.showError(response.data['message'] ?? 'Failed to delete space');
      }
    } catch (e) {
      SnackbarHelper.showError('Error deleting space. Check your connection.');
    }
  }

  Future<void> editSpace(Map space) async {
    Map fullSpace = space;
    try {
      final response = await _apiService.dio.get('/vendor/space/${space['id']}');
      if (response.data != null && response.data['status'] == true && response.data['data'] != null) {
        fullSpace = response.data['data'];
      }
    } catch (_) {}
    final result = await Get.toNamed(AppRoutes.addSpace, arguments: fullSpace);
    if (result == true) {
      fetchSpaces();
    }
  }

  Future<void> fetchFeaturePrerequisites() async {
    isFeaturePrereqLoading.value = true;
    try {
      final response = await _apiService.dio.get('/vendor/space/feature/prerequisites');
      if (response.data['status'] == true) {
        featureCharges.value = response.data['data']['featured_charges'] ?? [];
        paymentGateways.value = response.data['data']['payment_gateways'] ?? [];
        if (featureCharges.isNotEmpty) {
          selectedChargeId.value = featureCharges[0]['id'];
        } else {
          selectedChargeId.value = null;
        }
        selectedGatewayName.value = 'Select a Payment Method';
      }
    } catch (e) {
      SnackbarHelper.showError('Failed to load feature promotions or gateways');
    } finally {
      isFeaturePrereqLoading.value = false;
    }
  }

  void _initRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _openRazorpay(double price, String dayText) {
    final amountInPaise = (price * 100).toInt();

    final options = {
      'key': 'rzp_live_TizoH6DpiW0jl7',
      'amount': amountInPaise,
      'name': 'BookWithKhushi',
      'description': 'Promote space for $dayText',
      'currency': 'INR',
      'prefill': {
        'contact': '',
        'email': '',
      },
      'theme': {
        'color': '#471D24', // Burgundy
      },
      'modal': {
        'confirm_close': true,
        'animation': true,
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      SnackbarHelper.showError('Could not open Razorpay gateway');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (_checkoutSpaceId == null) return;
    isCheckoutLoading.value = true;
    try {
      final res = await _apiService.dio.post(
        '/vendor/space/feature/checkout',
        data: {
          'space_id': _checkoutSpaceId,
          'feature_charge_id': selectedChargeId.value,
          'payment_method': 'Razorpay',
          'gateway_type': 'online',
          'payment_id': response.paymentId ?? '',
          'order_id': response.orderId ?? '',
          'signature': response.signature ?? '',
        },
      );
      if (res.data['status'] == true) {
        if (Get.isDialogOpen ?? false) Get.back(); // close checkout dialog first!
        SnackbarHelper.showSuccess('🎉 Space featured successfully!');
        fetchSpaces();
      } else {
        SnackbarHelper.showError(res.data['message'] ?? 'Failed to complete feature subscription');
      }
    } catch (e) {
      SnackbarHelper.showError('Failed to complete feature checkout on server');
    } finally {
      isCheckoutLoading.value = false;
      _checkoutSpaceId = null;
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    final message = response.message ?? 'Payment was cancelled or failed.';
    if (response.code == Razorpay.PAYMENT_CANCELLED) {
      SnackbarHelper.showError('Payment cancelled.');
    } else {
      SnackbarHelper.showError('Payment failed: $message');
    }
    _checkoutSpaceId = null;
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _checkoutSpaceId = null;
  }

  Future<bool> checkoutFeature(int spaceId) async {
    if (selectedChargeId.value == null) {
      SnackbarHelper.showError('Please select a promotion package.');
      return false;
    }
    if (selectedGatewayName.value.isEmpty || selectedGatewayName.value == 'Select a Payment Method') {
      SnackbarHelper.showError('Please select a payment method.');
      return false;
    }

    final charge = featureCharges.firstWhere(
      (c) => c['id'] == selectedChargeId.value,
      orElse: () => null,
    );
    if (charge == null) {
      SnackbarHelper.showError('Invalid package selected');
      return false;
    }

    final gateway = paymentGateways.firstWhere(
      (g) => g['name'] == selectedGatewayName.value,
      orElse: () => null,
    );
    final gatewayType = gateway != null ? gateway['type'] : 'online';

    if (selectedGatewayName.value == 'Razorpay') {
      _checkoutSpaceId = spaceId;
      final priceStr = charge['price']?.toString() ?? '0';
      final priceDouble = double.tryParse(priceStr) ?? 0.0;
      final dayText = '${charge['day']} days';
      _openRazorpay(priceDouble, dayText);
      return false;
    } else {
      isCheckoutLoading.value = true;
      try {
        final response = await _apiService.dio.post(
          '/vendor/space/feature/checkout',
          data: {
            'space_id': spaceId,
            'feature_charge_id': selectedChargeId.value,
            'payment_method': selectedGatewayName.value,
            'gateway_type': gatewayType,
          },
        );

        if (response.data['status'] == true) {
          if (Get.isDialogOpen ?? false) Get.back(); // close the dialog first!
          SnackbarHelper.showSuccess('CASH featured request sent successfully! Waiting for admin approval.');
          fetchSpaces(); // Reload spaces to reflect featured status change
          return false; // return false as the dialog is already popped
        } else {
          SnackbarHelper.showError(response.data['message'] ?? 'Failed to process checkout');
          return false;
        }
      } catch (e) {
        SnackbarHelper.showError('Failed to process checkout. Please try again.');
        return false;
      } finally {
        isCheckoutLoading.value = false;
      }
    }
  }

  @override
  void onClose() {
    _razorpay.clear();
    super.onClose();
  }
}
