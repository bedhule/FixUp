# FixUp — Aplikasi Pelaporan Kerusakan Fasilitas Kampus

Aplikasi Flutter untuk melaporkan dan memantau kerusakan fasilitas kampus secara digital.

---

## Fitur

### 🎓 Sisi Pelapor (Mahasiswa)
- **Login** — Masuk dengan email kampus
- **Home** — Ringkasan laporan & akses cepat
- **Scan QR Lokasi** — Deteksi lokasi otomatis via QR ruangan
- **Form Lapor Kerusakan** — Foto, kategori, urgensi, deskripsi
- **Konfirmasi Terkirim** — Status awal: Diterima
- **Riwayat Laporan** — Semua laporan & statusnya dengan filter
- **Detail & Lacak Status** — Timeline Diterima → Diproses → Selesai
- **Rating & Feedback** — Nilai penanganan setelah selesai
- **Notifikasi** — Update otomatis perubahan status
- **Profil** — Data akun & pengaturan

### 🛠️ Sisi Staf Sarpras
- **Dashboard** — Statistik & daftar laporan masuk
- **Filter Laporan** — Berdasarkan gedung, kategori, urgensi
- **Kelola & Ubah Status** — Diterima → Diproses → Selesai
- **Papan Transparansi** — Ringkasan publik

### 📢 Papan Publik
- Ringkasan status tanpa login

---

## Setup

### Requirements
- Flutter SDK `>=3.0.0`
- Dart SDK `>=3.0.0`

### Instalasi

```bash
# Clone / buat folder project
cd fixup_app

# Install dependencies
flutter pub get

# Jalankan di emulator / device
flutter run
```

### Dependencies
```yaml
google_fonts: ^6.1.0        # Font Inter & Manrope
flutter_animate: ^4.3.0     # Animasi halus
shared_preferences: ^2.2.2  # Penyimpanan lokal
image_picker: ^1.0.7        # Upload foto
intl: ^0.19.0               # Format tanggal bahasa Indonesia
provider: ^6.1.1            # State management
```

---

## Struktur Folder

```
lib/
├── main.dart
├── theme/
│   └── app_theme.dart        # Warna & tipografi
├── models/
│   └── models.dart           # Model data & data contoh
├── widgets/
│   └── common_widgets.dart   # Widget reusable
└── screens/
    ├── login_screen.dart
    ├── publik_screen.dart
    ├── pelapor/
    │   ├── home_screen.dart
    │   ├── lapor_screen.dart
    │   ├── sukses_screen.dart
    │   ├── riwayat_screen.dart
    │   ├── detail_screen.dart
    │   ├── rating_screen.dart
    │   ├── notif_screen.dart
    │   └── profil_screen.dart
    └── sarpras/
        ├── sarpras_dashboard_screen.dart
        └── sarpras_detail_screen.dart
```

---

## Alur Navigasi

```
Login
  ├── Mahasiswa → HomeScreen (bottom nav)
  │     ├── LaporScreen → SuksesScreen → DetailScreen
  │     ├── RiwayatScreen → DetailScreen → RatingScreen
  │     ├── NotifScreen
  │     └── ProfilScreen
  └── Staf Sarpras → SarprasDashboardScreen (bottom nav)
        ├── SarprasDetailScreen
        ├── PublikScreen
        └── NotifScreen
```

---

## Palet Warna

| Nama      | Hex       | Kegunaan               |
|-----------|-----------|------------------------|
| Navy      | `#102A56` | Heading, brand         |
| Blue      | `#2F6FED` | Aksi utama, aktif      |
| Blue Light| `#E8F0FE` | Background chip, icon  |
| Ice       | `#F4F8FD` | Background halaman     |
| Green     | `#1FAE6B` | Status selesai         |
| Amber     | `#E5A100` | Status diterima        |
| Red       | `#E2453C` | Status darurat, error  |
