import 'package:hive_ce_flutter/hive_flutter.dart';
// ignore: uri_has_not_been_generated
import 'package:plant_care_tracker/hive_registrar.g.dart';
import '../models/plant.dart';
import '../models/care_task.dart';
import '../models/care_history.dart';

class DatabaseService {
  static const String _plantsBoxName = 'plants';
  static const String _settingsBoxName = 'settings';
  static const String _careTasksBoxName = 'careTasks';
  static const String _careHistoriesBoxName = 'careHistories';
  static const String _themeModeKey = 'isDarkMode';

  late Box<Plant> _plantsBox;
  late Box _settingsBox;
  late Box<CareTask> _careTasksBox;
  late Box<CareHistory> _careHistoriesBox;

  Future<void> init() async {
    await Hive.initFlutter();
    // ignore: undefined_method
    Hive.registerAdapters();

    _plantsBox = await Hive.openBox<Plant>(_plantsBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
    _careTasksBox = await Hive.openBox<CareTask>(_careTasksBoxName);
    _careHistoriesBox = await Hive.openBox<CareHistory>(_careHistoriesBoxName);
  }

  // Plant CRUD
  List<Plant> getAllPlants() {
    return _plantsBox.values.toList();
  }

  Future<void> savePlant(Plant plant) async {
    await _plantsBox.put(plant.id, plant);
  }

  Future<void> deletePlant(String id) async {
    await _plantsBox.delete(id);
  }

  // CareTask CRUD
  List<CareTask> getCareTasksForPlant(String plantId) {
    return _careTasksBox.values.where((t) => t.plantId == plantId).toList();
  }

  List<CareTask> getAllCareTasks() {
    return _careTasksBox.values.toList();
  }

  Future<void> saveCareTask(CareTask task) async {
    await _careTasksBox.put(task.id, task);
  }

  Future<void> deleteCareTask(String id) async {
    await _careTasksBox.delete(id);
  }

  Future<void> deleteCareTasksForPlant(String plantId) async {
    final tasks = getCareTasksForPlant(plantId);
    for (final task in tasks) {
      await _careTasksBox.delete(task.id);
    }
  }

  // CareHistory CRUD
  List<CareHistory> getCareHistoriesForPlant(String plantId) {
    return _careHistoriesBox.values
        .where((h) => h.plantId == plantId)
        .toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
  }

  List<CareHistory> getAllCareHistories() {
    return _careHistoriesBox.values.toList();
  }

  Future<void> saveCareHistory(CareHistory history) async {
    await _careHistoriesBox.put(history.id, history);
  }

  Future<void> deleteCareHistoriesForPlant(String plantId) async {
    final histories = getCareHistoriesForPlant(plantId);
    for (final h in histories) {
      await _careHistoriesBox.delete(h.id);
    }
  }

  // Theme
  Future<void> saveThemeMode(bool isDarkMode) async {
    await _settingsBox.put(_themeModeKey, isDarkMode);
  }

  bool getThemeMode() {
    return _settingsBox.get(_themeModeKey, defaultValue: false) as bool;
  }

  Future<void> clearAll() async {
    await _plantsBox.clear();
    await _settingsBox.clear();
    await _careTasksBox.clear();
    await _careHistoriesBox.clear();
  }
}
