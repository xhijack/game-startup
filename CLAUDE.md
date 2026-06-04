# CLAUDE.md — Startup Story (Game Project Constitution)

> File ini WAJIB dibaca di setiap sesi. Berisi aturan arsitektur, konvensi, dan
> batasan project. Tujuannya: hasil tetap konsisten lintas sesi dan TIDAK
> setengah-setengah. Referensi spesifikasi lengkap ada di `docs/PRD_StartupStory.md`.

---

## 1. Apa yang sedang dibangun

Game tycoon manajemen **startup teknologi Indonesia** bergaya **isometric pixel art**
(Kairosoft-like). Pemain membangun startup dari garasi sampai IPO: rekrut talent,
luncurkan layanan (ride-hailing → food → payment → logistics → super-app), kelola
burn rate & runway, menangkan perang pasar.

- **Engine:** Godot 4.x (GDScript)
- **Platform:** Android & PC dulu, iOS menyusul
- **Model:** Single-player, offline-first, premium paid (TANPA iklan/gacha)
- **Tampilan:** 2D engine dengan proyeksi isometric (BUKAN 3D). TileMap isometric + Y-sort.

---

## 2. Prinsip Utama (jangan dilanggar)

1. **Setiap fase HARUS playable.** Jangan pernah meninggalkan banyak sistem dalam
   keadaan setengah jadi sekaligus. Selesaikan satu sistem sampai jalan & teruji,
   baru lanjut ke berikutnya.
2. **JANGAN hardcode angka balancing.** Semua angka ekonomi (gaji, burn rate,
   revenue, growth, biaya R&D, threshold funding) WAJIB di file data `data/*.json`.
   Kode hanya membaca data, tidak menyimpan nilai balancing.
3. **MVP = ride-hailing saja.** Jangan bangun super-app, payment, atau logistics
   sebelum core loop ride-hailing tervalidasi. Tahan godaan scope creep.
4. **Placeholder dulu, art belakangan.** Bangun seluruh sistem dengan grafis
   placeholder (kotak/warna solid). Jangan menunggu/menuntut aset art untuk lanjut.
5. **Pisahkan data, logic, dan presentasi.** Logika game tidak boleh tahu soal
   rendering. UI membaca state, tidak menyimpan state.
6. **Tulis test untuk sistem inti.** Setiap sistem ekonomi/logika punya test
   (GUT — Godot Unit Test). Jangan tambah fitur kalau test existing merah.

---

## 3. Arsitektur & Struktur Folder

```
res://
├── data/                 # SEMUA balancing & definisi konten (JSON) — sumber kebenaran
│   ├── talents.json      # tipe talent, stat dasar, rentang gaji
│   ├── services.json     # layanan, biaya R&D, ops, kapasitas
│   ├── funding.json      # round, threshold metrik, jumlah dana, dilusi
│   ├── events.json       # event acak & musiman
│   └── balance.json      # konstanta global (burn rate, growth coef, dll)
├── scenes/               # Godot scenes (.tscn)
│   ├── main/             # bootstrap, game loop manager
│   ├── ui/               # panel: talent, services, funding, market, event log, HUD
│   └── world/            # peta kota isometric, tilemap
├── scripts/
│   ├── core/             # logika game murni (TANPA referensi node/UI)
│   │   ├── economy.gd    # cash, runway, burn rate, revenue
│   │   ├── talent.gd     # sistem SDM
│   │   ├── services.gd   # layanan & R&D
│   │   ├── funding.gd    # funding rounds & valuation
│   │   ├── market.gd     # user growth, kompetitor, promo
│   │   └── events.gd     # event system
│   ├── data/             # loader JSON → struct/resource
│   ├── ui/               # controller UI (baca state core, render)
│   └── save/             # save/load lokal
├── assets/               # art & audio (placeholder dulu)
│   ├── sprites/
│   ├── tiles/
│   ├── ui/
│   └── audio/
├── tests/                # unit test (GUT)
└── docs/
    └── PRD_StartupStory.md
```

**Aturan dependensi:** `scripts/core/` tidak boleh `import`/refer ke `scripts/ui/`
atau node scene. Core = logika murni yang bisa di-test tanpa membuka scene.

---

## 4. Konvensi Kode (GDScript)

- `snake_case` untuk variabel & fungsi, `PascalCase` untuk class/scene, `UPPER_SNAKE` untuk konstanta.
- Satu file = satu tanggung jawab jelas. Jangan bikin "god script".
- Fungsi pendek & deskriptif. Komentari *kenapa*, bukan *apa*.
- State game terpusat (mis. autoload `GameState`), bukan tersebar di banyak node.
- Sinyal (signal) untuk komunikasi UI ↔ core, hindari polling tiap frame bila bisa.
- Semua string yang tampil ke user lewat sistem lokalisasi (ID & EN) sejak awal.

---

## 5. Roadmap Eksekusi (kerjakan BERURUTAN)

> Selesaikan & validasi tiap fase sebelum lanjut. Minta playtest ke user di akhir tiap fase.

### P0 — Prototype (PRIORITAS SEKARANG)
- Project Godot ter-scaffold sesuai struktur di atas.
- Grid isometric + konversi koordinat + render placeholder.
- Core loop: 1 layanan (ride-hailing), 3 tipe talent, cash + runway + waktu (play/pause/ff).
- Data di JSON. Save/load dasar.
- Test untuk `economy.gd`.
- **Definisi sukses:** loop bikin user mau "satu giliran lagi" walau grafis kotak.

### P1 — Vertical Slice
- Funding rounds + valuation + dilusi.
- 2–3 layanan + sistem kombinasi talent×proyek.
- Event system (positif/negatif/musiman).
- Kompetitor AI + promo/bakar duit.

### P2 — Content & Art
- Integrasi isometric pixel art final + animasi + audio.
- Super-app, semua layanan, ekspansi kota.

### P3 — Polish & Launch
- Balancing intensif (via tweak JSON), lokalisasi penuh, ekspor Android/PC, soft launch.

---

## 6. Definition of Done (tiap fitur)

Sebuah fitur dianggap SELESAI hanya jika:
- [ ] Logika ada di `scripts/core/`, balancing-nya di `data/*.json`.
- [ ] Bisa dijalankan & dimainkan dalam game (bukan cuma kode mati).
- [ ] Punya test bila menyangkut logika ekonomi/aturan.
- [ ] UI terkait membaca state dengan benar & update via signal.
- [ ] Tidak merusak test/fitur sebelumnya.
- [ ] String user-facing sudah lewat lokalisasi.

---

## 7. Yang BUKAN tugas Claude Code (delegasi ke user)

- Pembuatan pixel art & audio asli (Claude pakai placeholder).
- Keputusan balancing final & "rasa seru" (user playtest → kasih feedback → Claude tweak JSON).
- Install Godot/Git/Node lokal & menjalankan editor.
- Keputusan bisnis (harga, store, marketing).

---

## 8. Cara kerja tiap sesi

1. Baca `CLAUDE.md` + bagian PRD yang relevan.
2. Konfirmasi fase aktif & tujuan sesi (1 hal fokus).
3. Implementasi mengikuti arsitektur & konvensi di atas.
4. Tulis/jalankan test bila relevan.
5. Akhiri dengan: apa yang berubah, cara user menjalankan/mengetes, dan saran langkah berikutnya.
