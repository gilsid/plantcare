# PlantCare

A Flutter app for tracking and managing houseplant care schedules, health scores, and growth progress. Offline-first with local storage.

## Features

- **Plant management** — add/edit/delete plants with photos, species, location, and notes
- **Care scheduling** — configure recurring tasks (watering, fertilizing, pruning, pest check, repotting) with custom intervals (hour/day/week/month)
- **Health score** — auto-calculated from watering history with overdue penalties; trend indicator (up/down/stable)
- **Notifications** — platform reminders when care is due; test notification button in Settings
- **Growth diary** — photo timeline with before/after comparison, notes per entry
- **Weekly schedule** — 7-day overview of all upcoming care tasks grouped by day
- **Search & filter** — by name, species, location; filter by health status, overdue tasks, or tags
- **Tag system** — categorize plants with custom tags, filter by tag
- **Sorting** — by date added, name, health score, or urgency
- **Streak tracking** — consecutive daily care completion counter
- **Swipe actions** — swipe left-to-right to water, right-to-left to delete
- **Grid/list view** — toggleable plant display layout
- **Bulk actions** — complete all overdue watering at once
- **Dark mode** — toggleable dark/light theme
- **Profile** — username setup (onboarding + settings)
- **Onboarding** — first-run intro slides with name input
- **Reset** — clear all data from settings
- **Health timeline** — animated care completion overlay
- **Fade transitions** — smooth page navigation

## Tech Stack

- **Flutter** — cross-platform UI framework
- **Hive CE** — lightweight, no-SQL embedded database (offline-first)
- **Provider** — state management
- **flutter_local_notifications** — push notifications
- **image_picker** — camera/gallery image capture
- **permission_handler** — notification permission requests
- **google_fonts** — custom typography
- **intl** — date formatting with locale support
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
├── app/               — theme, colors
├── models/            — data models (Plant, CareTask, CareHistory, GrowthEntry, etc.)
├── providers/         — state management (PlantProvider, ThemeProvider)
├── screens/
│   ├── add_edit_plant/ — add/edit plant form
│   ├── home/           — main screen (list/grid, search, filter, sort, swipe)
│   ├── onboarding/     — first-run intro
│   ├── plant_detail/   — detail view (health, care tasks, history, growth diary)
│   ├── schedule/       — weekly schedule overview
│   └── settings/       — dark mode, profile, test notification, reset
├── services/          — core services (database, notifications, images)
└── widgets/           — reusable UI components
```
