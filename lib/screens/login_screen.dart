import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../theme/app_theme.dart';
import '../firebase/firebase_helper.dart';
import '../models/models.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pelapor/home_screen.dart';
import 'sarpras/sarpras_dashboard_screen.dart';
import 'register_screen.dart';
import 'complete_profile_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  bool _rememberMe = false;
  String _socialLoading = '';

  static const String _googleLogoUrl = 'assets/images/google_logo.jpg';

  // ── Remember Me (Secure Storage) ──
  //
  // Alasan pendekatan auto-fill (bukan auto-login):
  //   Kita memilih mengisi otomatis field email & password (bukan langsung trigger login)
  //   karena lebih transparan — user bisa melihat kredensial yang tersimpan dan memutuskan
  //   apakah ingin melanjutkan login atau menggantinya. Auto-login bisa membingungkan jika
  //   kredensial sudah expired/diganti di device lain, karena error terjadi tanpa konteks.
  //
  // Perbedaan dengan Firebase Auth persistence bawaan:
  //   Firebase Auth secara default sudah membuat user tetap login meskipun app ditutup
  //   (persistence LOCAL — token refresh otomatis). Fitur "Ingat Saya" di sini adalah
  //   lapisan kedua yang menyimpan EMAIL & PASSWORD secara terenkripsi (flutter_secure_storage)
  //   supaya saat user logout (token Firebase dihapus), form login tidak kosong dan user
  //   tidak perlu mengetik ulang. Tanpa "Ingat Saya", setelah logout user harus isi manual.
  static const _secureStorage = FlutterSecureStorage();
  static const _secureKeyEmail = 'remembered_email';
  static const _secureKeyPass = 'remembered_password';
  static const _prefsKeyRemember = 'remember_me';

  @override
  void initState() {
    super.initState();
    _loadRememberedCredentials();
  }

  /// Cek apakah ada kredensial tersimpan di secure storage.
  /// Kalau ada (remember_me = true + email/password ada), isi otomatis field form.
  Future<void> _loadRememberedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remember = prefs.getBool(_prefsKeyRemember) ?? false;
      if (!remember) return;

      final email = await _secureStorage.read(key: _secureKeyEmail);
      final password = await _secureStorage.read(key: _secureKeyPass);

      if (email != null &&
          password != null &&
          email.isNotEmpty &&
          password.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _emailController.text = email;
          _passController.text = password;
          _rememberMe = true;
        });
      }
    } catch (_) {
      // Gagal baca storage → biarkan form kosong, tidak kritis
    }
  }

  /// Navigasi berdasarkan role setelah login
  Future<void> _navigateByRole(UserCredential cred) async {
    final helper = FirebaseHelper();
    final uid = cred.user!.uid;

    final exists = await helper.isUserDocumentExists(uid);
    if (!exists) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => CompleteProfileScreen(cred: cred)),
      );
      return;
    }

    final role = await helper.getUserRole(uid);
    if (!mounted) return;
    if (role == UserRole.sarpras) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SarprasDashboardScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  // ─── Login Email/Password ───

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passController.text;

    if (email.isEmpty || password.isEmpty) {
      _showSnack('Email dan kata sandi harus diisi', Colors.redAccent);
      return;
    }

    setState(() => _loading = true);
    try {
      final cred = await FirebaseHelper().loginWithEmail(email, password);

      // Simpan atau hapus kredensial berdasarkan status "Ingat Saya"
      if (_rememberMe) {
        await _secureStorage.write(key: _secureKeyEmail, value: email);
        await _secureStorage.write(key: _secureKeyPass, value: password);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_prefsKeyRemember, true);
      } else {
        await _secureStorage.delete(key: _secureKeyEmail);
        await _secureStorage.delete(key: _secureKeyPass);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_prefsKeyRemember, false);
      }

      if (!mounted) return;
      await _navigateByRole(cred);
    } on FirebaseAuthException catch (e) {
      // Jika login gagal padahal ada kredensial tersimpan, hapus agar tidak nyangkut
      if (_rememberMe) {
        await _secureStorage.delete(key: _secureKeyEmail);
        await _secureStorage.delete(key: _secureKeyPass);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_prefsKeyRemember, false);
      }

      String msg;
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          msg = 'Email atau kata sandi salah';
          break;
        case 'invalid-email':
          msg = 'Format email tidak valid';
          break;
        case 'too-many-requests':
          msg = 'Terlalu banyak percobaan. Coba lagi nanti.';
          break;
        case 'network-request-failed':
          msg = 'Tidak ada koneksi internet. Periksa jaringan kamu.';
          break;
        default:
          msg = 'Gagal masuk: ${e.message ?? "unknown error"}';
      }
      if (mounted) _showSnack(msg, Colors.redAccent);
    } catch (e) {
      if (mounted) _showSnack('Terjadi kesalahan: $e', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ─── Social Login ───

  Future<void> _loginGoogle() async {
    setState(() => _socialLoading = 'google');
    try {
      final cred = await FirebaseHelper().signInWithGoogle();
      if (!mounted) return;
      await _navigateByRole(cred);
    } catch (e) {
      if (mounted)
        _showSnack(
            e.toString().replaceFirst('Exception: ', ''), Colors.redAccent);
    } finally {
      if (mounted) setState(() => _socialLoading = '');
    }
  }

  Future<void> _loginFacebook() async {
    setState(() => _socialLoading = 'facebook');
    try {
      final cred = await FirebaseHelper().signInWithFacebook();
      if (!mounted) return;
      await _navigateByRole(cred);
    } catch (e) {
      if (mounted)
        _showSnack(
            e.toString().replaceFirst('Exception: ', ''), Colors.redAccent);
    } finally {
      if (mounted) setState(() => _socialLoading = '');
    }
  }

  Future<void> _loginApple() async {
    setState(() => _socialLoading = 'apple');
    try {
      final cred = await FirebaseHelper().signInWithApple();
      if (!mounted) return;
      await _navigateByRole(cred);
    } catch (e) {
      if (mounted)
        _showSnack(
            e.toString().replaceFirst('Exception: ', ''), Colors.redAccent);
    } finally {
      if (mounted) setState(() => _socialLoading = '');
    }
  }

  Future<void> _loginPhone() async {
    // Tampilkan dialog input nomor telepon
    final phoneController = TextEditingController();
    final phone = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Login dengan Nomor Telepon',
            style:
                GoogleFonts.manrope(fontSize: 17, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: '+62xxx',
            hintStyle: GoogleFonts.inter(color: AppColors.muted),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, phoneController.text.trim()),
              child: const Text('Kirim OTP')),
        ],
      ),
    );
    if (phone == null || phone.isEmpty) return;

    setState(() => _socialLoading = 'phone');
    try {
      await FirebaseHelper().verifyPhoneNumber(
        phoneNumber: phone,
        onCodeSent: (verificationId) async {
          if (!mounted) return;
          // Tampilkan dialog input kode OTP
          final codeController = TextEditingController();
          final smsCode = await showDialog<String>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text('Masukkan Kode OTP',
                  style: GoogleFonts.manrope(
                      fontSize: 17, fontWeight: FontWeight.w700)),
              content: TextField(
                controller: codeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '6 digit kode',
                  hintStyle: GoogleFonts.inter(color: AppColors.muted),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Batal')),
                ElevatedButton(
                    onPressed: () =>
                        Navigator.pop(ctx, codeController.text.trim()),
                    child: const Text('Verifikasi')),
              ],
            ),
          );
          if (smsCode == null || smsCode.isEmpty) return;

          if (!mounted) return;
          setState(() => _socialLoading = '');
          try {
            final cred = await FirebaseHelper().signInWithPhoneVerification(
              verificationId: verificationId,
              smsCode: smsCode,
            );
            if (!mounted) return;
            await _navigateByRole(cred);
          } catch (e) {
            if (mounted)
              _showSnack('Kode OTP salah atau expired', Colors.redAccent);
          }
        },
        onError: (e) {
          if (mounted) {
            String msg;
            switch (e.code) {
              case 'invalid-phone-number':
                msg = 'Nomor telepon tidak valid';
                break;
              case 'too-many-requests':
                msg = 'Terlalu banyak permintaan. Coba lagi nanti.';
                break;
              default:
                msg = 'Gagal kirim OTP: ${e.message}';
            }
            _showSnack(msg, Colors.redAccent);
          }
        },
      );
    } catch (e) {
      if (mounted) _showSnack('Gagal: $e', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _socialLoading = '');
    }
  }

  // ─── Lupa Password ───
  //
  // Alur keamanan standar Firebase:
  //   Proses reset/ganti password TIDAK terjadi di dalam app. Firebase mengirimkan
  //   email dengan link ke halaman resmi Firebase, di mana user bisa mengatur
  //   password baru. Ini adalah standar keamanan industri (OWASP) karena:
  //   1. Link bersifat one-time dan memiliki expiry time
  //   2. Verifikasi email terjadi otomatis saat user mengklik link
  //   3. App tidak perlu mengelola token reset sama sekali
  //   Bukan fitur yang kurang — memang ini cara yang aman.

  Future<void> _forgotPassword() async {
    final emailController = TextEditingController();
    bool sending = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text('Reset Kata Sandi',
                  style: GoogleFonts.manrope(
                      fontSize: 17, fontWeight: FontWeight.w700)),
              content: sending
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                              width: 28,
                              height: 28,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2.5)),
                          SizedBox(height: 16),
                          Text('Mengirim link reset...',
                              style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    )
                  : TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'Email kampus kamu',
                        hintStyle: GoogleFonts.inter(color: AppColors.muted),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
              actions: sending
                  ? []
                  : [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Batal'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final email = emailController.text.trim();

                          if (email.isEmpty) {
                            _showSnack('Email harus diisi', Colors.redAccent);
                            return;
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                              .hasMatch(email)) {
                            _showSnack(
                                'Format email tidak valid', Colors.redAccent);
                            return;
                          }

                          setDialogState(() => sending = true);

                          try {
                            await FirebaseHelper()
                                .sendPasswordResetEmail(email);

                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);

                            if (!mounted) return;
                            showDialog<void>(
                              context: context,
                              builder: (ctx2) => AlertDialog(
                                title: Row(
                                  children: [
                                    const Icon(Icons.check_circle,
                                        color: AppColors.green, size: 24),
                                    const SizedBox(width: 8),
                                    Text('Cek Email Kamu',
                                        style: GoogleFonts.manrope(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700)),
                                  ],
                                ),
                                content: Text(
                                  'Kami sudah kirim link reset kata sandi ke:\n$email\n\n'
                                  'Buka email kamu dan klik link tersebut untuk membuat kata sandi baru. '
                                  'Link hanya berlaku sementara.',
                                  style: GoogleFonts.inter(
                                      fontSize: 13, height: 1.5),
                                ),
                                actions: [
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(ctx2),
                                    child: const Text('Mengerti'),
                                  ),
                                ],
                              ),
                            );
                          } on FirebaseAuthException catch (e) {
                            String msg;
                            switch (e.code) {
                              case 'user-not-found':
                                msg = 'Email tidak terdaftar';
                                break;
                              case 'invalid-email':
                                msg = 'Format email tidak valid';
                                break;
                              case 'too-many-requests':
                                msg =
                                    'Terlalu banyak permintaan. Coba lagi nanti.';
                                break;
                              case 'network-request-failed':
                                msg =
                                    'Tidak ada koneksi internet. Periksa jaringan kamu.';
                                break;
                              default:
                                msg = 'Gagal: ${e.message ?? "unknown error"}';
                            }
                            setDialogState(() => sending = false);
                            _showSnack(msg, Colors.redAccent);
                          } catch (e) {
                            setDialogState(() => sending = false);
                            _showSnack(
                                'Terjadi kesalahan: $e', Colors.redAccent);
                          }
                        },
                        child: const Text('Kirim'),
                      ),
                    ],
            );
          },
        );
      },
    );
  }

  void _showSnack(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: bg,
      ),
    );
  }

  void _goToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildAuthContainer(context)),
        ],
      ),
    );
  }

  // ─── Header ───

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0E8A93), AppColors.primary],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FixUp',
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Selamat datang di FixUp',
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Lapor kerusakan fasilitas kampus dalam hitungan detik',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Auth Container ───

  Widget _buildAuthContainer(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
      ),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTabSwitcher(),
            const SizedBox(height: 32),
            _buildLoginForm(),
            const SizedBox(height: 40),
            _buildDivider(),
            const SizedBox(height: 24),
            _buildSocialButtons(),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                'Masuk',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: _goToRegister,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  'Daftar',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Login Form ───

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: GoogleFonts.inter(fontSize: 15, color: Colors.grey.shade700),
          decoration: InputDecoration(
            hintText: 'Email Kampus',
            hintStyle: GoogleFonts.inter(color: AppColors.muted),
            filled: true,
            fillColor: AppColors.primaryLight,
            prefixIcon: const Icon(Icons.email_outlined,
                color: AppColors.muted, size: 20),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                  color: AppColors.primary.withOpacity(0.2), width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                  color: AppColors.primary.withOpacity(0.2), width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _passController,
          obscureText: _obscure,
          style: GoogleFonts.inter(fontSize: 15, color: Colors.grey.shade700),
          decoration: InputDecoration(
            hintText: 'Kata Sandi',
            hintStyle: GoogleFonts.inter(color: AppColors.muted),
            filled: true,
            fillColor: AppColors.primaryLight,
            prefixIcon: const Icon(Icons.lock_outline,
                color: AppColors.muted, size: 20),
            suffixIcon: IconButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(
                _obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.muted,
                size: 20,
              ),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                  color: AppColors.primary.withOpacity(0.2), width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                  color: AppColors.primary.withOpacity(0.2), width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Checkbox "Ingat Saya"
            GestureDetector(
              onTap: () => setState(() => _rememberMe = !_rememberMe),
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: _rememberMe,
                      onChanged: (v) =>
                          setState(() => _rememberMe = v ?? false),
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Ingat saya',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Link "Lupa kata sandi?"
            TextButton(
              onPressed: _forgotPassword,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Lupa kata sandi?',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.buttonTop, AppColors.primary],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.39),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _loading ? null : _login,
                borderRadius: BorderRadius.circular(20),
                child: Center(
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Masuk',
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.primary.withOpacity(0.3))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'ATAU MASUK DENGAN',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade500,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(child: Divider(color: AppColors.primary.withOpacity(0.3))),
      ],
    );
  }

  // ─── Social Buttons ───

  Widget _buildSocialButtons() {
    return Row(
      children: [
        Expanded(
            child: _buildSocialButton(
          onTap: _socialLoading.isEmpty ? _loginGoogle : null,
          child: _socialLoading == 'google'
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Image.asset(_googleLogoUrl,
                  height: 22,
                  width: 22,
                  errorBuilder: (_, __, ___) => const Icon(
                      Icons.g_mobiledata_rounded,
                      color: AppColors.primary,
                      size: 24)),
        )),
        const SizedBox(width: 12),
        Expanded(
            child: _buildSocialButton(
          onTap: _socialLoading.isEmpty ? _loginFacebook : null,
          child: _socialLoading == 'facebook'
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.facebook, color: Color(0xFF3B5998), size: 24),
        )),
        const SizedBox(width: 12),
        Expanded(
            child: _buildSocialButton(
          onTap: _socialLoading.isEmpty ? _loginApple : null,
          child: _socialLoading == 'apple'
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.apple, color: Colors.black, size: 24),
        )),
        const SizedBox(width: 12),
        Expanded(
            child: _buildSocialButton(
          onTap: _socialLoading.isEmpty ? _loginPhone : null,
          child: _socialLoading == 'phone'
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(Icons.smartphone_outlined,
                  color: Colors.grey.shade700, size: 22),
        )),
      ],
    );
  }

  Widget _buildSocialButton({VoidCallback? onTap, required Widget child}) {
    return SizedBox(
      height: 52,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: child,
          ),
        ),
      ),
    );
  }
}
