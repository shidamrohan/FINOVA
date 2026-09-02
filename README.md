# 💰 SmartExpense — Personal Finance Tracker

> A full-featured Flutter expense tracker with cloud sync, budgets, debts, savings goals, analytics, PDF exports, and smart notifications.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Setup & Installation](#setup--installation)
- [Supabase Configuration](#supabase-configuration)
- [Google Sign-In Setup](#google-sign-in-setup)
- [Running the App](#running-the-app)
- [Building for Release](#building-for-release)
- [Settings & Customization](#settings--customization)
- [Known Info](#known-info)

---

## Overview

**SmartExpense** is a Flutter application for tracking personal finances. It supports email/password and Google OAuth authentication via Supabase, stores all data in the cloud, and provides a rich UI with charts, PDF/CSV exports, recurring bill reminders, and multi-currency support.

| Property | Value |
|----------|-------|
| **Package Name** | `com.example.expense_tracker` |
| **Version** | `1.0.0+1` |
| **Flutter SDK** | `>=3.0.0 <4.0.0` |
| **Backend** | Supabase |
| **Min Android SDK** | 21 |
| **Theme** | Light + Dark (green-accented) |

---

## Features

### 🔐 Authentication
- Email / Password Sign Up & Login
- Google Sign-In (OAuth via Supabase — code ready, needs Cloud setup)
- Forgot Password flow
- Email confirmation support
- User profile creation on Supabase `users` table

### 🏠 Dashboard (Home)
- Monthly income vs expense overview
- Quick expense add button
- Recent transactions list
- Budget progress bar
- Navigation to all major sections

### 💸 Expenses
- Add, edit, delete expenses
- Categorize with custom icons & colors
- Filter by month
- Search & sort

### 📊 Analytics
- Bar & line charts (via `fl_chart`)
- Monthly spending trends
- Category breakdown
- Income vs expense comparison

### 💼 Budget Management
- Monthly budget setup
- Multi-budget support (per category)
- Budget history tracking
- Add money / top-up
- Visual progress indicators

### 💵 Income Tracking
- Add multiple income sources
- View income history
- Monthly income totals

### 🏦 Savings Goals
- Create savings goals with targets
- Track progress per goal
- Goal detail view with contribution history

### 💳 Debts
- Add debts (owed to / owed by)
- Debt detail with payment tracking
- Status tracking (active / paid)

### 📅 Bills
- Recurring bill reminders
- Add / edit / delete bills
- Due date tracking
- Local push notifications for upcoming bills

### 📝 Money Notes
- Quick text notes (stored in Supabase)
- Add, edit, delete
- Synced across devices

### 📤 Export
- Export to **PDF** (formatted report)
- Export to **CSV**
- Share via system share sheet

### 🔔 Notifications
- Local push notifications for bills & budgets
- Notification settings screen
- Timezone-aware scheduling (`timezone` + `flutter_local_notifications`)

### ⚙️ Settings
- **Dark / Light mode** toggle
- **Font size**: Small, Medium, Large, Extra Large
- **Language**: English (US), English (UK), Spanish, French, German, Hindi
- **Currency**: 11 currencies with live exchange rates
- **Month start day** configuration
- **Category management** (add, edit, delete categories)
- **Help & Support** (FAQ, Documentation, Bug Report, Contact)
- **Privacy Policy** (full policy, 4 sections)
- **Contact Support** (Email, Website, Feedback, Bug Report)
- **Notification settings**

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **Framework** | Flutter (Dart) |
| **State Management** | Provider |
| **Backend / Auth** | Supabase (`supabase_flutter ^2.3.4`) |
| **Google Auth** | `google_sign_in ^6.1.5` |
| **Local Storage** | Hive + SharedPreferences + SQLite (sqflite) |
| **Charts** | `fl_chart ^0.68.0` |
| **PDF Export** | `pdf ^3.10.7` + `printing ^5.12.0` |
| **CSV Export** | `csv ^6.0.0` |
| **Notifications** | `flutter_local_notifications ^17.0.0` + `timezone ^0.9.2` |
| **Animations** | `animate_do ^3.1.2` + `flutter_animate ^4.3.0` + `lottie ^3.0.0` |
| **Currency Rates** | Live via HTTP (`http ^1.2.0`) |
| **SVG** | `flutter_svg ^2.0.9` |
| **URL Launcher** | `url_launcher ^6.2.4` |
| **Permissions** | `permission_handler ^11.3.0` |
| **Screenshot** | `screenshot ^2.1.0` |
| **Sharing** | `share_plus ^7.2.1` |

---

## Project Structure

```
expense_tracker/
├── lib/
│   ├── main.dart                    # App entry, Supabase init, Provider setup
│   ├── config/
│   │   └── theme.dart               # Light & Dark ThemeData
│   ├── models/                      # Data models
│   │   ├── expense.dart
│   │   ├── income.dart
│   │   ├── budget.dart
│   │   ├── bill.dart
│   │   ├── debt.dart
│   │   ├── savings_goal.dart
│   │   ├── money_note.dart
│   │   ├── category.dart
│   │   └── user_model.dart
│   ├── providers/                   # State management
│   │   ├── auth_provider.dart
│   │   ├── settings_provider.dart
│   │   ├── expense_provider.dart
│   │   ├── income_provider.dart
│   │   ├── budget_provider.dart
│   │   ├── bill_provider.dart
│   │   ├── debt_provider.dart
│   │   ├── savings_goal_provider.dart
│   │   ├── category_provider.dart
│   │   ├── money_note_provider.dart
│   │   ├── notification_provider.dart
│   │   └── app_state_provider.dart
│   ├── services/                    # Business logic & APIs
│   │   ├── auth_service.dart        # Supabase auth + Google Sign-In
│   │   ├── supabase_service.dart    # All Supabase DB operations
│   │   ├── database_service.dart    # Local SQLite operations
│   │   ├── notification_service.dart
│   │   ├── currency_service.dart    # Live exchange rates
│   │   ├── export_service.dart      # CSV export
│   │   └── pdf_export_service.dart  # PDF report generation
│   ├── screens/
│   │   ├── auth/                    # Login, Signup, Forgot Password
│   │   ├── home/                    # Main dashboard
│   │   ├── expenses/                # Expense list + add/edit
│   │   ├── budget/                  # Budget management
│   │   ├── finance/                 # Income, Debts, Savings Goals
│   │   ├── analytics/               # Charts & statistics
│   │   ├── bills/                   # Recurring bills
│   │   ├── stats/                   # Stats screen
│   │   ├── money_notes/             # Notes feature
│   │   ├── settings/                # All settings screens
│   │   ├── profile/                 # User profile
│   │   ├── categories/              # Category management
│   │   └── onboarding/              # Splash screen
│   ├── widgets/                     # Shared UI components
│   │   ├── premium_card.dart
│   │   ├── transaction_list_item.dart
│   │   ├── loading_overlay.dart
│   │   ├── shimmer_loading.dart
│   │   ├── empty_state.dart
│   │   └── ...
│   └── utils/
│       ├── currency_helper.dart
│       ├── currency_converter.dart
│       ├── mock_data_generator.dart
│       └── responsive.dart
├── android/
├── ios/
├── assets/
│   └── icon/                        # App icon (app_icon.png)
├── pubspec.yaml
└── README.md
```

---

## Prerequisites

Before running the app, make sure you have:

- **Flutter** `>=3.0.0` installed → [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Android Studio** or **VS Code** with Flutter extension
- **Android SDK** with min API 21 device/emulator
- A **Supabase** project (already set up — credentials are in `main.dart`)
- **Java / keytool** for SHA-1 generation (comes with JDK)

Verify your setup:

```bash
flutter doctor
```

---

## Setup & Installation

### 1. Clone / Open the Project

```bash
cd expense_tracker
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Generate Hive Adapters (if needed)

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 4. Create your `.env` file

```bash
cp .env.example .env
# Edit .env and fill in your Supabase URL and anon key
```

### 5. Run the App

```bash
flutter run --dart-define-from-file=.env
```

---

## Supabase Configuration

Credentials are loaded at build time from your `.env` file via `--dart-define-from-file`. **Never hardcode them in source code.**

```bash
# .env  (git-ignored — never commit this)
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your_anon_key_here
```

See `.env.example` for the template.

### Required Supabase Tables

The app expects these tables in your Supabase project:

| Table | Purpose |
|-------|---------|
| `users` | User profiles (id, email, name, avatar_url) |
| `expenses` | Expense records |
| `incomes` | Income records |
| `budgets` | Budget configurations |
| `bills` | Recurring bills |
| `debts` | Debt records |
| `savings_goals` | Savings goals |
| `money_notes` | Quick notes |
| `categories` | Expense categories |

> Row Level Security (RLS) must be enabled with policies that allow users to read/write their own data (`auth.uid() = user_id`).

---

## Google Sign-In Setup

Google Sign-In is **fully implemented in code** but requires a one-time Google Cloud setup.

### What You Need

1. A Google Cloud Project
2. Android OAuth credential with your SHA-1
3. iOS OAuth credential with your Bundle ID
4. Google OAuth enabled in Supabase

### Your Debug SHA-1

```
FC:23:A0:1C:79:65:72:05:26:E4:1B:C4:A5:45:8C:F8:11:76:6F:63
```

To regenerate it:

```powershell
# Windows PowerShell
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

### Quick Setup Steps

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project → Enable **Google Sign-In API**
3. **APIs & Services → Credentials → Create OAuth Client ID**
   - Type: **Android** → Package: `com.example.expense_tracker` → SHA-1: (above)
   - Type: **iOS** → Bundle ID: `com.example.expensetracker`
4. Go to your [Supabase Dashboard](https://supabase.com/dashboard)
5. **Authentication → Providers → Google → Enable**
6. Paste your Client ID and Client Secret → Save

For full details see: [`SETUP_GOOGLE_OAUTH.md`](SETUP_GOOGLE_OAUTH.md)

---

## Running the App

### Development

```bash
flutter run                    # Run on connected device/emulator
flutter run -d chrome          # Run as web app
flutter run --release          # Run in release mode
```

### Debugging

```bash
flutter logs                   # View device logs
flutter analyze                # Static analysis
```

---

## Building for Release

### Android APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (Play Store)

```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS

```bash
flutter build ios --release
# Open ios/Runner.xcworkspace in Xcode and archive
```

> For release builds, you'll need to create a release keystore and add its SHA-1 to Google Cloud Console as well.

---

## Settings & Customization

### App Theme

Defined in `lib/config/theme.dart`:

| Token | Light | Dark |
|-------|-------|------|
| Primary | `#13EC5B` (bright green) | `#13EC5B` |
| Background | `#F6F8F6` | `#102216` (dark green-tinted) |
| Surface | `#FFFFFF` | `#1C2E22` |
| Danger | `#DC2626` | `#DC2626` |

### Supported Currencies

INR ₹, USD $, EUR €, GBP £, JPY ¥, RUB ₽, BRL R$, CAD C$, AUD A$, CHF Fr, SEK kr

Exchange rates are fetched live on app start.

### Supported Languages

English (US), English (UK), Spanish, French, German, Hindi

> Language changes the locale preference stored in SharedPreferences. Full i18n/l10n integration can be wired up using the stored value from `SettingsProvider.language`.

### Font Sizes

Small, Medium, Large, Extra Large — stored in SharedPreferences, accessible via `SettingsProvider.fontSize`.

---

## Known Info

| Item | Detail |
|------|--------|
| Package name | `com.example.expense_tracker` |
| Debug SHA-1 | *(see `.env` / `DEPLOYMENT.md`)* |
| Supabase project | *(set in `.env`)* |
| App icon | `assets/icon/app_icon.png` |
| Theme color | `#13EC5B` |
| Background color | `#102216` |

---

*SmartExpense v1.0.0 — Flutter + Supabase*
