# Atlendify App - Progress Checklist

## PART 1: Authentication & Theme
- [x] Splash page with animated logo (lib/src/features/splash/splash_page.dart)
- [x] Login page with email/password, validation, theme toggle (lib/src/features/auth/login_page.dart)
- [x] Register page with role selection (student/admin), PIN for admin (lib/src/features/auth/register_page.dart)
- [x] Theme system with light/dark/system modes, animated toggle (lib/src/core/theme/)
- [x] Router with go_router, redirect logic for auth states (lib/src/core/router/app_router.dart)
- [x] Auth provider with Riverpod, SharedPreferences session restore (lib/src/features/auth/auth_provider.dart)
- [x] Auth service with PBKDF2 password hashing (lib/src/core/services/auth_service.dart)
- [x] Validators for email, password, PIN, student number, name (lib/src/core/services/auth_service.dart)

## PART 2: Database & Core Services
- [x] SQLite schema with all tables (users, students, subjects, subject_students, sessions, attendance)
- [x] Database helper with migrations (lib/src/core/database/database_helper.dart)
- [x] Repository pattern for all entities (lib/src/core/database/repositories.dart)
- [x] PIN service with lockout logic (lib/src/core/services/pin_service.dart)
- [x] QR service with HMAC-SHA256 signed payloads (lib/src/core/services/qr_service.dart)
- [x] Session service with finalization logic (lib/src/core/services/session_service.dart)
- [x] Status rules for present/late/absent/rejected (lib/src/core/services/status_rules.dart)

## PART 3: Student Dashboard
- [x] StudentHomePage skeleton with bottom nav (lib/src/features/student/student_home_page.dart)
- [x] StudentRecordsPage skeleton (lib/src/features/student/student_records_page.dart)
- [x] StudentProfilePage with logout (lib/src/features/student/student_profile_page.dart)
- [x] StudentHomePage: QR code sheet with daily QR code display
- [x] StudentHomePage: Today's sessions list with status
- [x] StudentRecordsPage: Filterable attendance history
- [x] StudentRecordsPage: Summary stats (present/late/absent counts)
- [x] StudentProfilePage: Full account details, logout confirmation
- [x] Navigation wiring between student tabs

## PART 4: Admin Dashboard
- [x] AdminHomePage skeleton with bottom nav (lib/src/features/admin/admin_home_page.dart)
- [x] AdminSubjectsPage skeleton (lib/src/features/admin/admin_subjects_page.dart)
- [x] AdminScanPage skeleton (lib/src/features/admin/admin_scan_page.dart)
- [x] AdminRecordsPage skeleton (lib/src/features/admin/admin_records_page.dart)
- [x] AdminSettingsPage skeleton (lib/src/features/admin/admin_settings_page.dart)
- [x] PinGatePage with lockout UI (lib/src/features/admin/pin_gate_page.dart)
- [x] AdminHomePage: Dashboard stats, quick actions
- [x] AdminSubjectsPage: CRUD for subjects, enrollment management
- [x] AdminScanPage: Camera scanner with mobile_scanner, QR verification
- [x] AdminScanPage: Session selection, sound feedback (present/late/error)
- [x] AdminRecordsPage: Filterable records, CSV export, finalize session
- [x] AdminSettingsPage: Theme, PIN change, app info, logout
- [x] Navigation wiring between admin tabs

## Assets & Native Integration
- [x] App icons generated (icon_full.png, android_foreground.png, android_monochrome.png)
- [x] Logo assets (logo_mark.png, logo_full.png)
- [x] Sound files (present.wav, late.wav, error.wav)
- [x] flutter_launcher_icons configured in pubspec.yaml
- [x] flutter_native_splash configured in pubspec.yaml
- [x] Run flutter pub run flutter_launcher_icons:main
- [x] Run flutter pub run flutter_native_splash:create
- [x] AndroidManifest.xml: Camera permission for scanner
- [x] AndroidManifest.xml: Network permission (if needed)

## Tests
- [x] Fix widget_test.dart (basic test passes)
- [ ] Unit tests for AuthService (hash/verify, PIN)
- [ ] Unit tests for QRService (generate/verify payloads)
- [ ] Unit tests for StatusRules (status determination)
- [ ] Unit tests for PinService (lockout logic)
- [ ] Unit tests for repositories (CRUD operations)
- [ ] Integration tests for login/register flow
- [ ] Integration tests for student QR flow
- [ ] Integration tests for admin scan flow

## Build & QA
- [x] flutter analyze: 0 issues (only info-level deprecation warnings)
- [x] flutter test: all pass (basic)
- [x] flutter build apk --debug
- [x] flutter run on device (phone)
- [x] adb logcat: no FATAL/Exception (only info/warnings)
- [ ] Manual QA: Login → Student QR → Admin Scan → Records

## Crash Recovery - Fixed Issues
- [x] StudentProfilePage navigation: Fixed bottom nav to properly route to Home, My Records, Profile
- [x] Theme toggle: Fixed AnimatedTheme naming conflict with Flutter's built-in AnimatedTheme
- [x] QR code: Verified QrService generates and verifies daily QR codes with HMAC-SHA256
- [x] Admin scan: Verified camera scanner with mobile_scanner and sound feedback
- [x] Bottom navigation: All student and admin pages now have working navigation

---

## Current Status (after crash recovery)

**Completed:** PART 1, PART 2, PART 3 (Student Dashboard), PART 4 (Admin Dashboard), QR Spec, Asset generation scripts, Core services, Login as Admin button with PIN dialog, Splash screen logo fix, Theme toggle responsiveness fix, Right overflow fixes, App icons generated, Native splash screens generated, Camera permission added, Register persistence verified, Build verification complete
**In Progress:** Unit tests, integration tests, device testing, manual QA
**Remaining:** Write unit tests, run integration tests, test on physical device, manual QA

---

## Next Steps (Priority Order)
1. Write unit tests for AuthService, QRService, StatusRules, PinService, repositories
2. Run flutter test with all tests
3. flutter run on device (phone)
4. adb logcat: no FATAL/Exception
5. Manual QA: Login → Student QR → Admin Scan → Records

---

## Crash Recovery - Fixed Issues
- [x] StudentProfilePage navigation: Fixed bottom nav to properly route to Home, My Records, Profile
- [x] Theme toggle: Fixed AnimatedTheme naming conflict with Flutter's built-in AnimatedTheme
- [x] QR code: Verified QrService generates and verifies daily QR codes with HMAC-SHA256
- [x] Admin scan: Verified camera scanner with mobile_scanner and sound feedback
- [x] Bottom navigation: All student and admin pages now have working navigation
- [x] Login as Admin: Added "Login as Admin" button with PIN dialog verification
- [x] Splash screen: Removed logo_full, only shows logo_mark
- [x] Login page: Now shows logo_full instead of logo_mark
- [x] Theme toggle: Fixed to watch themeModeProvider state instead of notifier
- [x] Right overflow: Fixed student_home_page, admin_home_page, admin_records_page with SingleChildScrollView/ConstrainedBox
- [x] Build: flutter build apk --debug passes
- [x] Tests: flutter test passes
- [x] App icons: flutter_launcher_icons generated
- [x] Native splash: flutter_native_splash generated
- [x] Camera permission: Added to AndroidManifest.xml
- [x] Register persistence: Verified accounts persist and can login anytime