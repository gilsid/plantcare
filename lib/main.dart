import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app/theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'providers/plant_provider.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'services/image_service.dart';
import 'screens/home/home_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/add_edit_plant/add_edit_plant_screen.dart';
import 'screens/plant_detail/plant_detail_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Core Services
  final dbService = DatabaseService();
  await dbService.init();

  final notificationService = NotificationService();
  await notificationService.init();
  // Request notifications permission on startup
  await notificationService.requestPermissions();

  final imageService = ImageService();

  runApp(
    MultiProvider(
      providers: [
        Provider<DatabaseService>.value(value: dbService),
        Provider<NotificationService>.value(value: notificationService),
        Provider<ImageService>.value(value: imageService),
        ChangeNotifierProvider<ThemeProvider>(
          create: (context) => ThemeProvider(dbService),
        ),
        ChangeNotifierProvider<PlantProvider>(
          create: (context) => PlantProvider(
            dbService: dbService,
            notificationService: notificationService,
            imageService: imageService,
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'PlantCare',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/plant-detail') {
          final String plantId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => PlantDetailScreen(plantId: plantId),
          );
        }
        if (settings.name == '/add-edit-plant') {
          final String? plantId = settings.arguments as String?;
          return MaterialPageRoute(
            builder: (context) => AddEditPlantScreen(plantId: plantId),
          );
        }
        return null;
      },
    );
  }
}
