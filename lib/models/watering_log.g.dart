// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watering_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WateringLogAdapter extends TypeAdapter<WateringLog> {
  @override
  final int typeId = 1;

  @override
  WateringLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WateringLog(
      id: fields[0] as String,
      wateredAt: fields[1] as DateTime,
      wasOnTime: fields[2] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, WateringLog obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.wateredAt)
      ..writeByte(2)
      ..write(obj.wasOnTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WateringLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
