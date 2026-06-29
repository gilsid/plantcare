import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../models/plant.dart';
import '../../models/enums.dart';
import '../../providers/plant_provider.dart';
import '../../services/database_service.dart';
import 'widgets/plant_card.dart';
import 'widgets/empty_state.dart';

enum PlantSortOption {
dateAdded,
nameAZ,
healthDesc,
mostUrgent,
}

class HomeScreen extends StatefulWidget {
const HomeScreen({super.key});

@override
State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'Semua';
  PlantSortOption _sortOption = PlantSortOption.dateAdded;
  bool _isGridView = false;
  String? _selectedTag;

String _greeting() {
final db = context.read<DatabaseService>();
final name = db.getUsername();
if (name.isEmpty) return 'PlantCare';
return 'Halo, $name!';
}

@override
void initState() {
super.initState();
WidgetsBinding.instance.addPostFrameCallback((_) {
context.read<PlantProvider>().loadPlants();
});
}

  List<Plant> _getFilteredPlants(List<Plant> plants) {
    return plants.where((plant) {
      final query = _searchQuery.toLowerCase();
      final matchesSearch = query.isEmpty ||
          plant.name.toLowerCase().contains(query) ||
          plant.species.toLowerCase().contains(query) ||
          (plant.location != null &&
              plant.location!.toLowerCase().contains(query));

      if (!matchesSearch) return false;

      if (_selectedFilter == 'Butuh Perawatan') {
        final provider = context.read<PlantProvider>();
        final tasks = provider.getCareTasksForPlant(plant.id);
        if (!tasks.any((t) => t.isOverdue)) return false;
      } else if (_selectedFilter == 'Sehat') {
        if (plant.healthScore < 80.0) return false;
      }

      if (_selectedTag != null && !plant.tags.contains(_selectedTag)) {
        return false;
      }

      return true;
    }).toList();
  }

  Set<String> _getAllTags(List<Plant> plants) {
    final tags = <String>{};
    for (final plant in plants) {
      tags.addAll(plant.tags);
    }
    return tags;
  }

int _getOverdueCount(List<Plant> plants) {
final provider = context.read<PlantProvider>();
int count = 0;
for (final plant in plants) {
final tasks = provider.getCareTasksForPlant(plant.id);
if (tasks.any((t) => t.isOverdue)) count++;
}
return count;
}

List<Plant> _getSortedPlants(List<Plant> plants) {
final provider = context.read<PlantProvider>();
final sorted = List<Plant>.from(plants);
switch (_sortOption) {
case PlantSortOption.dateAdded:
break;
case PlantSortOption.nameAZ:
sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
case PlantSortOption.healthDesc:
sorted.sort((a, b) => b.healthScore.compareTo(a.healthScore));
case PlantSortOption.mostUrgent:
sorted.sort((a, b) {
final aOverdue = provider.getCareTasksForPlant(a.id).where((t) => t.isOverdue).length;
final bOverdue = provider.getCareTasksForPlant(b.id).where((t) => t.isOverdue).length;
return bOverdue.compareTo(aOverdue);
});
}
return sorted;
}

String _sortLabel(PlantSortOption opt) {
switch (opt) {
case PlantSortOption.dateAdded:  return 'Terbaru';
case PlantSortOption.nameAZ:     return 'Nama A–Z';
case PlantSortOption.healthDesc: return 'Terhealthy';
case PlantSortOption.mostUrgent: return 'Paling Urgent';
}
}

Future<void> _completeAllOverdueWatering(
BuildContext context,
List<Plant> plants,
) async {
final provider = context.read<PlantProvider>();

final overdueWateringPlants = plants.where((plant) {
final tasks = provider.getCareTasksForPlant(plant.id);
return tasks.any((t) => t.careType == CareType.watering && t.isOverdue);
}).toList();

if (overdueWateringPlants.isEmpty) return;

int success = 0;
for (final plant in overdueWateringPlants) {
final result = await provider.completeCareTask(plant.id, CareType.watering);
if (result) success++;
}

if (context.mounted) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(
'$success tanaman berhasil disiram sekaligus!',
),
behavior: SnackBarBehavior.floating,
backgroundColor: AppColors.success,
duration: const Duration(seconds: 3),
),
);
}
}

@override
Widget build(BuildContext context) {
final textTheme = Theme.of(context).textTheme;
final isDark = Theme.of(context).brightness == Brightness.dark;

return Scaffold(
body: SafeArea(
child: Consumer<PlantProvider>(
builder: (context, provider, child) {
if (provider.isLoading) {
return const Center(child: CircularProgressIndicator());
}

final allPlants = provider.plants;
final sortedPlants = _getSortedPlants(allPlants);
final filteredPlants = _getFilteredPlants(sortedPlants);
final overdueCount = _getOverdueCount(allPlants);

return Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting(),
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 28,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          if (context.read<PlantProvider>().getStreakCount() > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Row(
                                children: [
                                  const Icon(Icons.local_fire_department, size: 14, color: Colors.orange),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${context.read<PlantProvider>().getStreakCount()} hari streak',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    Row(
mainAxisSize: MainAxisSize.min,
children: [
PopupMenuButton<PlantSortOption>(
icon: Icon(
Icons.sort,
color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
),
onSelected: (opt) => setState(() => _sortOption = opt),
itemBuilder: (context) => PlantSortOption.values
.map((opt) => PopupMenuItem(
value: opt,
child: Row(
mainAxisSize: MainAxisSize.min,
children: [
if (_sortOption == opt)
const Icon(Icons.check, size: 18),
if (_sortOption == opt) const SizedBox(width: 8),
Text(_sortLabel(opt)),
],
),
))
.toList(),
),
              IconButton(
                icon: Icon(
                  _isGridView ? Icons.view_list : Icons.grid_view,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
                onPressed: () => setState(() => _isGridView = !_isGridView),
              ),
              IconButton(
                icon: Icon(
                  Icons.calendar_month_outlined,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
                onPressed: () => Navigator.pushNamed(context, '/schedule'),
              ),
              IconButton(
                icon: Container(
padding: const EdgeInsets.all(8),
decoration: BoxDecoration(
color: isDark
? AppColors.surfaceDark
: Colors.white,
shape: BoxShape.circle,
border: Border.all(
color: isDark
? const Color(0xFF252D2A)
: const Color(0xFFE2E2DC),
),
),
child: const Icon(Icons.settings_outlined),
),
onPressed: () {
Navigator.pushNamed(context, '/settings');
},
),
],
      ),
      ],   // close outer children (179)
    ),     // close outer Row (177)
  ),       // close Padding (175)

if (allPlants.isNotEmpty) ...[
Container(
margin: const EdgeInsets.symmetric(
horizontal: 16,
vertical: 8,
),
width: double.infinity,
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
gradient: LinearGradient(
colors: isDark
? [const Color(0xFF1E2F26), const Color(0xFF131F19)]
: [
const Color(0xFFE8F5E9),
const Color(0xFFC8E6C9),
],
begin: Alignment.topLeft,
end: Alignment.bottomRight,
),
borderRadius: BorderRadius.circular(20),
border: Border.all(
color: isDark
? AppColors.primaryDark.withValues(alpha: 0.2)
: AppColors.primaryLight.withValues(alpha: 0.1),
),
),
child: Row(
children: [
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
overdueCount > 0
? 'Butuh Perhatian!'
: 'Semua Tanaman Sehat!',
style: textTheme.titleSmall?.copyWith(
fontWeight: FontWeight.bold,
color: overdueCount > 0
? AppColors.error
: (isDark
? AppColors.primaryDark
: AppColors.primaryLight),
),
),
const SizedBox(height: 4),
Text(
overdueCount > 0
? 'Ada $overdueCount tanaman dengan perawatan yang terlambat.'
: 'Hebat! Semua perawatan tanaman tepat waktu. Teruskan!',
style: textTheme.bodySmall?.copyWith(
color: isDark
? AppColors.textPrimaryDark
: AppColors.textPrimaryLight,
height: 1.4,
),
),
if (overdueCount > 0) ...[
const SizedBox(height: 10),
GestureDetector(
onTap: () => _completeAllOverdueWatering(context, allPlants),
child: Container(
padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
decoration: BoxDecoration(
color: AppColors.error,
borderRadius: BorderRadius.circular(8),
),
child: Row(
mainAxisSize: MainAxisSize.min,
children: [
const Icon(Icons.water_drop, color: Colors.white, size: 14),
const SizedBox(width: 6),
Text(
'Siram semua yang overdue',
style: textTheme.bodySmall?.copyWith(
color: Colors.white,
fontWeight: FontWeight.bold,
),
),
],
),
),
),
],
],
),
),
const SizedBox(width: 16),
CircleAvatar(
radius: 28,
backgroundColor: overdueCount > 0
? AppColors.error.withValues(alpha: 0.15)
: (isDark
? AppColors.primaryDark.withValues(
alpha: 0.15,
)
: AppColors.primaryLight.withValues(
alpha: 0.15,
)),
child: Icon(
overdueCount > 0
? Icons.warning_amber_rounded
: Icons.check_circle_outline_rounded,
color: overdueCount > 0
? AppColors.error
: (isDark
? AppColors.primaryDark
: AppColors.primaryLight),
size: 32,
),
),
],
),
),

Padding(
padding: const EdgeInsets.symmetric(
horizontal: 16,
vertical: 8,
),
child: TextField(
onChanged: (value) {
setState(() {
_searchQuery = value;
});
},
decoration: InputDecoration(
hintText: 'Cari nama, jenis, atau lokasi...',
prefixIcon: const Icon(Icons.search, size: 20),
suffixIcon: _searchQuery.isNotEmpty
? IconButton(
icon: const Icon(Icons.clear, size: 20),
onPressed: () {
setState(() {
_searchQuery = '';
});
},
)
: null,
),
),
),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: ['Semua', 'Butuh Perawatan', 'Sehat'].map((
                      filter,
                    ) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = filter;
                            });
                          },
                          selectedColor: isDark
                              ? AppColors.primaryDark.withValues(alpha: 0.2)
                              : AppColors.primaryLight.withValues(
                                  alpha: 0.1,
                                ),
                          checkmarkColor: isDark
                              ? AppColors.primaryDark
                              : AppColors.primaryLight,
                          labelStyle: textTheme.bodySmall?.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? (isDark
                                    ? AppColors.primaryDark
                                    : AppColors.primaryLight)
                                : (isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight),
                          ),
                          backgroundColor: isDark
                              ? AppColors.surfaceDark
                              : const Color(0xFFECECE5),
                          side: BorderSide(
                            color: isSelected
                                ? (isDark
                                    ? AppColors.primaryDark
                                    : AppColors.primaryLight)
                                : Colors.transparent,
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              if (_getAllTags(allPlants).isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            label: Text('Semua Tag'),
                            selected: _selectedTag == null,
                            onSelected: (_) => setState(() => _selectedTag = null),
                            selectedColor: isDark
                                ? AppColors.primaryDark.withValues(alpha: 0.2)
                                : AppColors.primaryLight.withValues(alpha: 0.1),
                            labelStyle: textTheme.bodySmall?.copyWith(
                              fontWeight: _selectedTag == null ? FontWeight.bold : FontWeight.normal,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              fontSize: 11,
                            ),
                            backgroundColor: isDark ? AppColors.surfaceDark : const Color(0xFFECECE5),
                            side: BorderSide(
                              color: _selectedTag == null
                                  ? (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                                  : Colors.transparent,
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        ..._getAllTags(allPlants).map((tag) {
                          final isSelected = _selectedTag == tag;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: Text(tag, style: const TextStyle(fontSize: 11)),
                              selected: isSelected,
                              onSelected: (_) => setState(() => _selectedTag = isSelected ? null : tag),
                              selectedColor: isDark
                                  ? AppColors.primaryDark.withValues(alpha: 0.2)
                                  : AppColors.primaryLight.withValues(alpha: 0.1),
                              labelStyle: textTheme.bodySmall?.copyWith(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected
                                    ? (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                                    : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                fontSize: 11,
                              ),
                              backgroundColor: isDark ? AppColors.surfaceDark : const Color(0xFFECECE5),
                              side: BorderSide(
                                color: isSelected
                                    ? (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                                    : Colors.transparent,
                                width: 1,
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],

Expanded(
child: allPlants.isEmpty
? EmptyState(
onAddPressed: () {
Navigator.pushNamed(context, '/add-edit-plant');
},
)
: filteredPlants.isEmpty
? Center(
child: Padding(
padding: const EdgeInsets.all(32.0),
child: Text(
'Tidak ada tanaman yang cocok dengan filter.',
textAlign: TextAlign.center,
style: textTheme.bodyMedium,
),
),
)
: _isGridView
? GridView.builder(
itemCount: filteredPlants.length,
padding: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
crossAxisCount: 2,
childAspectRatio: 0.75,
crossAxisSpacing: 12,
mainAxisSpacing: 12,
),
itemBuilder: (context, index) {
final plant = filteredPlants[index];
return PlantGridCard(
plant: plant,
onTap: () {
Navigator.pushNamed(
context,
'/plant-detail',
arguments: plant.id,
);
},
);
},
)
              : ListView.builder(
                itemCount: filteredPlants.length,
                padding: const EdgeInsets.only(bottom: 80),
                itemBuilder: (context, index) {
                  final plant = filteredPlants[index];
                  return Dismissible(
                    key: ValueKey('plant_${plant.id}'),
                    direction: DismissDirection.horizontal,
                    background: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 24),
                      child: const Icon(Icons.water_drop, color: Colors.white, size: 32),
                    ),
                    secondaryBackground: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 24),
                      child: const Icon(Icons.delete_outline, color: Colors.white, size: 32),
                    ),
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.startToEnd) {
                        final provider = context.read<PlantProvider>();
                        final result = await provider.completeCareTask(plant.id, CareType.watering);
                        if (result && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${plant.name} berhasil disiram!'),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                        return false;
                      } else {
                        final deleteProvider = context.read<PlantProvider>();
                        final bool? confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Hapus Tanaman'),
                            content: Text('Yakin ingin menghapus ${plant.name}?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Batal'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Hapus', style: TextStyle(color: AppColors.error)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await deleteProvider.deletePlant(plant.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Tanaman berhasil dihapus.'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                        return false;
                      }
                    },
                    child: PlantCard(
                      plant: plant,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/plant-detail',
                          arguments: plant.id,
                        );
                      },
                    ),
                  );
                },
              ),
),
],
);
},
),
),
floatingActionButton: Consumer<PlantProvider>(
builder: (context, provider, child) {
if (provider.plants.isEmpty) return const SizedBox.shrink();
return FloatingActionButton(
onPressed: () {
Navigator.pushNamed(context, '/add-edit-plant');
},
child: const Icon(Icons.add),
);
},
),
);
}
}
