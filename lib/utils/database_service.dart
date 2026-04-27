// lib/utils/database_service.dart
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/shop_profile.dart';
import '../models/karigar.dart';
import '../models/job.dart';
import 'dart:io';

class DatabaseService {
  static late Isar _isar;
  static bool _initialized = false;

  static Isar get isar => _isar;

  static Future<void> init() async {
    if (_initialized) {
      // Allow re-init after close (e.g. after restore)
      _initialized = false;
    }
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [ShopProfileSchema, KarigarSchema, JobSchema],
      directory: dir.path,
    );
    _initialized = true;
  }

  // ─── ShopProfile ─────────────────────────────────────────
  static Future<ShopProfile?> getProfile() async {
    return _isar.shopProfiles.where().findFirst();
  }

  static Future<void> saveProfile(ShopProfile profile) async {
    await _isar.writeTxn(() async {
      await _isar.shopProfiles.put(profile);
    });
  }

  // ─── Karigar ─────────────────────────────────────────────
  static Future<List<Karigar>> getAllKarigars() async {
    return _isar.karigars.where().sortByName().findAll();
  }

  static Future<Karigar?> getKarigar(int id) async {
    return _isar.karigars.get(id);
  }

  static Future<int> saveKarigar(Karigar karigar) async {
    late int id;
    await _isar.writeTxn(() async {
      id = await _isar.karigars.put(karigar);
    });
    return id;
  }

  static Future<void> deleteKarigar(int id) async {
    await _isar.writeTxn(() async {
      await _isar.karigars.delete(id);
    });
  }

  // ─── Jobs ─────────────────────────────────────────────────
  static Future<List<Job>> getAllJobs() async {
    return _isar.jobs.where().findAll();
  }

  static Future<List<Job>> getJobsForKarigar(int karigarId) async {
    return _isar.jobs.filter().karigarIdEqualTo(karigarId).findAll();
  }

  static Future<List<Job>> getActiveJobs() async {
    return _isar.jobs
        .filter()
        .statusEqualTo(JobStatus.active)
        .findAll();
  }

  static Future<List<Job>> getCompletedJobs() async {
    return _isar.jobs
        .filter()
        .statusEqualTo(JobStatus.completed)
        .sortByCompletedDateDesc()
        .findAll();
  }

  static Future<int> saveJob(Job job) async {
    late int id;
    await _isar.writeTxn(() async {
      id = await _isar.jobs.put(job);
    });
    return id;
  }

  static Future<void> deleteJob(int id) async {
    await _isar.writeTxn(() async {
      await _isar.jobs.delete(id);
    });
  }

  static Future<double> getTotalActiveGold() async {
    final jobs = await getActiveJobs();
    return jobs.fold<double>(0.0, (sum, j) => sum + (j.issuedWeight ?? 0));
  }

  static Future<bool> karigarHasActiveJobs(int karigarId) async {
    final count = await _isar.jobs
        .filter()
        .karigarIdEqualTo(karigarId)
        .statusEqualTo(JobStatus.active)
        .count();
    return count > 0;
  }

  // ─── Backup / Restore ────────────────────────────────────
  /// After a restore, absolute image paths stored in the DB may point to
  /// the original device's documents directory.  This method rewrites every
  /// Job.imagePath so the filename part is preserved but the directory
  /// prefix is updated to [currentDocDir]/jeweltrack_images/.
  static Future<void> rebaseImagePaths(String currentDocDir) async {
    final jobs = await getAllJobs();
    final newImgDir = p.join(currentDocDir, 'jeweltrack_images');
    bool anyChanged = false;

    await _isar.writeTxn(() async {
      for (final job in jobs) {
        if (job.imagePath == null) continue;
        final filename = p.basename(job.imagePath!);
        final newPath = p.join(newImgDir, filename);
        // Only update if the file actually exists at the new path
        if (File(newPath).existsSync() && job.imagePath != newPath) {
          job.imagePath = newPath;
          anyChanged = true;
          await _isar.jobs.put(job);
        }
      }
    });
  }
}
