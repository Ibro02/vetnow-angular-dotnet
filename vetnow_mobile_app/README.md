# VetNow Mobile

Flutter app for **VetNow** — a marketplace connecting pet owners with
partner veterinary stations (multi-tenant, like rezervacija.app but for
vet clinics). Design tokens are ported from
`frontend/src/styles/theme.css` so the mobile app visually matches the
Angular web dashboard, enriched with a few "premium marketplace" touches
(gold ratings, verified-partner badges, a deep-ink hero).

## Product shape

- **Pet owners** browse partner vet stations with no account required
  (guest-first, like Booksy/rezervacija.app). An account is only
  requested right before confirming a booking.
- **Vet stations** are partner entities already modeled in the backend
  (`VetStation` → `Employee` → `Vet/Nurse/Barber/MainVet`, TPT
  inheritance). They manage their own team/availability from the
  existing Angular web dashboard — this Flutter app is the pet-owner
  side only, for now.

## Screen flow

```
RootShell (bottom nav, always visible)
├── Explore          — city picker, search, filter chips, station list (guest OK)
│     └── VetStationDetail — rating, hours, services, staff, reviews
│           └── Booking    — service → staff (optional) → time slot
│                 └── (if guest) Login/Register gate → Confirmation
├── My appointments  — gated: AuthPrompt if guest, list if logged in
└── Profile          — gated: AuthPrompt if guest, pets/settings if logged in
```

## Setup

1. Copy this folder's `lib/` and `pubspec.yaml` into a fresh Flutter
   project (`flutter create vetnow_mobile_app`), or run
   `flutter pub get` directly here if you already have a project shell.

2. Point the app at your backend in `lib/config/api_config.dart`:
   - Android emulator → `http://10.0.2.2:5157` (default)
   - Chrome / web → `http://localhost:5157`
   - iOS simulator → `http://localhost:5157`
   - Physical device → your PC's LAN IP, e.g. `http://192.168.1.23:5157`

3. Run:
   ```bash
   flutter run
   ```

## What's included

- `lib/config/theme.dart` — design tokens (colors, radius, spacing,
  shadows, typography) ported from the Angular theme, plus premium
  accents (`AppColors.gold`, `AppColors.ink`, `AppShadows.glow`).
- `lib/state/auth_state.dart` — minimal guest/logged-in state
  (`ChangeNotifier` + `InheritedNotifier`, no external package yet).
- `lib/models/` — `VetStation` (extended with rating/city/verified),
  `VetService`, `StaffMember`, `Review`, `LoginRequest`.
- `lib/widgets/` — `AppButton`, `AppTextField`, `RatingBadge`,
  `VerifiedBadge`, `AuthPrompt`.
- `lib/screens/` — `RootShell`, `ExploreScreen`, `VetStationDetailScreen`,
  `BookingScreen`, `LoginScreen`, `RegisterScreen`,
  `MyAppointmentsScreen`, `ProfileScreen`.

## What's still a stub

Every screen uses mock/local data — no real HTTP calls yet. Every spot
that needs one is marked `// TODO:`. Suggested next step: build
`lib/services/api_service.dart` + `auth_service.dart` using the `http`
package already in `pubspec.yaml`, wire it into `AuthState.logIn()` and
the Explore/Booking screens, replacing the mock lists.

Fonts (Inter, Italiana) are referenced in the theme but not bundled —
see the commented-out `fonts:` section in `pubspec.yaml`.
