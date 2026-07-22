import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:audio_service/audio_service.dart';

import 'models/audio_item.dart';
import 'models/ruqyah_item.dart';
import 'services/ruqyah_audio_handler.dart';
import 'screens/main_screen.dart';

late RuqyahAudioHandler audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(AudioItemAdapter());
  Hive.registerAdapter(RuqyahSequenceItemAdapter());
  Hive.registerAdapter(RuqyahPlaylistAdapter());

  await Hive.openBox<AudioItem>('audios');
  await Hive.openBox<RuqyahPlaylist>('playlists');

  audioHandler = await AudioService.init(
    builder: () => RuqyahAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.ruqyah.offline_player.channel.audio',
      androidNotificationChannelName: 'الرقية الشرعية',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  runApp(const CustomRuqyahApp());
}

class CustomRuqyahApp extends StatelessWidget {
  const CustomRuqyahApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'الرقية الشرعية',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar', ''),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', ''),
      ],
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B5E20),
          primary: const Color(0xFF1B5E20),
          secondary: const Color(0xFF004D40),
          background: const Color(0xFFFAFAFA),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
          titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
          bodyLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black80),
          bodyMedium: TextStyle(fontSize: 18, color: Colors.black80),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
            textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      home: const MainScreen(),
    );
  }
}
