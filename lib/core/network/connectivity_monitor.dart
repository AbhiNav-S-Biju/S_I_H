// ==============================================================================
// NIRVANA - Connectivity Monitor
// Description: Monitors device network state using connectivity_plus and exposes
// a stream & Riverpod provider to orchestrate automatic background sync.
// ==============================================================================

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NetworkStatus {
  online,
  offline,
}

abstract class IConnectivityMonitor {
  Stream<NetworkStatus> get statusStream;
  Future<NetworkStatus> checkStatus();
}

class ConnectivityMonitor implements IConnectivityMonitor {
  final Connectivity _connectivity;

  ConnectivityMonitor({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  @override
  Stream<NetworkStatus> get statusStream {
    return _connectivity.onConnectivityChanged.map(_mapToStatus);
  }

  @override
  Future<NetworkStatus> checkStatus() async {
    final results = await _connectivity.checkConnectivity();
    return _mapToStatus(results);
  }

  static NetworkStatus _mapToStatus(List<ConnectivityResult> results) {
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      // If only 'none' is present
      if (results.length == 1 && results.first == ConnectivityResult.none) {
        return NetworkStatus.offline;
      }
      // If there's an active connection along with none, it's online
      final hasActive = results.any((r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet ||
          r == ConnectivityResult.vpn ||
          r == ConnectivityResult.other);
      return hasActive ? NetworkStatus.online : NetworkStatus.offline;
    }
    return NetworkStatus.online;
  }
}

/// Riverpod Providers
final connectivityMonitorProvider = Provider<IConnectivityMonitor>((ref) {
  return ConnectivityMonitor();
});

final networkStatusProvider = StreamProvider<NetworkStatus>((ref) {
  final monitor = ref.watch(connectivityMonitorProvider);
  return monitor.statusStream;
});
