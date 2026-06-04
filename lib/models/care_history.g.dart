// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'care_history.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CareHistoryAdapter extends TypeAdapter<CareHistory> {
  @override
  final int typeId = 5;

  @override
  CareHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CareHistory(
      id: fields[0] as String,
      plantId: fields[1] as String,
      careTypeIndex: (fields[2] as num).toInt(),
      completedAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CareHistory obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.plantId)
      ..writeByte(2)
      ..write(obj.careTypeIndex)
      ..writeByte(3)
      ..write(obj.completedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CareHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
