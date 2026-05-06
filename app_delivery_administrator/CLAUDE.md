# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this project is

**Runa Admin Panel** — Flutter Web administration console for the DeliPuno delivery platform. Sibling project to `app_delivery_usuario/` (customer app) and `app_delivery_repartidor/` (courier app); they all share the same Firebase project (`delypuno-ddd2d`).

This app is **web-first** (`flutter run -d chrome`) but the codebase compiles for any Flutter target.

## Commands (run from inside `app_delivery_administrator/`)

```bash
flutter pub get
flutter run -d chrome              # run on Chrome (web)
flutter analyze                    # must report "No issues found!"
flutter build web --no-tree-shake-icons
flutter test
```

PowerShell is the default shell on Windows. Chain commands with `;` then `if ($?) { ... }` — `&&` is a parser error in PowerShell 5.1.

## Architecture

**Stack:** Flutter 3.11+, Material 3 light theme, no state management library — local `StatefulWidget`/`setState` only. Backend is Firebase (Auth + Firestore), reusing the customer/courier project.

### Folder layout

```
lib/
├─ main.dart              # App entry, route table (onGenerateRoute)
├─ routes.dart            # AdminRoutes constants for every screen
├─ theme.dart             # AdminColors palette + buildAdminTheme()
├─ firebase_options.dart  # Firebase config for delypuno-ddd2d
├─ models/                # Plain Dart classes mirroring Firestore
│   ├─ order_model.dart
│   ├─ store_model.dart
│   ├─ courier_model.dart
│   ├─ customer_model.dart
│   ├─ admin_user_model.dart
│   ├─ ticket_model.dart
│   ├─ promo_model.dart
│   └─ zone_model.dart
├─ services/              # Static-method service classes (no instantiation)
│   ├─ auth_service.dart       # Firebase Auth + admins/{uid}
│   ├─ order_service.dart      # streams, cancel, reassign
│   ├─ store_service.dart
│   ├─ courier_service.dart
│   ├─ customer_service.dart
│   ├─ finance_service.dart
│   └─ support_service.dart
├─ widgets/               # Reusable UI primitives
│   ├─ admin_shell.dart        # Sidebar + topbar layout (every screen wraps in this)
│   └─ admin_widgets.dart      # AdminCard, AdminBadge, AdminButton, AdminAvatar, etc.
└─ screens/               # One file per screen, named by feature
    ├─ splash_screen.dart
    ├─ login_screen.dart
    ├─ dashboard_screen.dart
    ├─ orders_screen.dart / order_detail_screen.dart
    ├─ live_map_screen.dart
    ├─ stores_screen.dart / store_detail_screen.dart
    ├─ couriers_screen.dart / courier_detail_screen.dart
    ├─ approvals_screen.dart
    ├─ customers_screen.dart
    ├─ finance_screen.dart
    ├─ zones_screen.dart
    ├─ pricing_screen.dart
    ├─ promotions_screen.dart
    ├─ admin_users_screen.dart
    └─ support_screen.dart
```

### Routing

All routes are registered via `onGenerateRoute` in `main.dart`. Screens that need an argument receive it through `settings.arguments` — pass the model instance with `Navigator.pushNamed(context, AdminRoutes.orderDetail, arguments: order)`. The detail screens accept either a model or an id.

`SplashScreen` (route `/`) is the entry point. It checks `AuthService.currentUid` and pushes either `/login` or `/dashboard`.

### Firestore collections (shared with the other apps)

```
admins/{uid}                    ← admin profile {name, email, role, lastActive}
users/{uid}                     ← customers (read-only from admin)
stores/{storeId}/products/...   ← shared catalog
orders/{orderId}                ← shared; admin can cancel/reassign
couriers/{uid}                  ← admin reads + approves/rejects
tickets/{ticketId}              ← support tickets
```

Admin-only fields appended to orders: `cancelledAt`, `cancelledBy`, `cancelReason`.

### Theme & visual language

`lib/theme.dart` exports the `AdminColors` palette (Stripe/Linear/Vercel-inspired light theme, distinct from the customer app's warm palette and the courier app's dark palette). Primary `#FF6B35` is shared across all three apps.

`AdminShell` is the layout chrome — every authenticated screen wraps its content in it. The shell renders the dark sidebar, search box, top bar, and notifications icon. Pass `activeId` matching the nav item id (`'dashboard'`, `'pedidos'`, `'mapa'`, etc.) so the correct row highlights.

### Reusable widget catalogue (`widgets/admin_widgets.dart`)

- `AdminCard` / `AdminCard.flush` — surface card with rounded border (Stripe-style)
- `AdminBadge` — status pill (tones: gray, green, amber, red, blue, purple, coral)
- `AdminButton` — variants `primary`, `secondary`, `ghost`, `coral`, `danger`, `success`; sizes `sm`/`md`/`lg`; supports `icon` and `loading`
- `AdminAvatar` — gradient circle with initials (tone: coral, blue, green, purple, amber)
- `AdminStatusDot` — coloured dot + label
- `AdminEyebrow` — small uppercase muted heading
- `AdminFakeField` — non-functional bordered chip (for filter rows from the design that aren't wired yet)
- `AdminTextField` — real `TextField` with label and optional icon
- `AdminReadOnlyField` — boxed read-only key/value display
- `AdminPillToggle` — toggleable pill row used in tabs/filters

### Custom-painted graphics

Several screens render charts and maps via `CustomPainter` (no chart library):

- Dashboard sales chart — `_SalesChartPainter`
- Order detail map — `_FauxRoutePainter`
- Live map — `_CityPainter`
- Finance bars — `_BarChartPainter`
- Zones polygons — `_ZoneMapPainter`

These are intentional placeholders; swap for `google_maps_flutter` + a real chart lib when the design is finalized.

## Constraints

- **Never modify `app_delivery_usuario/` or `app_delivery_repartidor/`.** Both are considered the source of truth for their respective sides. Models in those apps may be referenced for shape, but copy them locally — don't import across packages.
- The admin app is **self-contained**: no relative imports outside this directory.
- `flutter analyze` must stay clean — no warnings, no info-level lints.
- Web is the primary target. Avoid platform-specific APIs that only work on mobile.

## Firebase config

The admin app reuses the existing `delypuno-ddd2d` Firebase project. The web app id from `firebase_options.dart` matches the customer app's web entry. **For production deploys**, register a dedicated Firebase Web App via `flutterfire configure` so the admin gets its own auth tokens and analytics stream.

The `admins/{uid}` collection is admin-only; security rules should restrict it to authenticated users present in that collection. Make sure those rules exist before exposing the panel publicly.
