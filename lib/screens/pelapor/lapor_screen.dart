import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../widgets/common_widgets.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'qr_scanner_screen.dart';
import 'preview_screen.dart';

class LaporScreen extends StatefulWidget {
  const LaporScreen({super.key});

  @override
  State<LaporScreen> createState() => _LaporScreenState();
}

class _LaporScreenState extends State<LaporScreen>
    with SingleTickerProviderStateMixin {
  String _selectedCampus = 'Kampus I';
String _selectedBuilding = 'Gedung B';
String _selectedRoom = 'Ruang 301';

bool _manualCampus = false;
bool _manualBuilding = false;
bool _manualRoom = false;

final _manualCampusController = TextEditingController();
final _manualBuildingController = TextEditingController();
final _manualRoomController = TextEditingController();
  ReportCategory? _selectedCategory;
  final TextEditingController _otherCategoryController =
    TextEditingController();
  bool _manualCategory = false;
final TextEditingController _manualCategoryController =
    TextEditingController();
  UrgencyLevel? _selectedUrgency;
  final _descController = TextEditingController();
  bool _photoAttached = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  // Menandai apakah lokasi terakhir diperbarui lewat scan QR (dipakai hanya
  // untuk tampilan badge "Terdeteksi", tidak mengubah logic apa pun).
  bool _locationFromQr = true;

  // Warna kuning untuk ikon QR, sesuai referensi desain.
  static const Color _qrYellow = Color(0xFFFBBF24);

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image =
          await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
          _photoAttached = true;
        });
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal membuka kamera: $e')));
    }
  }

  Future<void> _scanQR() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QRScannerScreen()),
    );
    if (result != null && result is String) {
      final parts = result.split('-');
      if (parts.length >= 2) {
        setState(() {
          _selectedCampus = parts[0].trim();
          _selectedBuilding = parts[0].trim();
          _selectedRoom = parts[1].trim();
          _manualCampus = false;
          _manualBuilding = false;
          _manualRoom = false;
          _locationFromQr = true;
        });
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Lokasi berhasil diperbarui dari QR Code',
                  style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.green));
      } else {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Format QR Code tidak dikenali',
                  style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.red));
      }
    }
  }

  String get _effectiveCampus =>
    _manualCampus ? _manualCampusController.text : _selectedCampus;
  String get _effectiveBuilding =>
      _manualBuilding ? _manualBuildingController.text : _selectedBuilding;
  String get _effectiveRoom =>
      _manualRoom ? _manualRoomController.text : _selectedRoom;

static const _campuses = [
  'Kampus I',
  'Kampus II',
  'Kampus III',
  'Kampus IV',
  'Kampus V',
  'Kampus VI',
  'Lokasi Lain',
];

  static const _buildings = [
    'Gedung A',
    'Gedung B',
    'Gedung C',
    'Gedung D',
    'Lokasi Lain'
  ];
  static const _rooms = [
    'Ruang 101',
    'Ruang 102',
    'Ruang 201',
    'Ruang 202',
    'Ruang 301',
    'Ruang 302',
    'Lab Mobile',
    'Lab Komputer',
    'Koridor Lt. 1',
    'Koridor Lt. 2',
    'Panel Listrik',
    'Toilet Lt. 1',
    'Toilet Lt. 2',
    'Lokasi Lain'
  ];

  void _submit() {
    if (_selectedCategory == null ||
    _selectedUrgency == null ||
    _descController.text.isEmpty ||
    (_selectedCategory == ReportCategory.lainnya &&
        _otherCategoryController.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Silakan lengkapi form terlebih dahulu')));
      return;
    }
    if ((_manualCampus && _manualCampusController.text.isEmpty) ||
        (_manualBuilding && _manualBuildingController.text.isEmpty) ||
        (_manualRoom && _manualRoomController.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Lengkapi lokasi manual terlebih dahulu')));
      return;
    }

    final effectiveCampus = _effectiveCampus;
    final effectiveBuilding = _effectiveBuilding;
    final effectiveRoom = _effectiveRoom;
    final floor = effectiveRoom.contains('Lt.')
        ? effectiveRoom.replaceAll(RegExp(r'.*Lt\.\s*'), 'Lt. ')
        : 'Lt. 1';
    final location = '$effectiveCampus ·$effectiveBuilding · $effectiveRoom';

    final report = Report(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '${_selectedCategory!.label} - $effectiveBuilding',
      location: location,
      building: effectiveBuilding,
      floor: floor,
      category: _selectedCategory!,
      otherCategory: _selectedCategory == ReportCategory.lainnya
    ? _otherCategoryController.text.trim()
    : null,
      urgency: _selectedUrgency!,
      status: _selectedUrgency == UrgencyLevel.darurat
          ? ReportStatus.darurat
          : ReportStatus.diterima,
      description: _descController.text,
      imagePath: _imageFile?.path,
      createdAt: DateTime.now(),
      history: [
        StatusHistory(
          status: _selectedUrgency == UrgencyLevel.darurat
              ? ReportStatus.darurat
              : ReportStatus.diterima,
          time: DateTime.now(),
          note: 'Laporan masuk ke sistem',
        )
      ],
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PreviewScreen(report: report)),
    );
  }

  @override
void dispose() {
  _manualBuildingController.dispose();
  _manualRoomController.dispose();

  _manualCategoryController.dispose();

  _descController.dispose();
  _otherCategoryController.dispose();
  _pulseController.dispose();
  super.dispose();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel('Lokasi'),
                  _buildLocationCard(),
                  const SectionLabel('Foto Kerusakan'),
                  _buildPhotoUpload(),
                  const SectionLabel('Kategori Kerusakan'),
                 Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [

   Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [

    Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ReportCategory.values.map((cat) {

        final selected = _selectedCategory == cat;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedCategory = cat;

              if (cat != ReportCategory.lainnya) {
                _otherCategoryController.clear();
              }
            });
          },

          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10),

            decoration: BoxDecoration(
              color: selected
                  ? AppColors.navy
                  : AppColors.white,

              border: Border.all(
                color: selected
                    ? AppColors.navy
                    : AppColors.line,
                width: selected ? 2 : 1.5,
              ),

              borderRadius: BorderRadius.circular(999),

              boxShadow: [
                BoxShadow(
                  color: (selected
                          ? AppColors.navy
                          : Colors.black)
                      .withOpacity(selected ? 0.18 : 0.04),
                  blurRadius: selected ? 10 : 4,
                  offset: Offset(0, selected ? 4 : 2),
                ),
              ],
            ),

            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [

                Text(
                  _categoryEmoji(cat.label),
                  style: const TextStyle(fontSize: 14),
                ),

                const SizedBox(width: 6),

                Text(
                  cat.label,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? Colors.white
                        : AppColors.slate,
                  ),
                ),

                if (selected)
                  const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Icon(
                      Icons.check_circle,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    ),

    if (_selectedCategory == ReportCategory.lainnya) ...[
      const SizedBox(height: 15),

      TextField(
        controller: _otherCategoryController,

        decoration: InputDecoration(
          hintText: "Tuliskan jenis kerusakan",

          filled: true,
          fillColor: Colors.white,

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
              color: AppColors.primary,
              width: 2,
            ),
          ),
        ),
      ),
    ],
  ],
),

    if (_manualCategory)

      Padding(

        padding: const EdgeInsets.only(top: 14),

        child: TextField(

          controller: _manualCategoryController,

          decoration: InputDecoration(

            hintText: "Masukkan kategori kerusakan",

            filled: true,

            fillColor: Colors.white,

            prefixIcon: const Icon(Icons.edit),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                  color: AppColors.primary,
                  width: 2),
            ),

          ),

        ),

      )

  ],
),
                  const SectionLabel('Tingkat Urgensi'),
                  Row(
                    children: UrgencyLevel.values.map((u) {
                      final selected = _selectedUrgency == u;
                      final isEmergency = u == UrgencyLevel.darurat;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedUrgency = u),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              // FIX: sama seperti chip kategori — curve tanpa
                              // overshoot supaya tidak crash.
                              curve: Curves.easeOutCubic,
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: selected
                                    ? (isEmergency
                                        ? AppColors.red
                                        : AppColors.navy)
                                    : AppColors.white,
                                border: Border.all(
                                  color: isEmergency
                                      ? AppColors.red
                                      : (selected
                                          ? AppColors.navy
                                          : AppColors.line),
                                  width: isEmergency ? 2 : (selected ? 2 : 1.5),
                                ),
                                borderRadius: BorderRadius.circular(999),
                                // FIX: boxShadow selalu ada, tidak pernah null.
                                boxShadow: [
                                  BoxShadow(
                                    color: (selected
                                            ? (isEmergency
                                                ? AppColors.red
                                                : AppColors.navy)
                                            : Colors.black)
                                        .withOpacity(selected ? 0.18 : 0.04),
                                    blurRadius: selected ? 10 : 4,
                                    offset: Offset(0, selected ? 4 : 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(_urgencyEmoji(u.label),
                                      style: const TextStyle(fontSize: 13)),
                                  const SizedBox(width: 5),
                                  Text(
                                    u.label,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      fontWeight: (selected || isEmergency)
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      color: selected
                                          ? Colors.white
                                          : (isEmergency
                                              ? AppColors.red
                                              : AppColors.slate),
                                    ),
                                  ),
                                  AnimatedSize(
                                    duration: const Duration(milliseconds: 180),
                                    curve: Curves.easeOutCubic,
                                    child: selected
                                        ? const Padding(
                                            padding: EdgeInsets.only(left: 5),
                                            child: Icon(
                                                Icons.check_circle_rounded,
                                                size: 13,
                                                color: Colors.white),
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SectionLabel('Deskripsi'),
                  TextField(
                    controller: _descController,
                    maxLines: 5,
                    style: GoogleFonts.inter(
                        fontSize: 13.5, color: AppColors.slate),
                    decoration: InputDecoration(
                      hintText: 'Jelaskan kondisi kerusakan secara singkat...',
                      hintStyle: GoogleFonts.inter(
                          color: AppColors.muted, fontSize: 13),
                      filled: true,
                      fillColor: AppColors.white,
                      contentPadding: const EdgeInsets.all(16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.line),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.line),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _buildSubmitButton(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(bottom: 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.headerEnd],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Material(
                    color: Colors.white.withOpacity(0.16),
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 18),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Form Laporan',
                      style: GoogleFonts.manrope(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Laporkan kerusakan fasilitas',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Kartu Lokasi — ikon QR kuning + badge deteksi, lalu opsi isi manual
  // yang lebih rapi dengan toggle chip eksplisit (bukan otomatis "nyelonong"
  // saat memilih "Lokasi Lain").
  // ---------------------------------------------------------------------
  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DETEKSI OTOMATIS',
            style: GoogleFonts.inter(
                fontSize: 11,
                letterSpacing: 0.6,
                color: AppColors.muted,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            'Scan QR Ruangan',
            style: GoogleFonts.manrope(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.slate),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScaleTransition(
                scale: Tween(begin: 0.95, end: 1.06).animate(
                  CurvedAnimation(
                      parent: _pulseController, curve: Curves.easeInOut),
                ),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFFFE7A0)),
                  ),
                  child: const Icon(Icons.qr_code_2_rounded,
                      color: _qrYellow, size: 30),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _locationFromQr
                            ? AppColors.greenBg
                            : AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _locationFromQr
                                ? Icons.check_circle
                                : Icons.tune_rounded,
                            size: 11,
                            color: _locationFromQr
                                ? AppColors.green
                                : AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _locationFromQr ? 'Terdeteksi' : 'Dipilih Manual',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _locationFromQr
                                  ? AppColors.green
                                  : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$_effectiveCampus - $_effectiveBuilding - $_effectiveRoom',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _scanQR,
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
              label: Text(
                'Scan QR Baru',
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(child: Divider(color: AppColors.line, height: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'atau isi manual ✍️',
                  style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted),
                ),
              ),
              const Expanded(child: Divider(color: AppColors.line, height: 1)),
            ],
          ),
          const SizedBox(height: 16),
          _buildLocationFieldCard(
  icon: Icons.location_city_rounded,
  label: 'Kampus',
  value: _selectedCampus,
  items: _campuses,
  isManual: _manualCampus,
  controller: _manualCampusController,
  accentColor: const Color(0xFF06B6D4),
  bgColor: const Color(0xFFEFFBFF),
  borderColor: const Color(0xFFC8F2FF),
  onDropdownChanged: (v) {
    setState(() {
      if (v == 'Lokasi Lain') {
        _manualCampus = true;
      } else {
        _selectedCampus = v!;
      }
      _locationFromQr = false;
    });
  },
  onToggleManual: () => setState(() {
    _manualCampus = !_manualCampus;
    if (!_manualCampus) {
      _manualCampusController.clear();
    }
    _locationFromQr = false;
  }),
),

const SizedBox(height: 12),
          _buildLocationFieldCard(
            icon: Icons.apartment_rounded,
            label: 'Gedung',
            value: _selectedBuilding,
            items: _buildings,
            isManual: _manualBuilding,
            controller: _manualBuildingController,
            accentColor: const Color(
                0xFF6366F1), // indigo — beda dari teal supaya tidak monoton
            bgColor: const Color(0xFFF0F1FE),
            borderColor: const Color(0xFFDCE0FB),
            onDropdownChanged: (v) {
              setState(() {
                if (v == 'Lokasi Lain') {
                  _manualBuilding = true;
                } else {
                  _selectedBuilding = v!;
                }
                _locationFromQr = false;
              });
            },
            onToggleManual: () => setState(() {
              _manualBuilding = !_manualBuilding;
              if (!_manualBuilding) _manualBuildingController.clear();
              _locationFromQr = false;
            }),
          ),
          const SizedBox(height: 12),
          _buildLocationFieldCard(
            icon: Icons.meeting_room_rounded,
            label: 'Ruangan',
            value: _selectedRoom,
            items: _rooms,
            isManual: _manualRoom,
            controller: _manualRoomController,
            accentColor:
                const Color(0xFFF59E0B), // amber — kontras hangat dengan Gedung
            bgColor: const Color(0xFFFFF6E9),
            borderColor: const Color(0xFFFCE3B4),
            onDropdownChanged: (v) {
              setState(() {
                if (v == 'Lokasi Lain') {
                  _manualRoom = true;
                } else {
                  _selectedRoom = v!;
                }
                _locationFromQr = false;
              });
            },
            onToggleManual: () => setState(() {
              _manualRoom = !_manualRoom;
              if (!_manualRoom) _manualRoomController.clear();
              _locationFromQr = false;
            }),
          ),
        ],
      ),
    );
  }

  /// Kartu field lokasi (Gedung / Ruangan) — masing-masing punya warna aksen
  /// sendiri supaya tidak numpuk jadi satu warna yang monoton, dengan toggle
  /// segmented yang jelas antara "pilih dari daftar" dan "isi manual".
  Widget _buildLocationFieldCard({
    required IconData icon,
    required String label,
    required String value,
    required List<String> items,
    required bool isManual,
    required TextEditingController controller,
    required Color accentColor,
    required Color bgColor,
    required Color borderColor,
    required ValueChanged<String?> onDropdownChanged,
    required VoidCallback onToggleManual,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      // FIX: easeOutCubic (tidak overshoot) — container ini tidak punya
      // boxShadow, tapi tetap disamakan supaya seluruh animasi implicit di
      // layar ini konsisten & aman.
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accentColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: accentColor),
              ),
              const Spacer(),
              _buildManualToggle(
                  isManual: isManual,
                  accentColor: accentColor,
                  onTap: onToggleManual),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isManual
                ? TextField(
                    key: ValueKey('manual-$label'),
                    controller: controller,
                    autofocus: true,
                    style: GoogleFonts.inter(
                        fontSize: 13.5,
                        color: AppColors.slate,
                        fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: accentColor.withOpacity(0.4)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: accentColor.withOpacity(0.4)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: accentColor, width: 1.5),
                      ),
                      hintText: 'Tulis $label secara manual',
                      hintStyle: GoogleFonts.inter(
                          fontSize: 12.5, color: AppColors.muted),
                    ),
                    onChanged: (_) => setState(() {}),
                  )
                :  DropdownButtonFormField<String>(
    key: ValueKey('dropdown-$label'),
    value: value,
    isExpanded: true,
    icon: Icon(
      Icons.keyboard_arrow_down_rounded,
      color: accentColor,
    ),
    decoration: InputDecoration(
      filled: true,
      fillColor: Colors.white,

      isDense: true,

      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: accentColor.withOpacity(0.35),
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: accentColor,
          width: 1.8,
        ),
      ),
    ),

    style: GoogleFonts.inter(
      fontSize: 13.5,
      color: AppColors.slate,
      fontWeight: FontWeight.w600,
    ),

    dropdownColor: Colors.white,

    items: items.map((v) {
      return DropdownMenuItem(
        value: v,
        child: Text(
          v,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }).toList(),

    onChanged: onDropdownChanged,
),
          ),
        ],
      ),
    );
  }

  /// Toggle segmented kecil (📋 daftar / ✏️ manual) supaya jelas mode mana
  /// yang aktif, bentuknya pill kecil dengan latar berbeda saat aktif.
  Widget _buildManualToggle({
    required bool isManual,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isManual ? Icons.list_alt_rounded : Icons.edit_rounded,
                size: 13,
                color: accentColor,
              ),
              const SizedBox(width: 4),
              Text(
                isManual ? 'Pilih daftar' : 'Isi manual',
                style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: accentColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Upload foto — dashed border, logic pick image tidak diubah.
  // ---------------------------------------------------------------------
  Widget _buildPhotoUpload() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 170,
        decoration: BoxDecoration(
          color: _photoAttached ? AppColors.greenBg : AppColors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: CustomPaint(
          painter: _LaporDashedBorderPainter(
            color: _photoAttached ? AppColors.green : AppColors.primary,
          ),
          child: _imageFile != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(_imageFile!, fit: BoxFit.cover),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.35),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 10,
                        top: 10,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: AppColors.green,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.green.withOpacity(0.4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.check,
                              color: Colors.white, size: 16),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        bottom: 10,
                        child: Text(
                          'Ketuk untuk ganti foto',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(Icons.camera_alt_outlined,
                            size: 28, color: AppColors.primary),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Ketuk untuk buka kamera 📸',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Foto membantu tim kami menilai kerusakan',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Tombol kirim — satu tombol saja (gantikan "Preview Laporan" +
  // "Scan QR Lokasi" yang sebelumnya bentrok dengan bottom nav aplikasi).
  // ---------------------------------------------------------------------
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.buttonTop, AppColors.primary],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _submit,
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Kirim Laporan',
                    style: GoogleFonts.inter(
                      fontSize: 15,
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
    );
  }

  // ---------------------------------------------------------------------
  // Emoji kecil biar chip kategori/urgensi terasa lebih hidup & lucu.
  // Murni tampilan — tidak memengaruhi data ReportCategory/UrgencyLevel.
  // ---------------------------------------------------------------------
  String _categoryEmoji(String label) {
    final l = label.toLowerCase();
    if (l.contains('ac')) return '❄️';
    if (l.contains('listrik')) return '⚡';
    if (l.contains('proyektor')) return '📽️';
    if (l.contains('furnitur')) return '🪑';
    if (l.contains('toilet')) return '🚻';
    return '🛠️';
  }

  String _urgencyEmoji(String label) {
    final l = label.toLowerCase();
    if (l.contains('ringan')) return '🙂';
    if (l.contains('sedang')) return '😐';
    if (l.contains('darurat')) return '🚨';
    return '•';
  }
}

// ---------------------------------------------------------------------
// Custom painter garis putus-putus untuk kotak unggah foto.
// ---------------------------------------------------------------------
class _LaporDashedBorderPainter extends CustomPainter {
  _LaporDashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const double dashWidth = 8;
    const double dashSpace = 8;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
      const Radius.circular(18),
    );

    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LaporDashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}
