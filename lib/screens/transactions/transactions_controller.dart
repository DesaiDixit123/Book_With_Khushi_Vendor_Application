import 'package:get/get.dart';
import '../../services/api_service.dart';
import '../../utils/snackbar_helper.dart';

class TransactionsController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  final isLoading = true.obs;
  final transactionsList = [].obs;

  @override
  void onInit() {
    super.onInit();
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    isLoading.value = true;
    try {
      final response = await _apiService.dio.get('/vendor/transactions');
      if (response.data['status'] == true) {
        transactionsList.value = response.data['data'];
      }
    } catch (e) {
      SnackbarHelper.showError('Failed to load transactions');
    } finally {
      isLoading.value = false;
    }
  }
}
