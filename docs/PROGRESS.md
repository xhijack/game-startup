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
- Modal awal **Rp 200 jt**. Founder digaji Rp 1.000.
- Aset CC0 (Kenney) untuk kantor + karakter, audio CC0.

**Data/balance:** `data/balance.json` (`feature_dev`, `bejek`), `data/bejek_v1.json` (6 fitur v1).

### ▶ Tycoon (lama — model awal, masih utuh)
Scene `scenes/main/main.tscn`. Office isometric, talent (level/stamina/train), funding+dilusi, event, kombinasi R&D, kompetitor+promo, multi-layanan, ekspansi kota, upgrade kantor, win=IPO.

## Testing
- `tests/verify_core.gd` (**60 assertion**, headless): `godot --headless --path . -s res://tests/verify_core.gd`.
- `tools/bejek_sim.gd` — simulasi loop BeJek (validasi pacing).
- GUT belum terpasang (runner sendiri dipakai).

## NEXT (urutan §9 BeJek)
1. **Boost** opt-in (judi saat develop) — §6.4
2. **Rush-release** (rilis cepat skip QA → cepat tapi skor turun + insiden) — §6.2
3. **Proposal / versi v2+** (buka fitur lanjutan)
4. Hiring channels berbiaya, balancing playtest

## Catatan balance (perlu playtest)
- Stamina drain/recover, pacing minggu, biaya/revenue, threshold review — semua di `data/*.json`, gampang di-tweak.
- Nama kandidat bisa duplikat (NAMES pool kecil).
