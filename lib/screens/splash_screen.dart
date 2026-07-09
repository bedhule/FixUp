import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../firebase/firebase_helper.dart';
import '../models/models.dart';
import 'publik_screen.dart';
import 'pelapor/home_screen.dart';
import 'sarpras/sarpras_dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    debugPrint('[SplashScreen] Menunggu 1.5 detik...');
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    final helper = FirebaseHelper();
    debugPrint('[SplashScreen] isLoggedIn: ${helper.isLoggedIn}');

    if (helper.isLoggedIn) {
      try {
        final uid = helper.currentUser!.uid;
        debugPrint('[SplashScreen] User UID: $uid');
        final role = await helper.getUserRole(uid);
        debugPrint('[SplashScreen] User role: $role');
        if (!mounted) return;
        if (role == UserRole.sarpras) {
          debugPrint('[SplashScreen] Navigasi ke SarprasDashboard');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const SarprasDashboardScreen()),
          );
        } else {
          debugPrint('[SplashScreen] Navigasi ke HomeScreen');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } catch (e) {
        debugPrint('[SplashScreen] Error get role: $e');
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PublikScreen()),
        );
      }
    } else {
      debugPrint('[SplashScreen] Tidak login, navigasi ke PublikScreen');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PublikScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final logoSize = size.width * 0.18;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // Background solid, tidak ada gradasi putih lagi
        color: AppColors.primary,
        child: SafeArea(
          child: Stack(
            children: [
              // Konten logo + teks benar-benar center di tengah layar
              Positioned.fill(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: logoSize.clamp(56, 80),
                        height: logoSize.clamp(56, 80),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(logoSize * 0.28),
                        ),
                        child: Center(
                          child: Text(
                            'FU',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.manrope(
                              fontSize: logoSize * 0.4,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'FixUp',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.manrope(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Positioned(
                bottom: 48,
                left: 0,
                right: 0,
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
