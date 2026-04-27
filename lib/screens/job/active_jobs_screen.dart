// lib/screens/job/active_jobs_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_providers.dart';
import '../../models/job.dart';
import '../../utils/app_theme.dart';
import 'job_detail_screen.dart';

class ActiveJobsScreen extends ConsumerWidget {
  const ActiveJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark    = AppTheme.isDark(context);
    final accent    = AppTheme.accentColor(context);
    final jobsAsync = ref.watch(jobsProvider);

    return Scaffold(
      body: SafeArea(
        child: jobsAsync.when(
          loading: () => Center(
              child: CircularProgressIndicator(color: accent)),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (jobs) {
            final activeJobs =
                jobs.where((j) => j.status == JobStatus.active).toList();

            if (activeJobs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.work_off_outlined,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        size: 48),
                    const SizedBox(height: 12),
                    Text('No active jobs',
                        style: GoogleFonts.lato(
                            color: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.color)),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: activeJobs.length,
              itemBuilder: (_, i) {
                final job      = activeJobs[i];
                final isOverdue = job.isOverdue;
                final color    = isOverdue ? AppTheme.redDot : AppTheme.yellowDot;

                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => JobDetailScreen(jobId: job.id)),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      // FIX 7: theme-aware card colour + blue accent left bar
                      color:  AppTheme.cardColor(context),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.dividerColor(context)),
                      boxShadow: isDark
                          ? []
                          : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                    child: Row(
                      children: [
                        // FIX 7: left accent bar — blue in light, colour-coded in dark
                        Container(
                          width: 4,
                          height: 78,
                          decoration: BoxDecoration(
                            color: isDark ? color : accent,
                            borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(14)),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Image
                        if (job.imagePath != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(job.imagePath!),
                              width: 52, height: 52, fit: BoxFit.cover,
                            ),
                          )
                        else
                          Container(
                            width: 52, height: 52,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppTheme.surfaceBg
                                  : AppTheme.lightSurfaceBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.diamond_outlined,
                                color: accent, size: 24),
                          ),

                        const SizedBox(width: 14),

                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(job.itemName,
                                  style: GoogleFonts.lato(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14)),
                              const SizedBox(height: 4),
                              Text(job.karigarName,
                                  style: GoogleFonts.lato(
                                      color: accent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(
                                  '${job.issuedWeight.toStringAsFixed(2)} grams issued',
                                  style: GoogleFonts.lato(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.color,
                                      fontSize: 11)),
                            ],
                          ),
                        ),

                        // Status badge
                        Padding(
                          padding: const EdgeInsets.only(right: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: color.withOpacity(0.3)),
                                ),
                                child: Text(
                                  isOverdue ? 'Overdue' : 'Active',
                                  style: GoogleFonts.lato(
                                      color: color,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Due: ${job.expectedDate.day}/${job.expectedDate.month}',
                                style: GoogleFonts.lato(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color,
                                    fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
