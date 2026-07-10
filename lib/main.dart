import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase/firebase_options.dart';
import 'config/supabase_config.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'providers/report_provider.dart';
import 'providers/notification_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('[main] Firebase initialized successfully');
  } catch (e) {
    debugPrint('[main] Firebase init FAILED: $e');
    // Fallback: aplikasi tetap berjalan dengan sample data lokal
  }
  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
    debugPrint('[main] Supabase initialized successfully');
  } catch (e) {
    debugPrint('[main] Supabase init FAILED: $e');
  }
  await initializeDateFormatting('id_ID', null);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(
    MultiProvider(
      providers: [
        // NotificationProvider harus dideklarasikan lebih dulu,
        // karena ReportProvider (di bawah) bergantung padanya.
        ChangeNotifierProvider(create: (_) => NotificationProvider()),

        // ReportProvider sekarang jadi ChangeNotifierProxyProvider agar
        // bisa memanggil NotificationProvider saat ada laporan baru/berubah status.
        // Logic pembuatan ReportProvider() aslinya tidak berubah.
        ChangeNotifierProxyProvider<NotificationProvider, ReportProvider>(
          create: (_) => ReportProvider(),
          update: (_, notificationProvider, reportProvider) {
            reportProvider!.updateNotificationProvider(notificationProvider);
            return reportProvider;
          },
        ),
      ],
      child: const FixUpApp(),
    ),
  );
}

class FixUpApp extends StatelessWidget {
  const FixUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FixUp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const SplashScreen(),
    );
  }
}