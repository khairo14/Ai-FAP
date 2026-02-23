import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:fundvanceai/shared/services/connectivity_service.dart';
import 'package:fundvanceai/shared/services/sync_service.dart';

/// ChangeNotifier that wraps [ConnectivityService] for use in the widget tree.
class ConnectivityProvider extends ChangeNotifier {
  ConnectivityProvider() {
    _isOnline = ConnectivityService.instance.isOnline;
    _subscription = ConnectivityService.instance.onConnectivityChanged
        .listen((online) {
      final wasOfflineBefore = !_isOnline;
      _isOnline = online;
      if (wasOfflineBefore && online) {
        _wasOffline = true;
        // Automatically drain the pending-ops queue on reconnect
        SyncService.instance.syncPending().catchError((_) {});
      }
      notifyListeners();
    });
  }

  late bool _isOnline;
  bool _wasOffline = false;
  StreamSubscription<bool>? _subscription;

  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;

  /// True once after coming back online from an offline state.
  /// Consuming this clears the flag.
  bool consumeWasOffline() {
    if (_wasOffline) {
      _wasOffline = false;
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
