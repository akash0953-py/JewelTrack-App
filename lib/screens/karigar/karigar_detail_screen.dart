// lib/screens/karigar/karigar_detail_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/karigar.dart';
import '../../models/job.dart';
import '../../providers/app_providers.dart';
import '../../utils/app_theme.dart';
import '../../utils/communication_service.dart';
import '../job/add_job_screen.dart';
import '../job/job_detail_screen.dart';
import 'add_karigar_screen.dart';

class KarigarDetailScreen extends ConsumerWidget {
  final int karigarId;
  const KarigarDetailScreen({super.key, required this.karigarId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final karigarAsync = ref.watch(karigarsProvider);
    return karigarAsync.when(
      loading: () => Scaffold(
          body: Center(
              child: CircularProgressIndicator(
                  color: AppTheme.accentColor(context)))),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (list) {
        final karigar = list
            .cast<Karigar?>()
            .firstWhere((k) => k?.id == karigarId, orElse: () => null);
        if (karigar == null) {
          return const Scaffold(
              body: Center(child: Text('Karigar not found')));
        }
        return _KarigarDetailView(karigar: karigar);
      },
    );
  }
}

class _KarigarDetailView extends ConsumerStatefulWidget {
  final Karigar karigar;
  const _KarigarDetailView({required this.karigar});
  @override
  ConsumerState<_KarigarDetailView> createState() =>
      _KarigarDetailViewState();
}

class _KarigarDetailViewState extends ConsumerState<_KarigarDetailView>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _deleteKarigar() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardColor(context),
        title: Text('Delete Karigar?',
            style: GoogleFonts.playfairDisplay(
                color: Theme.of(context).textTheme.bodyLarge?.color)),
        content: Text(
            'This will permanently delete ${widget.karigar.name}. This cannot be undone.',
            style: GoogleFonts.lato(
                color: Theme.of(context).textTheme.bodySmall?.color)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel',
                  style: TextStyle(
                      color:
                          Theme.of(context).textTheme.bodySmall?.color))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete',
                  style: TextStyle(color: AppTheme.redDot))),
        ],
      ),
    );
    if (confirm != true) return;
    final success =
        await ref.read(karigarsProvider.notifier).delete(widget.karigar.id);
    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Cannot delete: Karigar has active jobs. Complete or cancel them first.'),
          backgroundColor: AppTheme.redDot,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark       = AppTheme.isDark(context);
    final accent       = AppTheme.accentColor(context);
    final activeJobs   = ref.watch(karigarActiveJobsProvider(widget.karigar.id));
    final completedJobs= ref.watch(karigarCompletedJobsProvider(widget.karigar.id));
    final allJobs      = ref.watch(karigarAllJobsProvider(widget.karigar.id));

    final goldHeld        = activeJobs.fold(0.0, (s, j) => s + j.issuedWeight);
    final totalIssued     = allJobs.fold(0.0, (s, j) => s + j.issuedWeight);
    final totalReceived   = completedJobs.fold(0.0, (s, j) => s + (j.netGoldWeight ?? 0));
    final lifetimeWastage = totalIssued - totalReceived - goldHeld;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.karigar.name),
        // AppBar icons always white (AppBar bg is always coloured)
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        AddKarigarScreen(existing: widget.karigar))),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.redDot),
            onPressed: _deleteKarigar,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Profile header card ──────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              // FIX 4: theme-aware card colours
              decoration: BoxDecoration(
                color:   AppTheme.cardColor(context),
                borderRadius: BorderRadius.circular(16),
                border:  Border.all(color: AppTheme.dividerColor(context)),
                boxShadow: isDark
                    ? []
                    : [BoxShadow(color: accent.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: isDark ? AppTheme.surfaceBg : AppTheme.lightSurfaceBg,
                        child: widget.karigar.imagePath != null
                            ? ClipOval(
                                child: Image.file(
                                  File(widget.karigar.imagePath!),
                                  width: 64, height: 64, fit: BoxFit.cover,
                                ),
                              )
                            : Text(
                                widget.karigar.name[0].toUpperCase(),
                                style: GoogleFonts.playfairDisplay(
                                    color: accent,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700),
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.karigar.name,
                                style: GoogleFonts.playfairDisplay(
                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Row(children: [
                              Icon(Icons.phone_outlined,
                                  size: 13,
                                  color: Theme.of(context).textTheme.bodySmall?.color),
                              const SizedBox(width: 4),
                              Text(widget.karigar.phoneNumber,
                                  style: GoogleFonts.lato(
                                      color: Theme.of(context).textTheme.bodySmall?.color,
                                      fontSize: 13)),
                            ]),
                            if (widget.karigar.address != null) ...[
                              const SizedBox(height: 2),
                              Row(children: [
                                Icon(Icons.location_on_outlined,
                                    size: 13,
                                    color: Theme.of(context).textTheme.bodySmall?.color),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(widget.karigar.address!,
                                      style: GoogleFonts.lato(
                                          color: Theme.of(context).textTheme.bodySmall?.color,
                                          fontSize: 12),
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ]),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => CommunicationService.callNumber(
                            widget.karigar.phoneNumber),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: AppTheme.greenDot.withOpacity(0.15),
                              shape: BoxShape.circle),
                          child: const Icon(Icons.call_outlined,
                              color: AppTheme.greenDot, size: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: AppTheme.dividerColor(context), height: 1),
                  const SizedBox(height: 16),
                  // Metrics row
                  Row(children: [
                    Expanded(
                        child: _metricTile('Gold Held',
                            '${goldHeld.toStringAsFixed(2)} grams',
                            accent, Icons.diamond_outlined)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _metricTile(
                            'Lifetime Wastage',
                            '${lifetimeWastage.clamp(0, double.infinity).toStringAsFixed(2)} grams',
                            AppTheme.redDot,
                            Icons.trending_down)),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Tabs ─────────────────────────────────────────
            // FIX 4: tab indicator and label colours match theme
            TabBar(
              controller: _tabCtrl,
              tabs: [
                Tab(child: Text('Current Jobs (${activeJobs.length})',
                    style: GoogleFonts.lato(fontSize: 13))),
                Tab(child: Text('Completed (${completedJobs.length})',
                    style: GoogleFonts.lato(fontSize: 13))),
              ],
              indicatorColor: accent,
              labelColor:     accent,
              unselectedLabelColor:
                  Theme.of(context).textTheme.bodySmall?.color,
            ),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _JobList(jobs: activeJobs,    emptyMsg: 'No active jobs'),
                  _JobList(jobs: completedJobs, emptyMsg: 'No completed jobs yet'),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: accent,
        foregroundColor: isDark ? AppTheme.darkBg : Colors.white,
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => AddJobScreen(
                    preselectedKarigarId: widget.karigar.id))),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _metricTile(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:  color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Expanded(child: Text(label,
                style: GoogleFonts.lato(color: color, fontSize: 10, letterSpacing: 0.5))),
          ]),
          const SizedBox(height: 6),
          Text(value,
              style: GoogleFonts.lato(
                  color: color, fontSize: 14, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _JobList extends ConsumerWidget {
  final List<Job> jobs;
  final String emptyMsg;
  const _JobList({required this.jobs, required this.emptyMsg});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (jobs.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.work_off_outlined,
              color: Theme.of(context).textTheme.bodySmall?.color, size: 40),
          const SizedBox(height: 10),
          Text(emptyMsg,
              style: GoogleFonts.lato(
                  color: Theme.of(context).textTheme.bodySmall?.color)),
        ]),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: jobs.length,
      itemBuilder: (_, i) => _JobTile(job: jobs[i]),
    );
  }
}

class _JobTile extends StatelessWidget {
  final Job job;
  const _JobTile({required this.job});

  @override
  Widget build(BuildContext context) {
    final isDark    = AppTheme.isDark(context);
    final isOverdue = job.isOverdue;
    final barColor  = job.status == JobStatus.completed
        ? AppTheme.greenDot
        : isOverdue
            ? AppTheme.redDot
            : AppTheme.yellowDot;
    final dateStr =
        '${job.expectedDate.day}/${job.expectedDate.month}/${job.expectedDate.year}';

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => JobDetailScreen(jobId: job.id))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          // FIX 4: list tiles use theme-aware card colour
          color:  AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.dividerColor(context)),
          boxShadow: isDark
              ? []
              : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 72,
              decoration: BoxDecoration(
                color: barColor,
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(14)),
              ),
            ),
            const SizedBox(width: 14),
            if (job.imagePath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(File(job.imagePath!),
                    width: 48, height: 48, fit: BoxFit.cover),
              )
            else
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                    color: isDark ? AppTheme.surfaceBg : AppTheme.lightSurfaceBg,
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.diamond_outlined,
                    color: Theme.of(context).textTheme.bodySmall?.color, size: 22),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(job.itemName,
                      style: GoogleFonts.lato(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          fontSize: 14,
                          fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('${job.issuedWeight.toStringAsFixed(2)} grams issued',
                      style: GoogleFonts.lato(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontSize: 12)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(dateStr,
                      style: GoogleFonts.lato(
                          color: barColor, fontSize: 11, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: barColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      job.status == JobStatus.completed
                          ? 'Done'
                          : isOverdue
                              ? 'Overdue'
                              : 'Active',
                      style: GoogleFonts.lato(
                          color: barColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
