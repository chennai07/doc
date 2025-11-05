import 'package:flutter/material.dart';

/// ✅ Smooth fade transition — used for logout / session expiry
Route fadeRoute(Widget page) {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 600), // ⏳ slower fade
    reverseTransitionDuration: const Duration(milliseconds: 500),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOutCubic, // nice, natural fade
      );
      return FadeTransition(opacity: curvedAnimation, child: child);
    },
  );
}

/// ✅ Slide-up transition — used for forward navigation (e.g., login → profile)
Route slideUpRoute(Widget page) {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 550), // ⏳ slightly longer
    reverseTransitionDuration: const Duration(milliseconds: 450),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOutBack, // 🌀 gives that elegant “spring” effect
      );
      final slideAnimation = Tween<Offset>(
        begin: const Offset(0, 0.15), // starts slightly below
        end: Offset.zero, // slides into place
      ).animate(curved);

      return SlideTransition(
        position: slideAnimation,
        child: FadeTransition(opacity: curved, child: child),
      );
    },
  );
}
