# RekaDana Mobile — Tasks & Rencana Perbaikan

> Dokumen ini adalah hasil analisis menyeluruh dari proyek `rekadana_mobile` per 21 November 2026.
> Mencakup audit alur aplikasi, koneksi database Neon, dan rencana peningkatan tampilan UI.
> Antislop: `during` — berlaku sepanjang pengerjaan.

---

## Ringkasan Hasil Analisis

### Alur Aplikasi (App Flow)

```
Login / Register
    └── OrgSelectionScreen         ← Pilih organisasi & lihat peran
         └── EventsListScreen      ← Daftar kegiatan + ringkasan finansial 4 metrik
              ├── ScenarioListScreen
              │    ├── ScenarioCreateScreen
              │    └── ScenarioItemFormScreen
              ├── BudgetVersionListScreen
              │    └── BudgetVersionDetailScreen   ← Approve/reject anggaran (Bendahara)
              ├── ExpenseCreateScreen              ← Ajukan pengeluaran lapangan
              ├── ExpenseListScreen                ← Filter status + ringkasan
              │    └── ExpenseDetailScreen         ← Upload bukti, catat bayar, reversal
              └── BendaharaReviewScreen            ← Review dua tab: pending & riwayat
```

### Status Koneksi Database (Neon PostgreSQL — ap-southeast-1)

**Project:** `divine-brook-75737818` — RekaDana

| Tabel | Jumlah Data | Status |
|-------|------------|--------|
| `organizations` | 25 | Aktif |
| `events` | 11 | Aktif |
| `users` | >10 (seed realistis) | Aktif |
| `memberships` | Terisi | Aktif |
| `expense_requests` | 6 | Aktif |
| `budget_versions` | Beberapa approved | Aktif |
| `budget_scenarios` | 16 | Aktif |
| `payments` | 9 | Aktif |
| `evidence_files` | **0** | Kosong (tidak ada file tersimpan) |
| `audit_logs` | Ada | Aktif |

**Temuan penting:** Tabel `evidence_files` kosong. Upload bukti transaksi belum pernah berhasil tersimpan di production — kemungkinan Neon Object Storage belum dikonfigurasi atau endpoint tidak aktif.

---

## Temuan Bug & Masalah Fungsional

### KRITIS

| # | Masalah | Lokasi | Dampak |
|---|---------|--------|--------|
| B-01 | `evidence_files` kosong di DB — upload bukti tidak tersimpan ke Neon Object Storage | `expense_service.dart`, `ApiEndpoints.evidence` | Fitur upload bukti tidak berfungsi di production |
| B-02 | `AppColors` tidak selaras dengan `DESIGN.md` — menggunakan Indigo/Purple (`#4F46E5`) bukan Forest Green (`#153D35`) | `app_colors.dart`, `app_theme.dart` | Identitas visual brand tidak konsisten |
| B-03 | `AppTheme.moneyStyle` menggunakan `JetBrains Mono` — DESIGN.md melarang font mono terpisah, cukup `tabular-nums` | `app_theme.dart` L148-163 | Melanggar panduan tipografi DESIGN.md |
| B-04 | `BendaharaReviewScreen` tidak wrapping `TabBarView` dalam `Expanded` yang benar — body tidak di-refresh saat tab switch | `bendahara_review_screen.dart` L199 | Konten tab bisa blank saat state berubah |

### SEDANG

| # | Masalah | Lokasi | Dampak |
|---|---------|--------|--------|
| B-05 | `RejectionReasonDialog.show()` di `BendaharaReviewScreen` belum diimpor secara eksplisit — dipanggil tapi class-nya berada di `budget_version_list_screen.dart` | `bendahara_review_screen.dart` L127 | Potential runtime error jika dipindah file |
| B-06 | Hardcoded warna hex inline di beberapa widget (misalnya `const Color(0xFFDC2626)` di scenario_list_screen) — tidak menggunakan token dari `AppColors` | `scenario_list_screen.dart`, `expense_detail_screen.dart` | Susah maintenance, inkonsisten |
| B-07 | `AppButton` tidak mendukung ukuran `small` / `compact` — tombol selalu `double.infinity` width, tidak cocok untuk inline actions | `app_button.dart` | Layout double-button di card jadi cramped |
| B-08 | `EventsListScreen` memanggil `_loadEventReport` untuk setiap event secara paralel tanpa debounce — bisa overload saat banyak event | `events_list_screen.dart` L71-74 | Performance issue |
| B-09 | Form `_showApproveDialog` di `ExpenseDetailScreen` tidak menggunakan `AppTextField` / `InputDecoration` dari tema — raw `TextField` tanpa styling konsisten | `expense_detail_screen.dart` L345 | Inkonsisten visual |

### RINGAN

| # | Masalah | Lokasi | Dampak |
|---|---------|--------|--------|
| B-10 | `GestureDetector` untuk link "Daftar akun baru" di `LoginScreen` — lebih baik `TextButton` agar aksesibilitas keyboard terjamin | `login_screen.dart` L301 | Tidak bisa diakses keyboard |
| B-11 | `SnackBar` backgroundColor untuk sukses approve menggunakan `AppColors.statusApprovedBg` (hijau muda) — teks putih tidak kontras | `scenario_list_screen.dart` L97 | WCAG contrast fail |
| B-12 | Tidak ada `Semantics`/`ExcludeSemantics` pada `StatusBadge` — screen reader membaca ikon dan teks terpisah | `status_badge.dart` | Aksesibilitas kurang |
| B-13 | `register_screen.dart` belum diaudit — perlu cek konsistensi form validation dan navigasi | `register_screen.dart` | Belum diverifikasi |

---

## Temuan UI — Tidak Sesuai DESIGN.md

### Penyimpangan Palet Warna (KRITIS)

Seluruh `AppColors` menggunakan palet **Indigo/Purple** (AI default) bukan palet **Forest Green** yang ditetapkan DESIGN.md:

| Token DESIGN.md | Hex yang Benar | Yang Ada Sekarang | Di File |
|----------------|---------------|-------------------|---------|
| `color-forest` (primary) | `#153D35` | `#4338CA` (primary700) | `app_colors.dart` |
| `color-growth` (accent) | `#35B88A` | `#6366F1` (primary500) | `app_colors.dart` |
| `color-mint` (bg ringan) | `#EAF5F0` | `#EEF2FF` (primary50) | `app_colors.dart` |
| `color-cloud` (bg utama) | `#F6F8F7` | `#F8FAFC` (surfaceMuted) | `app_colors.dart` |
| `color-border` | `#D1E8DF` | `#E2E8F0` | `app_colors.dart` |

### Penyimpangan Komponen

| Komponen | Yang Seharusnya | Yang Ada |
|----------|----------------|----------|
| Tombol primary | bg `#153D35`, text putih, radius 6px | bg Indigo-700, radius 8px |
| Tombol accent | bg `#35B88A`, text `#153D35`, radius 6px | Tidak ada varian ini |
| Sidebar | bg `#153D35` | Tidak ada sidebar (mobile) |
| Border radius card | `radius-md: 10px` | 12px (sedikit lebih besar) |
| Font angka | `tabular-nums` via `Plus Jakarta Sans` | JetBrains Mono (font terpisah) |
| Tombol primary radius | 6px (decisive) | 8px |

---

## Rencana Pengerjaan — Fase Prioritas

> Format: `[ ]` belum, `[~]` sedang dikerjakan, `[x]` selesai.
> Setiap fase selesai → konfirmasi sebelum lanjut.

---

## Fase A — Perbaikan Palet & Token Warna (KRITIS, Kerjakan Pertama)

**Estimasi:** 2–3 jam  
**Blok pengerjaan:** Hanya ubah `app_colors.dart` dan `app_theme.dart`. Tidak menyentuh layar lain dulu.

### A.1 — Migrasi `AppColors` ke palet DESIGN.md

- [ ] Ganti semua token warna di `app_colors.dart`:
  - `primary` → Forest `#153D35`
  - `accent` (baru) → Growth Green `#35B88A`
  - `primary50` → Mint `#EAF5F0`
  - `surfaceMuted` → Cloud `#F6F8F7`
  - `border` → `#D1E8DF`
  - Pertahankan token status (approved/rejected/paid/partial) yang sudah WCAG-compliant
- [ ] Tambah token baru: `forest`, `growth`, `mint`, `cloud` agar nama token selaras DESIGN.md
- [ ] Verifikasi kontras: Growth Green (`#35B88A`) sebagai teks **dilarang** di latar terang

### A.2 — Update `AppTheme`

- [ ] Ubah `ColorScheme.primary` → `#153D35`
- [ ] Ubah warna `ElevatedButton` → bg Forest `#153D35`, radius 6px (bukan 8px)
- [ ] Hapus `moneyStyle` yang menggunakan JetBrains Mono — ganti ke `Plus Jakarta Sans` dengan `fontFeatures: [FontFeature.tabularFigures()]`
- [ ] Update `focusedBorder` input → ring `#35B88A` (bukan Indigo)
- [ ] Tambah `OutlinedButton` varian untuk Ghost button (bg transparent, border `#D1E8DF`)

### A.3 — Tambah Token Accent Button

- [ ] Tambah `AppButton.accent` variant (bg `#35B88A`, text `#153D35`) di `app_button.dart`
- [ ] Tambah parameter `size` di `AppButton`: `normal` (height 48) dan `compact` (height 40) untuk inline actions

---

## Fase B — Perbaikan Bug Fungsional

**Estimasi:** 3–4 jam

### B.1 — Investigasi & Fix Upload Bukti (B-01)

- [ ] Cek konfigurasi Neon Object Storage di web Next.js (`evidence.service.ts`)
- [ ] Verifikasi endpoint `/api/v1/evidence` aktif dan menerima multipart upload
- [ ] Test upload file dari Flutter ke endpoint production
- [ ] Jika S3/Object Storage tidak aktif: implementasikan fallback lokal atau tampilkan pesan informatif
- [ ] Pastikan `evidence_files` dapat terisi setelah fix

### B.2 — Fix Aksesibilitas Keyboard (B-10)

- [ ] Ganti `GestureDetector` di `login_screen.dart` → `TextButton` dengan `style` yang match warna link

### B.3 — Fix Warna SnackBar Sukses (B-11)

- [ ] SnackBar approve/success → gunakan `backgroundColor: AppColors.statusApprovedText` dengan teks putih
- [ ] Atau pakai SnackBar default (abu-abu gelap) dengan teks biasa — lebih aman untuk kontras

### B.4 — Konsolidasi Hardcoded Hex (B-06)

- [ ] Scan seluruh `lib/` untuk `Color(0xFF...)` hardcoded — replace dengan token `AppColors`
- [ ] Terutama di: `scenario_list_screen.dart`, `expense_detail_screen.dart`, `events_list_screen.dart`

### B.5 — Fix `RejectionReasonDialog` Dependency (B-05)

- [ ] Ekstrak `RejectionReasonDialog` ke file tersendiri: `lib/core/widgets/rejection_reason_dialog.dart`
- [ ] Import di semua screen yang menggunakannya

### B.6 — Tambah `Semantics` pada StatusBadge (B-12)

- [ ] Wrap isi `StatusBadge` dengan `Semantics(label: config.label, excludeSemantics: true)`
- [ ] Pastikan screen reader hanya membaca label teks, bukan "check circle outline, Disetujui"

---

## Fase C — Peningkatan UI/Visual (Tidak Terlihat AI-Generated)

**Estimasi:** 6–8 jam  
**Panduan:** Ikuti DESIGN.md. ENERGY 2/5 — tenang tapi tidak flat. MOTION 1/5 — transisi state saja.

### C.1 — Login Screen

Kondisi sekarang: Logo placeholder wallet icon pada box indigo — tidak sesuai brand.

- [ ] Ganti warna container logo → bg `#EAF5F0` (Mint), border `#D1E8DF`
- [ ] Ganti icon → `Icons.account_balance_wallet_outlined` tetap valid, tapi warna → `#153D35` (Forest)
- [ ] Judul "RekaDana Mobile" → `Plus Jakarta Sans`, weight 700, color `#153D35`
- [ ] Subtitle → weight 400, color `#475569` (body), 15px
- [ ] Tombol "Masuk ke Akun" → bg `#153D35`, radius 6px
- [ ] Link "Daftar akun baru" → warna `#153D35` (bukan Indigo)
- [ ] Ganti background dari putih murni → `#F6F8F7` (Cloud) untuk kesan lebih hangat

### C.2 — OrgSelectionScreen

Kondisi sekarang: Greeting card terasa generic. Icon organisasi flat.

- [ ] Greeting card → tambah subtle left-border 3px `#35B88A` (Growth) sebagai aksen identitas
- [ ] Avatar user → initial-based (huruf pertama nama user) bukan icon orang generic
- [ ] Org card: icon `Icons.apartment_outlined` → terlalu generic. Gunakan initial nama org sebagai avatar 2 huruf di dalam kotak Forest bg
- [ ] Badge peran → sesuaikan dengan token status badge DESIGN.md (tabel di DESIGN.md §5)
- [ ] Tambah `hero` number di header: jumlah organisasi aktif ("2 organisasi terdaftar")

### C.3 — EventsListScreen

Kondisi sekarang: 4 tombol per card terasa bertumpuk. Layout belum ada hierarki visual jelas.

- [ ] Hierarki tombol lebih tegas:
  - Tombol utama (1): "Ajukan Pengeluaran Lapangan" → primary Forest, penuh
  - Tombol sekunder (2): "Daftar Pengeluaran" + "Review Bendahara" → row 50:50, ghost style
  - Tombol tersier (3): "Scenario Lab" + "Versi Anggaran" → row 50:50, text-only style dengan ikon kecil
- [ ] Ringkasan finansial 4 metrik → gunakan warna yang selaras DESIGN.md:
  - Pagu Dana → `#153D35`
  - Anggaran Resmi → `#153D35`
  - Realisasi Bersih → `#0E7490` (statusPaidText)
  - Sisa Kontrol → `#15803D` (statusApprovedText)
- [ ] Card header: nama kegiatan → `fontSize: 15, weight: 700`, deskripsi → `13px, body`
- [ ] Badge peserta → bg `#EAF5F0`, text `#153D35`, border `#D1E8DF` (Mint-based, bukan Indigo)
- [ ] Empty state → gambar/ilustrasi lebih kontekstual (cukup icon `Icons.event_note_outlined`)

### C.4 — ExpenseListScreen

Kondisi sekarang: Filter chip menggunakan Indigo. Card tidak ada diferensiasi visual.

- [ ] Filter chip selected → bg `#EAF5F0`, border `#35B88A`, text `#153D35` (bukan Indigo-100)
- [ ] Summary row (Diajukan/Disetujui/Dibayar/Ditolak) → tambah subtle top-border 2px sesuai warna status
- [ ] Expense card: status badge di kiri atas, nominal di kanan bawah — hierarki sudah cukup baik, tinggal sesuaikan warna
- [ ] FAB "Ajukan Kebutuhan" → bg `#153D35`

### C.5 — ExpenseDetailScreen

Kondisi sekarang: Paling kompleks. 4 dialog inline (approve, reject, payment, reversal). Sudah cukup baik secara logika.

- [ ] Box ringkasan finansial (approved/paid/remaining) → gunakan 3-kolom horizontal metric, warna DESIGN.md
- [ ] Progress indicator sisa pembayaran → tambah `LinearProgressIndicator` tipis (2px height) dengan warna `#35B88A` (Growth)
- [ ] Upload bukti section → tambah ilustrasi placeholder "Belum ada bukti" yang sesuai DESIGN.md (bukan generic icon)
- [ ] Evidence card → tampilkan thumbnail preview untuk gambar, ikon PDF untuk dokumen
- [ ] Payment history → gunakan divider + timestamp kecil, bukan card terpisah per item
- [ ] Dialog-dialog internal → seragamkan padding dan input style dengan `AppTextField`

### C.6 — BendaharaReviewScreen

Kondisi sekarang: Tab "Menunggu Review" sudah baik. Card review memiliki dua tombol Tolak/Setujui.

- [ ] Review card: nominal diajukan → gunakan moneyLargeStyle dengan warna `#153D35` (bukan Indigo)
- [ ] Warning self-approval → bg `#FEF2F2`, border `#FECACA`, icon `Icons.lock_outlined` lebih tepat dari `info_outline`
- [ ] Tombol "Setujui" → bg `#15803D` (statusApprovedText) untuk asosiasi visual yang jelas
- [ ] Tombol "Tolak" → border `#B91C1C`, text `#B91C1C`, tanpa fill

### C.7 — BudgetVersionListScreen & DetailScreen

Kondisi sekarang: Versi aktif sudah ada banner. Card cukup informatif.

- [ ] Banner "Anggaran Resmi Aktif" → bg `#EAF5F0`, border `#35B88A`, icon `Icons.verified_outlined` → warna `#153D35`
- [ ] Nomor versi badge → bg `#153D35` (untuk approved) atau `#F1F5F9` (untuk lainnya)
- [ ] Snapshot financial box → selaraskan label font 11px dengan warna `#64748B` (muted)

### C.8 — ScenarioListScreen

Kondisi sekarang: Warning bar kuning sudah ada. Card skenario informatif.

- [ ] Info pagu dana bar → bg `#EAF5F0`, border `#D1E8DF`, teks pagu → warna `#153D35`
- [ ] Badge "Defisit" → sudah menggunakan warna merah yang tepat (pertahankan)
- [ ] Metric box → sesuaikan dengan spacing DESIGN.md (8px antar baris)
- [ ] Item preview list → gunakan bullet `›` bukan `•` untuk tampilan lebih clean
- [ ] Tombol "Ajukan ke Bendahara" → bg `#153D35` (bukan Indigo)

### C.9 — StateViews (EmptyState, ErrorState, Loading)

- [ ] `EmptyStateView` icon container → bg `#EAF5F0`, border `#D1E8DF`, icon warna `#153D35`
- [ ] `ErrorStateView` sudah menggunakan warna merah — pertahankan, hanya sesuaikan radius ke 10px
- [ ] `LoadingView` spinner → warna `#153D35`

---

## Fase D — Peningkatan UX & Koneksi Data

**Estimasi:** 4–5 jam

### D.1 — Perbaikan Empty State untuk Event Tanpa Anggaran

- [ ] EventCard: ketika `report == null` (event tanpa budget approved), tampilkan badge "Belum ada anggaran resmi" di area metrics — bukan "Memuat..."
- [ ] Tambah logika: jika semua report gagal dimuat, tampilkan `ErrorStateView` partial

### D.2 — Konfirmasi Navigasi Back saat Form Dirty

- [ ] `ScenarioCreateScreen`, `ExpenseCreateScreen`: jika form sudah diisi dan user tap back → tampilkan dialog konfirmasi "Data tidak tersimpan, yakin keluar?"
- [ ] Gunakan `PopScope` (Flutter 3.x) bukan `WillPopScope` (deprecated)

### D.3 — Lazy Loading untuk EventReport

- [ ] Ganti pendekatan paralel semua → sequential dengan `Future.wait` terbatas 3 concurrent
- [ ] Tambah shimmer placeholder di metric area saat report loading per card

### D.4 — Verifikasi Endpoint vs Database

- [ ] Test semua endpoint dari mobile client ke production:
  - `GET /api/v1/organizations` ✓ (data ada)
  - `GET /api/v1/organizations/:id/events` ✓ (data ada)
  - `GET /api/v1/events/:id/expense-requests` ✓ (data ada)
  - `GET /api/v1/events/:id/budget-scenarios` ✓ (data ada)
  - `GET /api/v1/events/:id/reports/budget-vs-actual` → perlu test
  - `POST /api/v1/evidence` → **GAGAL** (evidence_files kosong)
  - `GET /api/v1/evidence/:id/download` → perlu test
- [ ] Dokumentasikan hasil test per endpoint

### D.5 — Error Handling untuk Koneksi Production

- [ ] Tambah handling spesifik untuk 503/504 (server sedang suspend Neon)
- [ ] Pesan error yang lebih informatif: "Server sedang tidak aktif. Coba beberapa saat lagi." untuk timeout

---

## Fase E — Polishing & Quality Gates

**Estimasi:** 2–3 jam

### E.1 — Audit Kontras Warna Final

- [ ] Jalankan pengecekan manual setelah migrasi palet:
  - `#153D35` teks pada `#F6F8F7` → 11.25:1 ✅
  - `#FFFFFF` teks pada `#153D35` → 11.99:1 ✅
  - `#35B88A` sebagai teks → **DILARANG** di latar terang

### E.2 — Target Sentuh

- [ ] Pastikan semua tombol interaktif minimum 48px height (sudah ada di AppButton)
- [ ] Verifikasi `IconButton` di AppBar minimum 44px touch area

### E.3 — `flutter analyze`

- [ ] Pastikan 0 warning setelah semua perubahan
- [ ] Perbaiki deprecation warning jika ada (`WillPopScope`, dll.)

### E.4 — Rebuild APK

- [ ] `flutter build apk --release` setelah semua fase selesai
- [ ] Verifikasi APK build sukses

---

## Checklist Delivery Gate

Sebelum dinyatakan selesai, semua item berikut harus **PASS**:

- [ ] Palet warna sesuai DESIGN.md (Forest Green, bukan Indigo)
- [ ] Tidak ada `Color(0xFF...)` hardcoded di luar `app_colors.dart`
- [ ] `evidence_files` dapat terisi setelah test upload
- [ ] Semua tombol punya aksi nyata (R-26)
- [ ] Tidak ada `GestureDetector` untuk link navigasi — gunakan `TextButton` atau `InkWell`
- [ ] SnackBar sukses tidak ada contrast fail
- [ ] StatusBadge memiliki Semantics yang benar
- [ ] `flutter analyze` → 0 issues
- [ ] APK build bersih

---

## Catatan Teknis Penting

### Tentang Palet Warna

DESIGN.md sudah ada dan sudah disetujui pengguna (26 Oktober 2026). Namun `app_colors.dart` tidak mencerminkan palet tersebut — masih menggunakan default Indigo AI. **Ini adalah penyimpangan paling krusial** yang harus diperbaiki sebelum pekerjaan UI lain.

### Tentang Evidence Upload

Database Neon menunjukkan `evidence_count: 0`. Fitur upload sudah diimplementasikan di Flutter (`expense_service.dart`) dan logika backend ada (`seed-demo.ts` menyebut "adapter S3 Neon Object Storage"). Kemungkinan penyebab: Neon Object Storage belum dikonfigurasi bucket di production, atau endpoint tidak aktif.

### Tentang Font Angka

DESIGN.md §3 menyatakan: "Angka keuangan: gunakan `font-variant-numeric: tabular-nums`" dan "Tidak ada font mono terpisah." Namun `AppTheme.moneyStyle` menggunakan `GoogleFonts.jetBrainsMono`. Ini perlu diganti ke `Plus Jakarta Sans` dengan `fontFeatures: [FontFeature.tabularFigures()]`.

### Tentang Status Badge "Dibatalkan"

DESIGN.md §5 mendefinisikan status "Dibatalkan" tapi tidak ada case ini di `StatusBadge`. Perlu ditambahkan.

---

*Dokumen ini diperbarui: 21 November 2026*
*Analisis dilakukan oleh: Antigravity (Gemini)*
