import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityService with ChangeNotifier {
  bool _hasInternet = true;
  bool get hasInternet => _hasInternet;

  ConnectivityService() {
    _init();
  }

  Future<void> _init() async {
    await _checkConnectivity();
    Connectivity().onConnectivityChanged.listen((_) => _checkConnectivity());
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    final newStatus = !result.contains(ConnectivityResult.none);
    if (newStatus != _hasInternet) {
      _hasInternet = newStatus;
      notifyListeners();
    }
  }

  Future<void> retryConnection() async => _checkConnectivity();
}