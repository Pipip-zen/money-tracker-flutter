# Laporan Progress Selanjutnya Catetin

Tanggal: 2026-06-06

## Ringkasan

Fokus progress berikutnya ada pada empat area: Transaksi Rutin, Dompet Saya, Ekspor Laporan, dan Pengaturan Aplikasi. Fitur dasar sudah tersedia, tetapi masih perlu penguatan validasi, UX, dan konsistensi data agar aplikasi lebih siap dipakai harian.

## 1. Transaksi Rutin

Status saat ini:
- User bisa membuat dan mengelola transaksi berulang.
- Sistem masih memakai `workmanager` untuk pengecekan periodik.
- Notifikasi sudah dihapus, jadi transaksi rutin berjalan tanpa popup.

Progress selanjutnya:
- Tambahkan aksi pause/resume yang lebih jelas di daftar transaksi rutin.
- Tambahkan preview tanggal eksekusi berikutnya sebelum user menyimpan.
- Tambahkan validasi agar transaksi rutin tidak dibuat tanpa dompet aktif.
- Tambahkan riwayat eksekusi atau penanda "terakhir dijalankan" agar user tahu sistem sudah bekerja.
- Evaluasi apakah `workmanager` tetap dibutuhkan jika tanpa notifikasi, atau cukup diproses saat app dibuka.

File terkait:
- `lib/presentation/screens/recurring/recurring_screen.dart`
- `lib/core/services/recurring_service.dart`
- `lib/data/daos/recurring_transaction_dao.dart`
- `lib/data/repositories/recurring_transaction_repository_impl.dart`
- `lib/domain/entities/recurring_transaction_entity.dart`
- `lib/domain/repositories/recurring_transaction_repository.dart`
- `lib/main.dart`

## 2. Dompet Saya

Status saat ini:
- User bisa tambah, edit, hapus/nonaktifkan dompet.
- Ada saldo total dan detail dompet.
- Icon dompet sudah disederhanakan menjadi Cash, Bank, dan E-Wallet.
- Transfer antar dompet sudah tersedia.

Progress selanjutnya:
- Tambahkan validasi agar user tidak menghapus dompet default jika masih ada transaksi aktif.
- Tambahkan flow ganti dompet default yang lebih eksplisit.
- Tambahkan empty state yang mengarahkan user membuat dompet pertama.
- Tambahkan filter dompet berdasarkan tipe: Cash, Bank, E-Wallet.
- Rapikan konsistensi label mata uang, saat ini ada yang memakai `IDR` dan ada yang memakai `Rp`.

File terkait:
- `lib/presentation/screens/wallet/wallet_list_screen.dart`
- `lib/presentation/screens/wallet/wallet_form_screen.dart`
- `lib/presentation/screens/wallet/wallet_detail_screen.dart`
- `lib/presentation/widgets/wallet/wallet_card.dart`
- `lib/presentation/widgets/wallet/wallet_icon_mark.dart`
- `lib/presentation/widgets/wallet/wallet_picker_sheet.dart`
- `lib/presentation/providers/wallet_provider.dart`
- `lib/data/daos/wallet_dao.dart`
- `lib/data/repositories/wallet_repository_impl.dart`
- `lib/domain/entities/wallet.dart`
- `lib/domain/repositories/wallet_repository.dart`

## 3. Ekspor Laporan

Status saat ini:
- Ekspor CSV dan PDF tersedia.
- Ekspor bisa dilakukan dari pengaturan dan halaman transaksi.
- PDF sudah menampilkan ringkasan dan daftar transaksi.

Progress selanjutnya:
- Tambahkan pilihan nama file yang lebih mudah dibaca, misalnya `catetin_laporan_2026_06.pdf`.
- Tambahkan filter ekspor per dompet.
- Tambahkan filter ekspor per kategori.
- Tambahkan preview laporan sebelum share/export.
- Perbaiki tampilan PDF agar branding Catetin lebih konsisten.
- Tambahkan test untuk output CSV agar format tidak rusak saat data berisi koma atau kutip.

File terkait:
- `lib/core/services/export_service.dart`
- `lib/presentation/screens/settings/settings_screen.dart`
- `lib/presentation/screens/transactions/transactions_screen.dart`
- `lib/domain/entities/transaction_entity.dart`
- `lib/domain/entities/wallet.dart`
- `lib/presentation/providers/transaction_providers.dart`
- `lib/presentation/providers/wallet_provider.dart`

## 4. Pengaturan Aplikasi

Status saat ini:
- Pengaturan memuat akses ke transaksi berulang, kelola dompet, ekspor data, kategori custom, mode gelap, versi aplikasi, dan reset data.
- Fitur notifikasi sudah dihapus dari menu dan dependency.

Progress selanjutnya:
- Kelompokkan menu agar lebih ringkas: Data, Preferensi, Manajemen, Tentang.
- Tambahkan halaman profil user untuk edit nama dan email dari onboarding.
- Tambahkan konfirmasi lebih kuat untuk reset data, misalnya input kata `RESET`.
- Tambahkan backup/restore lokal sebelum reset data.
- Tambahkan halaman informasi aplikasi: versi, lisensi, dan kontak/support.

File terkait:
- `lib/presentation/screens/settings/settings_screen.dart`
- `lib/presentation/screens/settings/category_management_screen.dart`
- `lib/presentation/providers/settings_provider.dart`
- `lib/presentation/providers/user_provider.dart`
- `lib/core/constants/app_theme.dart`
- `lib/main.dart`
- `pubspec.yaml`

## Prioritas Rekomendasi

Prioritas 1:
- Perkuat Transaksi Rutin: validasi dompet aktif, preview tanggal berikutnya, dan status terakhir jalan.
- Rapikan Dompet Saya: default wallet, empty state, dan konsistensi mata uang.

Prioritas 2:
- Upgrade Ekspor Laporan: filter per dompet/kategori dan nama file lebih rapi.
- Tambah edit profil user di Pengaturan.

Prioritas 3:
- Backup/restore lokal.
- Preview PDF sebelum share.
- Test tambahan untuk CSV/PDF dan transaksi rutin.

## Catatan Teknis

- Setelah notifikasi dihapus, `workmanager` masih dipakai untuk transaksi rutin. Jika transaksi rutin dianggap harus tetap berjalan di background, pertahankan `workmanager`. Jika tidak wajib background, sederhanakan dengan menjalankan `RecurringService().runCheck()` saat app startup atau saat dashboard dibuka.
- Jangan hapus tabel recurring dari database karena fitur Transaksi Rutin masih aktif.
- Perubahan berikutnya sebaiknya tetap menjalankan:

```powershell
flutter analyze
flutter test
```
