# JewelTrack 💎
### Karigar Management App for Indian Jewellery Shop Owners

A local-first Flutter app for managing karigars (craftsmen), gold jobs, weights, and wastage — with WhatsApp reminders, backup/restore, and a beautiful dark gold UI.

---

## ✅ Features

- **Login / Shop Setup** — One-time setup with owner name, shop name, mobile number
- **Home Screen** — Gold summary card, karigar grid with status dots (🟢 free / 🟡 active / 🔴 overdue), universal search
- **Karigar Management** — Add, edit, delete karigars (delete blocked if active jobs exist)
- **Job Management** — Add jobs with ornament name, gold weight (grams), design image, expected date, karigar
- **Job Detail** — Design image (Hero animation), call button, WhatsApp reminder, Work Done flow with gross + net weight
- **Wastage Calculation** — `Wastage = Issued Weight − Net Gold Weight`
- **Cancel Job / Return Gold** — Returns gold without marking wastage
- **History Tab** — All completed jobs, searchable, with wastage summary
- **Profile & Backup** — Edit shop profile, export ZIP backup, restore from ZIP

---

## 🚀 Setup Instructions

### Prerequisites
- Flutter SDK ≥ 3.0
- Dart SDK ≥ 3.0
- Android Studio / Xcode

### Step 1 — Clone & Install
```bash
# Copy all these files into a new Flutter project
flutter create jeweltrack
# Replace lib/, android/, ios/, pubspec.yaml with the provided files

cd jeweltrack
flutter pub get
```

### Step 2 — Generate Isar Code
```bash
dart run build_runner build --delete-conflicting-outputs
```
This generates `*.g.dart` files for all models (ShopProfile, Karigar, Job).

### Step 3 — Run
```bash
flutter run
```

---

## 📁 Project Structure

```
lib/
├── main.dart                        # Entry point, app theme, routing
├── models/
│   ├── shop_profile.dart            # Isar collection: shop owner data
│   ├── karigar.dart                 # Isar collection: karigar records
│   └── job.dart                     # Isar collection: job records
├── providers/
│   └── app_providers.dart           # Riverpod providers for all state
├── screens/
│   ├── login/login_screen.dart      # First-launch setup screen
│   ├── home/home_screen.dart        # Main screen with grid & summary
│   ├── karigar/
│   │   ├── karigar_detail_screen.dart  # Karigar profile + job tabs
│   │   └── add_karigar_screen.dart     # Add/Edit karigar form
│   ├── job/
│   │   ├── add_job_screen.dart      # Add/Edit job form
│   │   └── job_detail_screen.dart   # Job detail with actions
│   ├── history/history_screen.dart  # All completed jobs
│   └── profile/profile_screen.dart  # Settings + Backup/Restore
└── utils/
    ├── app_theme.dart               # Dark gold theme, colors, typography
    ├── database_service.dart        # Isar DB read/write helpers
    ├── image_service.dart           # Image pick + compress (background isolate)
    ├── backup_service.dart          # ZIP backup + restore
    └── communication_service.dart   # Call + WhatsApp deep links
```

---

## 🔧 Key Technical Decisions

| Concern | Solution |
|---|---|
| **Database** | Isar (local-only, no Firebase) |
| **State Management** | Riverpod StateNotifier |
| **Image Compression** | `flutter_image_compress` via background `Isolate.run()` |
| **Backup** | `archive` package — ZIP of DB file + images folder |
| **WhatsApp** | `url_launcher` deep link `https://wa.me/91XXXXXXXXXX?text=...` |
| **Share Receipt** | `share_plus` — text summary + design image |
| **Gold Unit** | Always grams, enforced everywhere in UI |
| **Overflow Prevention** | SafeArea + SingleChildScrollView on all screens |

---

## 📦 Dependencies (pubspec.yaml)

```yaml
flutter_riverpod: ^2.5.1       # State management
isar + isar_flutter_libs: ^3.1 # Local database
path_provider: ^2.1.3          # App directory
image_picker: ^1.1.2           # Camera/Gallery
flutter_image_compress: ^2.3.0 # Image compression
url_launcher: ^6.3.0           # Call + WhatsApp
share_plus: ^9.0.0             # Share receipt
archive: ^3.6.1                # ZIP backup
file_picker: ^8.0.7            # Pick backup ZIP
google_fonts: ^6.2.1           # Playfair Display + Lato fonts
intl: ^0.19.0                  # Date formatting
```

---

## 📱 Android Permissions Required

Add to `android/app/src/main/AndroidManifest.xml` (already included):
- `CALL_PHONE`
- `CAMERA`
- `READ_EXTERNAL_STORAGE` / `READ_MEDIA_IMAGES`
- `INTERNET`

---

## 🍎 iOS Permissions Required

Already in `ios/Runner/Info.plist`:
- `NSCameraUsageDescription`
- `NSPhotoLibraryUsageDescription`
- `LSApplicationQueriesSchemes` → whatsapp, tel

---

## 🔄 Backup & Restore Flow

**Backup:** Creates a `.zip` containing:
- `default.isar` (Isar database file)
- `job_images/` folder (all compressed design photos)

Share via WhatsApp, Gmail, Drive, etc.

**Restore:** Pick the `.zip` file → app closes Isar → extracts files → reopens DB → all data is back.

---

## 🧮 Wastage Formula

```
Wastage (grams) = Issued Weight − Net Gold Weight
```

- **Issued Weight** — Gold given to karigar for the job
- **Net Gold Weight** — Gold weight of finished ornament (excluding stones)
- **Gross Weight** — Total finished ornament weight (including stones, for reference)

---

## ⚠️ Validation Rules

- Received weight cannot exceed issued weight (warning dialog shown)
- Karigar cannot be deleted if they have active jobs
- Once a job is completed, only `Net Gold Weight` (received weight) can be edited
- Gold weight inputs only accept positive decimal numbers
- All weight values displayed with "grams" unit

---

## 🌙 UI Theme

- **Colors:** Deep dark background (`#0F0E0A`), luxury gold (`#C9A84C`), card surfaces
- **Fonts:** Playfair Display (headings) + Lato (body)
- **Status Dots:** 🟢 Green = free, 🟡 Yellow = active, 🔴 Red = overdue
- **No overflows:** Every screen uses `SafeArea` + `SingleChildScrollView`

---

*Built with Flutter + Isar + Riverpod. Local-first, no internet required.*
