# Implementation Plan: AlarmPlus Heavy Sleeper Features (Phase 1)

This implementation plan details exactly how we will build the "Heavy Sleeper Essentials" to bring AlarmPlus to parity with top competitors like Alarmy, focusing on concrete code changes.

## 1. Wake-Up Check (Post-Dismissal Verification)
**Objective:** Ensure the user didn't fall back asleep after dismissing the alarm.
*   **Data Model Update (`alarm_model.dart`):** Add `wakeUpCheckEnabled` (bool) and `wakeUpCheckMinutes` (int) to the `AlarmModel` class and its `toMap`/`fromMap` methods.
*   **UI Update (`alarms_screen.dart`):** Add a toggle and dropdown (5, 10, 15 mins) for the Wake-Up Check in the alarm creation sheet.
*   **Execution Logic (`alarm_service.dart` & `AlarmForegroundService.kt`):**
    *   On alarm dismiss, if `wakeUpCheckEnabled` is true, schedule a secondary background timer or a local notification for `wakeUpCheckMinutes` into the future.
    *   If the user does not open the app and confirm they are awake within 60 seconds of that check, trigger the alarm payload to ring again.

## 2. Mission Chaining (Multiple Challenges / Quest Mode)
**Objective:** Require users to complete multiple challenges (e.g., Math -> Steps -> QR Code) sequentially to silence the alarm.
*   **Current State:** The data model already supports `questMode` (bool) and `questSteps` (List<ChallengeType>).
*   **UI Engine Refactor (`alarm_ring_screen.dart`):**
    *   Refactor the dismiss state machine. Instead of a single challenge view, iterate through `alarm.questSteps`.
    *   Show a progress indicator (e.g., "Challenge 1 of 3: Math").
    *   The background alarm sound/vibration must **continue playing** until the final challenge in the array is successfully completed.

## 3. Guardian Alert System
**Objective:** Send an automated alert if the alarm rings for an extended period without being dismissed.
*   **Settings UI (`settings_screen.dart`):** Add a "Guardian Alert Webhook" section where users can enter a URL (e.g., an IFTTT, Discord, or Zapier webhook).
*   **Storage (`storage_service.dart`):** Add methods to save/load the `_guardianWebhookUrl`.
*   **Execution Logic (`alarm_ring_screen.dart` or Native Service):**
    *   Start a timer when the alarm begins ringing.
    *   If the alarm rings continuously for 10 minutes, execute an asynchronous HTTP POST request to the saved Webhook URL with a payload: `{"message": "Alarm ringing for 10+ minutes without response!"}`.

## 4. Hardcore Anti-Cheat (Power-Off & App Kill Prevention)
**Objective:** Prevent users from swiping the app away or navigating home during an active alarm.
*   **Android Native Updates (`AndroidManifest.xml` & `MainActivity.kt`):**
    *   Add `SYSTEM_ALERT_WINDOW` permission to allow drawing the alarm screen over other apps.
    *   Intercept the back button (`onBackPressed`) and home button behavior while the `AlarmForegroundService` is active.
    *   Ensure the foreground service automatically restarts the activity if it is pushed to the background while an alarm is ringing.

## 5. Daily Morning Briefing (TTS)
**Objective:** Read the time, wake stats, and schedule to the user upon dismissal to engage their brain.
*   **Dependencies:** Add `flutter_tts` package to `pubspec.yaml`.
*   **Logic (`smart_alarm_service.dart`):**
    *   Create a `playMorningBriefing()` method using the TTS engine.
    *   Script: *"Good morning. It is [Time]. You took [X] seconds to dismiss your alarm. Let's start the day."*
    *   Call this method in `alarm_ring_screen.dart` immediately after the final dismiss challenge is passed and the alarm audio stops.
