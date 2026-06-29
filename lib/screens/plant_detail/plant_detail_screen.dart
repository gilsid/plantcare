import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../models/plant.dart';
import '../../models/care_task.dart';
import '../../models/care_history.dart';
import '../../models/enums.dart';
import '../../providers/plant_provider.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/health_bar.dart';
import '../../widgets/plant_image.dart';
import 'widgets/growth_timeline.dart';

class PlantDetailScreen extends StatelessWidget {
final String plantId;

const PlantDetailScreen({super.key, required this.plantId});

Future<void> _confirmDelete(BuildContext context, Plant plant) async {
final bool? confirm = await showDialog<bool>(
context: context,
builder: (context) => ConfirmDialog(
title: 'Hapus Tanaman',
message:
'Apakah Anda yakin ingin menghapus ${plant.name} dan seluruh riwayat perawatannya?',
confirmColor: AppColors.error,
confirmLabel: 'Hapus',
),
);

if (confirm == true && context.mounted) {
final messenger = ScaffoldMessenger.of(context);
final navigator = Navigator.of(context);
await context.read<PlantProvider>().deletePlant(plant.id);
messenger.showSnackBar(
const SnackBar(
content: Text('Tanaman berhasil dihapus.'),
behavior: SnackBarBehavior.floating,
),
);
navigator.pop();
}
}

String _getCareStatusText(CareTask task) {
if (task.isOverdue) {
final diff = DateTime.now().difference(task.nextDueDate);
final hours = diff.inHours;
if (hours < 24) return 'Terlambat $hours jam!';
final days = diff.inDays;
return 'Terlambat $days hari!';
}
final diff = task.nextDueDate.difference(DateTime.now());
final hours = diff.inHours;
if (hours < 24) {
if (hours <= 0) return 'Hari ini';
return 'Dalam $hours jam';
}
final days = diff.inDays;
return 'Dalam $days hari';
}

String _getDurationText(DateTime dateAdded) {
final now = DateTime.now();
final diff = now.difference(dateAdded);
final days = diff.inDays;

if (days < 7) return 'Baru ditambahkan $days hari lalu';
if (days < 30) {
final weeks = days ~/ 7;
return 'Dirawat selama $weeks minggu';
}
if (days < 365) {
final months = days ~/ 30;
return 'Dirawat selama $months bulan';
}
final years = days ~/ 365;
final remainMonths = (days % 365) ~/ 30;
if (remainMonths == 0) return 'Dirawat selama $years tahun';
return 'Dirawat selama $years tahun $remainMonths bulan';
}

@override
Widget build(BuildContext context) {
final textTheme = Theme.of(context).textTheme;
final isDark = Theme.of(context).brightness == Brightness.dark;

return Consumer<PlantProvider>(
builder: (context, provider, child) {
final plants = provider.plants;
final plant = plants.where((p) => p.id == plantId).firstOrNull;

if (plant == null) {
return const Scaffold(
body: Center(child: Text('Tanaman tidak ditemukan.')),
);
}

final careTasks = provider.getCareTasksForPlant(plant.id);
final careHistories = provider.getCareHistoriesForPlant(plant.id);
final String addedDateFormatted = DateFormat(
'dd MMMM yyyy',
).format(plant.dateAdded);

return Scaffold(
body: DefaultTabController(
length: 2,
child: NestedScrollView(
headerSliverBuilder: (context, innerBoxIsScrolled) {
return [
SliverAppBar(
expandedHeight: 280,
pinned: true,
actions: [
IconButton(
icon: const Icon(Icons.edit_outlined),
onPressed: () {
Navigator.pushNamed(
context,
'/add-edit-plant',
arguments: plant.id,
);
},
),
IconButton(
icon: const Icon(Icons.delete_outline),
onPressed: () => _confirmDelete(context, plant),
),
],
flexibleSpace: FlexibleSpaceBar(
title: Text(
plant.name,
style: textTheme.titleMedium?.copyWith(
fontWeight: FontWeight.bold,
color: Colors.white,
shadows: const [
Shadow(
offset: Offset(0, 1),
blurRadius: 4.0,
color: Colors.black54,
),
],
),
),
background: Stack(
fit: StackFit.expand,
children: [
Hero(
tag: 'plant_image_${plant.id}',
child: PlantImage(
photoPath: plant.photoPath,
fit: BoxFit.cover,
initials: plant.name,
placeholder: Container(
color: isDark
? const Color(0xFF1E2421)
: const Color(0xFFECECE5),
child: Icon(
Icons.local_florist,
size: 110,
color: isDark
? AppColors.textSecondaryDark
: AppColors.primaryLight.withValues(
alpha: 0.4,
),
),
),
),
),
const DecoratedBox(
decoration: BoxDecoration(
gradient: LinearGradient(
colors: [Colors.transparent, Colors.black45],
begin: Alignment.topCenter,
end: Alignment.bottomCenter,
),
),
),
],
),
),
),

SliverList(
delegate: SliverChildListDelegate([
Padding(
padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
plant.name,
style: textTheme.titleLarge?.copyWith(
fontSize: 26,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 4),
Text(
plant.species,
style: textTheme.bodyLarge?.copyWith(
fontStyle: FontStyle.italic,
color: isDark
? AppColors.primaryDark
: AppColors.primaryLight,
),
),
if (plant.location != null &&
plant.location!.isNotEmpty) ...[
const SizedBox(height: 4),
Row(
children: [
Icon(
Icons.location_on_outlined,
size: 16,
color: isDark
? AppColors.textSecondaryDark
: AppColors.textSecondaryLight,
),
const SizedBox(width: 4),
Text(
plant.location!,
style: textTheme.bodySmall?.copyWith(
color: isDark
? AppColors.textSecondaryDark
: AppColors.textSecondaryLight,
),
),
],
),
],
const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceDark
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF252D2A)
                              : const Color(0xFFE2E2DC),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Kesehatan',
                                style: textTheme.bodySmall,
                              ),
                              const Spacer(),
                              _buildTrend(context, provider, plant.id),
                            ],
                          ),
                          const SizedBox(height: 8),
                          HealthBar(
                            score: plant.healthScore,
                            height: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
const SizedBox(width: 12),
Expanded(
child: Container(
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
color: isDark
? AppColors.surfaceDark
: Colors.white,
borderRadius: BorderRadius.circular(16),
border: Border.all(
color: isDark
? const Color(0xFF252D2A)
: const Color(0xFFE2E2DC),
),
),
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Text(
'Perawatan',
style: textTheme.bodySmall,
),
const SizedBox(height: 6),
Text(
'${careTasks.length} jadwal',
style: textTheme.bodyLarge?.copyWith(
fontWeight: FontWeight.bold,
color: isDark
? AppColors.primaryDark
: AppColors.primaryLight,
),
),
],
),
),
),
],
),
const SizedBox(height: 16),

...careTasks.map((task) => _buildCareTaskCard(
context,
task,
provider,
plant,
isDark,
textTheme,
)),

if (careHistories.isNotEmpty) ...[
const SizedBox(height: 16),
Row(
children: [
Expanded(
child: _buildStatTile(
context: context,
label: 'Total Perawatan',
value: '${careHistories.length}x',
icon: Icons.check_circle_outline_rounded,
isDark: isDark,
textTheme: textTheme,
),
),
const SizedBox(width: 12),
Expanded(
child: _buildStatTile(
context: context,
label: 'Tepat Waktu',
value: () {
final onTime = careHistories
.where((h) => h.wasOnTime == true)
.length;
final pct = (onTime / careHistories.length * 100).round();
return '$pct%';
}(),
icon: Icons.timer_outlined,
isDark: isDark,
textTheme: textTheme,
),
),
],
),
],

const SizedBox(height: 8),
Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'Ditambahkan pada $addedDateFormatted',
style: textTheme.bodySmall?.copyWith(
fontSize: 11,
color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
),
),
const SizedBox(height: 2),
Text(
_getDurationText(plant.dateAdded),
style: textTheme.bodySmall?.copyWith(
fontSize: 11,
fontWeight: FontWeight.w600,
color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
),
),
],
),
const SizedBox(height: 16),
],
),
),
]),
),

SliverPersistentHeader(
pinned: true,
delegate: _SliverTabBarDelegate(
TabBar(
indicatorColor: isDark
? AppColors.primaryDark
: AppColors.primaryLight,
labelColor: isDark
? AppColors.primaryDark
: AppColors.primaryLight,
unselectedLabelColor: isDark
? AppColors.textSecondaryDark
: AppColors.textSecondaryLight,
labelStyle: textTheme.bodyMedium?.copyWith(
fontWeight: FontWeight.bold,
),
unselectedLabelStyle: textTheme.bodyMedium,
tabs: const [
Tab(text: 'Riwayat Perawatan'),
Tab(text: 'Diary Tumbuh'),
],
),
),
),
];
},
body: TabBarView(
children: [
_CareHistoryTab(histories: careHistories),
GrowthTimeline(plant: plant),
],
),
),
),
);
},
);
}

  Widget? _buildTrend(BuildContext context, PlantProvider provider, String plantId) {
    final trend = provider.getHealthTrend(plantId);
    if (trend == null) return null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(trend.icon, size: 14, color: trend.color),
        const SizedBox(width: 2),
        Text(
          trend.label,
          style: TextStyle(
            fontSize: 10,
            color: trend.color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showCompleteAnimation(BuildContext context) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _AnimatedCareOverlay(
        onDismissed: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }

  Widget _buildCareTaskCard(
    BuildContext context,
    CareTask task,
    PlantProvider provider,
    Plant plant,
    bool isDark,
    TextTheme textTheme,
  ) {
final isOverdue = task.isOverdue;
return Container(
margin: const EdgeInsets.only(bottom: 8),
padding: const EdgeInsets.all(12),
decoration: BoxDecoration(
color: isOverdue
? AppColors.error.withValues(alpha: 0.08)
: (isDark ? AppColors.surfaceDark : Colors.white),
borderRadius: BorderRadius.circular(16),
border: Border.all(
color: isOverdue
? AppColors.error.withValues(alpha: 0.3)
: (isDark ? const Color(0xFF252D2A) : const Color(0xFFE2E2DC)),
),
),
child: Row(
children: [
_getCareIcon(task.careType, isDark),
const SizedBox(width: 12),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
task.careType.displayName,
style: textTheme.bodyMedium?.copyWith(
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 2),
Text(
'Setiap ${task.intervalValue} ${task.intervalUnit.displayNamePlural}',
style: textTheme.bodySmall,
),
const SizedBox(height: 2),
Text(
_getCareStatusText(task),
style: textTheme.bodySmall?.copyWith(
color: isOverdue ? AppColors.error : AppColors.success,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 6),
_buildCareProgress(task),
],
),
),
ElevatedButton.icon(
icon: Icon(
_getCompleteIcon(task.careType),
size: 16,
),
label: Text(
_getCompleteLabel(task.careType),
style: const TextStyle(fontSize: 12),
),
style: ElevatedButton.styleFrom(
backgroundColor:
isOverdue ? AppColors.error : AppColors.primaryLight,
foregroundColor:
isOverdue ? Colors.white : (isDark ? Colors.black : Colors.white),
padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
minimumSize: Size.zero,
tapTargetSize: MaterialTapTargetSize.shrinkWrap,
),
onPressed: () async {
final messenger = ScaffoldMessenger.of(context);
final taskName = task.careType.displayName;
final plantName = plant.name;

final noteController = TextEditingController();
final note = await showDialog<String>(
context: context,
builder: (ctx) => AlertDialog(
title: Text('$taskName untuk $plantName'),
content: TextField(
controller: noteController,
maxLines: 3,
decoration: const InputDecoration(
hintText: 'Catatan (opsional) — misal: pupuk 10ml, daun kuning...',
border: OutlineInputBorder(),
),
),
actions: [
TextButton(
onPressed: () => Navigator.pop(ctx, ''),
child: const Text('Lewati'),
),
ElevatedButton(
onPressed: () => Navigator.pop(ctx, noteController.text.trim()),
child: const Text('Simpan'),
),
],
),
);
noteController.dispose();

                final success = await provider.completeCareTask(
                  plant.id, task.careType,
                  note: note?.isEmpty == true ? null : note,
                );
                if (success) {
                  _showCompleteAnimation(context);
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        '$taskName untuk $plantName selesai!',
                      ),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
},
),
],
),
);
}

Widget _buildCareProgress(CareTask task) {
final totalDuration = task.intervalUnit == IntervalUnit.hour
? Duration(hours: task.intervalValue)
: task.intervalUnit == IntervalUnit.day
? Duration(days: task.intervalValue)
: task.intervalUnit == IntervalUnit.week
? Duration(days: task.intervalValue * 7)
: Duration(days: task.intervalValue * 30);

final elapsed = task.lastCompletedDate != null
? DateTime.now().difference(task.lastCompletedDate!)
: totalDuration;

final progress = totalDuration.inSeconds > 0
? (elapsed.inSeconds / totalDuration.inSeconds).clamp(0.0, 1.0)
: 1.0;

final Color trackColor = task.isOverdue ? AppColors.error : AppColors.success;

return ClipRRect(
borderRadius: BorderRadius.circular(4),
child: LinearProgressIndicator(
value: progress,
minHeight: 4,
backgroundColor: trackColor.withValues(alpha: 0.12),
valueColor: AlwaysStoppedAnimation<Color>(
trackColor.withValues(alpha: task.isOverdue ? 0.7 : 0.5),
),
),
);
}

Widget _buildStatTile({
required BuildContext context,
required String label,
required String value,
required IconData icon,
required bool isDark,
required TextTheme textTheme,
}) {
return Container(
padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
decoration: BoxDecoration(
color: isDark ? AppColors.surfaceDark : Colors.white,
borderRadius: BorderRadius.circular(16),
border: Border.all(
color: isDark ? const Color(0xFF252D2A) : const Color(0xFFE2E2DC),
),
),
child: Row(
children: [
Icon(
icon,
size: 18,
color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
),
const SizedBox(width: 8),
Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
value,
style: textTheme.bodyLarge?.copyWith(
fontWeight: FontWeight.bold,
color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
),
),
Text(
label,
style: textTheme.bodySmall?.copyWith(fontSize: 10),
),
],
),
],
),
);
}

Widget _getCareIcon(CareType type, bool isDark) {
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
icon = Icons.change_circle_outlined;
}
return CircleAvatar(
radius: 18,
backgroundColor:
isDark
? AppColors.primaryDark.withValues(alpha: 0.15)
: AppColors.primaryLight.withValues(alpha: 0.1),
child: Icon(
icon,
size: 18,
color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
),
);
}

IconData _getCompleteIcon(CareType type) {
return Icons.check;
}

String _getCompleteLabel(CareType type) {
switch (type) {
case CareType.watering:
return 'Siram';
case CareType.fertilizing:
return 'Pupuk';
case CareType.pruning:
return 'Pangkas';
case CareType.pestCheck:
return 'Cek';
case CareType.repotting:
return 'Ganti';
}
}
}

class _AnimatedCareOverlay extends StatefulWidget {
  final VoidCallback onDismissed;

  const _AnimatedCareOverlay({required this.onDismissed});

  @override
  State<_AnimatedCareOverlay> createState() => _AnimatedCareOverlayState();
}

class _AnimatedCareOverlayState extends State<_AnimatedCareOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnim = Tween<double>(begin: 0.3, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.3)),
    );
    _controller.forward();
    Future.delayed(const Duration(milliseconds: 1200), () {
      widget.onDismissed();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnim.value,
                child: Transform.scale(
                  scale: _scaleAnim.value,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.success.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CareHistoryTab extends StatelessWidget {
final List<CareHistory> histories;

const _CareHistoryTab({required this.histories});

@override
Widget build(BuildContext context) {
final textTheme = Theme.of(context).textTheme;
final isDark = Theme.of(context).brightness == Brightness.dark;

if (histories.isEmpty) {
return Center(
child: Padding(
padding: const EdgeInsets.all(32.0),
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(
Icons.history_outlined,
size: 48,
color: isDark
? AppColors.textSecondaryDark
: AppColors.textSecondaryLight.withValues(alpha: 0.5),
),
const SizedBox(height: 16),
Text(
'Belum ada riwayat perawatan',
style: textTheme.bodyLarge?.copyWith(
fontWeight: FontWeight.w600,
),
),
const SizedBox(height: 8),
Text(
'Riwayat akan muncul saat Anda menyelesaikan perawatan.',
textAlign: TextAlign.center,
style: textTheme.bodySmall,
),
const SizedBox(height: 4),
Text(
'Gunakan tombol di bagian atas untuk mencatat perawatan.',
textAlign: TextAlign.center,
style: textTheme.bodySmall?.copyWith(
fontStyle: FontStyle.italic,
),
),
],
),
),
);
}

return ListView.builder(
itemCount: histories.length,
padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
itemBuilder: (context, index) {
final history = histories[index];
final formattedDate = DateFormat(
'dd MMMM yyyy, HH:mm',
).format(history.completedAt);

return Container(
margin: const EdgeInsets.only(bottom: 12),
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
color: isDark ? AppColors.surfaceDark : Colors.white,
borderRadius: BorderRadius.circular(16),
border: Border.all(
color:
isDark ? const Color(0xFF252D2A) : const Color(0xFFE2E2DC),
),
),
child: Row(
children: [
CircleAvatar(
backgroundColor: AppColors.success.withValues(alpha: 0.12),
radius: 20,
child: Icon(
Icons.check_rounded,
color: AppColors.success,
size: 20,
),
),
const SizedBox(width: 16),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'✓ ${history.careType.displayName}',
style: textTheme.bodyLarge?.copyWith(
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 2),
Text(formattedDate, style: textTheme.bodySmall),
],
),
),
],
),
);
},
);
}
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
final TabBar tabBar;

_SliverTabBarDelegate(this.tabBar);

@override
double get minExtent => tabBar.preferredSize.height;
@override
double get maxExtent => tabBar.preferredSize.height;

@override
Widget build(
BuildContext context,
double shrinkOffset,
bool overlapsContent,
) {
final isDark = Theme.of(context).brightness == Brightness.dark;
return Container(
color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
child: tabBar,
);
}

@override
bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
return false;
}
}
