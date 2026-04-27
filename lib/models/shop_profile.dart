// // lib/models/shop_profile.dart
// import 'package:isar/isar.dart';
//
// part 'shop_profile.g.dart';
//
// @collection
// class ShopProfile {
//   Id id = Isar.autoIncrement;
//   late String ownerName;
//   late String shopName;
//   late String mobileNumber;
//   String? profileImagePath;
// }

// lib/models/shop_profile.dart
import 'package:isar/isar.dart';

part 'shop_profile.g.dart';

@Collection()
class ShopProfile {
  Id id = Isar.autoIncrement;

  late String ownerName;
  late String shopName;
  late String mobileNumber;

  String? profileImagePath;
}