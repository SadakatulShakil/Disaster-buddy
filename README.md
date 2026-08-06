# Bipod Bondhu — বিপদ বন্ধু

Disaster-preparedness app for kids. Free version.
Initial hazards: **Earthquake, Flood, Lightning**.

Stack: Flutter · GetX · Clean Architecture · Floor · flutter_screenutil · Bn/En.

---

## ✅ Phase 0 — what's already done in this scaffold

- Clean Architecture folders (`core / data / domain / presentation`)
- `pubspec.yaml` with all dependencies
- Theme: `AppColors`, `AppTextStyles`, `AppTheme` (teal/sand palette)
- `AppConstants` + `AssetPaths` + `PrefKeys`
- `UserPrefService` singleton (language, sound, narration speed, first-run)
- Localization: `bn` + `en` GetX translations (`.tr`)
- GetX routing: `AppRoutes`, `AppPages`, `InitialBinding`
- `main.dart` wired up (screenutil + translations + prefs)
- Working flow: **Splash → Language picker → Home (placeholder)**

The placeholder Home is replaced by the real Adventure Map in Phase 2.

---

## 🖥️ Terminal steps to run it on your machine

This folder contains `lib/`, `pubspec.yaml`, `assets/` and config only.
Generate the platform folders (android/ios) with `flutter create`, then
drop these in.

```bash
# 1. Create a fresh Flutter project (gives you android/ ios/ etc.)
flutter create --org com.rimes --project-name bipod_bondhu bipod_bondhu_app
cd bipod_bondhu_app

# 2. Replace the generated lib/, pubspec.yaml, assets/ with the ones here
#    (copy the contents of this scaffold over the new project)
#    - copy lib/          -> bipod_bondhu_app/lib/
#    - copy pubspec.yaml  -> bipod_bondhu_app/pubspec.yaml
#    - copy assets/       -> bipod_bondhu_app/assets/
#    - copy analysis_options.yaml

# 3. Get packages
flutter pub get

# 4. Run
flutter run
```

You should see: tiger splash → language picker (বাংলা / English) →
placeholder home in the chosen language.

### Bangla font (recommended)
Download **Hind Siliguri** (Google Fonts, free), put the 4 `.ttf` files
in `assets/fonts/`, then uncomment the `fonts:` block in `pubspec.yaml`.

---

## ▶️ Next: Phase 1 — Data layer & content engine
- Module manifest JSON schema (`earthquake.json`, `flood.json`, `lightning.json`)
- Floor DB + entities (Module, Progress, Badge, QuizResult, KitItem) + DAOs
- `ContentAssetSource` to load manifests from assets
- Repositories + use cases + controllers
