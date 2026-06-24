import 'package:hive_ce/hive.dart';
import 'enums.dart';

part 'care_history.g.dart';

@HiveType(typeId: 5)
class CareHistory extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String plantId;

  @HiveField(2)
  int careTypeIndex;

  @HiveField(3)
  final DateTime completedAt;

  CareType get careType => CareType.values[careTypeIndex];

  @HiveField(4)
  final bool? wasOnTime;

  CareHistory({
    required this.id,
    required this.plantId,
    required this.careTypeIndex,
    required this.completedAt,
    this.wasOnTime,
  });
}
