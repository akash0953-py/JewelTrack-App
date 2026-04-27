// lib/models/job.dart
import 'package:isar/isar.dart';

part 'job.g.dart';

enum JobStatus { active, completed, cancelled }

@Collection()
class Job {
  Id id = Isar.autoIncrement;
  late int karigarId;
  late String karigarName;
  late String itemName;
  late double issuedWeight; // in grams
  double? grossWeight;      // total weight after completion
  double? netGoldWeight;    // net gold weight after completion (excl. stones)
  double? receivedWeight;   // alias to netGoldWeight for wastage calc
  String? imagePath;
  late DateTime dateAdded;
  late DateTime expectedDate;
  DateTime? completedDate;

  @enumerated
  JobStatus status = JobStatus.active;

  String? notes;

  // Calculated
  double get wastage {
    if (netGoldWeight != null) {
      return issuedWeight - netGoldWeight!;
    }
    return 0;
  }

  bool get isOverdue {
    return status == JobStatus.active && DateTime.now().isAfter(expectedDate);
  }
}
