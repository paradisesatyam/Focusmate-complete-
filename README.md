# FocusMate 🎯

A personal productivity assistant for students and working professionals — built with Flutter, deployed on web and Android from a single codebase.

## Features

| Section | What it does |
|---|---|
| 🔥 Focus Timer | Countdown timer with selectable sessions (15–60 min). Saves every session to your progress automatically. |
| ✅ To-Do Planner | Add tasks with deadlines and priority levels. Notifies you at exactly the deadline time (Android). Daily 8 PM check-in reminder. |
| 📅 Calendar | Visual calendar with task markers on due dates. Tap any day to see its tasks. |
| 📖 Diary | Private journal with mood emoji selector. Write, edit, delete entries. |
| 🤖 AI Chat | Powered by Google Gemini. Quick-prompt chips for common questions. |
| 📊 Progress | Bar chart of daily focus minutes. Pie chart of task completion. 7-day overview. |
| 💰 Expense Analytics | Add/delete expenses by category. Pie chart and bar chart views. Today and monthly breakdowns. |

## Tech Stack

Flutter · Dart · Firebase Auth · Cloud Firestore · flutter_local_notifications · fl_chart · table_calendar · Gemini API

## Setup

See [SETUP.md](SETUP.md) for full step-by-step instructions.

## Quick Start

```bash
git clone https://github.com/yourusername/focusmate.git
cd focusmate
flutter pub get
# → Add firebase_options.dart (see SETUP.md)
flutter run -d chrome   # web
flutter run             # Android
```

## License

MIT
