import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../firebase/firebase_helper.dart';
import '../models/models.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pelapor/home_screen.dart';
import 'sarpras/sarpras_dashboard_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _nimController = TextEditingController();
  final _nipController = TextEditingController();
  final _divisiController = TextEditingController();
  final _passController = TextEditingController();
  final _konfirmasiController = TextEditingController();
  bool _obscurePass = true;
  bool _obscureKonfirmasi = true;
  bool _loading = false;
  UserRole _role = UserRole.pelapor;

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _nimController.dispose();
    _nipController.dispose();
    _divisiController.dispose();
    _passController.dispose();
    _konfirmasiController.dispose();
    super.dispose();
  }

  void _showSnack(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: const TextStyle(color: Colors.white)), backgroundColor: bg),
    );
  }

  Future<void> _register() async {
    final nama = _namaController.text.trim();
    final email = _emailController.text.trim();
    final nim = _nimController.text.trim();
    final nip = _nipController.text.trim();
    final divisi = _divisiController.text.trim();
    final pass = _passController.text;
    final konfirmasi = _konfirmasiController.text;

    // ── Validasi ──
    if (nama.isEmpty) {
      _showSnack('Nama lengkap harus diisi', Colors.redAccent);
      return;
    }
    if (email.isEmpty) {
      _showSnack('Email harus diisi', Colors.redAccent);
      return;
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      _showSnack('Format email tidak valid', Colors.redAccent);
      return;
    }
    if (_role == UserRole.pelapor && nim.isEmpty) {
      _showSnack('NIM harus diisi', Colors.redAccent);
      return;
    }
    if (_role == UserRole.sarpras) {
      if (nip.isEmpty) {
        _showSnack('NIP harus diisi', Colors.redAccent);
        return;
      }
      if (divisi.isEmpty) {
        _showSnack('Divisi harus diisi', Colors.redAccent);
        return;
      }
    }
    if (pass.isEmpty) {
      _showSnack('Kata sandi harus diisi', Colors.redAccent);
      return;
    }
    if (pass.length < 6) {
      _showSnack('Kata sandi minimal 6 karakter', Colors.redAccent);
      return;
    }
    if (konfirmasi.isEmpty) {
      _showSnack('Konfirmasi kata sandi harus diisi', Colors.redAccent);
      return;
    }
    if (pass != konfirmasi) {
      _showSnack('Konfirmasi kata sandi tidak cocok', Colors.redAccent);
      return;
    }

    debugPrint('[Register] Validasi berhasil. Memulai registrasi...');
    setState(() => _loading = true);

    try {
      debugPrint('[Register] Memanggil FirebaseAuth.createUserWithEmailAndPassword...');
      final cred = await FirebaseHelper().registerWithEmail(
        email: email,
        password: pass,
        name: nama,
        nim: nim,
        nip: nip,
        divisi: divisi,
        role: _role,
      );
      debugPrint('[Register] Registrasi berhasil. UID: ${cred.user?.uid}');

      if (!mounted) return;
      _showSnack('Registrasi berhasil!', AppColors.green);

      final role = await FirebaseHelper().getUserRole(cred.user!.uid);
      if (!mounted) return;

      debugPrint('[Register] Navigasi ke halaman utama (role: $role)');
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
    } on FirebaseAuthException catch (e) {
      debugPrint('[Register] FirebaseAuthException: ${e.code} - ${e.message}');
      String msg;
      switch (e.code) {
        case 'email-already-in-use':
          msg = 'Email sudah terdaftar';
          break;
        case 'weak-password':
          msg = 'Kata sandi terlalu lemah';
          break;
        case 'invalid-email':
          msg = 'Format email tidak valid';
          break;
        case 'operation-not-allowed':
          msg = 'Email/Password sign-in tidak diaktifkan. Hubungi admin.';
          break;
        default:
          msg = 'Gagal daftar: ${e.message ?? "unknown error"}';
      }
      if (mounted) _showSnack(msg, Colors.redAccent);
    } on FirebaseException catch (e) {
      debugPrint('[Register] FirebaseException: ${e.code} - ${e.message}');
      if (e.code == 'permission-denied') {
        if (mounted) {
          _showSnack(
            'Firestore menolak akses. Periksa Firebase Console > Firestore > Security Rules.',
            Colors.redAccent,
          );
        }
      } else {
        if (mounted) _showSnack('Firebase error: ${e.message}', Colors.redAccent);
      }
    } catch (e, st) {
      debugPrint('[Register] Unexpected error: $e');
      debugPrint('[Register] Stack trace: $st');
      if (mounted) _showSnack('Terjadi kesalahan: $e', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _loading = false);
      debugPrint('[Register] Selesai (loading=false)');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Gradient header ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.headerEnd],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: SizedBox(
                  height: 52,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Daftar Akun',
                        style: GoogleFonts.manrope(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // ── Form ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _buildField('Nama Lengkap', _namaController, hint: 'Masukkan nama lengkap'),
                  _buildField('Email', _emailController, hint: 'email@kampus.ac.id', keyboardType: TextInputType.emailAddress),
                  if (_role == UserRole.pelapor)
                    _buildField('NIM', _nimController, hint: 'Nomor Induk Mahasiswa')
                  else ...[
                    _buildField('NIP / ID Staf', _nipController, hint: 'Nomor Induk Pegawai'),
                    _buildField('Divisi / Unit Kerja', _divisiController, hint: 'Contoh: Bagian Sarpras'),
                  ],
                  _buildField(
                    'Kata Sandi',
                    _passController,
                    hint: 'Minimal 6 karakter',
                    obscure: _obscurePass,
                    toggleObscure: () => setState(() => _obscurePass = !_obscurePass),
                  ),
                  _buildField(
                    'Konfirmasi Kata Sandi',
                    _konfirmasiController,
                    hint: 'Ulangi kata sandi',
                    obscure: _obscureKonfirmasi,
                    toggleObscure: () => setState(() => _obscureKonfirmasi = !_obscureKonfirmasi),
                  ),
                  const SizedBox(height: 16),
                  // Role
                  Text(
                    'DAFTAR SEBAGAI',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.muted, letterSpacing: 0.6),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _RoleChip(
                        label: 'Mahasiswa',
                        selected: _role == UserRole.pelapor,
                        onTap: () => setState(() => _role = UserRole.pelapor),
                      ),
                      const SizedBox(width: 8),
                      _RoleChip(
                        label: 'Staf Sarpras',
                        selected: _role == UserRole.sarpras,
                        onTap: () => setState(() => _role = UserRole.sarpras),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Daftar button
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
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity( 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _loading ? null : _register,
                          borderRadius: BorderRadius.circular(14),
                          child: Center(
                            child: _loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.person_add, color: Colors.white, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Daftar',
                                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Sudah punya akun? ',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted),
                      ),
                      GestureDetector(
                        onTap: _loading ? null : () => Navigator.pop(context),
                        child: Text(
                          'Masuk',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    VoidCallback? toggleObscure,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.muted, letterSpacing: 0.6),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(color: AppColors.muted, fontSize: 13),
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              suffixIcon: toggleObscure != null
                  ? IconButton(
                      icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.muted, size: 20),
                      onPressed: toggleObscure,
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RoleChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.navy : AppColors.white,
          border: Border.all(color: selected ? AppColors.navy : AppColors.line, width: 1.5),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.slate),
        ),
      ),
    );
  }
}
