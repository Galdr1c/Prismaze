import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:flutter/foundation.dart';

enum ConnectionStatus {
  online,
  offline,
}

class NetworkManager {
  static final NetworkManager _instance = NetworkManager._internal();
  factory NetworkManager() => _instance;
  NetworkManager._internal();

  final Connectivity _connectivity = Connectivity();
  final InternetConnectionChecker _internetChecker = InternetConnectionChecker();

  // Stream controller for connection status
  final StreamController<ConnectionStatus> _controller = StreamController<ConnectionStatus>.broadcast();
  Stream<ConnectionStatus> get statusStream => _controller.stream;

  bool _isOnline = false;
  bool get isOnline => _isOnline;

  // Initialize monitoring
  Future<void> init() async {
    // Initial check
    await _checkConnection();

    // Listen to changes
    _connectivity.onConnectivityChanged.listen((result) {
      _checkConnection();
    });
    
    print("NetworkManager: Initialized. Status: ${_isOnline ? 'Online' : 'Offline'}");
  }

  Future<void> _checkConnection() async {
    bool hasConnection = false;
    
    try {
      // 1. Check if hardware is connected (WiFi/Mobile)
      // connectivity_plus 6.0 returns List<ConnectivityResult>
      final result = await _connectivity.checkConnectivity();
      final results = result is List ? result : [result]; // Handle version differences safely if generic
      
      bool hardwareConnected = results.any((r) => r != ConnectivityResult.none && r != ConnectivityResult.bluetooth);

      if (hardwareConnected) {
        // 2. Check actual internet access
        // Note: InternetConnectionChecker pings google.com. 
        // If it fails on emulator, we might want to trust hardware or try fallback.
        hasConnection = await _internetChecker.hasConnection;
        
        // Fallback for emulators/restricted networks: 
        // If hardware says yes but checker says no, we might log a warning or trust hardware if desired.
        // For now, let's keep strict check but log explicitly.
        if (!hasConnection) { 
            print("NetworkManager: Hardware connected but no Internet access detected (Ping failed).");
            // Optional: Trust hardware if debug mode?
            // hasConnection = true; 
        }
      }
    } catch (e) {
      print("NetworkManager: Error checking connection: $e");
      hasConnection = false;
    }

    // Debounce/Update
    if (_isOnline != hasConnection) {
      _isOnline = hasConnection;
      _controller.add(_isOnline ? ConnectionStatus.online : ConnectionStatus.offline);
      print("NetworkManager: Connection changed to ${_isOnline ? 'Online' : 'Offline'}");
    }
  }
  
  // Force a re-check manually (e.g., when user taps 'Retry')
  Future<bool> checkNow() async {
    await _checkConnection();
    return _isOnline;
  }
  
  void dispose() {
    _controller.close();
  }
}
