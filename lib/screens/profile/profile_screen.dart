// // lib/screens/profile/profile_screen.dart
// import '../../providers/theme_provider.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:google_fonts/google_fonts.dart';
// import '../../models/shop_profile.dart';
// import '../../providers/app_providers.dart';
// import '../../utils/app_theme.dart';
// import '../../utils/backup_service.dart';
// import '../../utils/database_service.dart';
// import '../../services/auth_service.dart';         // NEW
// import '../auth/auth_login_screen.dart';            // NEW
//
// class ProfileScreen extends ConsumerStatefulWidget {
//   const ProfileScreen({super.key});
//   @override
//   ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
// }
//
// class _ProfileScreenState extends ConsumerState<ProfileScreen> {
//   bool _backingUp  = false;
//   bool _restoring  = false;
//
//   Future<void> _backup() async {
//     setState(() => _backingUp = true);
//     try {
//       final success = await BackupService.shareBackup();
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//           content: Text(success ? 'Backup ready to share!' : 'Backup failed. Try again.'),
//           backgroundColor: success ? AppTheme.greenDot : AppTheme.redDot,
//         ));
//       }
//     } finally {
//       if (mounted) setState(() => _backingUp = false);
//     }
//   }
//
//   Future<void> _restore() async {
//     final confirm = await showDialog<bool>(
//       context: context,
//       builder: (_) => AlertDialog(
//         backgroundColor: AppTheme.cardColor(context),
//         title: Text('Restore Data?',
//             style: GoogleFonts.playfairDisplay(
//                 color: Theme.of(context).textTheme.bodyLarge?.color)),
//         content: Text(
//           'This will replace ALL current data with the backup. '
//               'This cannot be undone. Make sure you have a recent backup.',
//           style: GoogleFonts.lato(
//               color: Theme.of(context).textTheme.bodySmall?.color),
//         ),
//         actions: [
//           TextButton(
//               onPressed: () => Navigator.pop(_, false),
//               child: Text('Cancel',
//                   style: TextStyle(
//                       color: Theme.of(context).textTheme.bodySmall?.color))),
//           ElevatedButton(
//             style:
//             ElevatedButton.styleFrom(backgroundColor: AppTheme.redDot),
//             onPressed: () => Navigator.pop(_, true),
//             child: const Text('Yes, Restore'),
//           ),
//         ],
//       ),
//     );
//     if (confirm != true) return;
//
//     setState(() => _restoring = true);
//     try {
//       final result = await BackupService.restoreBackup();
//       if (!mounted) return;
//       switch (result) {
//         case RestoreResult.success:
//           ref.invalidate(profileProvider);
//           ref.invalidate(karigarsProvider);
//           ref.invalidate(jobsProvider);
//           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//               content: Text('Data restored successfully!'),
//               backgroundColor: AppTheme.greenDot));
//           Navigator.pop(context);
//           break;
//         case RestoreResult.failed:
//           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//               content: Text('Restore failed. Invalid backup file.'),
//               backgroundColor: AppTheme.redDot));
//           break;
//         case RestoreResult.cancelled:
//           break;
//       }
//     } finally {
//       if (mounted) setState(() => _restoring = false);
//     }
//   }
//
//   Future<void> _editProfile(ShopProfile profile) async {
//     final nameCtrl  = TextEditingController(text: profile.ownerName);
//     final shopCtrl  = TextEditingController(text: profile.shopName);
//     final phoneCtrl = TextEditingController(text: profile.mobileNumber);
//     final formKey   = GlobalKey<FormState>();
//
//     await showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         backgroundColor: AppTheme.cardColor(context),
//         title: Text('Edit Profile',
//             style: GoogleFonts.playfairDisplay(
//                 color: Theme.of(context).textTheme.bodyLarge?.color)),
//         content: Form(
//           key: formKey,
//           child: Column(mainAxisSize: MainAxisSize.min, children: [
//             TextFormField(
//               controller: nameCtrl,
//               style: TextStyle(
//                   color: Theme.of(context).textTheme.bodyLarge?.color),
//               decoration: const InputDecoration(labelText: 'Owner Name'),
//               validator: (v) =>
//               (v?.trim().isEmpty ?? true) ? 'Required' : null,
//             ),
//             const SizedBox(height: 12),
//             TextFormField(
//               controller: shopCtrl,
//               style: TextStyle(
//                   color: Theme.of(context).textTheme.bodyLarge?.color),
//               decoration: const InputDecoration(labelText: 'Shop Name'),
//               validator: (v) =>
//               (v?.trim().isEmpty ?? true) ? 'Required' : null,
//             ),
//             const SizedBox(height: 12),
//             TextFormField(
//               controller: phoneCtrl,
//               style: TextStyle(
//                   color: Theme.of(context).textTheme.bodyLarge?.color),
//               keyboardType: TextInputType.phone,
//               decoration: const InputDecoration(labelText: 'Mobile Number'),
//               validator: (v) =>
//               (v?.trim().isEmpty ?? true) ? 'Required' : null,
//             ),
//           ]),
//         ),
//         actions: [
//           TextButton(
//               onPressed: () => Navigator.pop(_),
//               child: Text('Cancel',
//                   style: TextStyle(
//                       color:
//                       Theme.of(context).textTheme.bodySmall?.color))),
//           ElevatedButton(
//             onPressed: () async {
//               if (!formKey.currentState!.validate()) return;
//               profile.ownerName    = nameCtrl.text.trim();
//               profile.shopName     = shopCtrl.text.trim();
//               profile.mobileNumber = phoneCtrl.text.trim();
//               await DatabaseService.saveProfile(profile);
//               ref.invalidate(profileProvider);
//               if (_.mounted) Navigator.pop(_);
//             },
//             child: const Text('Save'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final profileAsync = ref.watch(profileProvider);
//     final accent       = AppTheme.accentColor(context);
//
//     return Scaffold(
//       appBar: AppBar(title: const Text('Profile & Settings')),
//       body: SafeArea(
//         child: profileAsync.when(
//           loading: () => Center(
//               child: CircularProgressIndicator(color: accent)),
//           error: (e, _) => Center(child: Text('Error: $e')),
//           data: (profile) {
//             if (profile == null) {
//               return const Center(child: Text('No profile found'));
//             }
//             return ListView(
//               padding: const EdgeInsets.all(20),
//               children: [
//                 // ── Profile card ────────────────────────────
//                 Container(
//                   padding: const EdgeInsets.all(20),
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       colors: [
//                         AppTheme.surfaceColor(context),
//                         AppTheme.cardColor(context),
//                       ],
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                     ),
//                     borderRadius: BorderRadius.circular(20),
//                     border: Border.all(
//                         color: accent.withOpacity(0.3)),
//                   ),
//                   child: Row(children: [
//                     Container(
//                       width: 64,
//                       height: 64,
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         color: Theme.of(context).scaffoldBackgroundColor,
//                         border: Border.all(color: accent, width: 2),
//                       ),
//                       child: Icon(Icons.store_outlined,
//                           color: accent, size: 30),
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(profile.shopName,
//                                 style: GoogleFonts.playfairDisplay(
//                                     color: accent,
//                                     fontSize: 18,
//                                     fontWeight: FontWeight.w700)),
//                             const SizedBox(height: 4),
//                             Text(profile.ownerName,
//                                 style: GoogleFonts.lato(
//                                     color: Theme.of(context)
//                                         .textTheme
//                                         .bodyLarge
//                                         ?.color,
//                                     fontSize: 13)),
//                             Text(profile.mobileNumber,
//                                 style: GoogleFonts.lato(
//                                     color: Theme.of(context)
//                                         .textTheme
//                                         .bodySmall
//                                         ?.color,
//                                     fontSize: 12)),
//                           ]),
//                     ),
//                     IconButton(
//                       icon: Icon(Icons.edit_outlined, color: accent, size: 20),
//                       onPressed: () => _editProfile(profile),
//                     ),
//                   ]),
//                 ),
//                 const SizedBox(height: 28),
//
//                 // ── Data & Backup ────────────────────────────
//                 _sectionHeader('Data & Backup'),
//                 const SizedBox(height: 12),
//                 _settingsTile(
//                   context: context,
//                   icon:      Icons.cloud_upload_outlined,
//                   iconColor: accent,
//                   title:    'Create Backup',
//                   subtitle: 'Export all data as a .zip file to share/save',
//                   trailing: _backingUp
//                       ? SizedBox(
//                       height: 18,
//                       width: 18,
//                       child: CircularProgressIndicator(
//                           strokeWidth: 2, color: accent))
//                       : Icon(Icons.chevron_right,
//                       color: Theme.of(context).textTheme.bodySmall?.color,
//                       size: 20),
//                   onTap: _backingUp ? null : _backup,
//                 ),
//                 const SizedBox(height: 10),
//                 _settingsTile(
//                   context:   context,
//                   icon:      Icons.cloud_download_outlined,
//                   iconColor: AppTheme.yellowDot,
//                   title:    'Restore from Backup',
//                   subtitle: 'Import a .zip backup to restore your data',
//                   trailing: _restoring
//                       ? const SizedBox(
//                       height: 18,
//                       width: 18,
//                       child: CircularProgressIndicator(
//                           strokeWidth: 2, color: AppTheme.yellowDot))
//                       : Icon(Icons.chevron_right,
//                       color: Theme.of(context).textTheme.bodySmall?.color,
//                       size: 20),
//                   onTap: _restoring ? null : _restore,
//                 ),
//                 const SizedBox(height: 28),
//
//                 // ── Appearance ───────────────────────────────
//                 _sectionHeader('Appearance'),
//                 const SizedBox(height: 12),
//                 Consumer(
//                   builder: (context, ref, _) {
//                     final themeMode = ref.watch(themeProvider);
//                     final isDark    = themeMode == ThemeMode.dark;
//                     return _settingsTile(
//                       context:   context,
//                       icon:      isDark ? Icons.dark_mode : Icons.light_mode,
//                       iconColor: accent,
//                       title:    isDark ? 'Dark Mode' : 'Light Mode',
//                       subtitle: 'Switch between light and dark theme',
//                       trailing: Switch(
//                         value:       isDark,
//                         activeColor: accent,
//                         onChanged:   (value) {
//                           ref.read(themeProvider.notifier).state =
//                           value ? ThemeMode.dark : ThemeMode.light;
//                         },
//                       ),
//                       onTap: () {
//                         ref.read(themeProvider.notifier).state =
//                         isDark ? ThemeMode.light : ThemeMode.dark;
//                       },
//                     );
//                   },
//                 ),
//                 const SizedBox(height: 28),
//
//                 const SizedBox(height: 28),
//
//                 // ── Account ──────────────────────────────────
//                 _sectionHeader('Account'),
//                 const SizedBox(height: 12),
//                 _settingsTile(
//                   context:   context,
//                   icon:      Icons.logout,
//                   iconColor: AppTheme.redDot,
//                   title:    'Logout',
//                   subtitle: 'Sign out from this device',
//                   trailing: Icon(Icons.chevron_right,
//                       color: Theme.of(context).textTheme.bodySmall?.color, size: 20),
//                   onTap:    _logout,
//                 ),
//                 // ── About ────────────────────────────────────
//                 _sectionHeader('About'),
//                 const SizedBox(height: 12),
//                 _settingsTile(
//                   context:   context,
//                   icon:      Icons.diamond_outlined,
//                   iconColor: accent,
//                   title:    'JewelTrack',
//                   subtitle: 'Version 1.0.0 • Made for Indian Jewellers',
//                   trailing: null,
//                   onTap:    null,
//                 ),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }
//
//   // ── Logout (NEW) ─────────────────────────────────────────────
//   Future<void> _logout() async {
//     final confirm = await showDialog<bool>(
//       context: context,
//       builder: (_) => AlertDialog(
//         backgroundColor: AppTheme.cardColor(context),
//         title: Text('Logout?',
//             style: GoogleFonts.playfairDisplay(
//                 color: Theme.of(context).textTheme.bodyLarge?.color)),
//         content: Text(
//           'You will be signed out from this device. Your local data will remain intact.',
//           style: GoogleFonts.lato(
//               color: Theme.of(context).textTheme.bodySmall?.color),
//         ),
//         actions: [
//           TextButton(
//               onPressed: () => Navigator.pop(_, false),
//               child: Text('Cancel',
//                   style: TextStyle(
//                       color: Theme.of(context).textTheme.bodySmall?.color))),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(backgroundColor: AppTheme.redDot),
//             onPressed: () => Navigator.pop(_, true),
//             child: const Text('Logout', style: TextStyle(color: Colors.white)),
//           ),
//         ],
//       ),
//     );
//     if (confirm != true || !mounted) return;
//     await AuthService.logout();
//     if (!mounted) return;
//     Navigator.pushAndRemoveUntil(
//       context,
//       MaterialPageRoute(builder: (_) => const AuthLoginScreen()),
//           (_) => false,
//     );
//   }
//
//   Widget _sectionHeader(String label) {
//     return Text(
//       label.toUpperCase(),
//       style: GoogleFonts.lato(
//           color:       Theme.of(context).textTheme.bodySmall?.color,
//           fontSize:    11,
//           letterSpacing: 1.2,
//           fontWeight:  FontWeight.w600),
//     );
//   }
//
//   Widget _settingsTile({
//     required BuildContext context,
//     required IconData   icon,
//     required Color      iconColor,
//     required String     title,
//     required String     subtitle,
//     required Widget?    trailing,
//     required VoidCallback? onTap,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.all(14),
//         decoration: BoxDecoration(
//           color:         AppTheme.cardColor(context),
//           borderRadius:  BorderRadius.circular(14),
//           border:        Border.all(color: AppTheme.dividerColor(context)),
//         ),
//         child: Row(children: [
//           Container(
//             padding: const EdgeInsets.all(9),
//             decoration: BoxDecoration(
//               color:         iconColor.withOpacity(0.12),
//               borderRadius:  BorderRadius.circular(10),
//             ),
//             child: Icon(icon, color: iconColor, size: 20),
//           ),
//           const SizedBox(width: 14),
//           Expanded(
//             child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//               Text(title,
//                   style: GoogleFonts.lato(
//                       color:      Theme.of(context).textTheme.bodyLarge?.color,
//                       fontSize:   14,
//                       fontWeight: FontWeight.w600)),
//               const SizedBox(height: 2),
//               Text(subtitle,
//                   style: GoogleFonts.lato(
//                       color:    Theme.of(context).textTheme.bodySmall?.color,
//                       fontSize: 11)),
//             ]),
//           ),
//           if (trailing != null) trailing,
//         ]),
//       ),
//     );
//   }
// }

// lib/screens/profile/profile_screen.dart
import '../../providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/shop_profile.dart';
import '../../providers/app_providers.dart';
import '../../utils/app_theme.dart';
import '../../utils/backup_service.dart';
import '../../utils/database_service.dart';
import '../../services/auth_service.dart';         // NEW
import '../auth/auth_login_screen.dart';            // NEW

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _backingUp  = false;
  bool _restoring  = false;

  Future<void> _backup() async {
    setState(() => _backingUp = true);
    try {
      final success = await BackupService.shareBackup();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success ? 'Backup ready to share!' : 'Backup failed. Try again.'),
          backgroundColor: success ? AppTheme.greenDot : AppTheme.redDot,
        ));
      }
    } finally {
      if (mounted) setState(() => _backingUp = false);
    }
  }

  Future<void> _restore() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardColor(context),
        title: Text('Restore Data?',
            style: GoogleFonts.playfairDisplay(
                color: Theme.of(context).textTheme.bodyLarge?.color)),
        content: Text(
          'This will replace ALL current data with the backup. '
              'This cannot be undone. Make sure you have a recent backup.',
          style: GoogleFonts.lato(
              color: Theme.of(context).textTheme.bodySmall?.color),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(_, false),
              child: Text('Cancel',
                  style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color))),
          ElevatedButton(
            style:
            ElevatedButton.styleFrom(backgroundColor: AppTheme.redDot),
            onPressed: () => Navigator.pop(_, true),
            child: const Text('Yes, Restore'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _restoring = true);
    try {
      final result = await BackupService.restoreBackup();
      if (!mounted) return;
      switch (result) {
        case RestoreResult.success:
          ref.invalidate(profileProvider);
          ref.invalidate(karigarsProvider);
          ref.invalidate(jobsProvider);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Data restored successfully!'),
              backgroundColor: AppTheme.greenDot));
          Navigator.pop(context);
          break;
        case RestoreResult.failed:
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Restore failed. Invalid backup file.'),
              backgroundColor: AppTheme.redDot));
          break;
        case RestoreResult.cancelled:
          break;
      }
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  Future<void> _editProfile(ShopProfile profile) async {
    final nameCtrl  = TextEditingController(text: profile.ownerName);
    final shopCtrl  = TextEditingController(text: profile.shopName);
    final phoneCtrl = TextEditingController(text: profile.mobileNumber);
    final formKey   = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardColor(context),
        title: Text('Edit Profile',
            style: GoogleFonts.playfairDisplay(
                color: Theme.of(context).textTheme.bodyLarge?.color)),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: nameCtrl,
              style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color),
              decoration: const InputDecoration(labelText: 'Owner Name'),
              validator: (v) =>
              (v?.trim().isEmpty ?? true) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: shopCtrl,
              style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color),
              decoration: const InputDecoration(labelText: 'Shop Name'),
              validator: (v) =>
              (v?.trim().isEmpty ?? true) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: phoneCtrl,
              style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color),
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Mobile Number'),
              validator: (v) =>
              (v?.trim().isEmpty ?? true) ? 'Required' : null,
            ),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(_),
              child: Text('Cancel',
                  style: TextStyle(
                      color:
                      Theme.of(context).textTheme.bodySmall?.color))),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              profile.ownerName    = nameCtrl.text.trim();
              profile.shopName     = shopCtrl.text.trim();
              profile.mobileNumber = phoneCtrl.text.trim();
              await DatabaseService.saveProfile(profile);
              ref.invalidate(profileProvider);
              if (_.mounted) Navigator.pop(_);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final accent       = AppTheme.accentColor(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: SafeArea(
        child: profileAsync.when(
          loading: () => Center(
              child: CircularProgressIndicator(color: accent)),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (profile) {
            if (profile == null) {
              return const Center(child: Text('No profile found'));
            }
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ── Profile card ────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.surfaceColor(context),
                        AppTheme.cardColor(context),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: accent.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).scaffoldBackgroundColor,
                        border: Border.all(color: accent, width: 2),
                      ),
                      child: Icon(Icons.store_outlined,
                          color: accent, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(profile.shopName,
                                style: GoogleFonts.playfairDisplay(
                                    color: accent,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(profile.ownerName,
                                style: GoogleFonts.lato(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color,
                                    fontSize: 13)),
                            Text(profile.mobileNumber,
                                style: GoogleFonts.lato(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color,
                                    fontSize: 12)),
                          ]),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit_outlined, color: accent, size: 20),
                      onPressed: () => _editProfile(profile),
                    ),
                  ]),
                ),
                const SizedBox(height: 28),

                // ── Data & Backup ────────────────────────────
                _sectionHeader('Data & Backup'),
                const SizedBox(height: 12),
                _settingsTile(
                  context: context,
                  icon:      Icons.cloud_upload_outlined,
                  iconColor: accent,
                  title:    'Create Backup',
                  subtitle: 'Export all data as a .zip file to share/save',
                  trailing: _backingUp
                      ? SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: accent))
                      : Icon(Icons.chevron_right,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      size: 20),
                  onTap: _backingUp ? null : _backup,
                ),
                const SizedBox(height: 10),
                _settingsTile(
                  context:   context,
                  icon:      Icons.cloud_download_outlined,
                  iconColor: AppTheme.yellowDot,
                  title:    'Restore from Backup',
                  subtitle: 'Import a .zip backup to restore your data',
                  trailing: _restoring
                      ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppTheme.yellowDot))
                      : Icon(Icons.chevron_right,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      size: 20),
                  onTap: _restoring ? null : _restore,
                ),
                const SizedBox(height: 28),

                // ── Appearance ───────────────────────────────
                _sectionHeader('Appearance'),
                const SizedBox(height: 12),
                Consumer(
                  builder: (context, ref, _) {
                    final themeMode = ref.watch(themeProvider);
                    final isDark    = themeMode == ThemeMode.dark;
                    return _settingsTile(
                      context:   context,
                      icon:      isDark ? Icons.dark_mode : Icons.light_mode,
                      iconColor: accent,
                      title:    isDark ? 'Dark Mode' : 'Light Mode',
                      subtitle: 'Switch between light and dark theme',
                      trailing: Switch(
                        value:       isDark,
                        activeColor: accent,
                        onChanged:   (value) {
                          ref.read(themeProvider.notifier).state =
                          value ? ThemeMode.dark : ThemeMode.light;
                        },
                      ),
                      onTap: () {
                        ref.read(themeProvider.notifier).state =
                        isDark ? ThemeMode.light : ThemeMode.dark;
                      },
                    );
                  },
                ),
                const SizedBox(height: 28),

                const SizedBox(height: 28),

                // ── Account ──────────────────────────────────
                _sectionHeader('Account'),
                const SizedBox(height: 12),
                _settingsTile(
                  context:   context,
                  icon:      Icons.logout,
                  iconColor: AppTheme.redDot,
                  title:    'Logout',
                  subtitle: 'Sign out from this device',
                  trailing: Icon(Icons.chevron_right,
                      color: Theme.of(context).textTheme.bodySmall?.color, size: 20),
                  onTap:    _logout,
                ),
                // ── About ────────────────────────────────────
                _sectionHeader('About'),
                const SizedBox(height: 12),
                _settingsTile(
                  context:   context,
                  icon:      Icons.diamond_outlined,
                  iconColor: accent,
                  title:    'JewelTrack',
                  subtitle: 'Version 1.0.0 • Made for Indian Jewellers',
                  trailing: null,
                  onTap:    null,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Logout (NEW) ─────────────────────────────────────────────
  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardColor(context),
        title: Text('Logout?',
            style: GoogleFonts.playfairDisplay(
                color: Theme.of(context).textTheme.bodyLarge?.color)),
        content: Text(
          'You will be signed out from this device. Your local data will remain intact.',
          style: GoogleFonts.lato(
              color: Theme.of(context).textTheme.bodySmall?.color),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(_, false),
              child: Text('Cancel',
                  style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.redDot),
            onPressed: () => Navigator.pop(_, true),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthLoginScreen()),
          (_) => false,
    );
  }

  Widget _sectionHeader(String label) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.lato(
          color:       Theme.of(context).textTheme.bodySmall?.color,
          fontSize:    11,
          letterSpacing: 1.2,
          fontWeight:  FontWeight.w600),
    );
  }

  Widget _settingsTile({
    required BuildContext context,
    required IconData   icon,
    required Color      iconColor,
    required String     title,
    required String     subtitle,
    required Widget?    trailing,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:         AppTheme.cardColor(context),
          borderRadius:  BorderRadius.circular(14),
          border:        Border.all(color: AppTheme.dividerColor(context)),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color:         iconColor.withOpacity(0.12),
              borderRadius:  BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: GoogleFonts.lato(
                      color:      Theme.of(context).textTheme.bodyLarge?.color,
                      fontSize:   14,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: GoogleFonts.lato(
                      color:    Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 11)),
            ]),
          ),
          if (trailing != null) trailing,
        ]),
      ),
    );
  }
}
