import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme.dart';
import 'core/providers.dart';
import 'features/gallery/gallery_screen.dart';
import 'features/map_view/map_screen.dart';
import 'features/capture/capture_screen.dart';
import 'features/splash/splash_screen.dart';
import 'services/database_service.dart';
import 'models/geo_entry.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Initialize cameras
  List<CameraDescription> cameras = [];
  try {
    cameras = await availableCameras();
  } catch (e) {
    debugPrint('Error fetching cameras: $e');
  }

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(GeoEntryAdapter());
  final box = await Hive.openBox<GeoEntry>('geo_entries');

  runApp(
    ProviderScope(
      overrides: [
        camerasProvider.overrideWithValue(cameras),
        databaseServiceProvider.overrideWithValue(DatabaseService(box)),
      ],
      child: const GeoTagApp(),
    ),
  );
}

class GeoTagApp extends ConsumerWidget {
  const GeoTagApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'GeoTag Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/home': (context) => const HomeScreen(),
        '/capture': (context) => const CaptureScreen(),
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [GalleryScreen(), MapScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _currentIndex == 1
          ? AppBar(title: const Text('Map View'))
          : null, // Gallery has its own AppBar
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            selectedIcon: Icon(Icons.photo_library),
            label: 'Gallery',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/capture'),
        child: const Icon(Icons.camera_alt),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      extendBody: true, // For transparency behind FAB if needed
    );
  }
}
