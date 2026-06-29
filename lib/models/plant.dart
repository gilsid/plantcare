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
  // Deprecated: Kept only for database migration compatibility.
  // Do NOT use for new features or business logic.
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

  // Index 11 is retired (previously roomId) and must not be reused.

  @HiveField(12)
  String? location;

  @HiveField(13)
  List<String> tags;

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
    this.location,
    List<String>? tags,
  }) : wateringHistory = wateringHistory ?? [],
       growthDiary = growthDiary ?? [],
       tags = tags ?? [];


}
