// lib/screens/home/home_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/karigar.dart';
import '../../providers/app_providers.dart';
import '../../utils/app_theme.dart';
import '../karigar/karigar_detail_screen.dart';
import '../karigar/add_karigar_screen.dart';
import '../job/add_job_screen.dart';
import '../history/history_screen.dart';
import '../profile/profile_screen.dart';
import '../../models/job.dart';
import '../../screens/job/active_jobs_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final profileAsync = ref.watch(profileProvider);
    final shopName = profileAsync.when(
      data: (p) => p?.shopName ?? 'JewelTrack',
      loading: () => 'JewelTrack',
      error: (_, __) => 'JewelTrack',
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // FIX 1: shop name always white on AppBar (AppBar bg is blue/maroon)
            Text(shopName,
                style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
            Text('Karigar Management',
                style: GoogleFonts.lato(
                    color: Colors.white70,
                    fontSize: 11)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
        ],
      ),
      body: IndexedStack(
        index: _tabIndex,
        children: const [
          _HomeTab(),
          ActiveJobsScreen(),
          HistoryScreen(),
        ],
      ),
      floatingActionButton: _tabIndex == 0
          ? FloatingActionButton.extended(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              onPressed: () => _showAddMenu(context),
              icon: const Icon(Icons.add),
              label: Text('Add', style: GoogleFonts.lato(fontWeight: FontWeight.w700)),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.work_outline), activeIcon: Icon(Icons.work), label: 'Active Jobs'),
          BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history), label: 'History'),
        ],
      ),
    );
  }

  void _showAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor(context),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.dividerColor(context), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.person_add_outlined, color: AppTheme.accentColor(context)),
              title: Text('Add Karigar', style: GoogleFonts.lato(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.w600)),
              subtitle: Text('Register a new karigar', style: GoogleFonts.lato(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AddKarigarScreen()));
              },
            ),
            ListTile(
              leading: Icon(Icons.work_outline, color: AppTheme.accentColor(context)),
              title: Text('Add Job', style: GoogleFonts.lato(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.w600)),
              subtitle: Text('Assign new work to a karigar', style: GoogleFonts.lato(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AddJobScreen()));
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─── Home Tab ─────────────────────────────────────────────────
class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppTheme.isDark(context);
    final karigarsAsync = ref.watch(karigarsProvider);
    final filteredKarigars = ref.watch(filteredKarigarsProvider);
    final totalGold = ref.watch(totalGoldOutProvider);

    return SafeArea(
      child: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                hintText: 'Search karigars or job items...',
                prefixIcon: Icon(Icons.search, color: Theme.of(context).textTheme.bodySmall?.color, size: 20),
                suffixIcon: ref.watch(searchQueryProvider).isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Theme.of(context).textTheme.bodySmall?.color, size: 18),
                        onPressed: () => ref.read(searchQueryProvider.notifier).state = '',
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
            ),
          ),
          const SizedBox(height: 16),
          // Summary card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _SummaryCard(totalGold: totalGold, karigarsAsync: karigarsAsync),
          ),
          const SizedBox(height: 16),
          // Grid header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Text('Karigars',
                  style: GoogleFonts.lato(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
              const SizedBox(width: 8),
              karigarsAsync.when(
                data: (list) => Text('(${list.length})', style: Theme.of(context).textTheme.bodySmall),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ]),
          ),
          const SizedBox(height: 8),
          // Grid
          Expanded(
            child: karigarsAsync.when(
              loading: () => Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
              error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppTheme.redDot))),
              data: (_) {
                if (filteredKarigars.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline, color: Theme.of(context).textTheme.bodySmall?.color, size: 48),
                        const SizedBox(height: 12),
                        Text('No karigars found', style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: filteredKarigars.length,
                  itemBuilder: (_, i) => _KarigarCard(karigar: filteredKarigars[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Summary Card ─────────────────────────────────────────────
class _SummaryCard extends ConsumerWidget {
  final double totalGold;
  final AsyncValue<List> karigarsAsync;

  const _SummaryCard({required this.totalGold, required this.karigarsAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppTheme.isDark(context);
    final accent = AppTheme.accentColor(context);

    final activeJobs = ref.watch(jobsProvider).when(
          data: (list) => list.where((j) => j.status == JobStatus.active).length,
          loading: () => 0,
          error: (_, __) => 0,
        );
    final overdueJobs = ref.watch(jobsProvider).when(
          data: (list) => list.where((j) => j.isOverdue).length,
          loading: () => 0,
          error: (_, __) => 0,
        );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // FIX 2: in light mode use a solid blue card, not pale gradient
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF2A2310), Color(0xFF1C1A14)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [AppTheme.lightPrimary, AppTheme.lightAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withOpacity(isDark ? 0.4 : 0.0), width: 1),
        boxShadow: [
          BoxShadow(color: accent.withOpacity(0.25), blurRadius: 16, spreadRadius: 2),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.bar_chart_rounded,
                color: isDark ? AppTheme.primaryGold : Colors.white70, size: 16),
            const SizedBox(width: 6),
            Text('TOTAL GOLD OUT',
                style: GoogleFonts.lato(
                    color: isDark ? AppTheme.textSecondary : Colors.white70,
                    fontSize: 11,
                    letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(totalGold.toStringAsFixed(2),
                  style: GoogleFonts.playfairDisplay(
                      color: isDark ? AppTheme.primaryGold : Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w700)),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('grams',
                    style: GoogleFonts.lato(
                        color: isDark ? AppTheme.textSecondary : Colors.white70,
                        fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(children: [
            _statChip(Icons.work_outline, '$activeJobs Active', AppTheme.yellowDot, isDark),
            const SizedBox(width: 10),
            _statChip(Icons.warning_amber_outlined, '$overdueJobs Overdue', AppTheme.redDot, isDark),
          ]),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label, Color color, bool isDark) {
    // In light mode on a blue card, use white-tinted chips
    final chipColor = isDark ? color : Colors.white;
    final chipBg = isDark ? color.withOpacity(0.12) : Colors.white.withOpacity(0.2);
    final chipBorder = isDark ? color.withOpacity(0.3) : Colors.white.withOpacity(0.4);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: chipBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: chipBorder),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: chipColor, size: 13),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.lato(color: chipColor, fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ─── Karigar Card ─────────────────────────────────────────────
class _KarigarCard extends ConsumerWidget {
  final Karigar karigar;
  const _KarigarCard({required this.karigar});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppTheme.isDark(context);
    final accent = AppTheme.accentColor(context);
    final activeJobs = ref.watch(karigarActiveJobsProvider(karigar.id));
    final status = getKarigarStatus(activeJobs);
    final dotColor = status == KarigarStatus.free
        ? AppTheme.greenDot
        : status == KarigarStatus.overdue
            ? AppTheme.redDot
            : AppTheme.yellowDot;
    final goldHeld = activeJobs.fold(0.0, (s, j) => s + j.issuedWeight);

    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => KarigarDetailScreen(karigarId: karigar.id))),
      // FIX 3: in light mode give cards a visible blue-tinted border + slight elevation
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.cardBg
              : Colors.white,
          border: Border.all(
            color: isDark ? AppTheme.divider : AppTheme.lightPrimary.withOpacity(0.3),
            width: isDark ? 1 : 1.5,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDark
              ? []
              : [BoxShadow(color: AppTheme.lightPrimary.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 100,
                  height: 85,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: accent, width: 1.5),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 6, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: karigar.imagePath != null
                        ? Image.file(File(karigar.imagePath!), fit: BoxFit.cover)
                        : Container(
                            color: isDark ? AppTheme.surfaceBg : AppTheme.lightSurfaceBg,
                            child: Center(
                              child: Text(
                                karigar.name[0].toUpperCase(),
                                style: GoogleFonts.playfairDisplay(
                                  color: accent,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
                // Status dot
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                    boxShadow: [BoxShadow(color: dotColor.withOpacity(0.5), blurRadius: 6, spreadRadius: 1)],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(karigar.name,
                style: GoogleFonts.lato(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 14,
                    fontWeight: FontWeight.w700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(karigar.phoneNumber,
                style: GoogleFonts.lato(
                    color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 11),
                overflow: TextOverflow.ellipsis),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.surfaceBg : AppTheme.lightSurfaceBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.diamond_outlined, size: 11, color: accent),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    goldHeld > 0 ? '${goldHeld.toStringAsFixed(2)}g' : 'Free',
                    style: GoogleFonts.lato(
                        color: goldHeld > 0 ? accent : AppTheme.greenDot,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
