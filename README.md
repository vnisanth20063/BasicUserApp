# BasicUserApp - Full-Stack Flutter & Node.js User Registration System

A beginner-friendly, production-ready full-stack mobile application consisting of a **Flutter Android App** with an emerald-green and white theme, backed by a **Node.js Express REST API** with thread-safe atomic JSON file persistence.

---

## Table of Contents
1. [Project Overview](#project-overview)
2. [Folder Structure](#folder-structure)
3. [Required Software](#required-software)
4. [Backend Setup & Execution](#backend-setup--execution)
5. [REST API Documentation](#rest-api-documentation)
6. [Flutter App Setup & Execution](#flutter-app-setup--execution)
7. [API Base URL Configuration (Emulator vs Phone vs Production)](#api-base-url-configuration)
8. [Physical Android Phone Testing Guide](#physical-android-phone-testing-guide)
9. [Public Backend Deployment Requirements](#public-backend-deployment-requirements)
10. [Building the Release APK & Installation](#building-the-release-apk--installation)
11. [Automated Verification & Test Results](#automated-verification--test-results)
12. [Common Errors & Troubleshooting](#common-errors--troubleshooting)

---

## 1. Project Overview

- **Frontend**: Flutter 3.47+ (Dart 3.13+), Material Design 3, HTTP client, responsive layout, form validation, error handling, loading states, registered user list with pull-to-refresh, in-app API target configuration dialog.
- **Backend**: Node.js (v24+), Express.js (ES Modules), CORS enabled, input validation (name, email, phone), duplicate email prevention, atomic file write and sequential locking to eliminate race conditions, centralized error handling without stack trace leaks.
- **Data Persistence**: JSON file storage (`backend/data/users.json`). *Note: Designed for educational demonstrations and small local testing. For production deployments, migrate to PostgreSQL or MongoDB.*

---

## 2. Folder Structure

```
BasicUserApp/
├── backend/
│   ├── data/
│   │   └── users.json            # Persistent user store (auto-created if missing)
│   ├── .gitignore                # Ignores node_modules, .env, and temp files
│   ├── package.json              # Node.js dependencies (express, cors) & scripts
│   ├── README.md                 # Backend-specific guide & API documentation
│   └── server.js                 # Complete REST API implementation
├── frontend/
│   ├── android/
│   │   └── app/
│   │       ├── build.gradle.kts  # Android build configuration (debug-signed for release testing)
│   │       └── src/main/
│   │           └── AndroidManifest.xml # INTERNET permission & usesCleartextTraffic enabled
│   ├── lib/
│   │   ├── config/
│   │   │   └── api_config.dart   # Centralized API base URL & networking guide
│   │   ├── models/
│   │   │   └── user_model.dart   # UserModel serialization & avatar initials helper
│   │   ├── screens/
│   │   │   └── home_screen.dart  # User registration form & registered users tab view
│   │   ├── services/
│   │   │   └── api_service.dart  # HTTP REST API client with robust error mapping
│   │   ├── theme/
│   │   │   └── app_theme.dart    # White background with emerald-green accents
│   │   ├── widgets/
│   │   │   └── backend_settings_sheet.dart # In-app API switcher & health test
│   │   └── main.dart             # Application entry point
│   ├── test/
│   │   └── widget_test.dart      # Flutter widget smoke tests
│   ├── pubspec.yaml              # Flutter dependencies (http, cupertino_icons)
│   └── analysis_options.yaml     # Flutter linter configuration
└── README.md                     # Comprehensive project documentation
```

---

## 3. Required Software

To develop, run, and build this project locally, ensure you have:

| Tool | Recommended Version | Purpose |
|---|---|---|
| **Node.js** | v18.0.0 or later (v24 tested) | Runs the Express backend server |
| **npm** | v9.0.0 or later | Node package manager |
| **Flutter SDK** | 3.20.0 or later (3.47 tested) | Compiles Dart code to Android / Web |
| **Dart SDK** | 3.3.0 or later (3.13 tested) | Bundled with Flutter |
| **Java JDK** | JDK 17 (recommended for Gradle) | Compiles Android applications |
| **Android SDK / Studio** | Android SDK 34 / API 34 | Required for building release APK |

---

## 4. Backend Setup & Execution

### Installation
Open a terminal in the project directory:
```bash
cd backend
npm install
```

### Running the Server
```bash
# Production mode:
npm start

# Development mode (auto-reloads on file change with Node 18+):
npm run dev
```

The server will automatically:
1. Create the `backend/data` directory and `backend/data/users.json` if they do not exist.
2. Bind to `0.0.0.0` on port `5000` (or `process.env.PORT` if set).
3. Print startup logs:
   ```
   ===============================================
    BasicUserApp Backend Server running on port 5000
    Local:   http://localhost:5000
    Network: http://0.0.0.0:5000
    Storage: .../backend/data/users.json
   ===============================================
   ```

---

## 5. REST API Documentation

### Consistent Response Envelope
All API responses follow a uniform structure:
```json
{
  "success": true,
  "message": "Human-readable status or error description",
  "data": { ... }
}
```

### Endpoints

#### 1. Health Check
- **Route**: `GET /api/health`
- **Purpose**: Verify backend connectivity and server status.
- **Response `200 OK`**:
  ```json
  {
    "success": true,
    "message": "BasicUserApp API is running smoothly.",
    "data": {
      "status": "healthy",
      "timestamp": "2026-10-29T14:10:00.000Z"
    }
  }
  ```

#### 2. Register New User
- **Route**: `POST /api/users`
- **Headers**: `Content-Type: application/json`
- **Request Body**:
  ```json
  {
    "name": "Alex Johnson",
    "email": "alex.johnson@example.com",
    "phone": "+1 (555) 019-2834"
  }
  ```
- **Validation Rules**:
  - `name`: String, non-empty, minimum 2 characters.
  - `email`: String, valid email format regex (`user@domain.ext`). Case-insensitive unique check.
  - `phone`: String, minimum 7 digits (permits `+`, `-`, spaces, parentheses).
- **Success Response `201 Created`**:
  ```json
  {
    "success": true,
    "message": "User registered successfully.",
    "data": {
      "id": "usr_1730210000000_abc123",
      "name": "Alex Johnson",
      "email": "alex.johnson@example.com",
      "phone": "+1 (555) 019-2834",
      "createdAt": "2026-10-29T14:10:23.968Z"
    }
  }
  ```
- **Failure Responses**:
  - `400 Bad Request` (Missing/invalid fields or duplicate email):
    ```json
    {
      "success": false,
      "message": "A user with this email address is already registered.",
      "data": null
    }
    ```

#### 3. Retrieve All Users
- **Route**: `GET /api/users`
- **Response `200 OK`**:
  ```json
  {
    "success": true,
    "message": "Users retrieved successfully.",
    "data": [
      {
        "id": "usr_1730210000000_abc123",
        "name": "Alex Johnson",
        "email": "alex.johnson@example.com",
        "phone": "+1 (555) 019-2834",
        "createdAt": "2026-10-29T14:10:23.968Z"
      }
    ]
  }
  ```

---

## 6. Flutter App Setup & Execution

### 1. Install Dependencies
```bash
cd frontend
flutter pub get
```

### 2. Run Code Analysis & Tests
```bash
# Analyze code for errors or style issues:
flutter analyze

# Run unit and widget tests:
flutter test
```

### 3. Launch App
```bash
# On an Android Emulator:
flutter run

# On a specific connected device:
flutter run -d <DEVICE_ID>

# In Chrome for quick testing:
flutter run -d chrome
```

---

## 7. API Base URL Configuration

The backend URL is centralized in [`frontend/lib/config/api_config.dart`](file:///c:/Users/SRIRA/BasicUserApp/frontend/lib/config/api_config.dart).

```dart
class ApiConfig {
  // Default for official Android Emulator:
  static const String defaultEmulatorUrl = 'http://10.0.2.2:5000';

  // Active base URL:
  static String baseUrl = defaultEmulatorUrl;
  ...
}
```

### Networking Table

| Environment | Base URL to Use | Explanation |
|---|---|---|
| **Android Emulator** | `http://10.0.2.2:5000` | The Android Emulator runs in a virtual router where `10.0.2.2` bridges directly to your development PC's `127.0.0.1`. |
| **Physical Android Phone (Wi-Fi)** | `http://<YOUR_COMPUTER_LAN_IP>:5000` (e.g. `http://192.168.1.15:5000`) | The phone connects over your local router. Both phone and PC must be on the same Wi-Fi. |
| **Remote Network / Cellular Data** | `https://your-deployed-service.onrender.com` | An APK on a phone outside your home Wi-Fi cannot see your PC's private IP. It requires a publicly reachable HTTPS server. |
| **Desktop / Web Browser** | `http://localhost:5000` | Localhost refers directly to the machine running the browser. |

> **Crucial Rule**: Never use `http://localhost:5000` inside Flutter code running on an Android device. On Android, `localhost` refers to the mobile phone itself!

---

## 8. Physical Android Phone Testing Guide

To test the Flutter app on a real Android device connected to your home/office Wi-Fi:

1. **Ensure Same Wi-Fi Network**: Connect your computer and your Android phone to the exact same Wi-Fi SSID.
2. **Find Your Computer's LAN IP**:
   - On Windows, open PowerShell and run:
     ```powershell
     ipconfig
     ```
   - Look for **IPv4 Address** under your active Wi-Fi adapter (e.g., `192.168.1.105`).
3. **Configure Firewall**: Ensure Windows Firewall permits incoming TCP traffic on port `5000`.
4. **Update App Configuration**:
   - **Method A (In-App)**: Tap the **API Config** button in the AppBar of the running app, type `http://192.168.1.105:5000`, tap **Test Health**, then **Save & Apply**.
   - **Method B (Code)**: In `frontend/lib/config/api_config.dart`, update:
     ```dart
     static String baseUrl = 'http://192.168.1.105:5000';
     ```
5. **Cleartext Traffic Enabled**: Android 9+ blocks cleartext HTTP by default. Our `AndroidManifest.xml` already includes `android:usesCleartextTraffic="true"`, allowing local HTTP testing.

---

## 9. Public Backend Deployment Requirements

When distributing the APK to friends or users who are not on your local Wi-Fi:
1. **Public Hosting**: Deploy the Node.js backend to a cloud host (such as Render, Railway, Fly.io, Heroku, or AWS Elastic Beanstalk).
2. **HTTPS Required**: Public mobile applications must communicate over encrypted HTTPS (e.g., `https://api.yourdomain.com`).
3. **Database Migration**: Switch `users.json` to a database (PostgreSQL, MongoDB, Supabase, or Firebase) to ensure persistence across cloud container restarts and multiple server instances.
4. **Environment Variables**: Store server configuration like `PORT`, `CORS_ORIGIN`, and database credentials in cloud environment variables rather than source code.

---

## 10. Building the Release APK & Installation

### Build Command
Run from the `frontend/` directory:
```bash
flutter build apk --release
```

### Build Artifact Location
When the Android SDK toolchain is installed, Flutter generates the APK at:
```
frontend/build/app/outputs/flutter-apk/app-release.apk
```

### Prerequisites for Building
- **Android Studio** or **Android Command Line Tools** with:
  - Android SDK Platform (API 34 or 35)
  - Android SDK Build-Tools (34.0.0 or 35.0.0)
  - Environment variable `ANDROID_HOME` pointing to your Android SDK folder (typically `C:\Users\<User>\AppData\Local\Android\Sdk`).
- **Java JDK**: JDK 17 configured in `JAVA_HOME`.

### How to Install the APK on Another Android Phone
1. **Transfer the APK**: Copy `app-release.apk` to the target Android phone via USB cable, Google Drive, WhatsApp, or email.
2. **Allow Installation from Unknown Sources**:
   - On the phone, open **Settings > Security** (or **Apps > Special app access > Install unknown apps**).
   - Allow your File Manager or Browser to install APKs.
3. **Install**: Tap `app-release.apk` in the phone's File Manager and select **Install**.
4. **Launch**: Open **BasicUserApp** from your phone's app launcher.

---

## 11. Automated Verification & Test Results

The following automated tests were executed during development:

| Test Item | Target | Result | Output Details |
|---|---|---|---|
| **GET /api/health** | REST API | **PASSED (200 OK)** | Returned `{ success: true, message: "BasicUserApp API is running smoothly." }` |
| **POST /api/users (Valid)** | REST API | **PASSED (201 Created)** | Created user `usr_...` for `john.doe@example.com` with timestamp |
| **POST /api/users (Invalid)** | REST API | **PASSED (400 Bad Request)** | Rejected empty fields and invalid email format with explicit errors |
| **POST /api/users (Duplicate)** | REST API | **PASSED (400 Bad Request)** | Rejected duplicate email with `"A user with this email address is already registered."` |
| **GET /api/users** | REST API | **PASSED (200 OK)** | Returned populated user array containing saved registrations |
| **flutter pub get** | Flutter | **PASSED (Code 0)** | All packages (including `http 1.6.0`) resolved |
| **flutter analyze** | Flutter | **PASSED (0 issues)** | "No issues found! (ran in 26.6s)" |
| **flutter test** | Flutter | **PASSED (All passed)** | Widget test verified "User Registration" header, input fields, and action buttons |
| **Android Device Testing** | Emulator/Device | **REPORTED (No physical device/emulator running)** | Verified 3 connected targets: Windows Desktop, Chrome, Edge. Android device was unavailable in current session. |
| **flutter build apk** | Flutter Android | **REPORTED (Requires Android SDK)** | Flutter engine artifacts downloaded; requires `ANDROID_HOME` to invoke Gradle. |

---

## 12. Common Errors & Troubleshooting

### 1. `ClientException: Connection refused` or `SocketException`
- **Cause**: The Flutter app cannot reach the backend server IP.
- **Fix**:
  - If using the Android Emulator, ensure the URL is `http://10.0.2.2:5000` (NOT `localhost`).
  - If using a physical phone, ensure both devices are on the same Wi-Fi and use `http://<PC_LAN_IP>:5000`.
  - Check that the Node.js server is actively running (`node backend/server.js`).

### 2. `Cleartext HTTP traffic not permitted`
- **Cause**: Android 9+ blocks unencrypted HTTP traffic by default.
- **Fix**: Already configured in `frontend/android/app/src/main/AndroidManifest.xml` via `android:usesCleartextTraffic="true"`.

### 3. `Duplicate email address` error
- **Cause**: The backend prevents duplicate registrations.
- **Fix**: Use a new email address or clear `backend/data/users.json` to reset registered users.

### 4. `No Android SDK found. Try setting the ANDROID_HOME environment variable.`
- **Cause**: Android Studio or Android SDK commandline-tools are not installed or `ANDROID_HOME` is not set.
- **Fix**: Install Android Studio from [developer.android.com/studio](https://developer.android.com/studio). Open Android Studio once to complete the SDK setup wizard, then add `ANDROID_HOME` to your system environment variables.

