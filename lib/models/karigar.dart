// // lib/models/karigar.dart
// import 'package:isar/isar.dart';
//
// part 'karigar.g.dart';
//
// @collection
// class Karigar {
//   Id id = Isar.autoIncrement;
//   late String name;
//   late String phoneNumber;
//   String? address;
//   String? imagePath;
//   DateTime createdAt = DateTime.now();
// }

// lib/models/karigar.dart
import 'package:isar/isar.dart';

part 'karigar.g.dart';

@Collection()
class Karigar {
  Id id = Isar.autoIncrement;

  late String name;
  // late String phoneNumber;

  @Index(unique: true)
  late String phoneNumber;

  String? address;
  String? imagePath;

  DateTime createdAt = DateTime.now();
}