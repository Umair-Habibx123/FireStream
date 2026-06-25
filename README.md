# 🔥 FireStream Chat App

### Real-time messaging powered by Flutter & Firebase

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Android](https://img.shields.io/badge/Android-API%2021+-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://android.com)
[![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)](LICENSE)

[⬇️ Download APK](https://github.com/Umair-Habibx123/FireStream/releases/download/v1.1/FireStream.apk) • [🐛 Report Bug](https://github.com/Umair-Habibx123/FireStream/issues) • [✨ Request Feature](https://github.com/Umair-Habibx123/FireStream/issues)

</div>

---

## 📖 About

**FireStream** is a powerful, feature-rich Flutter chat application that simplifies real-time communication. It leverages Firebase for seamless authentication, messaging, and group management — offering a full-featured chat experience on Android.

---

## ✨ Features

### 🔐 Authentication
- Email/Password and Google Sign-In
- Secure user registration and login

### 💬 Chats
- Send and receive text messages in real time
- Share images within chats
- Delete messages — admins manage all, users manage their own

### 👥 Contacts Management
- Add contacts via authenticated email addresses
- Blocklist unwanted contacts for enhanced privacy

### 🏘️ Group Chats
- Create groups and add/remove participants by email
- Admin controls for permissions and group configuration
- View group members and message individuals directly
- Add single contacts or bulk contact lists to groups

### 🖼️ Media & Profile
- Share images effortlessly in chats and groups
- Update and manage your profile picture and info

---

## 📲 Download

| Platform | Download |
|---|---|
| Android (APK) | [⬇️ Download APK](https://github.com/Umair-Habibx123/FireStream/releases/download/v1.1/FireStream.apk) |

> ℹ️ Enable **"Install from Unknown Sources"** in Android settings before installing.

All releases → [GitHub Releases](https://github.com/Umair-Habibx123/FireStream/releases)

---

## 🛠️ Built With

- [Flutter](https://flutter.dev/) — Cross-platform UI framework
- [Firebase Auth](https://firebase.google.com/products/auth) — Email & Google authentication
- [Cloud Firestore](https://firebase.google.com/products/firestore) — Real-time database & messaging
- [Firebase Storage](https://firebase.google.com/products/storage) — Image & media storage
- [Google Sign-In](https://pub.dev/packages/google_sign_in) — OAuth via Google
- [Image Picker](https://pub.dev/packages/image_picker) — Camera & gallery access

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.x or higher)
- [Android Studio](https://developer.android.com/studio) or [VS Code](https://code.visualstudio.com/)
- Android device or emulator (API 21+)
- [Firebase Project](https://console.firebase.google.com/) (free)

Check your Flutter setup:
```bash
flutter doctor
```

---

### Installation

**1. Clone the repository**
```bash
git clone https://github.com/Umair-Habibx123/FireStream
cd FireStream
```

**2. Install dependencies**
```bash
flutter pub get
```

**3. Set up Firebase**

- Go to [Firebase Console](https://console.firebase.google.com/) and create a new project
- Enable **Authentication** (Email/Password + Google)
- Enable **Cloud Firestore**
- Enable **Firebase Storage**
- Download config files and place them:

```
android/app/google-services.json       ← Android config
firebase.json                          ← root directory
```

**4. Run the app**
```bash
# Check connected devices
flutter devices

# Run on your device
flutter run -d <device_id>
```

---

## 📁 Project Structure

```
FireStream/
├── lib/
│   ├── main.dart                      # App entry point
│   ├── screens/
│   │   ├── loginScreen.dart           # Login & registration
│   │   ├── homeScreen.dart            # Chat list / home
│   │   ├── chatScreen.dart            # One-on-one chat
│   │   └── groupChatScreen.dart       # Group chat screen
│   ├── widgets/                       # Reusable UI components
│   ├── services/                      # Firebase & auth logic
│   └── models/                        # Data models
├── android/
│   └── app/
│       └── google-services.json       # Firebase Android config
├── firebase.json                      # Firebase project config
├── assets/                            # Images, fonts, etc.
└── pubspec.yaml                       # Dependencies & metadata
```

---

## 📦 Build APK

```bash
# Debug build (for testing)
flutter build apk --debug

# Release build (for distribution)
flutter build apk --release
```

Output:
```
build/app/outputs/flutter-apk/app-release.apk
```

---

## 📱 Usage Guide

| Feature | How To |
|---|---|
| **Sign In** | Login with email/password or tap Google Sign-In |
| **New Chat** | Go to Contacts → tap a contact to start chatting |
| **Send Image** | Tap the 📎 icon inside any chat |
| **Create Group** | Groups tab → tap ➕ → add participants by email |
| **Manage Group** | Open group → tap Group Info → admin controls |
| **Block Contact** | Contacts → long press → Block |
| **Edit Profile** | Tap your avatar → Edit Profile |

---

## 🤝 Contributing

Contributions are welcome!

1. Fork the repository
2. Create a feature branch
```bash
git checkout -b feature/AmazingFeature
```
3. Commit your changes
```bash
git commit -m "Add AmazingFeature"
```
4. Push to the branch
```bash
git push origin feature/AmazingFeature
```
5. Open a Pull Request

---

## 🐛 Issues

Found a bug or have a suggestion? [Open an issue](https://github.com/Umair-Habibx123/FireStream/issues)

---

## 📄 License

This project is open-source under the **MIT License**. See the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- [Firebase](https://firebase.google.com/) — For real-time backend infrastructure
- [Flutter](https://flutter.dev/) — For the amazing cross-platform framework
- Community contributors and supporters

---

<div align="center">

Made with ❤️ using Flutter & Firebase

⭐ Star this repo if you found it helpful!

</div>
```