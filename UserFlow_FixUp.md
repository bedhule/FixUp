# User Flow Aplikasi FixUp

## Alur Utama

``` text
Buka Aplikasi FixUp
        │
        ▼
Papan Transparansi (Landing Page)
- Statistik laporan
- Grafik penyelesaian
- Laporan terbaru
- Filter gedung
- Tombol Login

        │
        ├── Tetap sebagai Guest
        │       └── Melihat informasi publik
        │
        └── Login
                │
                ▼
            Pilih Peran
         ┌───────────────┐
         │ Mahasiswa     │
         │ Staff Sarpras │
         └───────────────┘
```

------------------------------------------------------------------------

## Flow Mahasiswa

``` text
Login
  │
  ▼
Home
  │
  ▼
Scan QR Lokasi
(atau pilih gedung manual)
  │
  ▼
Form Laporan
- Foto
- Lokasi
- Kategori
- Urgensi
- Deskripsi
  │
  ▼
Preview
  │
  ▼
Kirim Laporan
  │
  ▼
Notifikasi Berhasil
  │
  ▼
Detail Laporan
Diterima → Diproses → Selesai
  │
  ▼
Rating & Feedback
  │
  ▼
Riwayat Laporan
  │
  ▼
Profil & Pengaturan
```

------------------------------------------------------------------------

## Flow Staff Sarpras

``` text
Login
  │
  ▼
Dashboard
  │
  ▼
Filter Laporan
  │
  ▼
Smart Merging
  │
  ▼
Detail Laporan
  │
  ▼
Update Status
(Diterima / Diproses / Selesai)
  │
  ▼
Tambah Catatan
  │
  ▼
Simpan
  │
  ▼
Notifikasi Otomatis ke Mahasiswa
```

------------------------------------------------------------------------

## Flow Guest

``` text
Landing Page
  │
  ├── Statistik
  ├── Grafik
  ├── Laporan Terbaru
  ├── Filter Gedung
  ├── Search
  └── Login
```

------------------------------------------------------------------------

## Sinkronisasi Antar Role

``` text
Mahasiswa
    │
Kirim Laporan
    │
    ▼
Database
 ▲       │
 │       ▼
 │   Update Status
 │   oleh Sarpras
 │       │
 └───────┘
    │
    ▼
Notifikasi ke Mahasiswa

Seluruh perubahan status otomatis diperbarui pada
Papan Transparansi sehingga data publik selalu sinkron.
```

## Catatan UX

-   Landing page adalah **Papan Transparansi**, bukan halaman login.
-   Guest dapat melihat informasi tanpa autentikasi.
-   Login hanya diperlukan untuk Mahasiswa dan Staff Sarpras.
-   QR Scan memiliki fallback **Pilih Gedung Manual**.
-   Tersedia halaman **Preview** sebelum laporan dikirim.
-   Update status memicu notifikasi real-time dan pembaruan papan
    transparansi.
