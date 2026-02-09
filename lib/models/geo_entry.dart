import 'package:hive/hive.dart';

part 'geo_entry.g.dart';

@HiveType(typeId: 0)
class GeoEntry extends HiveObject {
  @HiveField(0)
  late String imagePath;

  @HiveField(1)
  late double latitude;

  @HiveField(2)
  late double longitude;

  @HiveField(3)
  double? accuracy;

  @HiveField(4)
  double? altitude;

  @HiveField(5)
  late DateTime timestamp;

  @HiveField(6)
  late String address;

  @HiveField(7)
  String? note;

  @HiveField(8)
  late String category; // 'Site Visit', 'Damage', 'Survey', 'Delivery', 'Other'

  @HiveField(9)
  bool synced = false;

  /// Default categories
  static const List<String> categories = [
    'Site Visit',
    'Damage',
    'Survey',
    'Delivery',
    'Other',
  ];
}
