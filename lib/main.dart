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
import 'screens/onboarding/onboarding_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Core Services
  final dbService = DatabaseService();
  await dbService.init();

  final hasSeenOnboarding = dbService.getOnboardingSeen();

  final notificationService = NotificationService();
  await notificationService.init(
    onNotificationTap: (plantId) {
      navigatorKey.currentState?.pushNamed('/plant-detail', arguments: plantId);
    },
  );
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
      child: MyApp(hasSeenOnboarding: hasSeenOnboarding),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool hasSeenOnboarding;
  const MyApp({super.key, required this.hasSeenOnboarding});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'PlantCare',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      initialRoute: hasSeenOnboarding ? '/' : '/onboarding',
      routes: {
        '/': (context) => const HomeScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/plant-detail') {
          final String plantId = settings.arguments as String;
          return PageRouteBuilder(
            settings: settings,
            pageBuilder: (context, animation, secondaryAnimation) =>
                PlantDetailScreen(plantId: plantId),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                ),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 280),
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
