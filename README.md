# Alarm Ekstrem (Flutter Android)

Aplikasi Alarm Anti-Kesiangan Ekstrem untuk Mahasiswa dengan Misi Bertingkat:
1. **Misi 1: Matematika (2 Soal Penjumlahan Acak)**
2. **Misi 2: Deteksi Wajah (Google ML Kit)** – Validasi mata terbuka lebar selama 3 detik stabil + Screen Flash penerang kamar gelap.
3. **Emergency Override** – 3 soal penjumlahan tambahan jika kamera bermasalah.
4. **Peringatan Darurat SMS (> 5 Menit)** – Mengirim SMS otomatis ke nomor teman via `telephony` jika alarm dibiarkan berdering.
5. **Offline-First & Supabase Logging** – Log dicatat di penyimpanan lokal dan otomatis di-sync ke Supabase saat online.

---

## Struktur Folder Proyek
```text
lib/
├── core/
│   ├── constants/
│   │   └── app_constants.dart       # Konstanta & konfigurasi kunci
│   └── services/
│       ├── alarm_service.dart       # Pengaturan Alarm, Full-Screen Intent & Volume
│       ├── device_service.dart      # UUID perangkat persisten
│       ├── sms_service.dart         # Pengirim SMS darurat otomatis
│       └── supabase_service.dart    # Offline-first logging & sync ke Supabase
├── features/
│   ├── alarm/screens/
│   │   ├── home_screen.dart         # Dashboard pengaturan jam, nomor teman, & tes
│   │   └── alarm_ring_screen.dart   # Layar penuh saat alarm berdering (anti-back)
│   ├── history/
│   │   └── history_screen.dart      # Daftar riwayat bangun tidur
│   └── missions/
│       ├── math_mission_view.dart   # Misi 2 soal penjumlahan + custom keypad
│       ├── face_mission_view.dart   # Misi scan wajah ML Kit + screen flash
│       └── emergency_override_view.dart # Fallback 3 soal tambahan
└── main.dart
```

---

## Cara Menjalankan & Build APK

### 1. Inisialisasi Dependensi
Buka terminal pada folder proyek ini:
```bash
flutter pub get
```

### 2. Jalankan di Ponsel Fisik (Rekomendasi)
Karena fitur ini menguji kamera depan, audio stream alarm, dan SMS native:
```bash
flutter run
```

### 3. Build File APK
Untuk menghasilkan file installer `.apk` yang siap dipasang di HP Anda:
```bash
flutter build apk --release
```
File APK akan berada di: `build/app/outputs/flutter-apk/app-release.apk`.

---

## Konfigurasi Supabase
1. Buka dashboard Supabase Anda.
2. Masuk ke **SQL Editor** dan jalankan DDL yang ada pada file `architecture_blueprint.md`.
3. Di dalam aplikasi, tekan ikon **Settings (Gerigi)** pada AppBar atas dan masukkan **Project URL** dan **Anon Key** Anda.
