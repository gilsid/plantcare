import 'package:hive_ce/hive.dart';

part 'watering_log.g.dart';

@HiveType(typeId: 1)
class WateringLog extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime wateredAt;

  @HiveField(2)
  final bool wasOnTime;

  WateringLog({
    required this.id,
    required this.wateredAt,
    required this.wasOnTime,
  });
}
