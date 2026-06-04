# BeJek — Core Systems Design (Refined)
### Desain Sistem Inti: Hiring, Waktu, Research Point, & Pengembangan Fitur

> Dokumen ini menyempurnakan konsep awal. Dipakai bareng `PRD_StartupStory.md`.
> Fokus: bikin tiap angka & sistem saling terhubung dan punya makna strategis,
> bukan sekadar pajangan.

---

## 0. Onboarding — Sang Sekretaris

Saat game pertama dibuka, **Sekretaris** (NPC pemandu) mengarahkan pemain langkah
demi langkah: "Bos, kita belum punya tim. Ayo rekrut dulu." Sekretaris berperan
sebagai suara tutorial sekaligus notifikasi sepanjang game (kandidat melamar,
proposal selesai, runway menipis, fitur rilis). Onboarding = alur terpandu, bukan
wall-of-text.

---

## 1. Dua Mata Uang Inti

| Mata uang | Dapat dari | Dipakai untuk |
|-----------|-----------|----------------|
| **Cash (Rp)** | Revenue layanan, funding | Gaji, iklan rekrut, biaya ops, sewa |
| **Research Point (RP)** | Karyawan saat bekerja (terakumulasi) | Bikin proposal, develop fitur, patch bug |

**Prinsip:** Produk maju lewat **RP**, bukan langsung lewat uang. Uang menjaga tim
tetap hidup; RP membangun produknya. Dua-duanya harus dijaga.

---

## 2. Sistem Waktu (Week-based)

- 1 tahun = **52 minggu**. Tiap **1 minggu = 1 tick** (satu "giliran" / satu hari kerja simulasi).
- Tiap tick: karyawan bekerja → hasilkan RP, cash berkurang (gaji + ops), event bisa muncul, lalu karyawan "pulang".
- **SEMUA biaya dikonversi ke per-minggu** biar pembukuan konsisten.
  - Contoh: total cost karyawan 60jt/tahun → **±1,15jt/minggu** otomatis terpotong tiap tick.
- Kontrol waktu: **play / pause / fast-forward**. Pemain bisa fast-forward saat menunggu fitur kelar.
- **Stamina:** tiap karyawan punya stamina. Kerja menurunkan stamina; minggu istirahat memulihkan. Stamina rendah → output RP turun. Maksa terus (lembur) → risiko burnout / resign. (Opsional untuk P1, bukan P0.)

---

## 3. Hiring System

### 3.1 Alur
1. Pilih **channel rekrut** (bayar biaya iklan).
2. Sekretaris: "Akan ada N kandidat yang melamar."
3. Pemain **cek tiap kandidat** (lihat skill & gaji), lalu terima/tolak.

### 3.2 Channel Rekrut (cost vs kualitas vs jumlah)

| Channel | Biaya | Jumlah kandidat | Kualitas (star talent) | Catatan |
|---------|-------|-----------------|------------------------|---------|
| Mulut ke mulut | Murah / gratis | 1–2 | Acak, cenderung rendah | Modal awal |
| Iklan koran | Sedang | 2–3 | Rendah–menengah | Stabil |
| Iklan internet | Sedang+ | 3–4 | Menengah, variatif | Pool luas |
| Iklan TV | Mahal | 2–3 | Menengah–tinggi | Peluang talent bintang |
| Headhunter | Sangat mahal | 1 (terkurasi) | Tinggi, terjamin | Untuk role kunci |

> Tiap channel punya **distribusi kualitas berbeda**, bukan cuma "lebih mahal = lebih bagus jumlahnya". TV bisa kasih bintang, tapi judi; headhunter mahal tapi pasti.

### 3.3 Anatomi Kandidat (contoh)

```
Developer — Level 1
  Skill Coding      : 10
  Skill UI/UX       : 2
  Skill QA          : 4
  Skill Management  : 1
  Gaji bulanan      : Rp 4.000.000
  BPJS/pajak/dll    : Rp 1.000.000
  Total/bulan       : Rp 5.000.000   (≈ Rp 1.150.000 / minggu)
```

Role lain: **UI/UX Designer, QA Engineer, Product Manager, Marketing, Ops** — tiap
role punya kecenderungan skill dominan berbeda.

---

## 4. Apa Fungsi Tiap Skill (INI YANG BIKIN HIRING BERMAKNA)

Tanpa ini, skill cuma angka. Tiap skill **mengisi komponen fitur** yang cocok
(lihat Bagian 6). Karyawan menghasilkan **point per komponen** tiap minggu:

| Skill | Menghasilkan point untuk komponen | Pengaruh |
|-------|-----------------------------------|----------|
| **Coding** | **Development** | Fungsi inti fitur — fitur tidak jalan tanpa ini |
| **UI/UX** | **UI/UX** | Kualitas tampilan → rating aplikasi & retensi user |
| **QA / Security** | **Security** | Keamanan & ketahanan → cegah insiden (hack, data bocor, server down) |
| **Management** | (semua) | **Booster output** seluruh tim; makin tinggi, makin efisien tim besar |

Konsekuensi desain: tim cuma jago Coding = fitur jalan tapi jelek & rawan diretas.
Pemain dipaksa **menyeimbangkan komposisi tim**, bukan asal cari skill tertinggi.

Point/minggu per komponen (koefisien ditaruh di `data/balance.json`):
```
Point_komponen = Σ(skill_relevan karyawan yang ditugaskan) × koef × (stamina%) × (1 + bonus_management)
```

---

## 5. Proposal — Mendefinisikan Produk

- Sebelum develop, pemain **bikin proposal** (mis. "BeJek v1"). Proposal = membuka
  **roadmap fitur** versi tersebut beserta starting point tiap komponennya.
- Proposal pertama dibuat **terpandu & murah** (hibah tutorial) untuk mengajari mekanik.
  Setelah itu, proposal versi baru butuh effort tim sungguhan.
- Tiap **versi besar baru** (v2, v3, …) butuh proposal baru → membuka fitur-fitur baru.
- Saat proposal kelar, Sekretaris menampilkan **daftar fitur** + kebutuhan komponennya.

---

## 6. Pengembangan Fitur

### 6.0 Alur BERTAHAP per-peran (refinement penting — 2026-06-04)

> Klarifikasi user: pengembangan fitur itu **alur bertahap berbasis peran**, bukan
> sekadar isi komponen paralel. **Pemilihan employee di tiap tahap = kunci sukses.**

**Tahapan satu fitur:**
1. **PRD / Proposal** — tunjuk employee (**Product Manager**) untuk bikin PRD fitur.
   PRD menetapkan **nilai-nilai target** fitur:
   **Creativity · UI/UX (user-friendly) · Security** (+ **Development/fungsi**).
   Skill Product → makin tinggi potensi/pondasi nilai PRD.
2. **Development** — tunjuk **Developer**. Kerjanya **menambah point** ke nilai-nilai
   (terutama Development/fungsi, plus sebagian dimensi lain).
3. **QA** — tunjuk **QA**. QA **menemukan bug** (makin jago makin banyak ketemu).
4. **Bug-fix** — **Developer** memperbaiki bug temuan QA → menaikkan kualitas/Security,
   mengurangi risiko insiden.
5. **Selesai** — fitur kelar membawa akumulasi point di tiap nilai.
6. **Release** — hasil (user & **uang**) **tergantung nilai-nilai tadi**: makin tinggi &
   makin disukai user → revenue makin besar. Nilai jeblok → rilis adem / insiden.

**4 dimensi nilai fitur:** **Creativity, UI/UX, Security, Development.**
(Creativity DITAMBAHKAN di sini; sebelumnya cuma Dev/UI-UX/Security.)

**Implikasi desain:**
- Butuh peran/skill **Product** (untuk PRD) selain Coding/UI-UX/QA/Management.
- Tahap berurutan (PRD → Dev → QA → Fix → Release), bukan cuma isi bareng. Implementasi:
  "fase aktif" per fitur + employee yang ditugaskan per fase.
- **Pemilihan employee yang tepat di tiap fase = inti keseruan & sukses.**

> Catatan implementasi: core `FeatureProject` (komponen + apply_week) sudah ada;
> tinggal tambah dimensi **Creativity**, **fase PRD**, dan loop **QA→bug→fix**.

### 6.1 Setiap fitur punya 3 komponen, masing-masing dengan **starting point** (kebutuhan dasar)

```
Fitur: Form Pesan Ojek
  Development : 50   ← diisi point dari Coding
  UI/UX       : 30   ← diisi point dari UI/UX
  Security    : 20   ← diisi point dari QA/Security
```

- "Starting point" = **kebutuhan dasar tiap komponen** untuk fitur itu (di `data/features.json`).
- Pemain **menugaskan karyawan** ke fitur. Tiap minggu, karyawan menyumbang point ke
  komponen sesuai skill-nya, sampai kebutuhan tiap komponen terpenuhi.
- Komponen terisi → progress bar naik. Fitur "selesai penuh" saat **ketiga komponen** tercapai.

### 6.2 Risk/Reward = keputusan "rilis cepat vs matang" (BUKAN judi acak)

Inilah pengganti mekanik RNG-gagal yang lama — lebih sehat & strategis. Pemain
boleh **merilis fitur lebih awal** walau komponen belum penuh, dengan konsekuensi
sesuai komponen yang dikorbankan:

| Komponen kurang | Konsekuensi |
|-----------------|-------------|
| **Development** belum penuh | Fitur belum bisa rilis sama sekali (ini fungsi inti, wajib penuh) |
| **UI/UX** rendah | Rating aplikasi turun, churn naik (user kabur karena ribet) |
| **Security** rendah | Risiko **insiden**: akun diretas, data bocor, server down → PR buruk, denda, user kabur massal |

→ Pemain menghadapi pilihan nyata tiap fitur: *"kejar rilis cepat demi kalahkan
kompetitor, atau matengin dulu biar aman?"* — ini jauh lebih seru daripada lempar dadu.

### 6.3 Mode Fokus Pengembangan (per-fitur)
*(diadaptasi dari Game Dev Story: Normal/Speed/Quality/Research)*

Saat mulai develop sebuah fitur, pemain memilih **mode fokus** — dial strategis yang
mengubah biaya, kecepatan, dan hasil:

| Mode | Biaya | Efek |
|------|-------|------|
| **Normal** | Dasar | Kecepatan & hasil standar |
| **Kebut Rilis** | +20% | Lebih cepat, tapi komponen UI/UX & Security cenderung tipis → risiko insiden/rating jeblok |
| **Matang** | +30% | Lebih lambat, komponen terisi lebih penuh → rating tinggi |
| **Riset** | +50% | Paling lambat, tapi hasilkan **RP ekstra** untuk fitur berikutnya |

Angka persentase di `data/balance.json`. Mode ini bikin tiap fitur punya keputusan
sendiri, bukan sekadar "tugaskan lalu tunggu".

### 6.4 Boost — judi opt-in (bukan paksaan)
*(diadaptasi dari "development event" Game Dev Story)*

Di tengah pengembangan (mis. progress 25%), seorang karyawan bisa **menawarkan boost**
ke satu komponen. Pemain **memilih** menerima atau menolak:
- **Sukses** → lonjakan besar point di komponen itu (peluang sukses tergantung skill karyawan).
- **Gagal** → menambah banyak **bug/celah** (lihat 6.5) & menurunkan hype fitur.

Karena opt-in dan peluangnya terbaca dari skill, ini judi yang *adil* — pemain hebat
ambil boost saat punya karyawan mumpuni, bukan dipaksa lempar dadu.

### 6.5 Bug & Celah — gameplay aktif untuk Security
*(diadaptasi dari sistem bug/debugging Game Dev Story)*

- Saat tim develop (apalagi mode **Kebut Rilis** atau gagal **Boost**), **bug/celah** menumpuk.
- Bug dibersihkan oleh karyawan ber-skill **QA/Security** (mengisi komponen Security).
- Tiap bug yang dibersihkan memberi **+1–3 RP** kecil → debugging bukan cuma beban, ada imbalannya.
- Rilis dengan bug belum bersih → reviewer (lihat 6.6) bisa menemukannya → rating turun, risiko insiden naik.

### 6.6 Skor Review Rilis → ledakan user awal
*(diadaptasi dari sistem review kritikus Game Dev Story)*

- Tiap rilis versi/fitur besar dinilai **review** (tech blogger / rating app store), mis. skala 40.
- Skor tinggi → **lonjakan adopsi user awal** besar; skor rendah → rilis adem.
- Jika dirilis ngebut dengan bug/Security tipis, reviewer menemukan masalah → skor anjlok.
- Skor sangat tinggi bisa jadi syarat unlock (mis. menarik investor / funding round).

### 6.7 Patch / Hardening
Komponen yang dikorbankan bisa **dilengkapi belakangan** (patch UI/UX, security
hardening, bug-fix) dengan menugaskan karyawan lagi → point komponen naik sampai aman.
Filosofi: persis dunia startup — ship dulu, benerin belakangan.

### 6.8 Kualitas & jembatan balik ke Cash
Komponen **UI/UX** menentukan rating; **Development** menentukan apakah fitur jalan;
**Security** menentukan apakah kamu kena insiden. Fitur matang + skor review tinggi →
user & revenue naik → Cash masuk untuk rekrut & versi berikutnya.

---

## 7. Daftar Fitur BeJek (banyak fitur kecil, sesuai konsep)

> Develop satu per satu. Tiap fitur punya 3 komponen (Development / UI/UX / Security)
> dengan starting point masing-masing. Angka di bawah contoh awal — tweak via data.

**BeJek v1 — Ojek Manual (MVP)**  *(format: Dev / UI-UX / Sec)*
- Form pesan ojek (pelanggan input lokasi) — 50 / 30 / 20
- Dispatch manual (ops/pemain menugaskan driver sendiri) — 60 / 20 / 15
- Kalkulasi tarif sederhana (flat / per-jarak) — 40 / 10 / 10
- Pembayaran tunai — 30 / 15 / 25
- Daftar order masuk — 35 / 25 / 10
- Konfirmasi order selesai — 25 / 15 / 10

**BeJek v2 — Otomasi & Driver**
- Aplikasi sisi driver (terima order)
- Peta & GPS
- Auto-matching driver terdekat
- Estimasi tarif & jarak otomatis
- Rating & review driver
- Riwayat order

**BeJek v3 — Retensi & Monetisasi**
- Kode promo / voucher
- BeJek Poin (loyalty)
- In-app chat pelanggan–driver
- Pesan terjadwal
- Notifikasi push

**BeJek v4 — Ekspansi Layanan**
- BeJek Food (pesan makanan)
- BeJekPay (dompet digital)
- BeJek Kirim (kurir/logistik)
- Top-up & saldo
- Split payment

(Tambahkan terus fitur kecil lain: alamat favorit, multi-stop, jadwal driver,
dashboard mitra, dsb. Banyak fitur kecil = banyak keputusan = lebih adiktif.)

---

## 8. Loop Lengkap (gabungan)

```
Rekrut tim (Cash, via channel iklan)
        ↓
Tim bekerja tiap minggu → isi komponen fitur (point per skill), kena gaji+ops (Cash turun)
        ↓
Bikin Proposal → buka roadmap fitur + starting point komponen
        ↓
Develop fitur: pilih Mode Fokus → isi Dev/UI-UX/Security → (opsional ambil Boost)
        ↓
Bersihkan bug → rilis fitur → dapat Skor Review → ledakan user awal
        ↓
Rating & user naik → Revenue (Cash) masuk
        ↓
Reinvest: rekrut lebih banyak / versi baru / funding round
```

Tension: **Cash (jaga tim hidup)** vs **Point/RP (bangun produk)** vs **Waktu (runway 52 minggu)**
vs **Cepat-vs-Matang (mode fokus & komponen)**.

---

## 9. Catatan Implementasi

- Semua angka (gaji, biaya channel, starting point komponen, persentase mode fokus,
  peluang boost, rate munculnya bug, bobot skor review) → **`data/*.json`**, bukan
  hardcode (sesuai `CLAUDE.md`).
- **Urutan adopsi mekanik (jangan sekaligus):**
  1. P0: komponen Dev/UI-UX/Security + isi via skill + rilis. *(inti — wajib kebukti seru dulu)*
  2. P1: Mode Fokus → Skor Review → Boost opt-in → bug/celah.
  3. P1+: kombinasi talent×proyek (combo "Not good"→"Amazing", DNA Kairosoft).
- P0 prototype cukup: 1 channel rekrut + 3 fitur BeJek v1 + komponen + loop point↔Cash + runway.
  Validasi dulu apakah loop "satu minggu lagi" terasa, baru tambah kedalaman di atas.
