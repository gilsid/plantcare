import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../models/enums.dart';
import '../../providers/plant_provider.dart';
import '../../services/image_service.dart';

class AddEditPlantScreen extends StatefulWidget {
  final String? plantId;

  const AddEditPlantScreen({super.key, this.plantId});

  @override
  State<AddEditPlantScreen> createState() => _AddEditPlantScreenState();
}

class _AddEditPlantScreenState extends State<AddEditPlantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _speciesController = TextEditingController();
  final _notesController = TextEditingController();
  final _customLocationController = TextEditingController();

  String? _photoPath;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _selectedLocation;
  bool _isCustomLocation = false;

  final List<_CareTaskForm> _careTasks = [];
  final ImageService _imageService = ImageService();

  static const List<String> _quickLocations = [
    'Teras',
    'Ruang Tamu',
    'Kamar',
    'Dapur',
    'Kebun',
  ];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.plantId != null;
    if (_isEditing) {
      _loadPlantData();
    } else {
      _careTasks.add(
        _CareTaskForm(
          type: CareType.watering,
          intervalValue: 1,
          intervalUnit: IntervalUnit.day,
        ),
      );
    }
  }

  void _loadPlantData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PlantProvider>();
      final plants = provider.plants;
      final plant = plants.firstWhere((p) => p.id == widget.plantId);

      _nameController.text = plant.name;
      _speciesController.text = plant.species;
      _notesController.text = plant.notes ?? '';
      _selectedLocation = plant.location;
      if (plant.location != null && !_quickLocations.contains(plant.location)) {
        _isCustomLocation = true;
        _customLocationController.text = plant.location!;
      }

      final existingTasks = provider.getCareTasksForPlant(plant.id);
      setState(() {
        _photoPath = plant.photoPath;
        if (existingTasks.isNotEmpty) {
          _careTasks.addAll(
            existingTasks.map(
              (t) => _CareTaskForm(
                type: t.careType,
                intervalValue: t.intervalValue,
                intervalUnit: t.intervalUnit,
              ),
            ),
          );
        } else {
          _careTasks.add(
            _CareTaskForm(
              type: CareType.watering,
              intervalValue: plant.wateringIntervalDays,
              intervalUnit: IntervalUnit.day,
            ),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _speciesController.dispose();
    _notesController.dispose();
    _customLocationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context);
    final path = await _imageService.pickAndSaveImage(source);
    if (path != null) {
      setState(() {
        _photoPath = path;
      });
    }
  }

  void _showImagePickerSheet() {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 20.0,
              horizontal: 16.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Pilih Foto Tanaman',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primaryLight,
                    child: Icon(Icons.camera_alt, color: Colors.white),
                  ),
                  title: const Text('Ambil Foto (Kamera)'),
                  onTap: () => _pickImage(ImageSource.camera),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primaryLight,
                    child: Icon(Icons.photo_library, color: Colors.white),
                  ),
                  title: const Text('Pilih dari Galeri'),
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddCareTaskSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tambah Perawatan',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...CareType.values.map((type) {
                  final alreadyAdded = _careTasks.any((t) => t.type == type);
                  return ListTile(
                    leading: _getCareIcon(type),
                    title: Text(type.displayName),
                    subtitle: Text(
                      alreadyAdded ? 'Sudah ditambahkan' : 'Tap untuk menambah',
                      style: TextStyle(
                        color: alreadyAdded
                            ? AppColors.success
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    enabled: !alreadyAdded,
                    onTap: alreadyAdded
                        ? null
                        : () {
                            setState(() {
                              _careTasks.add(
                                _CareTaskForm(
                                  type: type,
                                  intervalValue: 1,
                                  intervalUnit: IntervalUnit.day,
                                ),
                              );
                            });
                            Navigator.pop(context);
                          },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _removeCareTask(int index) {
    setState(() {
      _careTasks.removeAt(index);
    });
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);

    final location = _isCustomLocation
        ? _customLocationController.text.trim()
        : _selectedLocation;

    final provider = context.read<PlantProvider>();

    try {
      if (_isEditing) {
        debugPrint('[AddEditPlant] updatePlant: ${widget.plantId}');
        await provider.updatePlant(
          id: widget.plantId!,
          name: _nameController.text.trim(),
          species: _speciesController.text.trim(),
          location: location,
          photoPath: _photoPath,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );
        debugPrint('[AddEditPlant] updatePlant: success');
      } else {
        debugPrint('[AddEditPlant] addPlant: starting');
        final notificationFailures = await provider.addPlant(
          name: _nameController.text.trim(),
          species: _speciesController.text.trim(),
          location: location,
          careTasks:
              _careTasks
                  .map(
                    (ct) => (
                      type: ct.type,
                      intervalValue: ct.intervalValue,
                      intervalUnit: ct.intervalUnit,
                    ),
                  )
                  .toList(),
          photoPath: _photoPath,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );
        debugPrint('[AddEditPlant] addPlant: success (notification failures: $notificationFailures)');

        if (mounted && notificationFailures > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '$notificationFailures notifikasi gagal dijadwalkan. '
                'Data tanaman tetap tersimpan.',
              ),
              backgroundColor: AppColors.warning,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Tanaman berhasil diperbarui!'
                  : 'Tanaman berhasil ditambahkan!',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        debugPrint('[AddEditPlant] navigating back');
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('[AddEditPlant] ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Tanaman' : 'Tambah Tanaman',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPhotoSection(textTheme, isDark),
              const SizedBox(height: 32),
              _buildSectionLabel('Nama Tanaman'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama tanaman tidak boleh kosong';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  hintText: 'Misal: Monstera Obliqua, Janda Bolong',
                ),
              ),
              const SizedBox(height: 20),
              _buildSectionLabel('Jenis/Spesies Tanaman'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _speciesController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Jenis tanaman tidak boleh kosong';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  hintText: 'Misal: Monstera adansonii',
                ),
              ),
              const SizedBox(height: 20),
              _buildSectionLabel('Lokasi Tanaman'),
              const SizedBox(height: 8),
              _buildLocationSection(isDark, textTheme),
              const SizedBox(height: 20),
              _buildSectionLabel('Jadwal Perawatan'),
              const SizedBox(height: 8),
              ..._careTasks.asMap().entries.map(
                (entry) => _buildCareTaskCard(
                  entry.key,
                  entry.value,
                  isDark,
                  textTheme,
                ),
              ),
              const SizedBox(height: 12),
              if (!_isEditing)
                OutlinedButton.icon(
                  onPressed: _showAddCareTaskSheet,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Tambah Perawatan Lain'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              const SizedBox(height: 20),
              _buildSectionLabel('Catatan Perawatan (Opsional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText:
                      'Misal: Letakkan di tempat teduh, hindari sinar matahari langsung...',
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveForm,
                  child:
                      _isSaving
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : Text(
                            _isEditing
                                ? 'Simpan Perubahan'
                                : 'Tambah Tanaman',
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection(TextTheme textTheme, bool isDark) {
    return Center(
      child: GestureDetector(
        onTap: _showImagePickerSheet,
        child: Stack(
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF252D2A)
                    : const Color(0xFFECECE5),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? AppColors.primaryDark
                      : AppColors.primaryLight,
                  width: 2,
                ),
                image: _photoPath != null
                    ? DecorationImage(
                        image: FileImage(File(_photoPath!)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _photoPath == null
                  ? Icon(
                      Icons.add_a_photo_outlined,
                      size: 40,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    )
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 4,
              child: CircleAvatar(
                radius: 20,
                backgroundColor: isDark
                    ? AppColors.primaryDark
                    : AppColors.primaryLight,
                child: Icon(
                  Icons.edit,
                  size: 18,
                  color: isDark ? Colors.black : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildLocationSection(bool isDark, TextTheme textTheme) {
    final allLocations = [
      ..._quickLocations,
      'Lainnya...',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 500 ? 3 : 2;
            final spacing = 8.0;
            final rows = <Widget>[];

            for (var i = 0; i < allLocations.length; i += crossAxisCount) {
              final rowItems = allLocations.sublist(
                i,
                i + crossAxisCount > allLocations.length
                    ? allLocations.length
                    : i + crossAxisCount,
              );

              rows.add(
                Padding(
                  padding: EdgeInsets.only(
                    bottom: i + crossAxisCount < allLocations.length
                        ? spacing
                        : 0,
                  ),
                  child: Row(
                    children: [
                      for (var j = 0; j < rowItems.length; j++)
                        Padding(
                          padding: EdgeInsets.only(
                            right: j < rowItems.length - 1 ? spacing : 0,
                          ),
                          child: SizedBox(
                            width: (constraints.maxWidth -
                                    spacing * (crossAxisCount - 1)) /
                                crossAxisCount,
                            child: ChoiceChip(
                              label: SizedBox.expand(
                                child: Center(
                                  child: Text(rowItems[j]),
                                ),
                              ),
                              selected: rowItems[j] == 'Lainnya...'
                                  ? _isCustomLocation
                                  : !_isCustomLocation &&
                                      _selectedLocation == rowItems[j],
                              onSelected: (selected) {
                                setState(() {
                                  if (rowItems[j] == 'Lainnya...') {
                                    _isCustomLocation = selected;
                                    if (selected) _selectedLocation = null;
                                  } else {
                                    _isCustomLocation = false;
                                    _selectedLocation =
                                        selected ? rowItems[j] : null;
                                  }
                                });
                              },
                              selectedColor: isDark
                                  ? AppColors.primaryDark.withValues(alpha: 0.2)
                                  : AppColors.primaryLight
                                      .withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                      if (rowItems.length < crossAxisCount)
                        ...List.generate(
                          crossAxisCount - rowItems.length,
                          (_) => SizedBox(
                            width: (constraints.maxWidth -
                                    spacing * (crossAxisCount - 1)) /
                                crossAxisCount,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: rows,
            );
          },
        ),
        if (_isCustomLocation) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: _customLocationController,
            decoration: const InputDecoration(
              hintText: 'Ketik lokasi custom...',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCareTaskCard(
    int index,
    _CareTaskForm task,
    bool isDark,
    TextTheme textTheme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF252D2A) : const Color(0xFFE2E2DC),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _getCareIcon(task.type),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  task.type.displayName,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_careTasks.length > 1 || _isEditing)
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => _removeCareTask(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: AppColors.error,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Interval', style: textTheme.bodySmall),
                    const SizedBox(height: 4),
                    IntrinsicWidth(
                      child: Row(
                        children: [
                          SizedBox(
                            width: 80,
                            child: TextFormField(
                              initialValue: task.intervalValue.toString(),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              onChanged: (val) {
                                final parsed = int.tryParse(val);
                                if (parsed != null && parsed > 0) {
                                  task.intervalValue = parsed;
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<IntervalUnit>(
                              value: task.intervalUnit,
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              items: IntervalUnit.values.map((unit) {
                                return DropdownMenuItem(
                                  value: unit,
                                  child: Text(unit.displayNamePlural),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    task.intervalUnit = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _getCareIcon(CareType type) {
    IconData icon;
    switch (type) {
      case CareType.watering:
        icon = Icons.water_drop;
      case CareType.fertilizing:
        icon = Icons.science;
      case CareType.pruning:
        icon = Icons.content_cut;
      case CareType.pestCheck:
        icon = Icons.bug_report;
      case CareType.repotting:
        icon = Icons.replay;
    }
    return CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.primaryLight.withValues(alpha: 0.1),
      child: Icon(icon, size: 18, color: AppColors.primaryLight),
    );
  }
}

class _CareTaskForm {
  CareType type;
  int intervalValue;
  IntervalUnit intervalUnit;

  _CareTaskForm({
    required this.type,
    required this.intervalValue,
    required this.intervalUnit,
  });
}
