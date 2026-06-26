# PlantCare

A Flutter app for tracking and managing houseplant care schedules, health scores, and growth progress. Offline-first with local storage.

## Features

- **Plant management** — add/edit/delete plants with photos, species, and location
- **Care scheduling** — configure recurring tasks (watering, fertilizing, pruning, pest check, repotting) with custom intervals
- **Health score** — auto-calculated from watering history and overdue penalties
- **Notifications** — platform reminders when care is due
- **Growth diary** — photo timeline with notes
- **Search & filter** — by name, species, location; filter by health status or overdue tasks
- **Sorting** — by date added, name, health score, or urgency
- **Dark mode** — toggleable dark/light theme
- **Bulk actions** — complete all overdue watering at once
- **Onboarding** — first-run intro slides
- **Fade transitions** — smooth page navigation

## Tech Stack

- **Flutter** — cross-platform UI framework
- **Hive CE** — lightweight, no-SQL embedded database (offline-first)
- **Provider** — state management
- **flutter_local_notifications** — push notifications
- **image_picker** — camera/gallery image capture
- **google_fonts** — custom typography
- **intl** — date formatting
- **timezone** — timezone-aware scheduling
- **uuid** — unique IDs
- **path_provider** — file system paths

## Getting Started

```bash
flutter pub get
flutter run
```

### Build targets

```bash
# Web
flutter run -d web

# Android arm64 release
flutter build apk --target-platform android-arm64
```

## Project Structure

```
lib/
├── app/            — theme, colors
├── models/         — data models (Plant, CareTask, CareHistory, etc.)
├── providers/      — state management (PlantProvider, ThemeProvider)
├── screens/        — UI screens (home, detail, add/edit, settings, onboarding)
├── services/       — core services (database, notifications, images)
└── widgets/        — reusable UI components
```

## License

MIT
