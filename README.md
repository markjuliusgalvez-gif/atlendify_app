# 📱 Atlendify - Smart Attendance Management

A modern Flutter-based attendance tracking system for educators and administrators.

## ✨ Features

### 🎯 Core Functionality
- **QR Code Scanning** - Embedded mobile scanner for instant attendance marking
- **Dynamic Student Registration** - Scan any student QR → auto-create profile → auto-enroll → mark attendance
- **Real-time Dashboard** - Live attendance table updates without manual refresh
- **Session Management** - Start/close sessions with automatic time tracking
- **Late/Present Detection** - Automatic status based on session timing rules

### 📊 Reporting & Export
- **Professional PDF Reports** - Subject header, summary cards, session details, attendance table
- **Student Records** - Individual attendance history with status indicators
- **Admin Records** - Full oversight with filtering and search

### 🎨 User Experience
- **Soft Blue Theme** - Modern, calm design with PlusJakartaSans typography
- **Light/Dark Mode** - System-aware theme switching
- **Smooth Animations** - Entrance, fade, and slide transitions
- **PIN Security** - Admin gate protection

### 👥 Role-Based Access
- **Admin**: Subject management, session control, QR scanning, reports, settings
- **Student**: Profile view, personal attendance records

## 📸 Demo Screenshots

| Screen | Description |
|--------|-------------|
| Splash & Auth | Animated splash → Login/Register with theme toggle |
| Admin Dashboard | Subjects grid, quick actions, navigation |
| Subject Dashboard | Session card, live scanner, attendance table |
| QR Scanner | Embedded camera with overlay guide |
| PDF Export | Professional reports with branding |
| Student View | Personal records with status badges |

## 📦 Downloads

| Platform | File | Install |
|----------|------|---------|
| **Android** | `app-release.apk` | Enable "Unknown sources" → Install |
| **iOS** | `atlendify-unsigned.ipa` | Install via TestFlight or AltStore (unsigned) |

## 🚀 Quick Start

1. **Admin**: Login → Enter PIN → Manage Subjects → Start Session → Scan QR codes
2. **Student**: Register → Auto-enroll via QR scan → View attendance in profile
3. **Export**: Open Subject → Tap Export → Share/Print PDF report

## 🛠 Tech Stack

- **Framework**: Flutter 3.24 + Dart
- **Navigation**: GoRouter
- **State**: Riverpod
- **Database**: SQLite (sqflite) with Repository pattern
- **QR Scanning**: mobile_scanner
- **PDF**: pdf + printing packages
- **Architecture**: Feature-first, clean separation

## 📱 Platform Support

- ✅ **Android** (API 21+) - APK included
- ✅ **iOS** (13+) - Unsigned IPA built on macOS runners
- 🌐 **Web** - Compatible (not in this release)
- 💻 **Desktop** - Compatible (not in this release)

---

**Built with ❤️ for educators everywhere**

*Report issues: https://github.com/markjuliusgalvez-gif/atlendify_app/issues*
