# LifePilot

LifePilot is a Flutter-based personal life management app designed to help users organize their daily life in one place. The project combines task tracking, habit tracking, calendar planning, onboarding, profile settings, and AI-style guidance in a single mobile app.

This project is not just a task app. It is a personal productivity system that keeps the user’s important life activities together: what to do, what to track, when to do it, and how to stay consistent over time.

---

## 1. Project Overview

LifePilot is built as a feature-driven Flutter application with a modular structure under `lib/features`. Each feature owns its own models, screens, widgets, and services, which makes the application easier to scale and reason about.

The current implementation is a local-first MVP. It stores data in `SharedPreferences`, which makes it easy to prototype without a backend. It is designed around the idea that a user can:

- manage tasks with due dates and reminders
- track daily/weekly habits
- view a home dashboard with essential information
- complete onboarding once and persist the state
- personalize theme and notification settings
- access AI-style coaching suggestions
- see upcoming activity in calendar and insights views

---

## 2. Main Technologies

### Flutter + Dart
The app is built using Flutter and Dart. Flutter provides the UI layer, rendering, widgets, state management, navigation, and app lifecycle support.

### SharedPreferences
The app stores user preferences, onboarding state, auth session, task lists, and habit data using `shared_preferences`.

This is a lightweight local persistence layer that works well for MVPs and prototypes.

### Flutter Local Notifications
The app supports local scheduled reminders for tasks using the `flutter_local_notifications` package and the timezone package. This lets tasks trigger reminders even without a remote server.

### Google Fonts
The UI uses `google_fonts` to create a more modern and polished visual style.

---

## 3. Application Architecture

The project follows a layered, feature-oriented architecture:

- `lib/main.dart` starts the app
- `lib/app/app.dart` builds the root MaterialApp and decides the screen flow
- `lib/shared_controllers/app_controller.dart` holds global app state like user session, onboarding status, and theme
- `lib/features/*` contains the main feature modules
- `lib/core/*` contains shared theming, widgets, spacing, icons, and reusable UI components
- `lib/models`, `lib/screens`, `lib/services`, `lib/utils`, `lib/widgets` are supporting folders used for general app logic and reusable pieces

This architecture is simple and beginner-friendly: each feature is separated, but the app still remains compact enough to understand quickly.

---

## 4. App Startup and Runtime Flow

### Root entry point
`lib/main.dart` is the app entry point.

It does three important things:

1. ensures Flutter bindings are initialized
2. initializes the notification service
3. runs the `LifePilotApp`

### Root app controller
`lib/app/app.dart` creates the main app UI and decides which screen to show based on state.

The app checks:

- if the splash screen should still show
- whether onboarding has been completed
- whether a user is logged in
- whether the app should open the login screen or home screen

The decision tree is:

- show splash screen while loading
- if onboarding is incomplete -> show onboarding screen
- else if no user is logged in -> show login screen
- else -> show home screen for that user

### Global app state
`AppController` is used to manage:

- current user
- theme selection
- onboarding completion state
- loading state

It extends `ChangeNotifier` and exposes `AppControllerScope` as an `InheritedNotifier`, allowing child screens to access app state without passing props everywhere.

---

## 5. How the app decides what to show

The application is controlled primarily by `AppController` and the app root widget.

### States handled at runtime

1. Initial app load
   - load persisted preferences
   - load the current user from local storage
   - set loading state

2. Onboarding state
   - if onboarding is not completed, show the onboarding flow
   - after completion, persist the value in `SharedPreferences`

3. Auth state
   - if a user is currently saved in local storage, the app skips login
   - otherwise it shows the login/register flow

4. Theme state
   - user theme is stored in preferences and fed into `MaterialApp.themeMode`

This is a simple but effective state model for MVP apps.

---

## 6. Core Parts of the Project

### 6.1 `lib/main.dart`
This file is the application bootstrap. It initializes the platform and starts the app.

Key responsibilities:

- call `WidgetsFlutterBinding.ensureInitialized()`
- initialize notification system
- launch `LifePilotApp`

### 6.2 `lib/app/app.dart`
This is the root app widget. It controls the visible UI flow and holds the startup logic.

Important behavior:

- shows a splash screen for a brief moment
- loads app preferences and current session
- renders `OnboardingScreen`, `LoginScreen`, or `HomeScreen` based on state

### 6.3 `lib/app/router.dart`
This file defines named application routes for major screens such as:

- onboarding
- sign in
- sign up
- forgot password
- home
- calendar
- habits
- profile
- goals
- insights
- notifications

Even though the app currently uses direct widget navigation in many places, this router file provides a clean route map for future expansion.

---

## 7. Feature Modules

The application is organized by feature, which is a common and scalable pattern in Flutter apps.

### 7.1 Authentication and onboarding
Folder: `lib/features/auth/`

This module includes:

- user model: `models/user.dart`
- auth service: `services/auth_service.dart`
- onboarding screen: `screens/onboarding_screen.dart`
- login/register UI: `screens/sign_in_screen.dart`
- splash screen: `screens/splash_screen.dart`

#### What it does
- allows users to register a new account
- allows users to log in with email and password
- stores a logged-in user session in local storage
- persists onboarding completion status
- shows a multi-page onboarding experience explaining the app

#### Data flow
`AuthService` checks and writes user data to `SharedPreferences` using a local map of accounts. Login and registration are implemented in memory through persisted settings, not via a backend server.

This means user identity is local to the device. It is suitable for a mobile MVP, but not for production multi-device syncing.

---

### 7.2 Tasks
Folder: `lib/features/tasks/`

This module includes:

- model: `models/task.dart`
- service: `services/task_service.dart`
- screens: `screens/task_list_screen.dart`, `screens/add_task_sheet.dart`
- notification logic: `services/notification_service.dart`

#### Task model
The `Task` model includes:

- `id`
- `title`
- `description`
- `category`
- `priority`
- `completed`
- `dueDate`
- `reminderDate`
- `reminderEnabled`
- `estimatedMinutes`
- `createdAt`
- `completedAt`

It also has methods for:

- status calculation
- status label generation
- overdue detection
- serialization to JSON
- AI-friendly context generation

#### Task status logic
The task model determines whether the task is:

- overdue
- due today
- not due
- completed

This is determined by comparing the task’s due date to the current date unless the task is already marked complete.

#### Persistence
Each user has a separate storage key:

- `tasks_<userId>`

This isolates user data by account and prevents one user’s tasks from showing for another user.

#### Reminder system
Task reminders are scheduled using local notifications. If a task has a reminder enabled and a future reminder date, the app schedules a notification. If the task is completed or the time has passed, the reminder is cancelled.

---

### 7.3 Habits
Folder: `lib/features/habits/`

This module includes:

- model: `models/habit.dart`
- service: `services/habit_service.dart`
- screen: `screens/habit_screen.dart`
- widgets: `widgets/habit_card.dart`, `widgets/habit_statistics.dart`

#### Habit model
The `Habit` model tracks:

- id
- name
- list of completed dates

It supports:

- current streak calculation
- longest streak calculation
- date normalization
- JSON serialization and restoration

#### Streak logic
Habit streaks are calculated by taking a list of completed dates, normalizing them to calendar-day values, and checking consecutive days. This is an important feature for personal habit tracking and motivation.

#### Persistence
Habits are stored using a key like:

- `habits_<userId>`

This keeps habits separated for each user.

---

### 7.4 Calendar
Folder: `lib/features/calendar/`

This module contains the calendar UI and schedule-related widgets.

It likely provides:

- a monthly or weekly calendar view
- tasks displayed by date
- due-date selection
- event/task alignment in calendar context

The app organizes activity around dates, so tasks and lifecycle events become visible in a timeline.

---

### 7.5 Home Dashboard
Folder: `lib/features/home/`

This module is the main landing screen after login.

It contains:

- dashboard screen
- widgets for summary cards and sections
- task previews and habit previews
- quick access to task creation and task list

This screen acts as the hub for daily life. It gives the user a snapshot of priorities and progress without forcing them to open every feature separately.

Key responsibilities:

- load tasks for the signed-in user
- show today’s tasks
- allow users to create tasks quickly
- allow users to complete or toggle task state
- navigate to a deeper task list screen

---

### 7.6 Goals
Folder: `lib/features/goals/`

This module is designed to support long-term goal tracking.

It includes:

- `models/goal.dart`
- `services/goal_service.dart`
- `screens/goals_screen.dart`
- `widgets/goal_progress_card.dart`

The goal UI helps the user track bigger life outcomes beyond daily tasks. These can include personal milestones, progress bars, and structured planning.

---

### 7.7 Insights
Folder: `lib/features/insights/`

The insights area likely presents visual summaries from the user’s data, such as:

- habit streak data
- weekly completion trends
- task volume or category summaries
- general productivity analytics

This part of the app turns user activity into structured feedback and helps identify behavior patterns over time.

---

### 7.8 AI Chat
Folder: `lib/features/ai_chat/`

This feature is a conversational assistant layer.

It includes:

- chat message model
- AI service stub/demo logic
- chat screen and chat bubble widgets

#### Current implementation
The `AIService` is not connected to a real external AI provider yet. Instead, it returns demo responses based on the user’s message.

Examples include:

- “Plan my day”
- “help me prioritize my tasks”
- “how can I build a better habit?”

This is a placeholder service for future integration with an external LLM or personal planning engine.

---

### 7.9 Notifications
Folder: `lib/features/notifications/`

The notification module contains:

- notification model: `models/app_notification.dart`
- service: `services/notification_service.dart`
- screen: `screens/notifications_screen.dart`
- widgets: `widgets/notification_tile.dart`

This system manages user-facing app notifications beyond just task reminders. The app uses a local notification service to deliver reminder messages and may later expand to AI suggestions, streak notifications, and event reminders.

There is also a second notification service in `lib/features/tasks/services/notification_service.dart`, which appears to be a duplicate or older version. The active app initialization imports the one under the `notifications` feature, which is the correct one used by the app.

---

### 7.10 Profile and Preferences
Folder: `lib/features/profile/`

This module includes:

- `models/user_preferences.dart`
- `services/user_service.dart`
- `screens/profile_screen.dart`

This feature lets users:

- toggle theme mode
- configure notifications
- configure reminders
- reset onboarding state
- manage personal preferences

The stored settings are persisted to `SharedPreferences` using keys like:

- `theme`
- `notificationsEnabled`
- `reminderEnabled`

---

## 8. Shared UI and Theme System

### Core theme layer
Folder: `lib/core/theme/`

This includes reusable styling primitives such as:

- colors
- typography
- spacing
- radius
- theme definition

Files include:

- `app_colors.dart`
- `app_theme.dart`
- `app_typography.dart`
- `app_spacing.dart`

These files keep the app visually consistent and avoid repeating style settings in individual screens.

### Reusable widgets
Folder: `lib/core/widgets/`

This contains common UI components:

- `primary_button.dart`
- `secondary_button.dart`
- `app_card.dart`
- `app_chip.dart`
- `bottom_nav_bar.dart`
- `progress_ring.dart`
- `priority_badge.dart`

These widgets are created once and reused across the app, reducing duplication and helping maintain a common design language.

---

## 9. Data Storage Design

The app uses `SharedPreferences` instead of a remote database.

### Why this approach is used
It is suitable for:

- prototypes
- MVPs
- quick local experimentation
- offline-first mobile workflows

### What is stored
Examples:

- onboarding state
- user session
- user preferences
- task data per user
- habit data per user

### Per-user isolation strategy
The app uses keys like:

- `tasks_<userId>`
- `habits_<userId>`

This prevents data from mixing between users when multiple accounts are simulated locally.

---

## 10. Important Data Models

### User
Represents the signed-in user and includes fields like:

- id
- name
- email

This object is persisted by the auth service.

### Task
Represents an actionable item with scheduling and reminder metadata. It can be:

- complete or incomplete
- due today or overdue
- assigned to a category
- given a priority
- given a reminder date

### Habit
Represents a repeatable routine or daily behavior. It tracks completed days so the app can compute streaks and momentum.

### UserPreferences
Represents user preferences like:

- selected theme
- notification settings
- reminder settings

---

## 11. Example App Flow

A typical application flow looks like this:

1. App starts and shows splash screen.
2. App loads preferences and current user from storage.
3. If onboarding is not complete, the onboarding screen appears.
4. After onboarding completes, the user sees either login or home.
5. After login, the home screen appears with a dashboard.
6. User adds tasks and habits.
7. Tasks are saved locally in `SharedPreferences`.
8. Reminders are scheduled if due dates and reminder settings are valid.
9. The user can open profile settings to change app behavior.

This is a complete loop for a minimal personal productivity app.

---

## 12. What is already implemented

The current project is already quite feature-rich for an MVP. It includes:

- onboarding flow
- login/register flow
- app-level state controller
- home dashboard
- task creation and management
- task filtering and lists
- reminder scheduling
- local notifications
- habit tracking and streaks
- calendar view framework
- profile settings
- AI assistant placeholder
- insights page structure
- goals page structure

This means the project is not just a simple starter app — it already has a real product structure and multiple life-planning features.

---

## 13. What is still conceptual or incomplete

Because this is an MVP, some pieces are either partially implemented or intended for future phases.

Examples:

- no real backend database
- no real AI API integration yet
- no cloud sync
- no multi-device support
- no strong production security layer for authentication
- some screens are structured but may be more conceptual than fully production-polished

This is typical for an early-stage personal app where local-first fast iteration is more important than full backend architecture.

---

## 14. Development Notes

### Run the app
From the project root:

```bash
flutter pub get
flutter run
```

### Run tests
```bash
flutter test
```

### Check project health
```bash
flutter analyze
```

---

## 15. Suggested Mental Model for Understanding the Project

If you want to understand this project quickly, think of it as a modular life-planning app built with the following logic:

- `AppController` = global app brain
- `Auth` = user access and onboarding
- `Tasks` = short-term execution system
- `Habits` = consistency system
- `Calendar` = timeline view
- `Home` = overview dashboard
- `Insights` = feedback and progress review
- `AI Chat` = future assistant layer
- `Profile` = settings and personalization

This structure makes the app easier to expand into a larger personal life platform.

---

## 16. Final Summary

LifePilot is a Flutter application that manages a user’s personal life in a single place. It combines planning, tracking, habit-building, and lightweight AI guidance in a local-first MVP environment.

The project already demonstrates several real product ideas:

- user onboarding
- local authentication
- task management
- habit streaks
- reminders
- preference settings
- dashboard overview
- future AI assistance

In short, the app is a local-first personal productivity system built as a modular Flutter app, prepared for future growth into a more complete digital life assistant.

---

## 17. Recommended Next Improvements

Some logical next steps for this project are:

1. move from `SharedPreferences` to a real database or backend
2. connect AI service to a real LLM API
3. add user-based sync across devices
4. improve calendar and goal analytics
5. expand reminders and notification center features
6. add a stronger navigation system and route-based architecture
7. add more automated tests for task, habit, reminder, and profile flows

These improvements would make the app more robust and closer to a production-grade personal life platform.
