import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../models/plant.dart';
import '../../providers/plant_provider.dart';
import 'widgets/plant_card.dart';
import 'widgets/empty_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'Semua';

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
        return tasks.any((t) => t.isOverdue);
      } else if (_selectedFilter == 'Sehat') {
        return plant.healthScore >= 80.0;
      }

      return true;
    }).toList();
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
            final filteredPlants = _getFilteredPlants(allPlants);
            final overdueCount = _getOverdueCount(allPlants);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PlantCare',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 28,
                            ),
                          ),
                        ],
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
                ),

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
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
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
                      : ListView.builder(
                          itemCount: filteredPlants.length,
                          padding: const EdgeInsets.only(bottom: 80),
                          itemBuilder: (context, index) {
                            final plant = filteredPlants[index];
                            return PlantCard(
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
