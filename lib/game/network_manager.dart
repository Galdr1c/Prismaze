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
  NetworkManager._internal() {
     if (!kIsWeb) {
         _internetChecker = InternetConnectionChecker();
     }
  }

  final Connectivity _connectivity = Connectivity();
  InternetConnectionChecker? _internetChecker;

  // Stream controller for connection status
  final StreamController<ConnectionStatus> _controller = StreamController<ConnectionStatus>.broadcast();
  Stream<ConnectionStatus> get statusStream => _controller.stream;

  bool _isOnline = false;
  bool get isOnline => _isOnline;

  // Initialize monitoring
  Future<void> init() async {
    print("NetworkManager: init() called");
    // Initial check
    await _checkConnection();
    print("NetworkManager: _checkConnection() returned");

    // Listen to changes
    _connectivity.onConnectivityChanged.listen((result) {
      _checkConnection();
    });
    
    print("NetworkManager: Initialized. Status: ${_isOnline ? 'Online' : 'Offline'}");
  }

  Future<void> _checkConnection() async {
    print("NetworkManager: _checkConnection started");
    bool hasConnection = false;
    
    try {
      if (kIsWeb) {
          // FORCE ONLINE ON WEB to prevent any plugin hang
          print("NetworkManager: Web detected. Forcing Online.");
          hasConnection = true;
          // Debounce/Update logic needed here since we return early
          _updateStatus(true);
          return;
      }

      // 1. Check if hardware is connected (WiFi/Mobile)
      // connectivity_plus 6.0 returns List<ConnectivityResult>
      final result = await _connectivity.checkConnectivity();
      final results = result is List ? result : [result]; // Handle version differences safely if generic
      
      bool hardwareConnected = results.any((r) => r != ConnectivityResult.none && r != ConnectivityResult.bluetooth);

      if (hardwareConnected) {
        // 2. Check actual internet access
        // IMPORTANT: InternetConnectionChecker uses raw TCP sockets which are NOT supported on Web.
        // It will hang or throw on web platforms.
        if (kIsWeb) {
          // On Web, if hardware is connected, we trust it for now or assume online.
          // connectivity_plus on web is reliable for "is connected to a network".
          hasConnection = true;
          debugPrint("NetworkManager: Web detected - trusting connectivity_plus results.");
        } else {
          // On Native, we can use the strict ping check.
          if (_internetChecker != null) {
              hasConnection = await _internetChecker!.hasConnection;
          } else {
              hasConnection = true; // Fallback if checker failed to init
          }
        }
        
        if (!hasConnection && !kIsWeb) { 
            print("NetworkManager: Hardware connected but no Internet access detected (Ping failed).");
        }
      }
    } catch (e) {
      print("NetworkManager: Error checking connection: $e");
      hasConnection = false;
    }

    // Debounce/Update
    _updateStatus(hasConnection);
  }

  void _updateStatus(bool hasConnection) {
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

