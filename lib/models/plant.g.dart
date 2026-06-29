// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plant.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlantAdapter extends TypeAdapter<Plant> {
  @override
  final int typeId = 0;

  @override
  Plant read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Plant(
      id: fields[0] as String,
      name: fields[1] as String,
      species: fields[2] as String,
      dateAdded: fields[3] as DateTime,
      wateringIntervalDays: (fields[4] as num).toInt(),
      lastWatered: fields[5] as DateTime?,
      healthScore: fields[6] == null ? 100.0 : (fields[6] as num).toDouble(),
      notes: fields[7] as String?,
      photoPath: fields[8] as String?,
      wateringHistory: (fields[9] as List?)?.cast<WateringLog>(),
      growthDiary: (fields[10] as List?)?.cast<GrowthEntry>(),
      location: fields[12] as String?,
      tags: (fields[13] as List?)?.cast<String>() ?? [],
    );
  }

  @override
  void write(BinaryWriter writer, Plant obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.species)
      ..writeByte(3)
      ..write(obj.dateAdded)
      ..writeByte(4)
      ..write(obj.wateringIntervalDays)
      ..writeByte(5)
      ..write(obj.lastWatered)
      ..writeByte(6)
      ..write(obj.healthScore)
      ..writeByte(7)
      ..write(obj.notes)
      ..writeByte(8)
      ..write(obj.photoPath)
      ..writeByte(9)
      ..write(obj.wateringHistory)
      ..writeByte(10)
      ..write(obj.growthDiary)
      ..writeByte(12)
      ..write(obj.location)
      ..writeByte(13)
      ..write(obj.tags);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlantAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
