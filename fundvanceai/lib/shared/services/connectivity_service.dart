import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Monitors network connectivity and exposes a broadcast stream of [bool]
/// (true = online, false = offline).
///
/// Use [ConnectivityService.instance] for the singleton.
class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _connectivity = Connectivity();

  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isOnline = true; // Assume online at start; updated on first event
  bool _isWifi = false; // True when connected via Wi-Fi or Ethernet

  bool get isOnline => _isOnline;

  /// True when the current connection is specifically Wi-Fi or Ethernet
  /// (not mobile data). Used by the "Wi-Fi only sync" setting.
  bool get isWifiConnected => _isWifi;

  /// Broadcast stream of connectivity state (true = online).
  Stream<bool> get onConnectivityChanged => _controller.stream;

  /// Start listening. Call once from [main()].
  Future<void> initialize() async {
    // Get initial state
    final results = await _connectivity.checkConnectivity();
    _isOnline = _resultsToOnline(results);
    _isWifi = _resultsToWifi(results);

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final online = _resultsToOnline(results);
      final wifi = _resultsToWifi(results);
      if (online != _isOnline || wifi != _isWifi) {
        _isOnline = online;
        _isWifi = wifi;
        _controller.add(_isOnline);
        debugPrint(
            '[Connectivity] ${_isOnline ? "Online ✅" : "Offline ⚠️"} wifi=$_isWifi');
      }
    });
  }

  bool _resultsToOnline(List<ConnectivityResult> results) {
    return results.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet ||
        r == ConnectivityResult.vpn);
  }

  bool _resultsToWifi(List<ConnectivityResult> results) {
    return results.any((r) =>
        r == ConnectivityResult.wifi || r == ConnectivityResult.ethernet);
  }

  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}
