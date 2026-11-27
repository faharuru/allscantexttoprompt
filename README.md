# Keranjang Prompt (Android)

Kumpulkan teks dari aplikasi mana pun, kamera, atau screenshot, lalu gabung jadi prompt AI.

## Cara dapat APK
1. Buat repo baru di github.com (boleh Private).
2. Upload SEMUA isi folder ini ke repo (Add file > Upload files).
   Pastikan folder `.github` ikut terupload. Jika tidak (folder tersembunyi),
   pakai Add file > Create new file, ketik nama `.github/workflows/build.yml`,
   lalu tempel isi file build.yml.
3. Buka tab **Actions**. Build jalan otomatis (5-10 menit). Jika tidak,
   pilih "Build APK" > Run workflow.
4. Setelah hijau, klik run tersebut > bagian **Artifacts** > unduh
   `keranjang-prompt-apk` (zip berisi app-release.apk).
5. Ekstrak, kirim ke HP, instal (izinkan "instal dari sumber tidak dikenal").

## Cara pakai
Di aplikasi apa pun: blok teks > menu "Tambah ke Keranjang" (bisa di balik titik tiga).
Teks masuk dan kamu kembali ke aplikasi asal. Ulangi, lalu buka Keranjang Prompt,
atur urutan, dan tekan Copy.
