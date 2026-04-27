// lib/screens/history/history_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/job.dart';
import '../../providers/app_providers.dart';
import '../../utils/app_theme.dart';
import '../job/job_detail_screen.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});
  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final isDark        = AppTheme.isDark(context);
    final accent        = AppTheme.accentColor(context);
    final allCompleted  = ref.watch(completedJobsProvider);

    final filtered = _query.isEmpty
        ? allCompleted
        : allCompleted.where((j) {
            final q = _query.toLowerCase();
            return j.itemName.toLowerCase().contains(q) ||
                j.karigarName.toLowerCase().contains(q);
          }).toList();

    final totalWastage = allCompleted.fold(0.0, (s, j) => s + j.wastage);
    final totalIssued  = allCompleted.fold(0.0, (s, j) => s + j.issuedWeight);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text('History',
                style: GoogleFonts.playfairDisplay(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 22,
                    fontWeight: FontWeight.w700)),
          ),

          // ── FIX 8: Stat cards with solid, legible colours ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              Expanded(child: _statCard(context, 'Jobs Done',      '${allCompleted.length}',                   AppTheme.greenDot, isDark)),
              const SizedBox(width: 10),
              Expanded(child: _statCard(context, 'Total Issued',   '${totalIssued.toStringAsFixed(2)}g',   accent,              isDark)),
              const SizedBox(width: 10),
              Expanded(child: _statCard(context, 'Total Wastage',  '${totalWastage.toStringAsFixed(2)}g',  AppTheme.redDot,     isDark)),
            ]),
          ),
          const SizedBox(height: 12),

          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                hintText: 'Search by item or karigar...',
                prefixIcon: Icon(Icons.search,
                    color: Theme.of(context).textTheme.bodySmall?.color, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear,
                            size: 18,
                            color: Theme.of(context).textTheme.bodySmall?.color),
                        onPressed: () => setState(() => _query = ''))
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          const SizedBox(height: 8),

          // List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.history_outlined,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          size: 48),
                      const SizedBox(height: 12),
                      Text(
                          _query.isEmpty
                              ? 'No completed jobs yet'
                              : 'No results found',
                          style: GoogleFonts.lato(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color)),
                    ]),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _HistoryTile(job: filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }

  // FIX 8: solid filled card in light mode so text is always readable
  Widget _statCard(BuildContext context, String label, String value,
      Color color, bool isDark) {
    // In light mode: solid coloured card with white text — always readable
    final bg       = isDark ? color.withOpacity(0.08) : color;
    final border   = isDark ? color.withOpacity(0.2)  : Colors.transparent;
    final valColor = isDark ? color : Colors.white;
    final lblColor = isDark ? color.withOpacity(0.7) : Colors.white.withOpacity(0.85);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color:  bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
        boxShadow: isDark
            ? []
            : [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: GoogleFonts.lato(
                  color: valColor, fontSize: 15, fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.lato(color: lblColor, fontSize: 10)),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final Job job;
  const _HistoryTile({required this.job});

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final accent = AppTheme.accentColor(context);
    final completedDate = job.completedDate != null
        ? DateFormat('dd MMM yyyy').format(job.completedDate!)
        : '-';

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => JobDetailScreen(jobId: job.id))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:  AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.dividerColor(context)),
          boxShadow: isDark
              ? []
              : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          // Thumbnail
          if (job.imagePath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(File(job.imagePath!),
                  width: 52, height: 52, fit: BoxFit.cover),
            )
          else
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                  color: isDark ? AppTheme.surfaceBg : AppTheme.lightSurfaceBg,
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.diamond_outlined, color: accent, size: 24),
            ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(job.itemName,
                  style: GoogleFonts.lato(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontSize: 14,
                      fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Text(job.karigarName,
                  style: GoogleFonts.lato(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 12),
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Text('Completed: $completedDate',
                  style: GoogleFonts.lato(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 11)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${job.issuedWeight.toStringAsFixed(2)}g',
                style: GoogleFonts.lato(
                    color: accent, fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Waste: ${job.wastage.toStringAsFixed(2)}g',
                style: GoogleFonts.lato(color: AppTheme.redDot, fontSize: 11)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: AppTheme.greenDot.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20)),
              child: Text('Done',
                  style: GoogleFonts.lato(
                      color: AppTheme.greenDot,
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
            ),
          ]),
        ]),
      ),
    );
  }
}
