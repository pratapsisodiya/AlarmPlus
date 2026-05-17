# Unresolved Issues & Improvements

This document tracks identified issues, deprecations, and potential logic bugs in the **AlarmPlus** project that need fixing.

## 🔴 High Priority: Potential Bugs & Reliability
- **Empty Tests:** `test/widget_test.dart` is empty. There is zero automated test coverage for core alarm logic.
- **Android Signing:** `android/app/build.gradle.kts` still uses debug keys for release builds (line 36). A real keystore must be configured before publishing to Play Store.
- **Memory/Hardware Performance:** `.github/workflows/build-apk.yml` mentions "Fix memory issues", implying possible leaks or high consumption during builds/runtime.

## ✅ Fixed
- **Silent Failures (catch blocks):** All empty `catch (_) {}` blocks now log via `debugPrint`.
- **Hardcoded Package Name:** Application ID changed from `com.example.lumio` → `com.alarmplus.app`; Kotlin source files moved to matching package directory.
- **Flutter Deprecations:** All `MaterialStatePropertyAll`, `MaterialStateProperty`, `MaterialState` and `DropdownButtonFormField.value` usages replaced with `WidgetState*` / `initialValue` equivalents.
- **Unused Field:** `_settingsKey` in `storage_service.dart` was already absent in current code (stale issue).

## ✅ Phase 1 Heavy Sleeper Features (Implemented 2026-05-17)
- **Wake-Up Check:** AlarmModel gains `wakeUpCheckEnabled` + `wakeUpCheckMinutes` (5/10/15). After dismiss, a local notification fires; if not tapped within 60 s the alarm re-rings. Toggle in alarm creation sheet.
- **Mission Chaining / Quest Mode:** Already existed in the data model and ring screen (`questMode`, `questSteps`). Now wired end-to-end in creation UI.
- **Guardian Alert System:** `GuardianService` sends an HTTP POST to a user-configured webhook URL after 10 continuous minutes of un-dismissed ringing. Settings tile in Settings screen.
- **Hardcore Anti-Cheat Mode:** AlarmModel gains `hardcoreMode` bool. When enabled: (a) `PopScope(canPop: false)` blocks back-navigation in `AlarmRingScreen`; (b) `AlarmForegroundService` changed to `START_STICKY` + `onTaskRemoved` restarts the service if the app is swiped away.

---
*Updated on 2026-05-17*
