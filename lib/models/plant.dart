import 'package:hive_ce/hive.dart';
import 'watering_log.dart';
import 'growth_entry.dart';

part 'plant.g.dart';

@HiveType(typeId: 0)
class Plant extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String species;

  @HiveField(3)
  final DateTime dateAdded;

  @HiveField(4)
  int wateringIntervalDays;

  @HiveField(5)
  DateTime? lastWatered;

  @HiveField(6)
  double healthScore;

  @HiveField(7)
  String? notes;

  @HiveField(8)
  String? photoPath;

  @HiveField(9)
  List<WateringLog> wateringHistory;

  @HiveField(10)
  List<GrowthEntry> growthDiary;

  @HiveField(11)
  String? roomId;

  @HiveField(12)
  String? location;

  Plant({
    required this.id,
    required this.name,
    required this.species,
    required this.dateAdded,
    required this.wateringIntervalDays,
    this.lastWatered,
    this.healthScore = 100.0,
    this.notes,
    this.photoPath,
    List<WateringLog>? wateringHistory,
    List<GrowthEntry>? growthDiary,
    this.roomId,
    this.location,
  }) : wateringHistory = wateringHistory ?? [],
       growthDiary = growthDiary ?? [];

  DateTime get nextWateringDate {
    final baseDate = lastWatered ?? dateAdded;
    // Set time to the same time of day as baseDate, but we can truncate it to start of day for comparison
    return DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
    ).add(Duration(days: wateringIntervalDays));
  }

  bool get isWateringOverdue {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return today.isAfter(nextWateringDate);
  }

  int get daysUntilNextWatering {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(
      nextWateringDate.year,
      nextWateringDate.month,
      nextWateringDate.day,
    );
    return target.difference(today).inDays;
  }
}
