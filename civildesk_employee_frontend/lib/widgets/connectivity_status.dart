import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

/// Widget that shows offline status banner
/// Phase 3 Optimization - Offline Support
class ConnectivityStatus extends StatefulWidget {
  final Widget child;
  
  const ConnectivityStatus({
    super.key,
    required this.child,
  });

  @override
  State<ConnectivityStatus> createState() => _ConnectivityStatusState();
}

class _ConnectivityStatusState extends State<ConnectivityStatus> {
  late StreamSubscription<ConnectivityResult> _subscription;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _subscription = Connectivity().onConnectivityChanged.listen(
      (ConnectivityResult result) {
        setState(() {
          _isOnline = result != ConnectivityResult.none;
        });
      },
    );
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    if (mounted) {
      setState(() {
        _isOnline = result != ConnectivityResult.none;
      });
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Offline banner
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _isOnline ? 0 : 40,
          child: _isOnline
              ? const SizedBox.shrink()
              : Container(
                  width: double.infinity,
                  color: Colors.red.shade700,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_off,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'You are offline - Some features may be limited',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        // Main content
        Expanded(child: widget.child),
      ],
    );
  }
}

/// Mixin to add offline-aware capabilities to StatefulWidgets
mixin OfflineAwareMixin<T extends StatefulWidget> on State<T> {
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  bool isOnline = true;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    // Check initial state
    final result = await Connectivity().checkConnectivity();
    if (mounted) {
      setState(() {
        isOnline = result != ConnectivityResult.none;
      });
    }

    // Listen for changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (ConnectivityResult result) {
        if (mounted) {
          final wasOnline = isOnline;
          setState(() {
            isOnline = result != ConnectivityResult.none;
          });
          
          // Callback when connection restored
          if (!wasOnline && isOnline) {
            onConnectionRestored();
          }
        }
      },
    );
  }

  /// Override this to handle connection restoration
  void onConnectionRestored() {
    // Default: do nothing. Override in subclass to refresh data.
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }
}

