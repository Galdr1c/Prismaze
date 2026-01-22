import 'package:flutter/material.dart';

/// Fast page route with reduced animation duration for snappy transitions.
/// Uses 150ms fade transition instead of default 300ms slide.
class FastPageRoute<T> extends PageRouteBuilder<T> {
  FastPageRoute({
    required Widget page,
    RouteSettings? settings,
  }) : super(
    settings: settings,
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: const Duration(milliseconds: 150),
    reverseTransitionDuration: const Duration(milliseconds: 120),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
  );
}

/// Helper extension for fast navigation
extension FastNavigator on NavigatorState {
  Future<T?> pushFast<T>(Widget page, {RouteSettings? settings}) {
    return push(FastPageRoute<T>(page: page, settings: settings));
  }
}

