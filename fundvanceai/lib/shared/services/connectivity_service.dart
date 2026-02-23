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

  final StreamController<bool> _controller =
      StreamController<bool>.broadcast();

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isOnline = true; // Assume online at start; updated on first event

  bool get isOnline => _isOnline;

  /// Broadcast stream of connectivity state (true = online).
  Stream<bool> get onConnectivityChanged => _controller.stream;

  /// Start listening. Call once from [main()].
  Future<void> initialize() async {
    // Get initial state
    final results = await _connectivity.checkConnectivity();
    _isOnline = _resultsToOnline(results);

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final online = _resultsToOnline(results);
      if (online != _isOnline) {
        _isOnline = online;
        _controller.add(_isOnline);
        debugPrint('[Connectivity] ${_isOnline ? "Online ✅" : "Offline ⚠️"}');
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

  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}
