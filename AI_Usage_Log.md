# AI Usage Log
This document records all notable AI-assisted actions taken during development and debugging of the app. 

---

## 2025-11-02 — AI assistant (chat & code edits)
- What was asked: "Notifications aren't showing for workouts scheduled in the future — ask the AI to point out likely causes in the scheduling logic and possible areas to inspect."
- How it was applied: Used AI guidance to identify likely causes (permission checks, timezone initialization, channel creation). Based on those pointers, the developer updated notification setup in `lib/main.dart`: added timezone initialization, created Android notification channel, added runtime permission checks (via `permission_handler`), inserted debug log statements to trace scheduling, and added `showTestNotification()` to test immediate delivery.
- Files affected: `lib/main.dart`, `pubspec.yaml` (added `permission_handler`)
- Reflection: Learned that Android 13+ requires explicit notification permission and that timezone initialization and debug logs are essential for diagnosing delivery problems. Manual device testing remained necessary.

---

## 2025-11-02 — AI assistant (debugging)
- What was asked: "Progress tab isn't loading — ask the AI to point out likely reasons why data might be missing (e.g., table creation, migrations, seed logic)." 
- How it was applied: Used AI's diagnostic suggestions to inspect `DatabaseHelper` behavior and seed logic. The developer updated sample data seeding to ensure `workouts`, `calories`, and `weight_logs` tables are populated and documented that an app reinstall or migration may be required when schema changes occur.
- Files affected: `lib/services/database_helper.dart` (schema/table creation and seed logic)
- Reflection: Database schema changes can leave older installs with missing tables; seeding and migration strategies must be included in releases.

---

## 2025-11-03 — AI assistant (Android build fixes)
- What was asked: "Java 8 warnings and Gradle script errors observed during build — ask the AI to point out likely causes and recommended areas to check in Gradle/Kotlin DSL." 
- How it was applied: Based on AI suggestions, the developer enabled core library desugaring in `android/app/build.gradle.kts`, set Java compatibility to 11, added `desugar_jdk_libs` dependency, and removed an invalid `compilerArgs` edit that caused Gradle script errors.
- Files affected: `android/app/build.gradle.kts`
- Reflection: Gradle Kotlin DSL requires correct properties; removing invalid edits fixed compile-time script errors and using Java 11 addressed compatibility warnings.

---

## 2025-11-04 — AI assistant (UI diagnostic)
- What was asked: "Negative width constraint causing layout exceptions on small screens — ask the AI to point out probable layout causes and safe mitigation strategies." 
- How it was applied: Using AI's diagnostic suggestions, the developer updated responsive layout calculations in `lib/screens/home_screen.dart` and related screens to clamp negative values, prefer `LayoutBuilder`, and use `SizedBox`/`Wrap` for safe layout.
- Files affected: `lib/screens/home_screen.dart`, `lib/screens/workout_log_screen.dart` (layout fixes)
- Reflection: Responsive layouts need defensive clamping; testing on narrow devices helped reveal edge cases.

---

## 2025-11-04 — AI assistant (charts & export)
- What was asked: "Ask the AI to point out likely steps to aggregate time-series data for charts and to export that data to CSV for analysis and presentation."
- How it was applied: Used AI guidance to transform raw database rows into time-bucketed series (daily/weekly aggregation), compute moving averages/trendlines, and wire those structures to `fl_chart` widgets (LineChart and BarChart). Implemented a CSV export function to serialize aggregated rows and headers for download.
- Files affected: `lib/screens/progress_screen.dart`, `lib/services/database_helper.dart` (query helpers)
- Reflection: Learned practical aggregation patterns (bucketing, gap-filling, averaging) and simple CSV formatting that makes chart data portable for analysis or grading.

---

## 2025-11-01 — AI assistant (sample-data seeding & demo)
- What was asked: "Ask the AI to point out reasonable sample data shapes and seeding strategies for demonstrations and testing (avoid duplicating rows on repeated seeds)."
- How it was applied: Based on AI suggestions, the developer implemented `seedSampleData()` to populate realistic workout entries, calorie logs, and weight records and added a seed/demo button in the Progress screen to populate the app for presentations. The seeding logic avoids duplicates by checking existing rows or using idempotent inserts.
- Files affected: `lib/services/database_helper.dart`, `lib/screens/progress_screen.dart`
- Reflection: Sample data makes demonstrations immediate and reliable; seeding must be idempotent or accompanied by a reset option to avoid polluting real user data.

---

## 2025-11-05 — AI assistant (FutureBuilder / data mutation diagnostic)
- What was asked: "Ask the AI to point out likely causes when sorting query results in a FutureBuilder raises a read-only or unmodifiable-list error."
- How it was applied: The AI suggested that `sqflite` query results can be unmodifiable views and recommended creating a modifiable copy before performing in-place operations (sort, shuffle). The developer updated the code in `lib/screens/progress_screen.dart` to copy lists before sorting and added comments to prevent future regressions.
- Files affected: `lib/screens/progress_screen.dart`
- Reflection: Small mutable-vs-immutable mistakes are common when using database query results; copying before mutation prevents runtime exceptions and simplifies UI code.

---

## 2025-11-06 — AI assistant (CSV export diagnostic)
- What was asked: "Ask the AI to point out likely causes when exported CSV files open incorrectly (bad headers, missing newlines, or quoting issues)."
- How it was applied: The AI recommended consistent header ordering, quoting fields containing commas/newlines, and normalizing newline characters. The developer applied these suggestions when building the CSV export in `lib/screens/progress_screen.dart`, ensuring header rows are written once and each data row is escaped and terminated with `\n`.
- Files affected: `lib/screens/progress_screen.dart`
- Reflection: Proper CSV formatting is essential for interoperability with spreadsheet tools; small formatting fixes make exported files reliable for grading and analysis.

---

## 2025-11-08 — AI assistant (notification test & verification steps)
- What was asked: "Ask the AI to list practical, step-by-step checks a developer should run on device/emulator to verify scheduled notifications (permissions, channel, timezone, immediate test)."
- How it was applied: The AI listed steps (check app notification permission, run `showTestNotification()`, verify channel existence, schedule near-future notification, check Do Not Disturb). The developer added a small test button in `lib/screens/workout_log_screen.dart` to trigger `showTestNotification()` and followed the checklist on a test device to confirm behavior.
- Files affected: `lib/screens/workout_log_screen.dart`, `lib/main.dart`
- Reflection: Having a short device checklist and an immediate-test action accelerates debugging and confirms whether scheduling or system-level settings are the blocker.

---

## 2025-11-09 — AI assistant (database migration diagnostic)
- What was asked: "Ask the AI to point out likely migration strategies and causes for "no such table" errors after schema changes." 
- How it was applied: The AI recommended versioned migrations, fallback seeding, and communicating to users to reinstall if migrations are not supported. The developer added migration notes to `lib/services/database_helper.dart` and documented that older installs might require a reinstall or dedicated migration step.
- Files affected: `lib/services/database_helper.dart`, developer notes
- Reflection: Planning schema migrations early avoids data loss; documenting migration requirements is important for testers and graders.
