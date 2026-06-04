import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

part 'room.g.dart';

@HiveType(typeId: 3)
class Room extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String icon; // Icon name from Material Icons, e.g. 'bed', 'kitchen', 'yard'

  @HiveField(3)
  int colorValue; // Color as integer value

  Room({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorValue,
  });

  Color get color => Color(colorValue);
}

// Predefined room presets for easy setup
class RoomPresets {
  static const List<Map<String, dynamic>> presets = [
    {'name': 'Kamar Tidur', 'icon': 'bed', 'color': 0xFF7986CB},
    {'name': 'Ruang Tamu', 'icon': 'living', 'color': 0xFF81C784},
    {'name': 'Dapur', 'icon': 'kitchen', 'color': 0xFFFFB74D},
    {'name': 'Kamar Mandi', 'icon': 'bathroom', 'color': 0xFF4FC3F7},
    {'name': 'Balkon', 'icon': 'balcony', 'color': 0xFFAED581},
    {'name': 'Teras', 'icon': 'deck', 'color': 0xFFA5D6A7},
    {'name': 'Ruang Kerja', 'icon': 'desk', 'color': 0xFF9575CD},
    {'name': 'Taman', 'icon': 'yard', 'color': 0xFF66BB6A},
  ];
}
