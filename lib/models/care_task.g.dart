// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'care_task.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CareTaskAdapter extends TypeAdapter<CareTask> {
  @override
  final int typeId = 4;

  @override
  CareTask read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CareTask(
      id: fields[0] as String,
      plantId: fields[1] as String,
      careTypeIndex: (fields[2] as num).toInt(),
      intervalValue: (fields[3] as num).toInt(),
      intervalUnitIndex: (fields[4] as num).toInt(),
      nextDueDate: fields[5] as DateTime,
      lastCompletedDate: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, CareTask obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.plantId)
      ..writeByte(2)
      ..write(obj.careTypeIndex)
      ..writeByte(3)
      ..write(obj.intervalValue)
      ..writeByte(4)
      ..write(obj.intervalUnitIndex)
      ..writeByte(5)
      ..write(obj.nextDueDate)
      ..writeByte(6)
      ..write(obj.lastCompletedDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CareTaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
