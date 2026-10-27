# RekaDana — Mobile

Aplikasi Android untuk anggota panitia dan bendahara kegiatan sekolah. Menangani pengajuan pengeluaran lapangan, upload bukti, dan review approval secara mobile. Mengonsumsi REST API dari aplikasi web RekaDana.

## Stack

- **Framework:** Flutter (Dart)
- **Target platform:** Android (API level 21+)
- **HTTP client:** Dio
- **Auth storage:** flutter_secure_storage
- **Image picker:** image_picker
- **Font:** Plus Jakarta Sans (Google Fonts)

## Struktur

```
lib/
  core/
    constants/      # Warna (AppColors), tema (AppTheme), URL base
    network/        # ApiClient (Dio singleton, token interceptor, error mapping)
    storage/        # SecureStorageService (token, base URL)
    utils/          # CurrencyFormatter, DateFormatter
    widgets/        # StateViews (loading, error, empty), StatusBadge
  features/
    auth/           # Login screen, auth service, user model
    organization/   # Org selection, events list, models
    expenses/       # Expense list, create, detail, service, models
    approval/       # Bendahara review screen
  main.dart
```

## Menjalankan secara lokal

### Prasyarat

- Flutter SDK ≥ 3.12
- Android emulator atau device fisik

### Setup

```bash
# Install dependencies
flutter pub get

# Pastikan base URL server sudah dikonfigurasi
# Buka lib/core/constants/ dan sesuaikan URL jika perlu

# Jalankan di emulator/device
flutter run
```

### Perintah lain

```bash
flutter analyze         # Static analysis
flutter test            # Unit & widget tests
flutter build apk       # Build APK release
```

## Konfigurasi server

Aplikasi membaca base URL dari `SecureStorageService`. Untuk development, arahkan ke server lokal Next.js (`http://10.0.2.2:3000` dari emulator Android).

## Peran pengguna

| Role | Fitur utama di mobile |
|------|----------------------|
| Panitia/Anggota | Ajukan pengeluaran, upload bukti, pantau status |
| Bendahara | Review dan approve/reject permintaan pengeluaran |
| Ketua Kegiatan | Lihat status kegiatan dan ringkasan keuangan |

## Repo terkait

- [`RekaDana`](https://github.com/arsa-sans/RekaDana) — Web dashboard dan backend API
