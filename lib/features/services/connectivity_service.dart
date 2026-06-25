import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Connectivity service that verifies *real* internet access (not just a
/// network interface) by probing Google's lightweight `generate_204` endpoint.
///
/// `generate_204` returns an empty body with HTTP 204 and is designed exactly
/// for captive-portal / connectivity checks, so it is fast and cheap.
class ConnectivityService with ChangeNotifier {
  ConnectivityService() {
    _init();
  }

  // Lightweight endpoints used to confirm a true internet connection.
  // We try them in order; the first success wins.
  static const List<String> _probeUrls = [
    'https://www.gstatic.com/generate_204',
    'https://www.google.com/generate_204',
    'https://clients3.google.com/generate_204',
  ];

  static const Duration _probeTimeout = Duration(seconds: 5);
  static const Duration _periodicInterval = Duration(seconds: 15);

  bool _hasInternet = true;
  bool _isChecking = false;

  bool get hasInternet => _hasInternet;
  bool get isChecking => _isChecking;

  StreamSubscription? _subscription;
  Timer? _timer;

  Future<void> _init() async {
    await _verifyConnection();
    // Re-check whenever the OS reports a network change (wifi <-> mobile etc).
    _subscription =
        Connectivity().onConnectivityChanged.listen((_) => _verifyConnection());
    // Periodic re-check catches "connected to wifi but no real internet".
    _timer = Timer.periodic(_periodicInterval, (_) => _verifyConnection());
  }

  /// Returns true if at least one probe endpoint responds with HTTP 204.
  Future<bool> _hasRealInternet() async {
    // No interface at all -> definitely offline, skip the network call.
    final result = await Connectivity().checkConnectivity();
    if (result.contains(ConnectivityResult.none) && result.length == 1) {
      return false;
    }

    for (final url in _probeUrls) {
      try {
        final response =
            await http.get(Uri.parse(url)).timeout(_probeTimeout);
        if (response.statusCode == 204 || response.statusCode == 200) {
          return true;
        }
      } catch (_) {
        // Try the next endpoint.
      }
    }
    return false;
  }

  Future<void> _verifyConnection() async {
    if (_isChecking) return;
    _isChecking = true;
    notifyListeners();

    final online = await _hasRealInternet();

    _isChecking = false;
    if (online != _hasInternet) {
      _hasInternet = online;
    }
    notifyListeners();
  }

  /// Manual retry (used by the "No Internet" modal).
  Future<void> retryConnection() async => _verifyConnection();

  @override
  void dispose() {
    _subscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }
}
