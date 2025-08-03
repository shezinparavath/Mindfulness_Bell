import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:mindfulness_bell/core/background/background_service.dart';
import 'package:mindfulness_bell/features/timer/presentation/screens/mindfulness_bell_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/audio/audio_handler.dart';
import 'features/timer/presentation/providers/timer_provider.dart';
import 'features/timer/data/repositories/timer_repository_impl.dart';
import 'features/timer/domain/repositories/timer_repository.dart';

late SharedPreferences prefs;
late AudioPlayerHandler audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
    return Material(
      child: Center(
        child: Text(
          'An error occurred: ${errorDetails.exception}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  };

  try {
    // Initialize SharedPreferences first
    debugPrint('Initializing SharedPreferences...');
    prefs = await SharedPreferences.getInstance();
    debugPrint('SharedPreferences initialized');

    // Initialize audio service with error handling
    debugPrint('Initializing audio service...');
    audioHandler = await AudioService.init(
      builder: () => AudioPlayerHandler(),
      config: AudioServiceConfig(
        androidNotificationChannelId:
            'com.yourcompany.mindfulnessbell.channel.audio',
        androidNotificationChannelName: 'Mindfulness Bell',
        androidNotificationOngoing: false,
        androidStopForegroundOnPause: false,
        androidNotificationIcon: 'mipmap/ic_launcher',
      ),
    );
    debugPrint('Audio service initialized');

    // Initialize background service
    debugPrint('Initializing background service...');
    await BackgroundService.initialize();
    debugPrint('Background service initialized');

    // Initialize repositories
    final timerRepository = TimerRepositoryImpl(audioHandler);
    debugPrint('Repository initialized');

    // Run the app
    debugPrint('Starting app...');
    runApp(MyApp(timerRepository: timerRepository, audioHandler: audioHandler));
  } catch (e, stackTrace) {
    debugPrint('Error during initialization: $e');
    debugPrint('Stack trace: $stackTrace');

    // Run a fallback app
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Failed to initialize app',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Error: $e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Try to restart
                    main();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  final TimerRepository timerRepository;
  final AudioPlayerHandler audioHandler;

  const MyApp({
    super.key,
    required this.timerRepository,
    required this.audioHandler,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // App is going to background
      BackgroundService.startKeepAlive();
    } else if (state == AppLifecycleState.resumed) {
      // App is back in foreground
      BackgroundService.stopKeepAlive();
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Building MyApp...');

    return MaterialApp(
      title: 'Mindfulness Bell',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) {
              debugPrint('Creating TimerProvider...');
              return TimerProvider(
                widget.timerRepository,
                audioHandler: widget.audioHandler,
              );
            },
          ),
        ],
        child: const MindfulnessBellScreen(),
      ),
      // Add error handling for the entire app
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(1.0)),
          child: child!,
        );
      },
    );
  }
}
