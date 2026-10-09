import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../../services/api_service.dart';
import '../../utils/snackbar_helper.dart';
import '../../routes/app_routes.dart';

class FormsController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  final isLoading = true.obs;
  final isLoadingLanguages = false.obs;
  final isSaving = false.obs;
  final isLoadingInputs = false.obs;

  final formsList = <Map<String, dynamic>>[].obs;
  final languagesList = <Map<String, dynamic>>[].obs;
  final inputsList = <Map<String, dynamic>>[].obs;

  // Currently selected form for edit/manage
  Map<String, dynamic>? selectedForm;

  @override
  void onInit() {
    super.onInit();
    fetchForms();
    fetchLanguages();
  }

  Future<void> fetchForms() async {
    isLoading.value = true;
    try {
      final response = await _apiService.dio.get('/vendor/forms');
      if (response.data['status'] == true) {
        formsList.value = List<Map<String, dynamic>>.from(response.data['data']);
      } else {
        SnackbarHelper.showError(response.data['message'] ?? 'Failed to load forms');
      }
    } on DioException catch (e) {
      SnackbarHelper.showError(e.response?.data?['message'] ?? e.message ?? 'Failed to load forms');
    } catch (_) {
      SnackbarHelper.showError('Failed to load forms');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchLanguages() async {
    isLoadingLanguages.value = true;
    try {
      final response = await _apiService.dio.get('/vendor/forms/languages');
      if (response.data['status'] == true) {
        languagesList.value = List<Map<String, dynamic>>.from(response.data['data']);
      }
    } catch (_) {} finally {
      isLoadingLanguages.value = false;
    }
  }

  Future<void> addForm({required int languageId, required String name, required int status}) async {
    isSaving.value = true;
    try {
      final response = await _apiService.dio.post('/vendor/forms', data: {
        'language_id': languageId, 'name': name, 'status': status,
      });
      if (response.data['status'] == true) {
        SnackbarHelper.showSuccess('Form created successfully!');
        await fetchForms();
        Get.offNamed(AppRoutes.forms);
      } else {
        SnackbarHelper.showError(response.data['message'] ?? 'Failed to create form');
      }
    } on DioException catch (e) {
      SnackbarHelper.showError(e.response?.data?['message'] ?? 'Failed to create form');
    } catch (_) {
      SnackbarHelper.showError('Failed to create form');
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> updateForm({required int id, required int languageId, required String name, required int status}) async {
    isSaving.value = true;
    try {
      final response = await _apiService.dio.put('/vendor/forms/$id', data: {
        'language_id': languageId, 'name': name, 'status': status,
      });
      if (response.data['status'] == true) {
        SnackbarHelper.showSuccess('Form updated successfully!');
        await fetchForms();
        Get.offNamed(AppRoutes.forms);
      } else {
        SnackbarHelper.showError(response.data['message'] ?? 'Failed to update form');
      }
    } on DioException catch (e) {
      SnackbarHelper.showError(e.response?.data?['message'] ?? 'Failed to update form');
    } catch (_) {
      SnackbarHelper.showError('Failed to update form');
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> deleteForm(int id) async {
    try {
      final response = await _apiService.dio.delete('/vendor/forms/$id');
      if (response.data['status'] == true) {
        SnackbarHelper.showSuccess('Form deleted successfully!');
        formsList.removeWhere((f) => f['id'] == id);
      } else {
        SnackbarHelper.showError('Failed to delete form');
      }
    } catch (_) {
      SnackbarHelper.showError('Failed to delete form');
    }
  }

  // ─── Form Inputs ──────────────────────────────────────────────────────────

  Future<void> fetchInputs(int formId) async {
    isLoadingInputs.value = true;
    inputsList.clear();
    try {
      final response = await _apiService.dio.get('/vendor/forms/$formId/inputs');
      if (response.data['status'] == true) {
        inputsList.value = List<Map<String, dynamic>>.from(response.data['data']);
      }
    } on DioException catch (e) {
      SnackbarHelper.showError(e.response?.data?['message'] ?? 'Failed to load inputs');
    } catch (_) {
      SnackbarHelper.showError('Failed to load inputs');
    } finally {
      isLoadingInputs.value = false;
    }
  }

  Future<void> addInput({
    required int formId,
    required String label,
    required String type,
    String placeholder = '',
    int isRequired = 0,
  }) async {
    isSaving.value = true;
    try {
      final response = await _apiService.dio.post('/vendor/forms/$formId/inputs', data: {
        'label': label,
        'type': type,
        'placeholder': placeholder,
        'is_required': isRequired,
      });
      if (response.data['status'] == true) {
        SnackbarHelper.showSuccess('Input added successfully!');
        await fetchInputs(formId);
        // screen resets itself
      } else {
        SnackbarHelper.showError(response.data['message'] ?? 'Failed to add input');
      }
    } on DioException catch (e) {
      SnackbarHelper.showError(e.response?.data?['message'] ?? 'Failed to add input');
    } catch (_) {
      SnackbarHelper.showError('Failed to add input');
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> deleteInput(int formId, int inputId) async {
    try {
      final response = await _apiService.dio.delete('/vendor/forms/$formId/inputs/$inputId');
      if (response.data['status'] == true) {
        SnackbarHelper.showSuccess('Input deleted!');
        inputsList.removeWhere((i) => i['id'] == inputId);
      } else {
        SnackbarHelper.showError('Failed to delete input');
      }
    } catch (_) {
      SnackbarHelper.showError('Failed to delete input');
    }
  }
}
