import 'package:hive_ce/hive.dart';

part 'growth_entry.g.dart';

@HiveType(typeId: 2)
class GrowthEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final String photoPath;

  @HiveField(3)
  final String? note;

  GrowthEntry({
    required this.id,
    required this.date,
    required this.photoPath,
    this.note,
  });
}
