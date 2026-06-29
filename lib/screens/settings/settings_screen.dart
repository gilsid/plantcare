import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../providers/theme_provider.dart';
import '../../providers/plant_provider.dart';
import '../../services/database_service.dart';
import '../../widgets/confirm_dialog.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _resetApp(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => const ConfirmDialog(
        title: 'Reset Semua Data',
        message:
            'Apakah Anda yakin ingin menghapus semua tanaman dan pengaturan? Tindakan ini tidak dapat dibatalkan.',
        confirmColor: AppColors.error,
        confirmLabel: 'Reset',
      ),
    );

    if (confirm == true && context.mounted) {
      await context.read<PlantProvider>().resetAll();

      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Semua data berhasil di-reset.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pengaturan',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        children: [
          // Theme Section
          Text(
            'Tampilan',
            style: textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return SwitchListTile(
                  title: const Text('Mode Gelap (Dark Mode)'),
                  subtitle: const Text('Mengubah warna aplikasi menjadi gelap'),
                  value: themeProvider.isDarkMode,
                  // ignore: deprecated_member_use
                  activeColor: isDark
                      ? AppColors.primaryDark
                      : AppColors.primaryLight,
                  onChanged: (value) {
                    themeProvider.toggleTheme();
                  },
                  secondary: CircleAvatar(
                    backgroundColor: isDark
                        ? AppColors.primaryDark.withValues(alpha: 0.1)
                        : AppColors.primaryLight.withValues(alpha: 0.1),
                    child: Icon(
                      themeProvider.isDarkMode
                          ? Icons.dark_mode
                          : Icons.light_mode,
                      color: isDark
                          ? AppColors.primaryDark
                          : AppColors.primaryLight,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Profile Section
          Text(
            'Profil',
            style: textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isDark
                    ? AppColors.primaryDark.withValues(alpha: 0.1)
                    : AppColors.primaryLight.withValues(alpha: 0.1),
                child: Icon(Icons.person_outline,
                    color: isDark ? AppColors.primaryDark : AppColors.primaryLight),
              ),
              title: Text(
                context.read<DatabaseService>().getUsername().isNotEmpty
                    ? context.read<DatabaseService>().getUsername()
                    : 'Atur Nama',
              ),
              subtitle: Text(
                context.read<DatabaseService>().getUsername().isNotEmpty
                    ? 'Tap untuk mengganti nama'
                    : 'Tap untuk memberi nama',
              ),
              trailing: const Icon(Icons.edit),
              onTap: () {
                final controller = TextEditingController(
                  text: context.read<DatabaseService>().getUsername(),
                );
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Nama Kamu'),
                    content: TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: 'Masukkan nama...',
                        border: OutlineInputBorder(),
                      ),
                      autofocus: true,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Batal'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          context.read<DatabaseService>().setUsername(
                            controller.text.trim(),
                          );
                          Navigator.pop(ctx);
                          (context as Element).markNeedsBuild();
                        },
                        child: const Text('Simpan'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Data Management Section
          Text(
            'Manajemen Data',
            style: textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.error.withValues(alpha: 0.1),
                child: const Icon(Icons.delete_forever, color: AppColors.error),
              ),
              title: const Text('Reset Aplikasi'),
              subtitle: const Text('Menghapus semua data tanaman dan riwayat'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _resetApp(context),
            ),
          ),
          const SizedBox(height: 24),

          // About Section
          Text(
            'Tentang Aplikasi',
            style: textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.primaryDark.withValues(alpha: 0.15)
                              : AppColors.primaryLight.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.local_florist,
                          color: isDark
                              ? AppColors.primaryDark
                              : AppColors.primaryLight,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PlantCare',
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text('Versi 0.0.2-alpha'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Text(
                    'PlantCare adalah aplikasi pencatat offline-first untuk melacak dan merawat tanaman hias Anda secara teratur dan terjadwal.',
                    style: textTheme.bodySmall?.copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
