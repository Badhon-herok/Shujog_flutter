# Shujog (Flutter)

Shujog is a Flutter mobile application for connecting **workers** and **employers** through job posting, applications, profiles, and notifications.

## Highlights
- Role-based experience (Worker / Employer)
- Authentication (Login / Signup)
- Employer: dashboard, manage jobs, settings/profile
- Worker: dashboard, profile, applications
- Notifications + notification settings
- Shared theme + reusable widgets

## Screens (Optional)
> Add screenshots in `/assets/screenshots/` and link here.
- Home / Dashboard
- Manage Jobs
- Profile / Settings
- Notifications

## Tech Stack
- Flutter (Dart)
- Backend: (Supabase / Firebase / REST API) — update this line based on what you used
- State management: (setState / Provider / Riverpod / Bloc) — update if needed

## Getting Started

### Prerequisites
- Flutter SDK installed
- Android Studio or VS Code
- Android Emulator or a physical Android device

### Setup
1. Clone the repository:
   ```bash
   git clone https://github.com/Badhon-herok/Shujog_flutter.git
   cd Shujog_flutter
Install dependencies:

bash
flutter pub get
Run the app:

bash
flutter run
Build (APK)
bash
flutter build apk --release
Project Structure (High Level)
This project follows a feature-based structure:

lib/main.dart → App entry point

lib/core/ → App-wide theme/config (e.g., app_colors.dart, app_theme.dart)

lib/common/ → Shared widgets/components (e.g., buttons)

lib/features/

auth/

presentation/pages/ → login_page.dart, signup_page.dart

services/ → auth logic (e.g., auth_service.dart)

home/

presentation/pages/ → dashboards, profiles, job pages, settings, notifications

presentation/widgets/ → feature widgets (e.g., dialogs)

