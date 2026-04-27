// lib/screens/job/add_job_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/job.dart';
import '../../models/karigar.dart';
import '../../providers/app_providers.dart';
import '../../utils/app_theme.dart';
import '../../utils/communication_service.dart';
import '../../utils/image_service.dart';
import '../karigar/add_karigar_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AddJobScreen extends ConsumerStatefulWidget {
  final int? preselectedKarigarId;
  final Job? existing; // for edit mode
  const AddJobScreen({super.key, this.preselectedKarigarId, this.existing});
  @override
  ConsumerState<AddJobScreen> createState() => _AddJobScreenState();
}

class _AddJobScreenState extends ConsumerState<AddJobScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _itemCtrl   = TextEditingController();
  final _weightCtrl = TextEditingController();
  String?   _imagePath;
  DateTime? _expectedDate;
  int?      _selectedKarigarId;
  bool      _saving = false;

  bool get _isEdit     => widget.existing != null;
  bool get _isFinished => widget.existing?.status == JobStatus.completed;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedKarigarId != null) {
      _selectedKarigarId = widget.preselectedKarigarId;
    }
    if (_isEdit) {
      final j = widget.existing!;
      _itemCtrl.text   = j.itemName;
      _weightCtrl.text = j.issuedWeight.toString();
      _imagePath        = j.imagePath;
      _expectedDate     = j.expectedDate;
      _selectedKarigarId = j.karigarId;
    }
  }

  @override
  void dispose() {
    _itemCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now    = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expectedDate ?? now.add(const Duration(days: 7)),
      firstDate:  now,
      lastDate:   now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary:   AppTheme.accentColor(ctx),
            surface:   AppTheme.cardColor(ctx),
            onSurface: Theme.of(ctx).textTheme.bodyLarge?.color ?? Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _expectedDate = picked);
  }

  Future<void> _pickImage(bool fromCamera) async {
    final path =
        await ImageService.pickAndCompress(fromCamera: fromCamera);
    if (path != null) setState(() => _imagePath = path);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedKarigarId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select a karigar'),
          backgroundColor: AppTheme.redDot));
      return;
    }
    if (_expectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select expected due date'),
          backgroundColor: AppTheme.redDot));
      return;
    }

    setState(() => _saving = true);
    try {
      final karigars = ref.read(karigarsProvider).asData?.value ?? [];
      final karigar =
          karigars.firstWhere((k) => k.id == _selectedKarigarId);
      final weight = double.parse(_weightCtrl.text.trim());

      final job = (_isEdit ? widget.existing! : Job())
        ..karigarId    = _selectedKarigarId!
        ..karigarName  = karigar.name
        ..itemName     = _itemCtrl.text.trim()
        ..issuedWeight = weight
        ..imagePath    = _imagePath
        ..expectedDate = _expectedDate!;

      if (!_isEdit) job.dateAdded = DateTime.now();

      if (_isEdit) {
        await ref.read(jobsProvider.notifier).update(job);
        if (mounted) Navigator.pop(context, true);
      } else {
        await ref.read(jobsProvider.notifier).add(job);
        // ✅ Show receipt sheet after job creation
        if (mounted) {
          await _showReceiptSheet(context, karigar, job);
          if (mounted) Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.redDot));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Receipt bottom sheet ──────────────────────────────────────
  Future<void> _showReceiptSheet(
      BuildContext context, Karigar karigar, Job job) async {
    final shopName =
        ref.read(profileProvider).asData?.value?.shopName ?? 'Jewellery Shop';
    final dateAdded  = DateFormat('dd/MM/yyyy').format(job.dateAdded);
    final dateExpect = DateFormat('dd/MM/yyyy').format(job.expectedDate);

    final receipt = '🏅 *Work Order Receipt*\n\n'
        '*Shop:* $shopName\n'
        '*Karigar:* ${karigar.name}\n'
        '*Item:* ${job.itemName}\n'
        '*Gold Issued:* ${job.issuedWeight.toStringAsFixed(2)} grams\n'
        '*Date:* $dateAdded\n'
        '*Expected By:* $dateExpect\n\n'
        '_Please keep this receipt for your reference._\n'
        '— $shopName';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardColor(context),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.dividerColor(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Header
            Row(children: [
              Icon(Icons.receipt_long_outlined,
                  color: AppTheme.accentColor(context), size: 22),
              const SizedBox(width: 10),
              Text('Job Created!',
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.accentColor(context))),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.greenDot.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppTheme.greenDot.withOpacity(0.4)),
                ),
                child: Text('✓ Saved',
                    style: GoogleFonts.lato(
                        color: AppTheme.greenDot,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ]),
            const SizedBox(height: 14),

            // Receipt card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppTheme.accentColor(context).withOpacity(0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _receiptRow(context, 'Shop', shopName),
                  _receiptDivider(context),
                  _receiptRow(context, 'Karigar', karigar.name),
                  _receiptDivider(context),
                  _receiptRow(context, 'Item', job.itemName),
                  _receiptDivider(context),
                  _receiptRow(context, 'Gold Issued',
                      '${job.issuedWeight.toStringAsFixed(2)} grams'),
                  _receiptDivider(context),
                  _receiptRow(context, 'Date', dateAdded),
                  _receiptDivider(context),
                  _receiptRow(context, 'Expected By', dateExpect),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // WhatsApp send button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(FontAwesomeIcons.whatsapp, size: 18),
                label: Text('Send receipt to ${karigar.name} on WhatsApp',
                    style: GoogleFonts.lato(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                onPressed: () async {
                  Navigator.pop(sheetCtx);
                  await CommunicationService.sendWhatsApp(
                    phone:   karigar.phoneNumber,
                    message: receipt,
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // Skip button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(sheetCtx),
                child: Text('Skip',
                    style: GoogleFonts.lato(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _receiptRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Text(label,
            style: GoogleFonts.lato(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 12)),
        const Spacer(),
        Text(value,
            style: GoogleFonts.lato(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _receiptDivider(BuildContext context) =>
      Divider(color: AppTheme.dividerColor(context), height: 1, thickness: 1);

  // ── Old share receipt (keep for the AppBar button) ───────────
  Future<void> _shareReceiptViaSystem() async {
    if (_selectedKarigarId == null) return;
    final karigars = ref.read(karigarsProvider).asData?.value ?? [];
    final karigar = karigars
        .cast<Karigar?>()
        .firstWhere((k) => k?.id == _selectedKarigarId, orElse: () => null);
    if (karigar == null) return;

    final shopName =
        ref.read(profileProvider).asData?.value?.shopName ?? 'Jewellery Shop';
    final dateStr = _expectedDate != null
        ? DateFormat('dd/MM/yyyy').format(_expectedDate!)
        : 'TBD';
    final msg = '🏅 *Work Order Receipt*\n\n'
        '*Shop:* $shopName\n'
        '*Karigar:* ${karigar.name}\n'
        '*Item:* ${_itemCtrl.text.trim()}\n'
        '*Gold Issued:* ${_weightCtrl.text.trim()} grams\n'
        '*Expected By:* $dateStr\n\n'
        '_Please keep this receipt for your reference._';

    await CommunicationService.sendWhatsApp(
        phone: karigar.phoneNumber, message: msg);
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final karigarsAsync = ref.watch(karigarsProvider);
    final karigars      = karigarsAsync.asData?.value ?? [];
    final accent        = AppTheme.accentColor(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Job' : 'Add Job'),
        actions: [
          if (!_isFinished)
            TextButton.icon(
              onPressed: _shareReceiptViaSystem,
              icon: Icon(FontAwesomeIcons.whatsapp, size: 16, color: accent),
              label: Text('Send Receipt',
                  style: GoogleFonts.lato(color: accent, fontSize: 13)),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Design Image ──────────────────────────────
                Text('Design Image',
                    style: GoogleFonts.lato(
                        color:
                            Theme.of(context).textTheme.bodySmall?.color,
                        fontSize: 12,
                        letterSpacing: 0.5)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _isFinished ? null : _showImagePicker,
                  child: Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor(context),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppTheme.dividerColor(context)),
                      image: _imagePath != null
                          ? DecorationImage(
                              image: FileImage(File(_imagePath!)),
                              fit: BoxFit.cover)
                          : null,
                    ),
                    child: _imagePath == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color,
                                  size: 36),
                              const SizedBox(height: 8),
                              Text('Tap to add design image',
                                  style: GoogleFonts.lato(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.color,
                                      fontSize: 12)),
                            ],
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 20),

                // ── Item name ─────────────────────────────────
                TextFormField(
                  controller: _itemCtrl,
                  enabled: !_isFinished,
                  style: TextStyle(
                      color:
                          Theme.of(context).textTheme.bodyLarge?.color),
                  decoration: InputDecoration(
                    labelText: 'Ornament Name *',
                    hintText: 'e.g. Ring, Necklace, Bangle',
                    prefixIcon: Icon(Icons.diamond_outlined,
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color,
                        size: 20),
                  ),
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? 'Item name is required' : null,
                ),
                const SizedBox(height: 16),

                // ── Weight ────────────────────────────────────
                TextFormField(
                  controller: _weightCtrl,
                  enabled: !_isFinished,
                  style: TextStyle(
                      color:
                          Theme.of(context).textTheme.bodyLarge?.color),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Gold Issued *',
                    hintText: '0.00',
                    prefixIcon: Icon(Icons.scale_outlined,
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color,
                        size: 20),
                    suffix: const Text('grams'),
                  ),
                  validator: (v) {
                    if (v?.trim().isEmpty ?? true) return 'Weight is required';
                    final n = double.tryParse(v!.trim());
                    if (n == null || n <= 0) {
                      return 'Enter a valid weight in grams';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Karigar selector ──────────────────────────
                if (!_isFinished) ...[
                  Text('Karigar *',
                      style: GoogleFonts.lato(
                          color: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.color,
                          fontSize: 12,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.dividerColor(context)),
                    ),
                    child: Row(children: [
                      Icon(Icons.person_outline,
                          color: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.color,
                          size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _selectedKarigarId,
                            hint: Text(
                              'Select karigar',
                              style: GoogleFonts.lato(
                                color: (Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.color ??
                                        Colors.grey)
                                    .withOpacity(0.5),
                              ),
                            ),
                            dropdownColor: AppTheme.cardColor(context),
                            style: GoogleFonts.lato(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color,
                                fontSize: 14),
                            items: karigars
                                .map((k) => DropdownMenuItem(
                                    value: k.id, child: Text(k.name)))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedKarigarId = v),
                            isExpanded: true,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final result =
                              await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const AddKarigarScreen()));
                          if (result == true) {
                            final newList = ref
                                    .read(karigarsProvider)
                                    .asData
                                    ?.value ??
                                [];
                            if (newList.isNotEmpty) {
                              setState(() =>
                                  _selectedKarigarId = newList.last.id);
                            }
                          }
                        },
                        child: Text('+ New',
                            style: GoogleFonts.lato(
                                color: accent, fontSize: 12)),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Expected date ─────────────────────────────
                Text('Expected Due Date *',
                    style: GoogleFonts.lato(
                        color:
                            Theme.of(context).textTheme.bodySmall?.color,
                        fontSize: 12,
                        letterSpacing: 0.5)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _isFinished ? null : _pickDate,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.dividerColor(context)),
                    ),
                    child: Row(children: [
                      Icon(Icons.calendar_today_outlined,
                          color: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.color,
                          size: 18),
                      const SizedBox(width: 10),
                      Text(
                        _expectedDate != null
                            ? DateFormat('dd MMM yyyy')
                                .format(_expectedDate!)
                            : 'Select date',
                        style: GoogleFonts.lato(
                            color: _expectedDate != null
                                ? Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color
                                : (Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.color ??
                                        Colors.grey)
                                    .withOpacity(0.5),
                            fontSize: 14),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 36),

                // ── Save button ───────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_saving || _isFinished) ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(_isEdit ? 'Save Changes' : 'Add Job'),
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
    final accent = AppTheme.accentColor(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor(context),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt_outlined, color: accent),
              title: Text('Take Photo',
                  style: GoogleFonts.lato(
                      color: Theme.of(context).textTheme.bodyLarge?.color)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(true);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library_outlined, color: accent),
              title: Text('Choose from Gallery',
                  style: GoogleFonts.lato(
                      color:
                          Theme.of(context).textTheme.bodyLarge?.color)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(false);
              },
            ),
            if (_imagePath != null)
              ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: AppTheme.redDot),
                title: Text('Remove Image',
                    style: GoogleFonts.lato(color: AppTheme.redDot)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _imagePath = null);
                },
              ),
          ],
        ),
      ),
    );
  }
}
