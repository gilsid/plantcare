import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../app/theme/app_colors.dart';
import '../models/plant.dart';
import '../models/watering_log.dart';
import '../models/growth_entry.dart';
import '../models/care_task.dart';
import '../models/care_history.dart';
import '../models/enums.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/image_service.dart';

class PlantProvider extends ChangeNotifier {
final DatabaseService _dbService;
final NotificationService _notificationService;
final ImageService _imageService;
final Uuid _uuid = const Uuid();

List<Plant> _plants = [];
List<CareTask> _careTasks = [];
List<CareHistory> _careHistories = [];
bool _isLoading = false;

List<Plant> get plants => _plants;
List<CareTask> get careTasks => _careTasks;
List<CareHistory> get careHistories => _careHistories;
bool get isLoading => _isLoading;

PlantProvider({
required DatabaseService dbService,
required NotificationService notificationService,
required ImageService imageService,
}) : _dbService = dbService,
_notificationService = notificationService,
_imageService = imageService;

List<CareTask> getCareTasksForPlant(String plantId) {
return _careTasks.where((t) => t.plantId == plantId).toList();
}

List<CareHistory> getCareHistoriesForPlant(String plantId) {
return _careHistories.where((h) => h.plantId == plantId).toList();
}

Future<void> loadPlants() async {
_isLoading = true;
notifyListeners();

try {
_plants = _dbService.getAllPlants();
_careTasks = _dbService.getAllCareTasks();
_careHistories = _dbService.getAllCareHistories();

for (var plant in _plants) {
final hasOldData =
plant.wateringIntervalDays > 0 &&
getCareTasksForPlant(plant.id).isEmpty;

if (hasOldData) {
await _migrateOldPlant(plant);
}

final double currentScore = _calculateHealthScore(plant);
if (plant.healthScore != currentScore) {
plant.healthScore = currentScore;
await _dbService.savePlant(plant);
}
}
} catch (e, stackTrace) {
debugPrint('[PlantProvider] loadPlants: ❌ $e');
debugPrintStack(stackTrace: stackTrace);
} finally {
_isLoading = false;
notifyListeners();
}
}

Future<void> _migrateOldPlant(Plant plant) async {
final defaultInterval = plant.wateringIntervalDays;
final nextDue = plant.lastWatered != null
? DateTime(
plant.lastWatered!.year,
plant.lastWatered!.month,
plant.lastWatered!.day,
).add(Duration(days: defaultInterval))
: plant.dateAdded.add(Duration(days: defaultInterval));

final task = CareTask(
id: _uuid.v4(),
plantId: plant.id,
careTypeIndex: CareType.watering.index,
intervalValue: defaultInterval,
intervalUnitIndex: IntervalUnit.day.index,
nextDueDate: nextDue,
lastCompletedDate: plant.lastWatered,
);

await _dbService.saveCareTask(task);
_careTasks.add(task);

if (plant.wateringHistory.isNotEmpty) {
for (final log in plant.wateringHistory) {
final history = CareHistory(
id: _uuid.v4(),
plantId: plant.id,
careTypeIndex: CareType.watering.index,
completedAt: log.wateredAt,
wasOnTime: log.wasOnTime,
);
await _dbService.saveCareHistory(history);
_careHistories.add(history);
}
}
}

  Future<int> addPlant({
    required String name,
    required String species,
    String? location,
    required List<({CareType type, int intervalValue, IntervalUnit intervalUnit})> careTasks,
    String? photoPath,
    String? notes,
    List<String>? tags,
  }) async {
    final String id = _uuid.v4();
    final Plant newPlant = Plant(
      id: id,
      name: name,
      species: species,
      dateAdded: DateTime.now(),
      wateringIntervalDays: 1,
      photoPath: photoPath,
      notes: notes,
      location: location,
      tags: tags,
    );

newPlant.healthScore = _calculateHealthScore(newPlant);

debugPrint('[PlantProvider] addPlant: saving plant $id ($name)');
await _dbService.savePlant(newPlant);
debugPrint('[PlantProvider] addPlant: plant saved');
_plants.add(newPlant);

int notificationFailures = 0;

for (final ct in careTasks) {
final task = CareTask(
id: _uuid.v4(),
plantId: id,
careTypeIndex: ct.type.index,
intervalValue: ct.intervalValue,
intervalUnitIndex: ct.intervalUnit.index,
nextDueDate: DateTime.now(),
);
task.complete();

debugPrint('[PlantProvider] addPlant: saving care task ${ct.type}');
await _dbService.saveCareTask(task);
debugPrint('[PlantProvider] addPlant: care task saved');
_careTasks.add(task);

try {
debugPrint('[PlantProvider] addPlant: scheduling notification for ${ct.type}');
await _notificationService.scheduleCareReminder(
plantId: id,
plantName: name,
careType: ct.type,
nextDueDate: task.nextDueDate,
);
debugPrint('[PlantProvider] addPlant: notification scheduled');
} catch (e, stackTrace) {
debugPrint('[PlantProvider] addPlant: ❌ notification FAILED for ${ct.type}: $e');
debugPrintStack(stackTrace: stackTrace);
notificationFailures++;
}
}

notifyListeners();
debugPrint('[PlantProvider] addPlant: done ($notificationFailures notification failures)');
return notificationFailures;
}

  Future<void> updatePlant({
    required String id,
    required String name,
    required String species,
    String? location,
    String? photoPath,
    String? notes,
    List<String>? tags,
  }) async {
final int index = _plants.indexWhere((p) => p.id == id);
if (index != -1) {
final Plant plant = _plants[index];

if (photoPath != null &&
plant.photoPath != null &&
plant.photoPath != photoPath) {
final isReferencedByDiary = plant.growthDiary.any((entry) => entry.photoPath == plant.photoPath);
if (!isReferencedByDiary) {
await _imageService.deleteImage(plant.photoPath);
}
}

plant.name = name;
plant.species = species;
plant.location = location;
if (photoPath != null) {
plant.photoPath = photoPath;
}
    plant.notes = notes;
    if (tags != null) {
      plant.tags = tags;
    }

    plant.healthScore = _calculateHealthScore(plant);

await _dbService.savePlant(plant);
notifyListeners();
}
}

Future<void> deletePlant(String id) async {
final int index = _plants.indexWhere((p) => p.id == id);
if (index != -1) {
final Plant plant = _plants[index];

final tasks = getCareTasksForPlant(id);
for (final task in tasks) {
await _notificationService.cancelCareReminder(
id,
task.careType,
);
}

if (plant.photoPath != null) {
await _imageService.deleteImage(plant.photoPath);
}
for (var entry in plant.growthDiary) {
await _imageService.deleteImage(entry.photoPath);
}

await _dbService.deletePlant(id);
await _dbService.deleteCareTasksForPlant(id);
await _dbService.deleteCareHistoriesForPlant(id);

_careTasks.removeWhere((t) => t.plantId == id);
_careHistories.removeWhere((h) => h.plantId == id);
_plants.removeAt(index);

notifyListeners();
}
}

Future<bool> completeCareTask(String plantId, CareType careType, {String? note}) async {
final tasks = getCareTasksForPlant(plantId);
final task = tasks.where((t) => t.careType == careType).firstOrNull;
if (task == null) return false;

final now = DateTime.now();
final bool wasOnTime = !task.isOverdue;

final history = CareHistory(
id: _uuid.v4(),
plantId: plantId,
careTypeIndex: careType.index,
completedAt: now,
wasOnTime: wasOnTime,
note: note,
);
await _dbService.saveCareHistory(history);
_careHistories.insert(0, history);

task.complete();
await _dbService.saveCareTask(task);

final plant = _plants.firstWhere(
(p) => p.id == plantId,
orElse: () => throw StateError('[completeCareTask] Plant not found: $plantId'),
);
if (careType == CareType.watering) {
plant.lastWatered = now;
final log = WateringLog(
id: _uuid.v4(),
wateredAt: now,
wasOnTime: wasOnTime,
);
plant.wateringHistory.insert(0, log);

plant.healthScore = _calculateHealthScore(plant);
await _dbService.savePlant(plant);
}

try {
await _notificationService.scheduleCareReminder(
plantId: plantId,
plantName: plant.name,
careType: careType,
nextDueDate: task.nextDueDate,
);
} catch (e, stackTrace) {
debugPrint('[PlantProvider] completeCareTask: ❌ schedule FAILED: $e');
debugPrintStack(stackTrace: stackTrace);
}

  notifyListeners();
    _updateStreak();
    return true;
  }

  Future<void> _updateStreak() async {
    final db = _dbService;
    final lastDateStr = db.getLastStreakDate();
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);

    if (lastDateStr == todayStr) return;

    final yesterdayStr = DateTime.now()
        .subtract(const Duration(days: 1))
        .toIso8601String()
        .substring(0, 10);

    int streak = db.getStreakCount();
    if (lastDateStr == yesterdayStr || lastDateStr == null) {
      streak++;
    } else {
      streak = 1;
    }

    await db.setStreakCount(streak);
    await db.setLastStreakDate(todayStr);
  }

  int getStreakCount() {
    return _dbService.getStreakCount();
  }

Future<void> updateCareTask({
required String taskId,
required int intervalValue,
required IntervalUnit intervalUnit,
}) async {
final task = _careTasks.firstWhere(
(t) => t.id == taskId,
orElse: () => throw StateError('[updateCareTask] Task not found: $taskId'),
);
task.intervalValue = intervalValue;
task.intervalUnit = intervalUnit;

// Hitung ulang nextDueDate dari lastCompletedDate (bukan dari sekarang),
// sehingga jadwal tetap konsisten dengan kapan task terakhir dilakukan.
// Jika belum pernah dilakukan, gunakan sekarang sebagai basis.
final basis = task.lastCompletedDate ?? DateTime.now();
task.nextDueDate = task.nextDueDateFromBasis(basis);

await _dbService.saveCareTask(task);

final plant = _plants.firstWhere(
(p) => p.id == task.plantId,
orElse: () => throw StateError('Plant not found: ${task.plantId}'),
);
try {
await _notificationService.scheduleCareReminder(
plantId: task.plantId,
plantName: plant.name,
careType: task.careType,
nextDueDate: task.nextDueDate,
);
} catch (e, stackTrace) {
debugPrint('[PlantProvider] updateCareTask: ❌ schedule FAILED: $e');
debugPrintStack(stackTrace: stackTrace);
}

notifyListeners();
}

Future<void> addCareTask({
required String plantId,
required CareType careType,
required int intervalValue,
required IntervalUnit intervalUnit,
}) async {
final task = CareTask(
id: _uuid.v4(),
plantId: plantId,
careTypeIndex: careType.index,
intervalValue: intervalValue,
intervalUnitIndex: intervalUnit.index,
nextDueDate: DateTime.now(),
);
task.complete();

await _dbService.saveCareTask(task);
_careTasks.add(task);

final plant = _plants.firstWhere(
(p) => p.id == plantId,
orElse: () => throw StateError('[addCareTask] Plant not found: $plantId'),
);
try {
await _notificationService.scheduleCareReminder(
plantId: plantId,
plantName: plant.name,
careType: careType,
nextDueDate: task.nextDueDate,
);
} catch (e, stackTrace) {
debugPrint('[PlantProvider] addCareTask: ❌ schedule FAILED: $e');
debugPrintStack(stackTrace: stackTrace);
}

notifyListeners();
}

Future<void> removeCareTask(String taskId) async {
final task = _careTasks.firstWhere(
(t) => t.id == taskId,
orElse: () => throw StateError('[removeCareTask] Task not found: $taskId'),
);
await _dbService.deleteCareTask(taskId);
_careTasks.removeWhere((t) => t.id == taskId);

try {
await _notificationService.cancelCareReminder(
task.plantId,
task.careType,
);
} catch (e, stackTrace) {
debugPrint('[PlantProvider] removeCareTask: ❌ cancel FAILED: $e');
debugPrintStack(stackTrace: stackTrace);
}

notifyListeners();
}

Future<void> addGrowthEntry({
required String plantId,
required String photoPath,
String? note,
}) async {
final int index = _plants.indexWhere((p) => p.id == plantId);
if (index != -1) {
final Plant plant = _plants[index];

final GrowthEntry entry = GrowthEntry(
id: _uuid.v4(),
date: DateTime.now(),
photoPath: photoPath,
note: note,
);

plant.growthDiary.insert(0, entry);
plant.photoPath = photoPath;

await _dbService.savePlant(plant);
notifyListeners();
}
}

Future<void> deleteGrowthEntry({
required String plantId,
required String entryId,
}) async {
final int index = _plants.indexWhere((p) => p.id == plantId);
if (index != -1) {
final Plant plant = _plants[index];

final int entryIndex = plant.growthDiary.indexWhere(
(e) => e.id == entryId,
);
if (entryIndex != -1) {
final GrowthEntry entry = plant.growthDiary[entryIndex];
await _imageService.deleteImage(entry.photoPath);

plant.growthDiary.removeAt(entryIndex);

if (plant.photoPath == entry.photoPath) {
plant.photoPath = plant.growthDiary.isNotEmpty
? plant.growthDiary.first.photoPath
: null;
}

await _dbService.savePlant(plant);
notifyListeners();
}
}
}

Future<void> resetAll() async {
try {
await _notificationService.cancelAllReminders();
await _imageService.deleteAllImages();
await _dbService.clearAll();
_plants = [];
_careTasks = [];
_careHistories = [];
} catch (e, stackTrace) {
debugPrint('[PlantProvider] resetAll: ❌ $e');
debugPrintStack(stackTrace: stackTrace);
} finally {
notifyListeners();
}
}

  ({IconData icon, Color color, String label})? getHealthTrend(String plantId) {
    final histories = _careHistories
        .where((h) => h.plantId == plantId && h.careType == CareType.watering)
        .toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));

    if (histories.length < 4) return null;

    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final twoWeeksAgo = now.subtract(const Duration(days: 14));

    final recentWeek = histories
        .where((h) => h.completedAt.isAfter(weekAgo))
        .toList();
    final prevWeek = histories
        .where((h) =>
            h.completedAt.isAfter(twoWeeksAgo) &&
            h.completedAt.isBefore(weekAgo))
        .toList();

    if (recentWeek.isEmpty || prevWeek.isEmpty) return null;

    final recentOnTime = recentWeek.where((h) => h.wasOnTime == true).length;
    final prevOnTime = prevWeek.where((h) => h.wasOnTime == true).length;
    final recentRatio = recentOnTime / recentWeek.length;
    final prevRatio = prevOnTime / prevWeek.length;

    final diff = recentRatio - prevRatio;
    if (diff.abs() < 0.05) {
      return (
        icon: Icons.trending_flat,
        color: Colors.grey,
        label: 'Stabil',
      );
    }
    if (diff > 0) {
      return (
        icon: Icons.trending_up,
        color: AppColors.success,
        label: '${(diff * 100).round()}%',
      );
    }
    return (
      icon: Icons.trending_down,
      color: AppColors.error,
      label: '${(diff.abs() * 100).round()}%',
    );
  }

  /// Menghitung health score tanaman (0.0 - 100.0).
///
/// Catatan desain: baseScore hanya dihitung dari riwayat PENYIRAMAN
/// karena penyiraman adalah faktor kesehatan paling kritis.
/// Jenis perawatan lain (pupuk, pangkas, dll) berkontribusi melalui
/// overdue deduction di [_applyCurrentOverdueDeduction].
double _calculateHealthScore(Plant plant) {
final histories = _careHistories
.where((h) => h.plantId == plant.id && h.careType == CareType.watering)
.toList()
..sort((a, b) => b.completedAt.compareTo(a.completedAt));

if (histories.isEmpty) {
return _applyCurrentOverdueDeduction(100.0, plant);
}

final now = DateTime.now();
final recentHistories = histories
.where((h) => now.difference(h.completedAt).inDays <= 30)
.toList()
..sort((a, b) => b.completedAt.compareTo(a.completedAt));

final List<bool> onTimeFlags;
if (recentHistories.length >= 5) {
onTimeFlags = recentHistories.take(5).map((h) => h.wasOnTime ?? true).toList();
} else if (histories.length >= 5) {
onTimeFlags = histories.take(5).map((h) => h.wasOnTime ?? true).toList();
} else {
onTimeFlags = histories.map((h) => h.wasOnTime ?? true).toList();
}

final int onTimeCount = onTimeFlags.where((f) => f).length;
double baseScore = (onTimeCount / onTimeFlags.length) * 100.0;

return _applyCurrentOverdueDeduction(baseScore, plant);
}

double _applyCurrentOverdueDeduction(double baseScore, Plant plant) {
final tasks = getCareTasksForPlant(plant.id);
int overdueCount = 0;
for (final task in tasks) {
if (task.isOverdue) overdueCount++;
}

if (overdueCount > 0) {
baseScore -= (overdueCount * 10.0);
}

final wateringTasks =
tasks.where((t) => t.careType == CareType.watering).toList();
if (wateringTasks.isNotEmpty) {
final wateringTask = wateringTasks.first;
if (wateringTask.isOverdue) {
final daysLate =
DateTime.now().difference(wateringTask.nextDueDate).inDays;
if (daysLate > 3) {
baseScore -= 15.0;
} else if (daysLate > 0) {
baseScore -= 5.0;
}
}
}

return baseScore.clamp(0.0, 100.0);
}
}
