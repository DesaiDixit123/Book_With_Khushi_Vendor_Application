import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

class ConnectivityService extends GetxService {
  final Connectivity _connectivity = Connectivity();
  final RxBool isConnected = true.obs;

  Future<ConnectivityService> init() async {
    final List<ConnectivityResult> result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);
    
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    return this;
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
    if (result.contains(ConnectivityResult.none)) {
      isConnected.value = false;
      // You can trigger a global 'No Internet' overlay or snackbar here
    } else {
      isConnected.value = true;
    }
  }
}
