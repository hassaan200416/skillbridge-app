# SkillBridge Requirements & Setup Guide

Complete guide to project dependencies, environment setup, and build/deployment instructions.

---

## Table of Contents

1. [System Requirements](#system-requirements)
2. [Dependencies](#dependencies)
3. [Environment Setup](#environment-setup)
4. [Local Development](#local-development)
5. [Build Instructions](#build-instructions)
6. [Deployment](#deployment)
7. [Troubleshooting](#troubleshooting)

---

## System Requirements

### Minimum Versions

| Component   | Version       | Note                                  |
| ----------- | ------------- | ------------------------------------- |
| Flutter     | 3.27+         | Ensure `flutter --version` matches    |
| Dart        | 3.4.0 - 4.0.0 | Bundled with Flutter                  |
| Java        | 11+           | Required for Android builds           |
| Android SDK | API 31+       | Target API 35+ recommended            |
| Xcode       | 15.0+         | Required for iOS/macOS builds         |
| CocoaPods   | 1.15+         | iOS dependency manager                |
| Node.js     | 18+           | Optional (for web build optimization) |

### Supported Platforms

- ✅ **Android** (API 31+)
- ✅ **iOS** (iOS 13+)
- ✅ **Web** (Chrome, Firefox, Safari, Edge)
- ✅ **Windows** (Windows 10+)
- ✅ **macOS** (macOS 11+)
- ✅ **Linux** (Ubuntu 20.04+)

### IDE & Tools

- **Recommended IDE:** Android Studio with Flutter/Dart plugins
- **Alternative IDE:** VS Code with Flutter and Dart extensions
- **Build Tools:** Gradle (Android), CocoaPods (iOS)

---

## Dependencies

### Core Framework & State Management

| Package               | Version | Purpose                                 |
| --------------------- | ------- | --------------------------------------- |
| `flutter`             | SDK     | UI framework                            |
| `flutter_riverpod`    | ^2.6.1  | State management (reactive, composable) |
| `riverpod_annotation` | ^2.6.1  | Riverpod code-gen annotations           |
| `riverpod_generator`  | ^2.6.1  | Build-time code generation (dev)        |

### Backend & Data

| Package            | Version | Purpose                                       |
| ------------------ | ------- | --------------------------------------------- |
| `supabase_flutter` | ^2.8.4  | Supabase client (auth, DB, realtime, storage) |
| `http`             | ^1.2.2  | HTTP client for Groq AI API                   |
| `uuid`             | ^4.5.1  | Generate UUIDs client-side                    |

### Navigation & Routing

| Package     | Version | Purpose                              |
| ----------- | ------- | ------------------------------------ |
| `go_router` | ^14.6.2 | Declarative routing with auth guards |

### Configuration & Environment

| Package          | Version | Purpose                        |
| ---------------- | ------- | ------------------------------ |
| `flutter_dotenv` | ^5.2.1  | Load .env variables at runtime |

### UI & Widgets

| Package                | Version | Purpose                                         |
| ---------------------- | ------- | ----------------------------------------------- |
| `google_fonts`         | ^8.0.2  | Poppins/Inter fonts for web (auth/marketing UI) |
| `flutter_rating_bar`   | ^4.0.1  | Interactive star rating widget                  |
| `shimmer`              | ^3.0.0  | Loading skeleton shimmer effect                 |
| `table_calendar`       | ^3.1.2  | Calendar widget for date selection              |
| `fl_chart`             | ^0.69.0 | Line/bar/pie charts for analytics               |
| `cached_network_image` | ^3.4.1  | Image caching with HTTP headers                 |
| `cupertino_icons`      | ^1.0.8  | iOS-style icons (bundled with Flutter)          |

### Media & Files

| Package         | Version | Purpose                                |
| --------------- | ------- | -------------------------------------- |
| `image_picker`  | ^1.1.2  | Pick images from device camera/gallery |
| `image_cropper` | ^8.0.2  | Crop images before upload              |
| `file_picker`   | ^11.0.2 | Pick files from device storage         |
| `path_provider` | ^2.1.5  | Access device file system paths        |
| `share_plus`    | ^10.1.2 | Native share sheet (iOS/Android)       |

### Utilities & Formatters

| Package             | Version | Purpose                                           |
| ------------------- | ------- | ------------------------------------------------- |
| `intl`              | ^0.19.0 | Date/number formatting (DateFormat, NumberFormat) |
| `timeago`           | ^3.7.0  | Relative timestamps ("2 hours ago")               |
| `connectivity_plus` | ^6.1.1  | Detect network connectivity changes               |
| `url_launcher`      | ^6.3.1  | Open URLs, phone, email links                     |

### Development Dependencies

| Package         | Version | Purpose                           |
| --------------- | ------- | --------------------------------- |
| `flutter_test`  | SDK     | Unit & widget testing             |
| `build_runner`  | ^2.4.13 | Code generation runner (Riverpod) |
| `flutter_lints` | ^5.0.0  | Linting rules                     |

---

## Environment Setup

### 1. Install Flutter & Dart

#### macOS / Linux

```bash
# Install Flutter (uses git)
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:$(pwd)/flutter/bin"

# Verify installation
flutter --version
dart --version
```

#### Windows

```powershell
# Download Flutter from https://flutter.dev/docs/get-started/install/windows
# Extract to C:\flutter (or preferred location)
# Add to PATH: C:\flutter\bin

# Verify
flutter --version
dart --version
```

### 2. Set Up Android Development

#### macOS / Linux / Windows

```bash
# Install Android SDK (via Android Studio or brew)
flutter doctor -v

# Configure Android SDK path (if needed)
export ANDROID_SDK_ROOT=/path/to/android/sdk
export ANDROID_HOME=$ANDROID_SDK_ROOT

# Accept Android licenses
flutter doctor --android-licenses
```

### 3. Set Up iOS Development (macOS only)

```bash
# Install CocoaPods
sudo gem install cocoapods

# Install iOS development tools
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer

# Verify setup
flutter doctor -v
```

### 4. Clone Repository

```bash
# Clone SkillBridge repository
git clone https://github.com/yourorg/skillbridge-app.git
cd skillbridge-app

# Install dependencies
flutter pub get
```

### 5. Create Environment File

#### Create `assets/app.env`

```bash
# Supabase Configuration
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# Groq API Configuration (for SkillBot AI)
GROQ_API_KEY=gsk_your_api_key_here

# Optional: Custom Backend URL (if not using Supabase directly)
# BACKEND_URL=https://your-backend.com
```

**Security Note:** Never commit `app.env` to version control. Add to `.gitignore`:

```
assets/app.env
ios/.symlinks/plugins/flutter_dotenv/.env
```

### 6. Configure Supabase Backend

#### Prerequisites

- Create Supabase account: https://supabase.com
- Create new project (PostgreSQL database)

#### Database Schema

Run these SQL queries in Supabase SQL Editor to set up tables:

```sql
-- Users table
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT auth.uid(),
  email TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  role TEXT CHECK (role IN ('customer', 'provider', 'admin')) NOT NULL,
  verified BOOLEAN DEFAULT FALSE,
  suspended BOOLEAN DEFAULT FALSE,
  profile_picture_url TEXT,
  experience_years INTEGER,
  service_area TEXT,
  location TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Services table
CREATE TABLE services (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  rating DECIMAL(2,1) DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  ai_summary TEXT,
  ai_summary_cached_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Bookings table
CREATE TABLE bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  provider_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  service_id UUID NOT NULL REFERENCES services(id) ON DELETE CASCADE,
  booking_date DATE NOT NULL,
  time_slot TEXT CHECK (time_slot IN ('morning', 'afternoon', 'evening')),
  status TEXT CHECK (status IN ('pending', 'confirmed', 'completed', 'cancelled')) DEFAULT 'pending',
  price_at_booking DECIMAL(10,2) NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Reviews table
CREATE TABLE reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_id UUID NOT NULL REFERENCES services(id) ON DELETE CASCADE,
  booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
  customer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  provider_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  rating INTEGER CHECK (rating >= 1 AND rating <= 5) NOT NULL,
  comment TEXT,
  flagged BOOLEAN DEFAULT FALSE,
  provider_response TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Notifications table
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  related_id UUID,
  read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Conversations table
CREATE TABLE conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  provider_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  last_message TEXT,
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Messages table
CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  text TEXT NOT NULL,
  is_bot BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Chat read tracking table
CREATE TABLE chat_read_state (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  last_read_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, conversation_id)
);
```

#### Enable Row-Level Security (RLS)

```sql
-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE services ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_read_state ENABLE ROW LEVEL SECURITY;

-- Users: Each user can read all users, write only their own profile
CREATE POLICY "Users can read all profiles" ON users FOR SELECT USING (TRUE);
CREATE POLICY "Users can update own profile" ON users FOR UPDATE USING (auth.uid() = id);

-- Services: Anyone can read active services, provider can edit own
CREATE POLICY "Services visible if active" ON services FOR SELECT USING (is_active = TRUE);
CREATE POLICY "Providers can edit own services" ON services FOR UPDATE USING (auth.uid() = provider_id);

-- Bookings: Customer/provider can see own bookings
CREATE POLICY "Users can see own bookings" ON bookings FOR SELECT
  USING (auth.uid() = customer_id OR auth.uid() = provider_id);
CREATE POLICY "Customers can create bookings" ON bookings FOR INSERT WITH CHECK (auth.uid() = customer_id);
CREATE POLICY "Parties can update booking status" ON bookings FOR UPDATE
  USING (auth.uid() = customer_id OR auth.uid() = provider_id);

-- Notifications: Users can see own notifications
CREATE POLICY "Users can see own notifications" ON notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update own notifications" ON notifications FOR UPDATE USING (auth.uid() = user_id);

-- Conversations: Participants can see conversation
CREATE POLICY "Participants can see conversation" ON conversations FOR SELECT
  USING (auth.uid() = customer_id OR auth.uid() = provider_id);

-- Messages: Participants can see messages
CREATE POLICY "Participants can see messages" ON messages FOR SELECT
  USING (EXISTS (SELECT 1 FROM conversations c
    WHERE c.id = messages.conversation_id
    AND (c.customer_id = auth.uid() OR c.provider_id = auth.uid())));
```

#### Configure Storage Buckets

In Supabase Storage tab:

1. Create bucket: `service-images` (public, no authentication required initially)
2. Create bucket: `profile-pictures` (public)

Update RLS policies for public access:

```sql
-- Allow anyone to view images (optional: restrict to authenticated users)
-- Allow users to upload/delete their own images
```

### 7. Configure Groq API (for SkillBot)

1. Sign up at https://console.groq.com
2. Create API key
3. Add to `assets/app.env`:
   ```
   GROQ_API_KEY=gsk_...
   ```

**Pricing:** Groq offers free tier (100 requests/month); paid plans for production.

---

## Local Development

### Run on Emulator/Simulator

```bash
# List available devices
flutter devices

# Run on Android emulator (must be running first)
flutter run

# Run on iOS simulator (macOS only)
flutter run -d "iPhone 15 Pro"

# Run on web (hot reload supported)
flutter run -d chrome

# Run on Windows desktop
flutter run -d windows

# Run on macOS desktop
flutter run -d macos

# Run on Linux desktop
flutter run -d linux
```

### Run on Physical Device

#### Android

```bash
# Enable USB debugging on device
# Connect via USB
flutter run

# Or specify device by ID
flutter run -d <device-id>
```

#### iOS

```bash
# Connect via USB
# Xcode may prompt for provisioning profile setup
flutter run -d <device-id>
```

### Hot Reload & Hot Restart

During `flutter run`:

- Press `r` to hot reload (code changes, no state reset)
- Press `R` to hot restart (full app restart, state reset)
- Press `q` to quit

### Code Generation

After modifying files with `@riverpod` annotation:

```bash
# Generate code (one-time)
flutter pub run build_runner build

# Watch mode (auto-regenerate on file changes)
flutter pub run build_runner watch

# Clean generated files
flutter pub run build_runner clean
```

### Run Analyzer & Tests

```bash
# Check for lint violations
flutter analyze

# Run unit/widget tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run tests with coverage
flutter test --coverage

# View coverage report (if coverage tool installed)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## Build Instructions

### Android

#### Debug APK (for testing)

```bash
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk
```

#### Release APK (for app stores)

```bash
# Create/configure signing key (first time only)
keytool -genkey -v -keystore ~/.android/release-keystore.jks \
  -alias skillbridge \
  -keyalg RSA -keysize 2048 -validity 10000

# Build release APK
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk
```

#### Release App Bundle (for Google Play Store)

```bash
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS

#### Debug Build

```bash
flutter build ios --debug
```

#### Release Build (for App Store)

```bash
# Requires Apple Developer account and provisioning profiles
flutter build ios --release

# Output: build/ios/iphoneos/Runner.app
# Use Xcode to export IPA for App Store
```

### Web

#### Development Build

```bash
flutter build web --debug
# Output: build/web/ (serves from localhost:8080 with hot reload)
```

#### Release Build

```bash
flutter build web --release
# Output: build/web/ (optimized, minified, ready for deployment)
```

Deploy to Vercel (via GitHub Actions):

```bash
# Commit to main branch → GitHub Actions triggers build
# Vercel deploys build/web/ automatically
```

### Windows

```bash
flutter build windows --release
# Output: build/windows/runner/Release/
```

### macOS

```bash
flutter build macos --release
# Output: build/macos/Build/Products/Release/
```

### Linux

```bash
flutter build linux --release
# Output: build/linux/x64/release/bundle/
```

---

## Deployment

### Web (Vercel)

#### Prerequisites

- GitHub account with repo access
- Vercel account connected to GitHub

#### Automatic Deployment

1. Push to `main` branch
2. GitHub Actions workflow (`.github/workflows/build.yml`) triggers
3. Workflow runs `flutter build web --release`
4. Vercel deploys `build/web/` automatically
5. App live at `https://skillbridge-app-beta.vercel.app`

#### Manual Deployment

```bash
# Install Vercel CLI
npm install -g vercel

# Build locally
flutter build web --release

# Deploy
cd build/web/
vercel
```

#### Environment Variables (in Vercel Dashboard)

```
SUPABASE_URL=https://...supabase.co
SUPABASE_ANON_KEY=eyJ...
GROQ_API_KEY=gsk_...
```

### Android (Google Play Store)

#### Prerequisites

- Google Play Developer account ($25 registration)
- Signing key configured (see Build Instructions above)

#### Upload App Bundle

1. Open Google Play Console
2. Create new app or select existing
3. Navigate to Release → Production
4. Upload `build/app/outputs/bundle/release/app-release.aab`
5. Fill in store listing details, screenshots, privacy policy
6. Submit for review (~24-48 hours)

### iOS (Apple App Store)

#### Prerequisites

- Apple Developer account ($99/year)
- Xcode with provisioning profiles configured

#### Build & Export

```bash
flutter build ios --release
# Open in Xcode:
open ios/Runner.xcworkspace
# Product → Archive → Distribute App → App Store Connect
```

### Database Backups

#### Supabase Auto-Backup

- Supabase automatically backs up daily (included with paid plan)
- Access in Supabase Dashboard → Settings → Backups

#### Manual Backup

```bash
# Export database schema + data
pg_dump postgres://user:pass@host:port/dbname > backup.sql

# Or use Supabase CLI
supabase db dump > backup.sql
```

---

## Troubleshooting

### Common Issues

#### Flutter/Dart Not Found

```bash
# Add Flutter to PATH (macOS/Linux)
export PATH="$PATH:$(pwd)/flutter/bin"

# Add Flutter to PATH (Windows PowerShell)
$env:PATH += ";C:\flutter\bin"

# Verify
flutter doctor
```

#### Android Build Fails

```bash
# Update Gradle
flutter clean
flutter pub get
flutter build apk --debug

# Check Android SDK version
flutter doctor -v

# Accept all licenses
flutter doctor --android-licenses
```

#### iOS Build Fails

```bash
# Clean Xcode build
flutter clean
cd ios && rm -rf Pods Podfile.lock && cd ..
flutter pub get

# Update CocoaPods
sudo gem install cocoapods
```

#### Hot Reload Not Working

```bash
# Restart debug session
flutter run --hot

# Or full restart
flutter run --no-fast-start
```

#### Riverpod Code Generation Issues

```bash
# Clean build artifacts
flutter clean
flutter pub get

# Regenerate code
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

#### Supabase Connection Error

```
Error: Failed to authenticate
```

**Solution:**

- Check `SUPABASE_URL` and `SUPABASE_ANON_KEY` in `assets/app.env`
- Verify Supabase project is running
- Check network connectivity

#### Groq API Errors

```
Error: 401 Unauthorized
```

**Solution:**

- Verify `GROQ_API_KEY` in `assets/app.env` is correct
- Check API key has appropriate permissions
- Verify rate limits not exceeded

### Getting Help

1. **Check Flutter Doctor**

   ```bash
   flutter doctor -v
   ```

   Identifies missing dependencies and version mismatches.

2. **Enable Verbose Logging**

   ```bash
   flutter run -v
   ```

   Shows detailed build logs.

3. **Clean & Rebuild**

   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

   Resolves most build issues.

4. **Check Docs**
   - [Flutter Docs](https://flutter.dev/docs)
   - [Supabase Docs](https://supabase.com/docs)
   - [Riverpod Docs](https://riverpod.dev)
   - [GoRouter Docs](https://pub.dev/packages/go_router)

---

## Test Accounts

### Staging Environment (Supabase)

#### Customer Account

- **Email:** customer@test.com
- **Password:** Test@123456
- **Role:** Customer

#### Provider Account

- **Email:** provider@test.com
- **Password:** Test@123456
- **Role:** Provider

#### Admin Account

- **Email:** admin@test.com
- **Password:** Test@123456
- **Role:** Admin

**Note:** These are demo accounts. Use for local testing only; do not use in production.

---

## Additional Resources

- [Flutter Documentation](https://flutter.dev)
- [Supabase Reference](https://supabase.com/docs)
- [Riverpod Guide](https://riverpod.dev)
- [GoRouter Routing](https://pub.dev/packages/go_router)
- [Material Design](https://material.io/design)

---

## Summary

SkillBridge is a full-stack Flutter application requiring:

- **Flutter 3.27+** with Dart 3.4.0+
- **Supabase** backend with PostgreSQL database
- **Groq API** for AI features (SkillBot)
- **Android/iOS/Web/Desktop** build toolchains

Follow the setup guide above to configure your development environment, then use the build instructions to create releases for each platform. Deployment to Vercel (web) is automated via GitHub Actions; mobile apps are published through respective app stores.
