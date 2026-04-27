// lib/screens/karigar/add_karigar_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/karigar.dart';
import '../../providers/app_providers.dart';
import '../../utils/app_theme.dart';
import '../../utils/image_service.dart';

class AddKarigarScreen extends ConsumerStatefulWidget {
  final Karigar? existing; // for edit mode
  const AddKarigarScreen({super.key, this.existing});
  @override
  ConsumerState<AddKarigarScreen> createState() => _AddKarigarScreenState();
}

class _AddKarigarScreenState extends ConsumerState<AddKarigarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  String? _imagePath;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _nameCtrl.text = widget.existing!.name;
      _phoneCtrl.text = widget.existing!.phoneNumber;
      _addressCtrl.text = widget.existing!.address ?? '';
      _imagePath = widget.existing!.imagePath;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool fromCamera) async {
    final path = await ImageService.pickAndCompress(fromCamera: fromCamera);
    if (path != null) setState(() => _imagePath = path);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final karigar = (_isEdit ? widget.existing! : Karigar())
        ..name = _nameCtrl.text.trim()
        ..phoneNumber = _phoneCtrl.text.trim()
        ..address = _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim()
        ..imagePath = _imagePath;
      print("Saving: $_imagePath");
      print("Fetched: ${karigar.imagePath}");
      if (_isEdit) {
        await ref.read(karigarsProvider.notifier).update(karigar);
      } else {
        await ref.read(karigarsProvider.notifier).add(karigar);
      }
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Karigar' : 'Add Karigar')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Photo picker
                GestureDetector(
                  onTap: () => _showImagePicker(),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: AppTheme.surfaceBg,
                   // backgroundImage: _imagePath != null ? FileImage(File(_imagePath!)) : null,
                    child: _imagePath != null
                        ? ClipOval(
                      child: Image.file(
                        File(_imagePath!),
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    )
                        : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                         Icon(Icons.camera_alt_outlined,
                            color: Theme.of(context).textTheme.bodySmall?.color, size: 28),
                        const SizedBox(height: 4),
                        Text('Add Photo',
                            style: GoogleFonts.lato(
                                color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 10)),
                      ],
                    ),
                    // child: _imagePath == null
                    //     ? Column(mainAxisSize: MainAxisSize.min, children: [
                    //         const Icon(Icons.camera_alt_outlined, color: Theme.of(context).textTheme.bodySmall?.color, size: 28),
                    //         const SizedBox(height: 4),
                    //         Text('Add Photo', style: GoogleFonts.lato(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 10)),
                    //       ])
                    //     : null,
                  ),
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _nameCtrl,
                  style:  TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  decoration:  InputDecoration(labelText: 'Karigar Name *', prefixIcon: Icon(Icons.person_outline, color: Theme.of(context).textTheme.bodySmall?.color, size: 20)),
                  validator: (v) => (v?.trim().isEmpty ?? true) ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneCtrl,
                  style:  TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  keyboardType: TextInputType.phone,
                  decoration:  InputDecoration(labelText: 'Phone Number *', prefixIcon: Icon(Icons.phone_outlined, color: Theme.of(context).textTheme.bodySmall?.color, size: 20)),
                  validator: (v) {
                    final s = v?.trim() ?? '';
                    if (s.isEmpty) return 'Phone number is required';
                    if (s.replaceAll(RegExp(r'\D'), '').length < 10) return 'Enter valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressCtrl,
                  style:  TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  decoration:  InputDecoration(labelText: 'Address / Workplace (Optional)', prefixIcon: Icon(Icons.location_on_outlined, color: Theme.of(context).textTheme.bodySmall?.color, size: 20)),
                  maxLines: 2,
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.darkBg))
                        : Text(_isEdit ? 'Save Changes' : 'Add Karigar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppTheme.primaryGold),
              title: Text('Take Photo', style: GoogleFonts.lato(color: Theme.of(context).textTheme.bodyLarge?.color)),
              onTap: () { Navigator.pop(context); _pickImage(true); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppTheme.primaryGold),
              title: Text('Choose from Gallery', style: GoogleFonts.lato(color: Theme.of(context).textTheme.bodyLarge?.color)),
              onTap: () { Navigator.pop(context); _pickImage(false); },
            ),
            if (_imagePath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppTheme.redDot),
                title: Text('Remove Photo', style: GoogleFonts.lato(color: AppTheme.redDot)),
                onTap: () { Navigator.pop(context); setState(() => _imagePath = null); },
              ),
          ],
        ),
      ),
    );
  }
}
