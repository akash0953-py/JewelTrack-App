// lib/screens/job/job_detail_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/job.dart';
import '../../providers/app_providers.dart';
import '../../utils/app_theme.dart';
import '../../utils/communication_service.dart';
import '../job/add_job_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class JobDetailScreen extends ConsumerWidget {
  final int jobId;
  const JobDetailScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(jobsProvider);
    return jobsAsync.when(
      loading: () => Scaffold(
          body: Center(
              child: CircularProgressIndicator(color: AppTheme.accentColor(context)))),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (list) {
        final job = list.cast<Job?>().firstWhere((j) => j?.id == jobId, orElse: () => null);
        if (job == null) return const Scaffold(body: Center(child: Text('Job not found')));
        return _JobDetailView(job: job);
      },
    );
  }
}

class _JobDetailView extends ConsumerWidget {
  final Job job;
  const _JobDetailView({required this.job});

  void _showFullscreenImage(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (ctx, _, __) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(job.itemName, style: GoogleFonts.lato(color: Colors.white, fontSize: 16)),
          ),
          body: Center(
            child: Hero(
              tag: 'job_image_${job.id}',
              child: InteractiveViewer(
                panEnabled: true,
                scaleEnabled: true,
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.file(File(job.imagePath!), fit: BoxFit.contain),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark      = AppTheme.isDark(context);
    final accent      = AppTheme.accentColor(context);
    final isActive    = job.status == JobStatus.active;
    final isCompleted = job.status == JobStatus.completed;
    final isCancelled = job.status == JobStatus.cancelled;
    final isOverdue   = job.isOverdue;

    final profileAsync = ref.watch(profileProvider);
    final shopName = profileAsync.asData?.value?.shopName ?? 'Jewellery Shop';

    final Color statusColor = isCompleted
        ? AppTheme.greenDot
        : isOverdue
            ? AppTheme.redDot
            : isCancelled
                ? (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey)
                : AppTheme.yellowDot;

    return Scaffold(
      appBar: AppBar(
        title: Text(job.itemName, overflow: TextOverflow.ellipsis),
        // AppBar always coloured, icons always white
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (isActive)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => AddJobScreen(existing: job))),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Design image ─────────────────────────────────
              if (job.imagePath != null)
                GestureDetector(
                  onTap: () => _showFullscreenImage(context),
                  child: Hero(
                    tag: 'job_image_${job.id}',
                    child: Stack(children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(File(job.imagePath!),
                            width: double.infinity, height: 220, fit: BoxFit.cover),
                      ),
                      Positioned(
                        right: 10, bottom: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.zoom_in, color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text('Tap to expand',
                                style: GoogleFonts.lato(color: Colors.white, fontSize: 11)),
                          ]),
                        ),
                      ),
                    ]),
                  ),
                )
              else
                Container(
                  width: double.infinity, height: 140,
                  decoration: BoxDecoration(
                    color:  AppTheme.surfaceColor(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.dividerColor(context)),
                  ),
                  child: Icon(Icons.diamond_outlined, color: accent, size: 48),
                ),
              const SizedBox(height: 20),

              // ── Status badge + title ──────────────────────────
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color:  statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    isCompleted ? 'Completed' : isOverdue ? 'Overdue' : isCancelled ? 'Cancelled' : 'Active',
                    style: GoogleFonts.lato(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              Text(job.itemName,
                  style: GoogleFonts.playfairDisplay(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Karigar: ${job.karigarName}',
                  style: GoogleFonts.lato(
                      color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 13)),
              const SizedBox(height: 20),

              // ── FIX 6: Receipt card replaces plain details card for active jobs ──
              if (isActive) ...[
                _receiptCard(context, accent, isDark),
                const SizedBox(height: 12),

                // Send receipt to karigar
                _sendReceiptButton(context, ref, shopName, accent),
                const SizedBox(height: 20),
              ],

              // For completed / cancelled jobs, show normal details card
              if (!isActive)
                _detailCard(context, [
                  _detailRow(context, Icons.scale_outlined, 'Gold Issued',
                      '${job.issuedWeight.toStringAsFixed(2)} grams'),
                  _detailRow(context, Icons.calendar_today_outlined, 'Date Added',
                      DateFormat('dd MMM yyyy').format(job.dateAdded)),
                  _detailRow(context, Icons.event_outlined, 'Expected By',
                      DateFormat('dd MMM yyyy').format(job.expectedDate)),
                  if (isCompleted) ...[
                    _detailRow(context, Icons.check_circle_outline, 'Completed On',
                        DateFormat('dd MMM yyyy').format(job.completedDate ?? DateTime.now())),
                    if (job.grossWeight != null)
                      _detailRow(context, Icons.straighten_outlined, 'Gross Weight',
                          '${job.grossWeight!.toStringAsFixed(2)} grams'),
                    if (job.netGoldWeight != null)
                      _detailRow(context, Icons.diamond_outlined, 'Net Gold Weight',
                          '${job.netGoldWeight!.toStringAsFixed(2)} grams'),
                    _detailRow(context, Icons.trending_down, 'Gold Wastage',
                        '${job.wastage.toStringAsFixed(2)} grams'),
                  ],
                ]),
              const SizedBox(height: 20),

              // ── FIX 5: Action buttons — solid colours in light mode ──
              if (isActive) ...[
                Row(children: [
                  Expanded(
                    child: _solidActionButton(
                      context: context,
                      icon: Icons.call_outlined,
                      label: 'Call Karigar',
                      color: AppTheme.greenDot,
                      isDark: isDark,
                      onTap: () => _getKarigarPhone(
                          ref, (phone) => CommunicationService.callNumber(phone)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _solidActionButton(
                      context: context,
                      icon: FontAwesomeIcons.whatsapp,
                      label: isOverdue ? 'Send Reminder' : 'WhatsApp',
                      color: isOverdue ? AppTheme.redDot : const Color(0xFF25D366),
                      isDark: isDark,
                      onTap: () => _sendWhatsApp(context, ref, shopName),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.greenDot,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    icon: const Icon(Icons.task_alt_outlined),
                    label: const Text('Work Done'),
                    onPressed: () => _showWorkDoneDialog(context, ref),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.redDot,
                      side: const BorderSide(color: AppTheme.redDot),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text('Cancel Job / Return Gold'),
                    onPressed: () => _cancelJob(context, ref),
                  ),
                ),
              ],

              if (isCompleted)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: accent,
                      side: BorderSide(color: accent),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit Received Weight'),
                    onPressed: () => _editReceivedWeight(context, ref),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── FIX 6: Receipt card widget ────────────────────────────────
  Widget _receiptCard(BuildContext context, Color accent, bool isDark) {
    final dateAdded  = DateFormat('dd MMM yyyy').format(job.dateAdded);
    final dateExpect = DateFormat('dd MMM yyyy').format(job.expectedDate);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:  isDark ? AppTheme.cardBg : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.3), width: 1.5),
        boxShadow: isDark
            ? []
            : [BoxShadow(color: accent.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Receipt header
          Row(children: [
            Icon(Icons.receipt_long_outlined, color: accent, size: 16),
            const SizedBox(width: 8),
            Text('JOB RECEIPT',
                style: GoogleFonts.lato(
                    color: accent, fontSize: 11,
                    fontWeight: FontWeight.w700, letterSpacing: 1.2)),
          ]),
          Divider(color: AppTheme.dividerColor(context), height: 16),
          _receiptRow(context, 'Item',        job.itemName),
          _receiptDivider(context),
          _receiptRow(context, 'Karigar',     job.karigarName),
          _receiptDivider(context),
          _receiptRow(context, 'Gold Issued', '${job.issuedWeight.toStringAsFixed(2)} grams'),
          _receiptDivider(context),
          _receiptRow(context, 'Date Added',  dateAdded),
          _receiptDivider(context),
          _receiptRow(context, 'Expected By', dateExpect),
        ],
      ),
    );
  }

  Widget _receiptRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        Text(label,
            style: GoogleFonts.lato(
                color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12)),
        const Spacer(),
        Text(value,
            style: GoogleFonts.lato(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _receiptDivider(BuildContext context) =>
      Divider(color: AppTheme.dividerColor(context), height: 1, thickness: 1);

  // ── Send receipt button ───────────────────────────────────────
  Widget _sendReceiptButton(
      BuildContext context, WidgetRef ref, String shopName, Color accent) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF25D366),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: const Icon(FontAwesomeIcons.whatsapp, size: 18),
        label: Text('Send Receipt to Karigar',
            style: GoogleFonts.lato(fontWeight: FontWeight.w700, fontSize: 14)),
        onPressed: () => _sendReceiptWhatsApp(context, ref, shopName),
      ),
    );
  }

  Future<void> _sendReceiptWhatsApp(
      BuildContext context, WidgetRef ref, String shopName) async {
    final karigars = ref.read(karigarsProvider).asData?.value ?? [];
    final karigar  = karigars.cast().firstWhere(
        (k) => k.id == job.karigarId, orElse: () => null);
    if (karigar == null) return;

    final dateAdded  = DateFormat('dd/MM/yyyy').format(job.dateAdded);
    final dateExpect = DateFormat('dd/MM/yyyy').format(job.expectedDate);
    final receipt    = '🏅 *Work Order Receipt*\n\n'
        '*Shop:* $shopName\n'
        '*Karigar:* ${karigar.name}\n'
        '*Item:* ${job.itemName}\n'
        '*Gold Issued:* ${job.issuedWeight.toStringAsFixed(2)} grams\n'
        '*Date:* $dateAdded\n'
        '*Expected By:* $dateExpect\n\n'
        '_Please keep this receipt for your reference._\n'
        '— $shopName';

    await CommunicationService.sendWhatsApp(
        phone: karigar.phoneNumber, message: receipt);
  }

  // ── FIX 5: Solid action buttons ──────────────────────────────
  Widget _solidActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    // In light mode: filled solid button; in dark: ghost style
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color:  isDark ? color.withOpacity(0.12) : color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? color.withOpacity(0.4) : Colors.transparent),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: isDark ? color : Colors.white, size: 18),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.lato(
                  color: isDark ? color : Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────
  Future<void> _getKarigarPhone(
      WidgetRef ref, Function(String) callback) async {
    final karigars = ref.read(karigarsProvider).asData?.value ?? [];
    final karigar  = karigars.cast().firstWhere(
        (k) => k.id == job.karigarId, orElse: () => null);
    if (karigar != null) callback(karigar.phoneNumber);
  }

  Future<void> _sendWhatsApp(
      BuildContext context, WidgetRef ref, String shopName) async {
    final karigars = ref.read(karigarsProvider).asData?.value ?? [];
    final karigar  = karigars.cast().firstWhere(
        (k) => k.id == job.karigarId, orElse: () => null);
    if (karigar == null) return;
    final msg = CommunicationService.buildReminderMessage(
      shopName:      shopName,
      karigarName:   karigar.name,
      itemName:      job.itemName,
      issuedWeight:  job.issuedWeight,
      expectedDate:  job.expectedDate,
    );
    await CommunicationService.sendWhatsApp(
        phone: karigar.phoneNumber, message: msg);
  }

  void _showWorkDoneDialog(BuildContext context, WidgetRef ref) {
    final grossCtrl = TextEditingController();
    final netCtrl   = TextEditingController();
    final formKey   = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardColor(context),
        title: Text('Mark Work Done',
            style: GoogleFonts.playfairDisplay(
                color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 18)),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Item: ${job.itemName}',
                style: GoogleFonts.lato(
                    color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12)),
            Text('Issued: ${job.issuedWeight.toStringAsFixed(2)} grams',
                style: GoogleFonts.lato(color: AppTheme.accentColor(context), fontSize: 12)),
            const SizedBox(height: 16),
            TextFormField(
              controller: grossCtrl,
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Gross Weight', suffix: Text('grams'),
                  hintText: 'Total weight of ornament'),
              validator: (v) {
                final n = double.tryParse(v?.trim() ?? '');
                if (n == null || n <= 0) return 'Enter valid gross weight';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: netCtrl,
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Net Gold Weight', suffix: Text('grams'),
                  hintText: 'Excluding stones'),
              validator: (v) {
                final net = double.tryParse(v?.trim() ?? '');
                if (net == null || net <= 0) return 'Enter valid net gold weight';
                if (net > job.issuedWeight) {
                  return 'Net gold cannot exceed issued weight (${job.issuedWeight.toStringAsFixed(2)}g)';
                }
                return null;
              },
            ),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(_),
              child: Text('Cancel',
                  style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color))),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final gross = double.parse(grossCtrl.text.trim());
              final net   = double.parse(netCtrl.text.trim());
              Navigator.pop(_);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (__) => AlertDialog(
                  backgroundColor: AppTheme.cardColor(context),
                  title: Text('Confirm',
                      style: GoogleFonts.playfairDisplay(
                          color: Theme.of(context).textTheme.bodyLarge?.color)),
                  content: Text(
                    'Mark this job as complete?\n\n'
                    'Gross: ${gross.toStringAsFixed(2)} grams\n'
                    'Net Gold: ${net.toStringAsFixed(2)} grams\n'
                    'Wastage: ${(job.issuedWeight - net).toStringAsFixed(2)} grams',
                    style: GoogleFonts.lato(
                        color: Theme.of(context).textTheme.bodySmall?.color),
                  ),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(__, false),
                        child: Text('Back',
                            style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color))),
                    ElevatedButton(
                        onPressed: () => Navigator.pop(__, true),
                        child: const Text('Confirm')),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                await ref.read(jobsProvider.notifier).complete(job, gross, net);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _cancelJob(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardColor(context),
        title: Text('Cancel Job?',
            style: GoogleFonts.playfairDisplay(
                color: Theme.of(context).textTheme.bodyLarge?.color)),
        content: Text(
          'This will return ${job.issuedWeight.toStringAsFixed(2)} grams of gold '
          'back to the shop. No wastage will be recorded.',
          style: GoogleFonts.lato(
              color: Theme.of(context).textTheme.bodySmall?.color),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(_, false),
              child: Text('Back',
                  style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color))),
          TextButton(
              onPressed: () => Navigator.pop(_, true),
              child: const Text('Cancel Job',
                  style: TextStyle(color: AppTheme.redDot))),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(jobsProvider.notifier).cancel(job);
      if (context.mounted) Navigator.pop(context);
    }
  }

  void _editReceivedWeight(BuildContext context, WidgetRef ref) {
    final netCtrl = TextEditingController(
        text: job.netGoldWeight?.toStringAsFixed(2) ?? '');
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardColor(context),
        title: Text('Edit Received Weight',
            style: GoogleFonts.playfairDisplay(
                color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 18)),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: netCtrl,
            style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
                labelText: 'Net Gold Weight', suffix: Text('grams')),
            validator: (v) {
              final n = double.tryParse(v?.trim() ?? '');
              if (n == null || n < 0) return 'Enter valid weight';
              if (n > job.issuedWeight) {
                return 'Cannot exceed issued (${job.issuedWeight.toStringAsFixed(2)}g)';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(_),
              child: Text('Cancel',
                  style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color))),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final net = double.parse(netCtrl.text.trim());
              job.netGoldWeight  = net;
              job.receivedWeight = net;
              await ref.read(jobsProvider.notifier).update(job);
              if (_.mounted) Navigator.pop(_);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _detailCard(BuildContext context, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:  AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.dividerColor(context)),
      ),
      child: Column(children: children),
    );
  }

  Widget _detailRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        Icon(icon, size: 16, color: Theme.of(context).textTheme.bodySmall?.color),
        const SizedBox(width: 10),
        Text(label,
            style: GoogleFonts.lato(
                color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 13)),
        const Spacer(),
        Text(value,
            style: GoogleFonts.lato(
                color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
