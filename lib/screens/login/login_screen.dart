// lib/screens/login/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/shop_profile.dart';
import '../../providers/app_providers.dart';
import '../../utils/app_theme.dart';
import '../../utils/database_service.dart';
import '../home/home_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _ownerCtrl = TextEditingController();
  final _shopCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _loading = false;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _ownerCtrl.dispose();
    _shopCtrl.dispose();
    _phoneCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final profile = ShopProfile()
        ..ownerName = _ownerCtrl.text.trim()
        ..shopName = _shopCtrl.text.trim()
        ..mobileNumber = _phoneCtrl.text.trim();
      await DatabaseService.saveProfile(profile);
      ref.invalidate(profileProvider);
      if (mounted) {
        // Navigate to HomeScreen and clear entire stack so back button doesn't
        // return to the setup screen.
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
              (_) => false,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  Center(
                    child: Container(
                      width: 90, height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.surfaceBg,
                        border: Border.all(color: AppTheme.primaryGold, width: 2),
                        boxShadow: [BoxShadow(color: AppTheme.primaryGold.withOpacity(0.25), blurRadius: 20, spreadRadius: 2)],
                      ),
                      child: const Icon(Icons.diamond_outlined, color: AppTheme.primaryGold, size: 44),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(child: Text('JewelTrack', style: GoogleFonts.playfairDisplay(color: AppTheme.primaryGold, fontSize: 34, fontWeight: FontWeight.w700, letterSpacing: 1))),
                  const SizedBox(height: 6),
                  Center(child: Text('Karigar Management System', style: GoogleFonts.lato(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 13))),
                  const SizedBox(height: 52),
                  Text('Setup Your Shop', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text('Enter your details to get started. This is a one-time setup.', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 28),
                  _buildField(controller: _ownerCtrl, label: 'Owner Name', hint: 'Your full name', icon: Icons.person_outline, validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null),
                  const SizedBox(height: 16),
                  _buildField(controller: _shopCtrl, label: 'Shop Name', hint: 'e.g. Shri Ram Jewellers', icon: Icons.store_outlined, validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null),
                  const SizedBox(height: 16),
                  _buildField(controller: _phoneCtrl, label: 'Mobile Number', hint: '10-digit number', icon: Icons.phone_outlined, keyboardType: TextInputType.phone, validator: (v) { final s = v?.trim() ?? ''; if (s.isEmpty) return 'Required'; if (s.replaceAll(RegExp(r'\D'), '').length < 10) return 'Enter a valid mobile number'; return null; }),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _save,
                      child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.darkBg)) : const Text('Get Started →'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({required TextEditingController controller, required String label, required String hint, required IconData icon, TextInputType? keyboardType, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style:  TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
      decoration: InputDecoration(labelText: label, hintText: hint, prefixIcon: Icon(icon, color: Theme.of(context).textTheme.bodySmall?.color, size: 20)),
      validator: validator,
    );
  }
}
