// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'utils/database_service.dart';
import 'utils/app_theme.dart';
import 'screens/login/login_screen.dart';
import 'screens/auth/auth_login_screen.dart';
import 'screens/home/home_screen.dart';
import 'providers/app_providers.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.init();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor:          Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const ProviderScope(child: JewelTrackApp()));
}

class JewelTrackApp extends ConsumerWidget {
  const JewelTrackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode    = ref.watch(themeProvider);
    final authAsync    = ref.watch(authSessionProvider);
    final profileAsync = ref.watch(profileProvider);

    return MaterialApp(
      title:                     'JewelTrack',
      debugShowCheckedModeBanner: false,
      locale:                    const Locale('en', 'US'),
      themeMode:                 themeMode,
      theme:                     AppTheme.lightTheme,
      darkTheme:                 AppTheme.darkTheme,
      home: authAsync.when(
        loading: () => const _SplashScreen(),
        error:   (_, __) => const AuthLoginScreen(),
        data: (isLoggedIn) {
          // Not authenticated → show API login screen
          if (!isLoggedIn) return const AuthLoginScreen();

          // Authenticated → check if shop profile exists in Isar
          // This handles the APP RESTART case (token already saved).
          // The first-login navigation is handled inside auth_login_screen.dart.
          return profileAsync.when(
            loading: () => const _SplashScreen(),
            error:   (_, __) => const LoginScreen(),
            data:    (profile) =>
            profile == null ? const LoginScreen() : const HomeScreen(),
          );
        },
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Center(
        child: CircularProgressIndicator(color: AppTheme.primaryGold),
      ),
    );
  }
}
