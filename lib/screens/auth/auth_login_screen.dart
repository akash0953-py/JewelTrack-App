// lib/screens/auth/auth_login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_providers.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import '../home/home_screen.dart';
import '../login/login_screen.dart';

class AuthLoginScreen extends ConsumerStatefulWidget {
  const AuthLoginScreen({super.key});

  @override
  ConsumerState<AuthLoginScreen> createState() => _AuthLoginScreenState();
}

class _AuthLoginScreenState extends ConsumerState<AuthLoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey    = GlobalKey<FormState>();
  final _userCtrl   = TextEditingController();
  final _passCtrl   = TextEditingController();
  bool _obscurePass = true;
  bool _loading     = false;
  String? _errorMsg;

  late final AnimationController _animCtrl;
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
        begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading  = true;
      _errorMsg = null;
    });

    // Step 1: Call the backend API
    final result = await AuthService.login(
      username: _userCtrl.text,
      password: _passCtrl.text,
    );

    if (!mounted) return;

    if (!result.success) {
      // API login failed — show error, stay on this screen
      setState(() {
        _loading  = false;
        _errorMsg = result.message;
      });
      return;
    }

    // Step 2: API login succeeded. Check if Isar shop profile exists.
    // We read profileProvider.future directly to get the current value NOW.
    final profile = await ref.read(profileProvider.future);

    if (!mounted) return;
    setState(() => _loading = false);

    if (profile == null) {
      // NEW USER — no shop profile in Isar yet → go to shop setup screen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (_) => false,
      );
    } else {
      // RETURNING USER — profile exists in Isar → go straight to home
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
            (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.darkTheme,
      child: Scaffold(
        backgroundColor: AppTheme.darkBg,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 36),

                      // ── Logo ──────────────────────────────
                      Center(
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.surfaceBg,
                            border: Border.all(color: AppTheme.primaryGold, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                  color: AppTheme.primaryGold.withOpacity(0.28),
                                  blurRadius: 24,
                                  spreadRadius: 3),
                            ],
                          ),
                          child: const Icon(Icons.diamond_outlined,
                              color: AppTheme.primaryGold, size: 46),
                        ),
                      ),
                      const SizedBox(height: 22),

                      // ── Title ─────────────────────────────
                      Center(
                        child: Text('JewelTrack',
                            style: GoogleFonts.playfairDisplay(
                                color: AppTheme.primaryGold,
                                fontSize: 34,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1)),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Text('Karigar Management System',
                            style: GoogleFonts.lato(
                                color: AppTheme.textSecondary, fontSize: 13)),
                      ),
                      const SizedBox(height: 52),

                      Text('Sign In',
                          style: GoogleFonts.playfairDisplay(
                              color: AppTheme.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text('Enter your credentials to continue.',
                          style: GoogleFonts.lato(
                              color: AppTheme.textSecondary, fontSize: 13)),
                      const SizedBox(height: 28),

                      // ── Username ──────────────────────────
                      _buildField(
                        controller: _userCtrl,
                        label:      'Username',
                        hint:       'Enter your username',
                        icon:       Icons.person_outline,
                        validator:  (v) =>
                        (v?.trim().isEmpty ?? true) ? 'Username is required' : null,
                      ),
                      const SizedBox(height: 16),

                      // ── Password ──────────────────────────
                      TextFormField(
                        controller:  _passCtrl,
                        obscureText: _obscurePass,
                        style: GoogleFonts.lato(
                            color: AppTheme.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          labelText:  'Password',
                          hintText:   'Enter your password',
                          prefixIcon: Icon(Icons.lock_outline,
                              color: AppTheme.textSecondary, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePass
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppTheme.textSecondary,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _obscurePass = !_obscurePass),
                          ),
                          filled:     true,
                          fillColor:  AppTheme.surfaceBg,
                          labelStyle: GoogleFonts.lato(
                              color: AppTheme.textSecondary, fontSize: 13),
                          hintStyle: GoogleFonts.lato(
                              color: AppTheme.textSecondary.withOpacity(0.5),
                              fontSize: 13),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppTheme.divider)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppTheme.divider)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: AppTheme.primaryGold, width: 1.5)),
                          errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppTheme.redDot)),
                          focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppTheme.redDot)),
                        ),
                        validator: (v) =>
                        (v?.trim().isEmpty ?? true) ? 'Password is required' : null,
                        onFieldSubmitted: (_) => _login(),
                      ),
                      const SizedBox(height: 24),

                      // ── Error message ─────────────────────
                      if (_errorMsg != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:        AppTheme.redDot.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppTheme.redDot.withOpacity(0.4)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.error_outline,
                                color: AppTheme.redDot, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(_errorMsg!,
                                  style: GoogleFonts.lato(
                                      color: AppTheme.redDot, fontSize: 13)),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ── Login button ──────────────────────
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGold,
                            foregroundColor: AppTheme.darkBg,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13)),
                            elevation: 4,
                            shadowColor: AppTheme.primaryGold.withOpacity(0.4),
                          ),
                          onPressed: _loading ? null : _login,
                          child: _loading
                              ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppTheme.darkBg),
                          )
                              : Text('Sign In',
                              style: GoogleFonts.lato(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5)),
                        ),
                      ),
                      const SizedBox(height: 36),

                      Center(
                        child: Text(
                          'Contact your administrator to get access.',
                          style: GoogleFonts.lato(
                              color: AppTheme.textSecondary.withOpacity(0.6),
                              fontSize: 11),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller:  controller,
      style: GoogleFonts.lato(color: AppTheme.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText:  label,
        hintText:   hint,
        prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 20),
        filled:     true,
        fillColor:  AppTheme.surfaceBg,
        labelStyle: GoogleFonts.lato(color: AppTheme.textSecondary, fontSize: 13),
        hintStyle:  GoogleFonts.lato(
            color: AppTheme.textSecondary.withOpacity(0.5), fontSize: 13),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.divider)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.divider)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primaryGold, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.redDot)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.redDot)),
      ),
      validator: validator,
    );
  }
}
