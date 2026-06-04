# PRD — Startup Story (Working Title)
### Game Tycoon Manajemen Startup Indonesia, Gaya Pixel Art (Interior Kantor)

**Versi:** 2.0 (sinkron dengan prototipe)
**Status:** **Prototipe PLAYABLE end-to-end** (P0 + P1 lengkap + P2 sebagian) — lihat §11 Status Implementasi
**Tipe Project:** Produk komersial, solo developer
**Genre:** Simulation / Management / Tycoon (single-player, offline-first)
**Platform Target:** Android & PC (Windows) di rilis awal, iOS menyusul
**Engine terpasang:** Godot 4.6.3 (GDScript), renderer gl_compatibility

---

## 1. Ringkasan & Visi

**Pitch satu kalimat:**
Bangun startup teknologi dari garasi sampai IPO — rekrut talent, luncurkan layanan (ride-hailing, food, payment, logistics), kelola burn rate, dan menangkan perang pasar di lanskap startup Indonesia.

**Inspirasi gameplay:** Kairosoft (Game Dev Story, Mega Mall Story) — loop "bangun → kelola → optimalkan → angka naik" yang adiktif, dengan sistem kombinasi/unlock sebagai pendorong rasa penasaran.

**Diferensiasi:**
- Tema startup teknologi Indonesia yang belum pernah digarap di genre ini.
- Nuansa lokal autentik: perang promo/bakar duit, ojek pangkalan vs online, demand spike Ramadhan, ekspansi kota tier-2, regulasi.
- Domain knowledge founder asli (kredibilitas mekanik bisnis).

**Tampilan (REVISI v2.0):** Pixel art 2D — **interior kantor dilihat dari atas** (gaya Game Dev Story / Kairosoft), **BUKAN peta kota**. Pemain melihat ke dalam kantornya: tiap talent = satu pekerja di mejanya, kantor makin ramai saat hire, dan **naik kelas (Garasi → Ruko → Kantor → Menara)** saat di-upgrade. Keputusan desain 2026-06-04: konsep "peta kota isometric" di draft awal diganti ke "interior kantor" karena lebih personal & sesuai referensi Kairosoft.

**Tujuan komersial:** Premium paid (one-time purchase) di Google Play & Steam, harga ~Rp 30–60rb / $2.99–4.99. Hindari iklan & gacha untuk menjaga reputasi premium dan menarik audiens internasional juga.

---

## 2. Target Audience

| Segmen | Deskripsi |
|--------|-----------|
| Primer | Penggemar game tycoon/simulasi (fans Kairosoft, Game Dev Tycoon) |
| Sekunder | Pelaku/penggemar dunia startup & teknologi Indonesia |
| Tersier | Pasar global penyuka pixel-art management game (game tetap dukung English) |

---

## 3. Core Gameplay Loop

```
Rekrut/kelola talent  →  Bangun & rilis fitur/layanan  →  Dapatkan user & revenue
        ↑                                                          ↓
   Funding round / reinvest   ←   Kelola burn rate, runway, event pasar
```

**Tension utama:** Burn rate vs Revenue. Pemain harus tumbuh cukup cepat untuk meraih funding round berikutnya sebelum kehabisan runway (cash habis = game over / forced down round).

---

## 4. Sistem & Mekanik Detail

### 4.1 Talent (SDM)
- Tipe: **Engineer, Designer, Product, Marketing, Ops, Data**.
- Stat per talent: `Skill`, `Speed`, `Stamina`, `Gaji`, `Level`, `Spesialisasi`.
- Talent naik level lewat pengerjaan proyek (XP). Stamina turun saat kerja, perlu istirahat / "overtime" berisiko burnout.
- Rekrut via job board (acak kualitas), atau headhunt mahal untuk talent bintang.

### 4.2 Layanan / Produk (progresi unlock)
Urutan unlock yang disarankan (juga urutan development MVP → full):
1. **Ride-hailing** (motor) — layanan awal, MVP fokus di sini.
2. **Food delivery** — unlock setelah milestone user tertentu.
3. **Payment / Dompet Digital** — buka revenue stream baru (fee transaksi).
4. **Logistics / Kurir.**
5. **Super-app dashboard** — reward jangka panjang, gabungan semua layanan.

Tiap layanan punya: biaya R&D, biaya operasional, kapasitas, kualitas (memengaruhi rating & retensi user).

### 4.3 Sistem Kombinasi (DNA Kairosoft)
Gabungkan **tipe talent + tipe proyek** → unlock fitur/feature combo dengan bonus.
- Contoh: `Engineer Senior + Data + proyek Payment` → unlock "Credit Scoring" (fee lebih tinggi).
- Kombinasi rahasia mendorong eksperimen & replayability.

### 4.4 Ekonomi & Funding
- **Cash & Runway:** runway = cash / burn rate bulanan. Ditampilkan menonjol (jam pasir/alarm saat menipis).
- **Funding rounds:** Bootstrap → Seed → Series A → B → C → IPO. Tiap round: butuh metrik (MAU, GMV, growth) untuk unlock, memberi suntikan cash besar tapi dilusi kepemilikan.
- **Valuation & ownership %:** pemain melihat saham terdilusi tiap round — tension antara ambil dana vs jaga kepemilikan.
- **Win condition:** IPO sukses dengan valuation target. **Lose condition:** runway habis tanpa funding.

### 4.5 User Growth & Market
- **MAU / GMV** sebagai metrik utama.
- **Promo/bakar duit:** naikkan growth jangka pendek, bakar cash — keputusan strategis klasik startup.
- **Kompetitor AI:** 1–2 kompetitor yang juga tumbuh; berebut pangsa pasar kota.
- **Ekspansi geografis:** mulai 1 kota (Bandung/Jakarta) → buka kota baru (biaya + ops).

### 4.6 Event System
Event berkala bikin tiap sesi terasa hidup:
- **Positif:** viral campaign, fitur tembus jadi tren, investor tertarik.
- **Negatif:** server down, kompetitor kasih promo agresif, regulasi baru, talent resign.
- **Musiman/lokal:** lonjakan demand Ramadhan/Lebaran, musim hujan (ride turun), tahun ajaran baru.

---

## 5. Scope & Milestone (Solo Dev — realistis)

| Fase | Durasi est. | Output | Tujuan |
|------|-------------|--------|--------|
| **P0 — Prototype** | Bulan 1–2 | 1 layanan (ride-hailing), 3 tipe talent, cash & runway, 1 screen, grafis placeholder | Validasi: apakah core loop *seru* tanpa polish? |
| **P1 — Vertical slice** | Bulan 3–5 | Funding rounds, 2–3 layanan, event system, sistem kombinasi | Loop lengkap & balanced |
| **P2 — Content & art** | Bulan 6–8 | Isometric art final, semua layanan, super-app, audio | Konten penuh |
| **P3 — Polish & launch** | Bulan 9+ | Balancing intensif, save/load, lokalisasi ID/EN, soft launch | Rilis komersial |

**Prinsip:** Jangan bikin super-app di MVP. Validasi ride-hailing dulu. Kalau prototype kotak-kotak saja sudah bikin "satu turn lagi", baru lanjut.

---

## 6. Teknologi (Tech Stack)

### 6.1 Game Engine — **Godot 4.x** (rekomendasi utama)
**Alasan:**
- Gratis & open-source penuh, tanpa royalti/lisensi rumit (penting untuk komersial solo).
- 2D & isometric tilemap kuat — punya **TileMap** dengan dukungan Y-sort & isometric tile shape bawaan.
- Ekspor mulus ke Android, Windows, iOS, Web.
- GDScript mudah (mirip Python) — cepat untuk solo dev. Bisa pakai C# kalau perlu performa.
- Ringan, cocok untuk style pixel.

> Alternatif: Unity (lebih berat & lisensi lebih ribet untuk kasus ini) atau LÖVE/Defold (lebih niche). Godot adalah pilihan paling masuk akal di sini.

### 6.2 Rendering Isometric
- Gunakan **Godot TileMap** dengan `Tile Shape = Isometric`.
- **Y-sort** untuk depth sorting otomatis (objek di belakang ter-render dulu).
- Konversi koordinat grid ↔ layar isometric (rumus standar 2:1 diamond).
- Sprite karakter & bangunan sebagai pixel art menghadap diagonal.

### 6.3 Art & Audio Tools
- **Aseprite** — pixel art & animasi (standar industri, sekali beli).
- **Tiled** (opsional) — desain map, integrasi ke Godot ada.
- Audio: aset CC0/berlisensi (itch.io, OpenGameArt) untuk SFX/musik chiptune; kustom menyusul.

### 6.4 Arsitektur Data
- **Offline-first**, single-player. Save/load lokal (Godot `FileAccess` / JSON / resource).
- Definisi konten (talent, layanan, event) di **file data terpisah** (JSON/Resource) — bukan hardcode — agar balancing gampang di-tweak tanpa ubah kode.

### 6.5 Tooling Pendukung
- **Git** untuk version control (Godot ramah Git).
- **Claude Code** untuk akselerasi development (lihat bagian 8).

---

## 7. UI/UX

- **Layar utama (REVISI v2.0):** interior kantor isometric (pekerja di meja, gaya Game Dev Story) di tengah; HUD atas (cash, runway, MAU, GMV, tanggal) + kontrol waktu; panel di sisi (Kantor/Upgrade, Layanan, Kompetitor/Promo, Tim, Job Board, Funding, R&D, Kota, Event Log).
- **Panel:** Talent, Layanan/R&D, Funding, Market/Kompetitor, Event log.
- **Kontrol mobile-first:** tap & drag, pinch-zoom peta, panel slide. Pastikan touch target besar.
- **Time control:** play / pause / fast-forward (esensial untuk game tycoon).
- **Tone visual:** ceria, warna cerah ala Kairosoft, font pixel yang tetap terbaca di layar HP.
- **Lokalisasi:** Bahasa Indonesia & English (string table terpisah sejak awal).

---

## 8. Catatan Eksekusi via Claude Code

- Simpan PRD ini + buat `CLAUDE.md` di root project Godot sebagai konteks autonomous.
- Mulai dari **P0 prototype** — minta Claude Code scaffold project Godot, sistem grid isometric, dan core loop ekonomi dengan data placeholder.
- Pisahkan **data balancing** ke file JSON agar bisa di-tweak cepat.
- Pendekatan iteratif: validasi loop dulu sebelum investasi art.

---

## 9. Risiko & Mitigasi

| Risiko | Mitigasi |
|--------|----------|
| Balancing ekonomi makan ratusan jam | Pisahkan data ke JSON; bangun tool tweak internal; playtest dini |
| Scope creep (godaan bikin super-app duluan) | Disiplin milestone; MVP = ride-hailing saja |
| Art jadi bottleneck solo | Placeholder dulu; outsource pixel artist lokal setelah loop tervalidasi |
| Burnout solo dev | Milestone kecil & terukur; rilis P0 internal sebagai motivasi |
| Pasar niche | Dukungan English + tema universal "startup" memperluas jangkauan global |

---

## 10. Definisi Sukses (MVP/P0)

Prototype dianggap berhasil jika: **pemain merasakan dorongan "satu giliran lagi"** dengan hanya core loop ride-hailing + talent + runway, tanpa art final. Jika ya → lanjut. Jika tidak → tuning loop sebelum tambah fitur apa pun.

---

## 11. Status Implementasi (per 2026-06-04)

> Ringkasan apa yang **sudah dibangun & teruji** di prototipe Godot. Game sudah
> **playable end-to-end**: Menu → main → menang (IPO) / kalah (bangkrut) → Main Lagi.
> 42 assertion core hijau + smoke "main agresif" terbukti bisa menang IPO.

### 11.1 Engine & arsitektur
- **Godot 4.6.3** (GDScript), gl_compatibility (ramah Android). `default_texture_filter=0` (nearest, pixel-art).
- Pemisahan ketat: `scripts/core/` logika MURNI (no node) → `economy, talent, service, market, funding, events, research, competitor, cities`. Orkestrator autoload `GameState`. Presentasi: `scripts/ui/ui_root.gd`, `scripts/world/{iso_grid, office_renderer}.gd`, autoload `Audio`.
- **Semua balancing di `data/*.json`** (balance, talents, services, funding, events, features, cities, office) — nol hardcode.

### 11.2 Mekanik yang sudah jalan
**P0 — core loop:** ride-hailing, talent + hire (job board), cash/burn/**runway**, waktu play/pause/ff, save/load lokal, MAU/GMV.

**P1 — vertical slice (4 sistem):**
- **Funding rounds:** Seed→Series A→B→**IPO**, valuasi = MAU×value_per_mau, **dilusi ownership**, win = IPO.
- **Event system:** acak/musiman per pergantian bulan (viral, server down, promo kompetitor, regulasi, Ramadhan, musim hujan, dll) + Event Log.
- **Sistem kombinasi talent×proyek (R&D Fitur):** kombinasi tipe talent meng-unlock fitur bonus permanen (Surge Pricing, Referral, Revamp UX, Ekspansi Armada).
- **Kompetitor AI + Promo:** RivalGo tumbuh logistik & menekan pangsa pasar; promo = bakar duit (boost akuisisi, biaya harian). Marketing menumpuk per tim → mesin pertumbuhan untuk mengalahkan kompetitor.

**P2 — content (sebagian):**
- **Multi-layanan / Super-app:** food delivery, dompet digital, logistics di-launch saat MAU capai threshold; semua layanan aktif memonetisasi MAU yang sama.
- **Ekspansi kota:** Bandung (home) → Jakarta/Surabaya/Medan/Makassar (bayar + ops, jangkauan akuisisi naik).
- **🏢 Sistem Upgrade Kantor (BARU):** Garasi (4 meja) → Ruko (8) → Kantor (16) → Menara (30). Hire DIBLOKIR saat kantor penuh; harus upgrade (bayar) untuk muat lebih banyak karyawan. Ukuran ruangan & tampilan ikut naik kelas.

### 11.3 Visual & audio (lihat §1 Tampilan revisi)
- **Interior kantor isometric** disusun sebagai Image (CPU blit) → ImageTexture. Tiap talent = **sprite pixel karakter Kenney (CC0)** di mejanya (28 varian via flip), badge warna per peran.
- **Animasi kerja** (bob ngetik + monitor kedip saat waktu jalan), **speech bubble** ("Cuan!/🚀 IPO!") saat funding/event-positif/menang/upgrade.
- **Dekorasi**: tanaman, dispenser air, karpet, dinding berjendela. **Kamera auto-fit** zoom mengikuti ukuran kantor.
- **Audio**: SFX UI (klik/konfirmasi/error), jingle event & menang, **musik latar chiptune** loop + tombol mute. Semua **CC0**.

### 11.4 Flow end-to-end
Main Menu (Main Baru / Lanjutkan / Keluar) → game → overlay **menang/kalah** dengan **🔄 Main Lagi** & **🏠 Menu**. Save/Load in-game + Continue dari menu.

### 11.5 Balancing default (ROUGH — menunggu playtest)
- Do-nothing → bangkrut ~bulan 7 (tekanan nyata). Main agresif (tim marketing besar) → **IPO menang**.
- Angka di `data/*.json` masih kasar; tuning "rasa seru" final = wewenang user via playtest (lihat §11.7).

### 11.6 Aset & lisensi (penting untuk produk berbayar)
- **Semua aset CC0** (public domain, bebas komersial, tanpa kewajiban kredit): karakter & interior **Kenney Roguelike**, SFX/jingle **Kenney**, musik **OpenGameArt** ("Pixel Paradise"). Lihat `LICENSES.md`.
- ❌ Hindari CC-BY-NC (non-komersial) & CC-BY-SA (copyleft). CC-BY boleh tapi wajib kredit.

### 11.7 Belum dikerjakan / next
- Tuning balancing intensif (playtest), tutorial/onboarding, lokalisasi EN penuh.
- Furniture/karakter pixel kelas modern-office (Kenney roguelike masih gaya RPG); animasi pindah kantor; layer baju karakter.
- Belum `git init`. Belum ekspor Android/PC. GUT belum terpasang (pakai runner `tests/verify_core.gd` + `smoke_run.gd`).
