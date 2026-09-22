# Local Android performance

For performance testing on the connected ARM64 phone, use an AOT profile build
with the existing local backend:

```powershell
flutter build apk --profile --target-platform android-arm64 --dart-define=APP_ENV=local --dart-define=USE_FIREBASE=false
adb install -r build/app/outputs/flutter-apk/app-profile.apk
```

Keep the package and signing identity unchanged and use `install -r` to preserve
the SQLite database. Do not uninstall to resolve a signing mismatch.

Debug builds run with development checks and JIT compilation; do not use their
scrolling or startup timings as production performance measurements. The profile
build above retains local account, store application, and chat behavior. It does
not enable communication between devices. Production release builds continue to
require Firebase through `AppConfig.validate`.

UI performance changes:

- Tabs initialize on first visit and retain their state afterward.
- Home sections are built as a lazy sliver list.
- Product photos decode at a bounded display-appropriate width.
- Navigation avoids full-screen fade composition and backdrop blur.
- Local demo operations no longer have artificial delays.

Regression checks: `test/tab_loading_test.dart`, `test/redesign_test.dart`,
`test/location_map_test.dart`, `test/store_chat_test.dart`, `test/widget_test.dart`.

## Device spot check, 2026-09-09

RMX3142, ARM64, existing app data retained:

- Android `am start -W` reported cold Activity launch: Debug 3267 ms;
  updated Profile 1580 ms.
- Welcome-screen process PSS snapshots: Debug 366531 KB; Profile 172238 KB.
- 19 regression tests passed; changed Dart files passed static analysis.

These are individual observations, not a controlled benchmark or measurements
of Flutter frame timing, network tile loading, or every application operation.
