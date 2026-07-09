import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../firebase/firebase_helper.dart';
import '../models/models.dart';
import 'pelapor/home_screen.dart';
import 'sarpras/sarpras_dashboard_screen.dart';

class CompleteProfileScreen extends StatefulWidget {
  final UserCredential cred;
  const CompleteProfileScreen({super.key, required this.cred});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _namaController = TextEditingController();
  final _nimController = TextEditingController();
  final _nipController = TextEditingController();
  final _divisiController = TextEditingController();
  final _emailController = TextEditingController();
  bool _loading = false;
  UserRole _role = UserRole.pelapor;

  @override
  void initState() {
    super.initState();
    final user = widget.cred.user;
    _namaController.text = user?.displayName ?? '';
    _emailController.text = user?.email ?? '';
  }

  @override
  void dispose() {
    _namaController.dispose();
    _nimController.dispose();
    _nipController.dispose();
    _divisiController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _showSnack(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: const TextStyle(color: Colors.white)), backgroundColor: bg),
    );
  }

  Future<void> _save() async {
    final nama = _namaController.text.trim();
    final email = _emailController.text.trim();

    if (nama.isEmpty) {
      _showSnack('Nama lengkap harus diisi', Colors.redAccent);
      return;
    }

    String? nim, nip, divisi;
    if (_role == UserRole.pelapor) {
      nim = _nimController.text.trim();
      if (nim.isEmpty) {
        _showSnack('NIM harus diisi', Colors.redAccent);
        return;
      }
    } else {
      nip = _nipController.text.trim();
      divisi = _divisiController.text.trim();
      if (nip.isEmpty) {
        _showSnack('NIP harus diisi', Colors.redAccent);
        return;
      }
      if (divisi.isEmpty) {
        _showSnack('Divisi harus diisi', Colors.redAccent);
        return;
      }
    }

    setState(() => _loading = true);
    try {
      final uid = widget.cred.user!.uid;
      await FirebaseHelper().createUserDocument(
        uid: uid,
        name: nama,
        email: email,
        role: _role,
        nim: nim,
        nip: nip,
        divisi: divisi,
      );
      await widget.cred.user!.updateDisplayName(nama);

      if (!mounted) return;
      _showSnack('Profil berhasil dilengkapi!', AppColors.green);

      if (_role == UserRole.sarpras) {
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
    } catch (e) {
      if (mounted) _showSnack('Gagal menyimpan: $e', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Lengkapi Profil'),
        backgroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.line),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pilih peran kamu untuk mulai menggunakan FixUp',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 20),
            // Role chips
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
            const SizedBox(height: 20),
            _buildField('Nama Lengkap', _namaController, hint: 'Nama lengkap'),
            _buildField('Email', _emailController, hint: 'email@kampus.ac.id', readOnly: true),
            if (_role == UserRole.pelapor)
              _buildField('NIM', _nimController, hint: 'Nomor Induk Mahasiswa')
            else ...[
              _buildField('NIP / ID Staf', _nipController, hint: 'Nomor Induk Pegawai'),
              _buildField('Divisi / Unit Kerja', _divisiController, hint: 'Contoh: Bagian Sarpras'),
            ],
            const SizedBox(height: 24),
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
                    onTap: _loading ? null : _save,
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
                          : Text(
                              'Simpan & Mulai',
                              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {String? hint, bool readOnly = false}) {
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
            readOnly: readOnly,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(color: AppColors.muted, fontSize: 13),
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
