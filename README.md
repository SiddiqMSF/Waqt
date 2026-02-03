# 🕌 Waqt – Adaptive Prayer Alarms

**Smart alarms that follow the sun, not the clock.**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey)](/)

---

## 🚨 The Problem with Regular Alarms

You set your alarm for **5:00 AM** to wake up for Fajr. It works great... until the seasons change.

> **Ramadan comes. Fajr is now at 4:47 AM.**
> Your alarm rings at 5:00 AM.
> **You missed Fajr.**

Traditional alarms don't understand that prayer times shift **every single day**. In some locations, Fajr can vary by **over 2 hours** throughout the year.

---

## ✨ The Solution: Prayer-Based Alarms

**Prayer Times** is the first app that lets you set alarms **relative to prayer times**, not fixed clock times.

| Traditional Alarm | Prayer-Based Alarm |
|-------------------|-------------------|
| ⏰ "Wake me at 5:00 AM" | 🕌 "Wake me **30 min before Fajr**" |
| ❌ Breaks when seasons change | ✅ Automatically adjusts daily |
| 😴 Miss prayers, feel guilty | 🤲 Never miss a prayer again |

### How It Works

```
Today:     Fajr at 5:15 AM → Alarm rings at 4:45 AM
Tomorrow:  Fajr at 5:14 AM → Alarm rings at 4:44 AM  
Ramadan:   Fajr at 4:30 AM → Alarm rings at 4:00 AM
```

**One setting. Automatic forever.**

---

## 🎯 Key Features

### 🔔 Smart Prayer Alarms
- Set alarms like **"30 min before Fajr"** or **"10 min after Isha"**
- Works for all 5 daily prayers + Sunrise, Midnight, Last Third of Night
- Alarms automatically recalculate every day

### 📍 Accurate Prayer Times
- Powered by the trusted **Adhan** calculation library
- Supports multiple calculation methods (Muslim World League, ISNA, Umm Al-Qura, etc.)
- Location-based calculations using GPS

### 🌙 Night Prayer Support
- **Last Third of Night** marker for Tahajjud
- **Islamic Midnight** calculation
- Perfect for those who want to establish Qiyam al-Layl

### ⏱️ Live Countdown
- Beautiful home screen with countdown to next prayer
- Iqamah time tracking
- Persistent notification with real-time updates

### 🎨 Modern Design
- Glassmorphic UI with stunning visuals
- Dark mode optimized
- Smooth animations

---

## 📱 Screenshots

<!-- Add your screenshots here -->
| Home Screen | Quick Alarm | Alarm Settings |
|-------------|-------------|----------------|
| ![Home](screenshots/home.png) | ![Quick](screenshots/quick_alarm.png) | ![Settings](screenshots/alarm_settings.png) |

---

## 🚀 Getting Started

### Prerequisites
- Flutter 3.x or higher
- Android Studio / Xcode

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/prayer-times.git

# Navigate to project
cd prayer-times

# Install dependencies
flutter pub get

# Run the app
flutter run
```

---

## 🛠️ Tech Stack

- **Framework:** Flutter (Dart)
- **State Management:** Riverpod
- **Prayer Calculations:** Adhan package
- **Alarms:** alarm package (native Android/iOS)
- **Storage:** SharedPreferences
- **Background Service:** flutter_background_service

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🌟 Support

If this app helps you pray on time, please consider:
- ⭐ Starring this repository
- 📣 Sharing with friends and family
- 🤲 Making dua for the developers

---

## 🔑 Keywords

`prayer times` `salah times` `fajr alarm` `islamic alarm` `muslim app` `adhan` `athan` `prayer reminder` `salat times` `namaz times` `qibla` `islamic prayer` `fajr` `dhuhr` `asr` `maghrib` `isha` `tahajjud` `qiyam` `ramadan` `flutter` `open source`

---

<p align="center">
  <b>Built with ❤️ for the Ummah</b>
</p>
