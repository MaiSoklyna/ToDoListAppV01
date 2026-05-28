import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription? _subscription;
  bool _isOnline = true;

  bool get isOnline => _isOnline;

  /// Callback triggered when connection is restored (for sync)
  VoidCallback? onReconnected;

  ConnectivityService() {
    _init();
  }

  void _init() {
    _checkConnectivity();
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final wasOnline = _isOnline;
      _isOnline = results.any((r) => r != ConnectivityResult.none);
      if (wasOnline != _isOnline) {
        notifyListeners();
        // Trigger sync when reconnected
        if (_isOnline && !wasOnline) {
          onReconnected?.call();
        }
      }
    });
  }

  Future<void> _checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _isOnline = results.any((r) => r != ConnectivityResult.none);
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
