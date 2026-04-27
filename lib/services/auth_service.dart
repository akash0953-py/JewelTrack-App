// // lib/services/auth_service.dart
// //
// // Handles:
// //   • Login API call  →  POST /login
// //   • Persisting JWT + username in SharedPreferences
// //   • Reading stored session on app start
// //   • Logout (clear session)
// //
// // Nothing in this file touches Isar / existing app data.
//
// import 'dart:convert';
// import 'package:device_info_plus/device_info_plus.dart';
// import 'package:flutter/foundation.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
//
// class AuthService {
//   // ── Change this to your server IP/domain before running ──────
//   static const String _baseUrl = 'https://jeweltrack-backend.onrender.com'; // Android emulator
//   // static const String _baseUrl = 'http://localhost:3000'; // iOS simulator
//   // static const String _baseUrl = 'http://192.168.x.x:3000'; // Real device
//
//   static const _keyToken    = 'auth_token';
//   static const _keyUsername = 'auth_username';
//
//   // ── Device ID ─────────────────────────────────────────────────
//   static Future<String> getDeviceId() async {
//     final info = DeviceInfoPlugin();
//     try {
//       if (defaultTargetPlatform == TargetPlatform.android) {
//         final android = await info.androidInfo;
//         return android.id; // stable hardware ID
//       } else if (defaultTargetPlatform == TargetPlatform.iOS) {
//         final ios = await info.iosInfo;
//         return ios.identifierForVendor ?? 'ios-unknown';
//       }
//     } catch (_) {}
//     return 'unknown-device';
//   }
//
//   // ── Login ─────────────────────────────────────────────────────
//   /// Returns an [AuthResult] describing success or failure.
//   static Future<AuthResult> login({
//     required String username,
//     required String password,
//   }) async {
//     final deviceId = await getDeviceId();
//
//     try {
//       final response = await http
//           .post(
//         Uri.parse('$_baseUrl/login'),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({
//           'username': username.trim(),
//           'password': password.trim(),
//           'deviceId': deviceId,
//         }),
//       )
//           .timeout(const Duration(seconds: 15));
//
//       final body = jsonDecode(response.body) as Map<String, dynamic>;
//
//       if (response.statusCode == 200 && body['success'] == true) {
//         // Persist session
//         final prefs = await SharedPreferences.getInstance();
//         await prefs.setString(_keyToken, body['token'] as String? ?? '');
//         await prefs.setString(_keyUsername, username.trim());
//         return AuthResult.success(body['message'] as String? ?? 'Login successful');
//       } else {
//         return AuthResult.failure(body['message'] as String? ?? 'Login failed');
//       }
//     } on Exception catch (e) {
//       // Log full error for developer
//       // debugPrint("Login error: $e");
//       return AuthResult.failure('Unable to connect. Please check your internet or try again.');
//     }
//   }
//
//   // ── Session helpers ───────────────────────────────────────────
//   static Future<bool> isLoggedIn() async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString(_keyToken);
//     return token != null && token.isNotEmpty;
//   }
//
//   static Future<String?> getStoredUsername() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString(_keyUsername);
//   }
//
//   static Future<String?> getStoredToken() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString(_keyToken);
//   }
//
//   static Future<void> logout() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove(_keyToken);
//     await prefs.remove(_keyUsername);
//   }
// }
//
// // ── Result type ───────────────────────────────────────────────
// class AuthResult {
//   final bool success;
//   final String message;
//
//   const AuthResult._({required this.success, required this.message});
//
//   factory AuthResult.success(String message) =>
//       AuthResult._(success: true, message: message);
//
//   factory AuthResult.failure(String message) =>
//       AuthResult._(success: false, message: message);
// }

// lib/services/auth_service.dart
//
// Handles:
//   • Login API call  →  POST /login
//   • Persisting JWT + username in SharedPreferences
//   • Reading stored session on app start
//   • Logout (clear session)
//
// Nothing in this file touches Isar / existing app data.

import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // ── Change this to your server IP/domain before running ──────
  static const String _baseUrl = 'https://jeweltrack-backend.onrender.com'; // Android emulator
  // static const String _baseUrl = 'http://localhost:3000'; // iOS simulator
  // static const String _baseUrl = 'http://192.168.x.x:3000'; // Real device

  static const _keyToken    = 'auth_token';
  static const _keyUsername = 'auth_username';

  // ── Device ID ─────────────────────────────────────────────────
  static Future<String> getDeviceId() async {
    final info = DeviceInfoPlugin();
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final android = await info.androidInfo;
        return android.id; // stable hardware ID
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final ios = await info.iosInfo;
        return ios.identifierForVendor ?? 'ios-unknown';
      }
    } catch (_) {}
    return 'unknown-device';
  }

  // ── Login ─────────────────────────────────────────────────────
  /// Returns an [AuthResult] describing success or failure.
  static Future<AuthResult> login({
    required String username,
    required String password,
  }) async {
    final deviceId = await getDeviceId();

    try {
      final response = await http
          .post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username.trim(),
          'password': password.trim(),
          'deviceId': deviceId,
        }),
      )
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && body['success'] == true) {
        // Persist session
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyToken, body['token'] as String? ?? '');
        await prefs.setString(_keyUsername, username.trim());
        return AuthResult.success(body['message'] as String? ?? 'Login successful');
      } else {
        return AuthResult.failure(body['message'] as String? ?? 'Login failed');
      }
    } on Exception catch (e) {
      return AuthResult.failure('Connection error ');  //${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  // ── Session helpers ───────────────────────────────────────────
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);
    return token != null && token.isNotEmpty;
  }

  static Future<String?> getStoredUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername);
  }

  static Future<String?> getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUsername);
  }
}

// ── Result type ───────────────────────────────────────────────
class AuthResult {
  final bool success;
  final String message;

  const AuthResult._({required this.success, required this.message});

  factory AuthResult.success(String message) =>
      AuthResult._(success: true, message: message);

  factory AuthResult.failure(String message) =>
      AuthResult._(success: false, message: message);
}
