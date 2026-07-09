import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../firebase/firebase_helper.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _nameController = TextEditingController();
  final _nimController = TextEditingController();
  final _roleController = TextEditingController();
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  bool _loading = true;
  bool _saving = false;
  String? _photoUrl;
  String? _uid;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final helper = FirebaseHelper();
    final user = helper.currentUser;
    if (user == null) {
      _nameController.text = 'Abdul Hakim';
      _nimController.text = '2400016015';
      _roleController.text = 'Mahasiswa';
      if (mounted) setState(() => _loading = false);
      return;
    }
    _uid = user.uid;
    try {
      final data = await helper.getUserData(user.uid);
      if (data != null) {
        _nameController.text = data['name'] ?? user.displayName ?? '';
        _nimController.text = data['nim'] ?? '';
        _roleController.text = data['role'] == 'sarpras' ? 'Staf Sarpras' : 'Mahasiswa';
        _photoUrl = data['photoUrl'];
      } else {
        _nameController.text = user.displayName ?? '';
      }
    } catch (e) {
      debugPrint('[AccountSettings] Error load user data: $e');
      _nameController.text = user.displayName ?? 'Abdul Hakim';
      _nimController.text = '2400016015';
      _roleController.text = 'Mahasiswa';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (image != null) {
        setState(() => _profileImage = File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat foto: $e')));
      }
    }
  }

  Future<void> _save() async {
    if (_uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan login terlebih dahulu'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final helper = FirebaseHelper();
      String? photoUrl = _photoUrl;
      if (_profileImage != null) {
        photoUrl = await helper.uploadProfileImage(_uid!, _profileImage!.path);
      }
      await helper.updateUserProfile(
        uid: _uid!,
        name: _nameController.text.trim(),
        nim: _nimController.text.trim(),
        photoUrl: photoUrl,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui'),
            backgroundColor: AppColors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nimController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _nameController.text.isNotEmpty
        ? _nameController.text.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join()
        : 'AH';

    return Scaffold(
      backgroundColor: AppColors.ice,
      appBar: AppBar(
        title: const Text('Pengaturan Akun'),
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: AppColors.blueLight,
                            borderRadius: BorderRadius.circular(44),
                            image: _profileImage != null
                                ? DecorationImage(image: FileImage(_profileImage!), fit: BoxFit.cover)
                                : (_photoUrl != null && _photoUrl!.isNotEmpty
                                    ? DecorationImage(
                                        image: NetworkImage(_photoUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null),
                          ),
                          child: _profileImage == null && (_photoUrl == null || _photoUrl!.isEmpty)
                              ? Center(
                                  child: Text(
                                    initials,
                                    style: GoogleFonts.manrope(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.blue,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ketuk untuk ganti foto',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      border: Border.all(color: AppColors.line),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('NAMA LENGKAP', style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.muted, letterSpacing: 0.6)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: 'Nama lengkap',
                            filled: true,
                            fillColor: AppColors.ice,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.line)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('NIM / NIP', style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.muted, letterSpacing: 0.6)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _nimController,
                          decoration: InputDecoration(
                            hintText: 'Nomor induk',
                            filled: true,
                            fillColor: AppColors.ice,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.line)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('ROLE', style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.muted, letterSpacing: 0.6)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _roleController,
                          readOnly: true,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.ice,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.line)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: _saving ? 'Menyimpan...' : 'Simpan Perubahan',
                    onPressed: _saving ? null : () => _save(),
                    icon: Icons.save,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
