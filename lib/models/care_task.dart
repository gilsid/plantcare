import 'package:hive_ce/hive.dart';
import 'enums.dart';

part 'care_task.g.dart';

@HiveType(typeId: 4)
class CareTask extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String plantId;

  @HiveField(2)
  int careTypeIndex;

  @HiveField(3)
  int intervalValue;

  @HiveField(4)
  int intervalUnitIndex;

  @HiveField(5)
  DateTime nextDueDate;

  @HiveField(6)
  DateTime? lastCompletedDate;

  CareType get careType => CareType.values[careTypeIndex];
  set careType(CareType value) => careTypeIndex = value.index;

  IntervalUnit get intervalUnit => IntervalUnit.values[intervalUnitIndex];
  set intervalUnit(IntervalUnit value) => intervalUnitIndex = value.index;

  CareTask({
    required this.id,
    required this.plantId,
    required this.careTypeIndex,
    required this.intervalValue,
    required this.intervalUnitIndex,
    required this.nextDueDate,
    this.lastCompletedDate,
  });

  DateTime _addInterval(DateTime from) {
    switch (intervalUnit) {
      case IntervalUnit.hour:
        return from.add(Duration(hours: intervalValue));
      case IntervalUnit.day:
        return from.add(Duration(days: intervalValue));
      case IntervalUnit.week:
        return from.add(Duration(days: 7 * intervalValue));
      case IntervalUnit.month:
        return DateTime(
          from.year,
          from.month + intervalValue,
          from.day,
          from.hour,
          from.minute,
        );
    }
  }

  void complete() {
    final now = DateTime.now();
    lastCompletedDate = now;
    nextDueDate = _addInterval(now);
  }

  bool get isOverdue {
    return DateTime.now().isAfter(nextDueDate);
  }

  /// Menghitung nextDueDate berdasarkan basis waktu tertentu.
  /// Digunakan saat interval diubah, agar jadwal dihitung dari
  /// lastCompletedDate (bukan dari DateTime.now()).
  DateTime nextDueDateFromBasis(DateTime basis) {
    return _addInterval(basis);
  }

  Duration get timeUntilDue {
    return nextDueDate.difference(DateTime.now());
  }

  bool get isDueSoon {
    final remaining = timeUntilDue;
    return !isOverdue && remaining.isNegative == false && remaining.inHours <= 24;
  }
}
