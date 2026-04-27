// // lib/providers/auth_provider.dart
// //
// // A single Riverpod FutureProvider that resolves to true if the user
// // is already logged in (token in SharedPreferences), false otherwise.
// //
// // Used ONLY by the root widget in main.dart to decide which screen to show.
// // No existing providers are touched.
//
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../services/auth_service.dart';
//
// /// Resolves once on app start. true = already logged in.
// final authSessionProvider = FutureProvider<bool>((ref) async {
//   return AuthService.isLoggedIn();
// });

// lib/providers/auth_provider.dart
//
// A Riverpod FutureProvider that resolves to true if the user already
// has a valid JWT in SharedPreferences, false otherwise.
//
// Used ONLY by the root JewelTrackApp widget in main.dart.
// When invalidated (e.g. after login or logout), the provider re-fetches
// and the root widget rebuilds — showing the correct screen automatically.
//
// No existing providers are touched.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

/// true  = JWT exists in SharedPreferences → user is logged in
/// false = no JWT → show AuthLoginScreen
final authSessionProvider = FutureProvider<bool>((ref) async {
  return AuthService.isLoggedIn();
});
