import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'storage_service.dart';

class ApiService extends GetxService {
  late Dio _dio;

  final String baseUrl = 'https://bookwithkhushi.com/api'; // Live Server
  // final String baseUrl = 'http://192.168.29.73:8000/api'; // Local Testing
  Future<ApiService> init() async {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      responseType: ResponseType.json,
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await Get.find<StorageService>().getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        options.headers['Accept'] = 'application/json';
        return handler.next(options);
      },
      onResponse: (response, handler) {
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        // Handle global errors like 401 Unauthorized here
        if (e.response?.statusCode == 401) {
          final path = e.requestOptions.path;
          // Only redirect if the 401 didn't come from login, signup, or password reset requests
          if (path != '/vendor/login' && path != '/vendor/signup' &&
              path != '/vendor/verify-email' && path != '/vendor/reset-password-direct' &&
              path != '/vendor/send-otp' && path != '/vendor/verify-otp-login') {
            Get.find<StorageService>().removeToken();
            Get.offAllNamed('/login'); // Force redirect to login
          }
        }
        return handler.next(e);
      },
    ));

    return this;
  }

  Dio get dio => _dio;
}
