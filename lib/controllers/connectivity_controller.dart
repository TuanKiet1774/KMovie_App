import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'movie_controller.dart';

class ConnectivityController extends GetxController {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  
  final _isConnected = true.obs;
  bool get isConnected => _isConnected.value;
  RxBool get isConnectedRx => _isConnected;

  @override
  void onInit() {
    super.onInit();
    _checkInitialStatus();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _checkInitialStatus() async {
    final result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    bool connected = results.any((result) => result != ConnectivityResult.none);
    
    // Nếu trước đó mất mạng và bây giờ có mạng, báo hiệu để reload
    if (!_isConnected.value && connected) {
      _onNetworkRestored();
    }
    
    _isConnected.value = connected;
    print('Connectivity changed: ${results.toString()} - Connected: $connected');
  }

  void _onNetworkRestored() {
    // Tự động tải lại dữ liệu khi có mạng trở lại
    if (Get.isRegistered<MovieController>()) {
      Get.find<MovieController>().refreshMovies();
    }
    
    Get.snackbar(
      'Trực tuyến',
      'Đã kết nối lại internet. Đang tự động tải lại dữ liệu...',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.withOpacity(0.8),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.wifi, color: Colors.white),
    );
  }

  @override
  void onClose() {
    _connectivitySubscription.cancel();
    super.onClose();
  }
}
