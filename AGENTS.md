# al_medynah â€” Quran Flutter App

## Quick start
```sh
flutter pub get
flutter run          # run on device/emulator
flutter analyze      # lint (uses flutter_lints defaults)
flutter test         # no tests exist yet
```

## Key structure
| Path | Purpose |
|------|---------|
| `lib/main.dart` | Entry: `SplashScreen` â†’ `HomePage` |
| `lib/screens/splash.dart` | 3s splash, navigates to `HomePage` |
| `lib/screens/home_page.dart` | Main menu (Arabic RTL, dark/light toggle, date, grid, search) |
| `lib/screens/ayah_list_page.dart` | Surah list â†’ navigates to `MushafScreen(pageNumber)` |
| `lib/screens/quran_search_screen.dart` | Verse search across 604 JSON page files |
| `lib/screens/reciter_page.dart` | Fetches reciters from live Quran.com API, download/play |
| `lib/features/quran/mushaf_screen.dart` | Quran mushaf (page-by-page), word-tap highlights, audio sync |
| `lib/model/surah_model.dart` | Surah model + all 114 surahs as `const` list |
| `lib/model/reciters_model.dart` | Reciter model with `fromJson` |
| `lib/services/audio_manager_api.dart` | Singleton `AudioManager`: fetch reciters/audio/timings from Quran.com API, download/play with `just_audio` |

## Assets
- `assets/quran_data/pages/` â€” 604 JSON files (one per page, word-level data)
- `assets/quran_data/verses.json` â€” verse lookup data
- `assets/quran_data/fonts/` â€” 47 QCF Hafs .ttf fonts (page-range mapped via `font-map.json`)
- `assets/images/` â€” background.png, logo.jpg, surah header frames, ayah number frames
- Font families registered in `pubspec.yaml` (QCF4_Hafs_01 through QCF4_Hafs_47)

## Notable conventions
- UI is RTL Arabic; uses `Directionality(textDirection: TextDirection.rtl)` per-screen
- Gold/dark brown color scheme (`Color(0xFFB8964E)`, `Color(0xFF3E2A0F)`)
- `AudioManager()` is a singleton (use `AudioManager()` factory, not `AudioManager._internal()`)
- Reciter data fetched live from `https://api.qurancdn.com/api/qdc/audio/reciters` â€” no local list
- Audio downloads stored in `{appDocDir}/audio/{reciterId}/{surahNumber padded 3}.mp3`
- Selected reciter persisted via `SharedPreferences` keys: `selected_reciter`, `selected_server_url`, `selected_reciter_name`
- No CI config, no tests, no codegen, no build_runner
