// lib/providers/app_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/karigar.dart';
import '../models/job.dart';
import '../models/shop_profile.dart';
import '../utils/database_service.dart';

// ─── Profile ──────────────────────────────────────────────────
final profileProvider = FutureProvider<ShopProfile?>((ref) async {
  return DatabaseService.getProfile();
});

// ─── Karigars ─────────────────────────────────────────────────
final karigarsProvider = StateNotifierProvider<KarigarsNotifier, AsyncValue<List<Karigar>>>(
  (ref) => KarigarsNotifier(),
);

class KarigarsNotifier extends StateNotifier<AsyncValue<List<Karigar>>> {
  KarigarsNotifier() : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final list = await DatabaseService.getAllKarigars();
      state = AsyncValue.data(list);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<int> add(Karigar karigar) async {
    final id = await DatabaseService.saveKarigar(karigar);
    await load();
    return id;
  }

  Future<void> update(Karigar karigar) async {
    await DatabaseService.saveKarigar(karigar);
    await load();
  }

  Future<bool> delete(int id) async {
    final hasJobs = await DatabaseService.karigarHasActiveJobs(id);
    if (hasJobs) return false;
    await DatabaseService.deleteKarigar(id);
    await load();
    return true;
  }
}

// ─── Jobs ─────────────────────────────────────────────────────
final jobsProvider = StateNotifierProvider<JobsNotifier, AsyncValue<List<Job>>>(
  (ref) => JobsNotifier(),
);

class JobsNotifier extends StateNotifier<AsyncValue<List<Job>>> {
  JobsNotifier() : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final list = await DatabaseService.getAllJobs();
      state = AsyncValue.data(list);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<int> add(Job job) async {
    final id = await DatabaseService.saveJob(job);
    await load();
    return id;
  }

  Future<void> update(Job job) async {
    await DatabaseService.saveJob(job);
    await load();
  }

  Future<void> cancel(Job job) async {
    job.status = JobStatus.cancelled;
    await DatabaseService.saveJob(job);
    await load();
  }

  Future<void> complete(Job job, double grossWeight, double netGoldWeight) async {
    job.grossWeight = grossWeight;
    job.netGoldWeight = netGoldWeight;
    job.receivedWeight = netGoldWeight;
    job.status = JobStatus.completed;
    job.completedDate = DateTime.now();
    await DatabaseService.saveJob(job);
    await load();
  }
}

// ─── Derived: active jobs for karigar ─────────────────────────
final karigarActiveJobsProvider = Provider.family<List<Job>, int>((ref, karigarId) {
  final jobs = ref.watch(jobsProvider);
  return jobs.when(
    data: (list) => list
        .where((j) => j.karigarId == karigarId && j.status == JobStatus.active)
        .toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

final karigarCompletedJobsProvider = Provider.family<List<Job>, int>((ref, karigarId) {
  final jobs = ref.watch(jobsProvider);
  return jobs.when(
    data: (list) => list
        .where((j) => j.karigarId == karigarId && j.status == JobStatus.completed)
        .toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

final karigarAllJobsProvider = Provider.family<List<Job>, int>((ref, karigarId) {
  final jobs = ref.watch(jobsProvider);
  return jobs.when(
    data: (list) => list.where((j) => j.karigarId == karigarId).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

// ─── Total Gold Out ────────────────────────────────────────────
final totalGoldOutProvider = Provider<double>((ref) {
  final jobs = ref.watch(jobsProvider);
  return jobs.when(
    data: (list) => list
        .where((j) => j.status == JobStatus.active)
        .fold(0.0, (sum, j) => sum + j.issuedWeight),
    loading: () => 0,
    error: (_, __) => 0,
  );
});

// ─── Completed (history) jobs ─────────────────────────────────
final completedJobsProvider = Provider<List<Job>>((ref) {
  final jobs = ref.watch(jobsProvider);
  return jobs.when(
    data: (list) => list
        .where((j) => j.status == JobStatus.completed)
        .toList()
      ..sort((a, b) => (b.completedDate ?? b.dateAdded)
          .compareTo(a.completedDate ?? a.dateAdded)),
    loading: () => [],
    error: (_, __) => [],
  );
});

// ─── Search query ─────────────────────────────────────────────
final searchQueryProvider = StateProvider<String>((ref) => '');

// ─── Filtered karigars for home ───────────────────────────────
final filteredKarigarsProvider = Provider<List<Karigar>>((ref) {
  final karigars = ref.watch(karigarsProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();
  final jobs = ref.watch(jobsProvider);

  return karigars.when(
    data: (list) {
      if (query.isEmpty) return list;
      return list.where((k) {
        if (k.name.toLowerCase().contains(query)) return true;
        // Also match by job item names
        final kJobs = jobs.when(
          data: (jlist) => jlist.where((j) =>
              j.karigarId == k.id &&
              j.status == JobStatus.active &&
              j.itemName.toLowerCase().contains(query)),
          loading: () => <Job>[],
          error: (_, __) => <Job>[],
        );
        return kJobs.isNotEmpty;
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// ─── Karigar status ───────────────────────────────────────────
enum KarigarStatus { free, active, overdue }

KarigarStatus getKarigarStatus(List<Job> jobs) {
  if (jobs.isEmpty) return KarigarStatus.free;
  if (jobs.any((j) => j.isOverdue)) return KarigarStatus.overdue;
  return KarigarStatus.active;
}
