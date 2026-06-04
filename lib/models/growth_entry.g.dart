// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'growth_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GrowthEntryAdapter extends TypeAdapter<GrowthEntry> {
  @override
  final int typeId = 2;

  @override
  GrowthEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GrowthEntry(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      photoPath: fields[2] as String,
      note: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, GrowthEntry obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.photoPath)
      ..writeByte(3)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GrowthEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
