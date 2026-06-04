# PROGRESS — Startup Story / BeJek

> State pengembangan terakhir. Engine: **Godot 4.6.3** (GDScript, gl_compatibility).
> Repo: `git@github.com:xhijack/game-startup.git` (branch `main`).
> Jalankan: buka `project.godot` di Godot, F5. Main scene = `scenes/main/menu.tscn`.

## Dua mode (dari menu)

### 🚀 BeJek (FOKUS UTAMA — gaya Game Dev Story)
Scene `scenes/bejek/bejek.tscn` (`scripts/bejek/{bejek_game,bejek_world,bejek_ui}.gd`).
Desain: `docs/BeJek_CoreSystems.md`.

**Loop:** rekrut tim → develop fitur (alur bertahap) → rilis → user & uang naik → reinvest → rilis semua v1 = **menang**. Runway habis = kalah. Waktu **mingguan**.

**Sudah jadi & jalan:**
- Loop mingguan (play/pause/ff), Sekretaris (pemandu/notifikasi).
- **Develop fitur bertahap:** PRD → Development → QA → Fix → Done → Release (`scripts/core/feature_dev.gd`).
- **4 dimensi nilai:** Creativity · UI/UX · Security · Development.
- **Skill → fase:** Product→PRD/Creativity, Coding→Dev/Fix, QA→cari bug/Security, UI/UX→dimensi UI/UX, Management→booster.
- **Sistem bug:** muncul saat Dev, ditemukan QA, dibersihkan saat Fix.
- **Tugaskan employee** ke fitur (`assigned`) + **petunjuk skill per fase** + **stamina** (yang skill-relevan kerja → capek; lain pulih → rotasi).
- **Mode Fokus:** Normal / Kebut / Matang / Riset (multiplier dev/quality/bug).
- **Skor Review /40** saat rilis → multiplier user (viral≥34:1.8×, dst).
- **User (MAU)** tumbuh dari rilis + organik → **revenue = user × ARPU**.
- **Rilis Cepat (§6.2):** boleh rilis begitu Development penuh walau fase belum DONE →
  skor lebih rendah + **risiko insiden** (Security tipis/bug → user kabur massal).
- **Boost / terobosan (§6.4):** judi opt-in saat Development — peluang sukses dari
  skill coding tim; sukses → lonjakan Dev, gagal → bug menumpuk.
- **Proposal & versi v2+ (§5):** roadmap multi-versi (`data/bejek_versions.json` →
  v1 Ojek Manual → v2 Otomasi → v3 Retensi → v4 Super-app). v1 = tutorial (langsung
  terbuka); backlog versi habis → PM bikin **proposal** (akumulasi product point) →
  versi berikutnya & fitur barunya terbuka. **Menang = semua fitur v4 dirilis.**
- **Hiring channels (§3.2):** rekrut lewat pasang iklan berbiaya (`data/recruit_channels.json`):
  mulut-ke-mulut (gratis) · koran · internet · TV (peluang bintang) · headhunter (mahal,
  pasti tinggi). Tiap channel beda cost/jumlah/kualitas + peluang talent bintang.
  Role bisa direkrut: Product · Developer · Designer · QA · **Manajer**.
- **Team chemistry / combo (§9 P1+, DNA Kairosoft):** komposisi tim makin lengkap
  (skill product/coding/ui_ux/qa/management beragam) → tier chemistry naik
  (Seadanya→Cukup→Bagus→Mantap→Luar Biasa) → **multiplier output fitur & proposal**.
  Mendorong rekrut beragam. Tiers di `data/balance.json` (`feature_dev.combos`).
- **(P2) Kantor visual tumbuh:** ruangan upgrade otomatis seiring ukuran tim
  (Garasi→Ruko→Kantor→Menara, kapasitas dari `data/office.json`) — meja & pekerja
  pixel CC0 (Kenney) bertambah, badge warna per peran, banner aktivitas in-world
  (fitur/fase/proposal). Audio cue: rilis/unlock → jingle, insiden → error.
- Modal awal **Rp 200 jt**. Founder digaji Rp 1.000.
- Aset CC0 (Kenney) untuk kantor + karakter, audio CC0.

> **Fix penting (sesi ini):** loop mingguan BeJek (kas burn, user organik, maju minggu,
> cek runway/game-over) sempat jadi *dead code* di `_phase_skill()` → tidak pernah jalan.
> Sudah dipindah ke `_advance_week()`; tension runway aktif lagi.

**Data/balance:** `data/balance.json` (`feature_dev`, `bejek`), `data/bejek_versions.json`
(roadmap 4 versi) + `data/bejek_v1..v4.json` (fitur tiap versi), `data/recruit_channels.json`
(channel rekrut).

### ▶ Tycoon (lama — model awal, masih utuh)
Scene `scenes/main/main.tscn`. Office isometric, talent (level/stamina/train), funding+dilusi, event, kombinasi R&D, kompetitor+promo, multi-layanan, ekspansi kota, upgrade kantor, win=IPO.

## Testing
- `tests/verify_core.gd` (**~84 assertion**, headless): `godot --headless --path . -s res://tests/verify_core.gd`
  (termasuk rilis-cepat `can_release`/`security_ratio`, boost, team chemistry `team_combo`,
  `dim_ratios`, integritas roadmap versi/channel/office).
- `tools/bejek_sim.gd` — simulasi loop BeJek (validasi pacing).
- GUT belum terpasang (runner sendiri dipakai).

## NEXT (urutan §9 BeJek)
1. ✅ **Boost** opt-in (judi saat develop) — §6.4 *(selesai)*
2. ✅ **Rush-release** (rilis cepat → cepat tapi skor turun + insiden) — §6.2 *(selesai)*
3. ✅ **Proposal / versi v2+** (buka fitur lanjutan) — §5 *(selesai)*
4. ✅ **Hiring channels berbiaya** (mulut/koran/internet/TV/headhunter) — §3.2 *(selesai)*
5. ✅ **Combo talent×tim** (team chemistry "Seadanya"→"Luar Biasa", DNA Kairosoft) — §9 P1+ *(selesai)*
6. **Balancing playtest** (boost chance, rush incident, proposal effort, biaya channel, tier combo, runway pacing) — butuh feedback playtest user

## P2 — Content & Art (BARU MULAI)
- ✅ Kantor visual tumbuh otomatis (tier Garasi→Menara) + badge peran + banner aktivitas + audio cue.
- ✅ **Reveal rilis** ala Game Dev Story: layar skor animasi (4 bar dimensi terisi + Review /40
  menghitung naik + verdict + user gain + insiden), jeda saat reveal lalu lanjut. Sinyal
  `feature_released` + `FeatureProject.dim_ratios()`.
- ✅ **Speech bubble in-world**: reaksi emoji di atas pekerja (🐞 QA nemu bug · 😴 kelelahan ·
  💡 nawarin boost · 🚀/💥 hasil boost), naik & memudar. Sinyal `worker_react` + `OfficeRenderer.head_pos()`.
- ⏳ Ikon fitur per layanan, animasi karakter lebih kaya (jalan ke meja), overlay milestone/funding.
- ⏳ Integrasi pixel art final (MENUNGGU ASET dari user — Claude pakai CC0/placeholder).
- ⏳ Layar/efek rilis & funding, SFX tambahan.
- Catatan: pembuatan art & audio ASLI = ranah user (CLAUDE.md §7). Sistem siap menerima aset final.

## Catatan balance (perlu playtest)
- Stamina drain/recover, pacing minggu, biaya/revenue, threshold review — semua di `data/*.json`, gampang di-tweak.
- Nama kandidat bisa duplikat (NAMES pool kecil).
