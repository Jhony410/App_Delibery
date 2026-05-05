# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Workspace layout

This directory holds **two sibling Flutter apps** that share one Firebase project (`delypuno-ddd2d`):

| Folder | App | Status |
|---|---|---|
| `app_delivery_usuario/` | DeliPuno — customer app (orders food, tracks delivery) | **Read-only.** Do not modify any files inside. See `app_delivery_usuario/CLAUDE.md` for its architecture. |
| `app_delivery_repartidor/` | Dely Repartidor — courier/driver app | Active project. All work happens here. |

The two apps are **independent Dart packages** (not a monorepo with shared code) — they only share the Firestore database. The courier app duplicates models like `OrderModel` locally rather than importing from the user app, so each app can evolve independently.

A third folder `D:\Aplication Delibery-handoff-repartidor\` (sibling to this workspace) holds the source design files (`.jsx` mockups) the courier app was built from. Useful when adding new screens or matching pixel details.

## Commands (run from inside `app_delivery_repartidor/`)

```bash
flutter pub get                    # install dependencies
flutter run                        # run on connected device/emulator
flutter build apk --debug          # build debug APK
flutter build apk --release        # build release APK (debug-signed)
flutter analyze                    # lint — must report "No issues found!"
flutter test                       # run all widget tests
flutter test test/widget_test.dart # single test file
```

PowerShell is the default shell (Windows 11). When chaining commands, use `;` then `if ($?) { ... }` — `&&` is a parser error in PowerShell 5.1.

## Courier app architecture

**Stack:** Flutter 3.11+, Material 3 dark theme, no state management library — local `StatefulWidget`/`setState` only. Backend is Firebase (Auth + Firestore), reusing the user app's project.

### Entry point & routing

`lib/main.dart` initializes Firebase via `firebase_options.dart`, locks portrait orientation, and registers all routes via `onGenerateRoute`. Workflow screens take an `OrderModel` through `settings.arguments` — pass it explicitly when navigating with `Navigator.pushNamed(context, '/route', arguments: order)`.

### Screen flow

```
/ (SplashScreen — decides next based on auth + courier.status)
  → /login → /register → /review (account pending verification)
  → /home (MainShell — bottom nav: Home / Pedidos / Billetera / Perfil)

Delivery workflow (sequential, each screen mutates order.status):
  /new-order (modal, 15s timer)
    → accept → /order-detail
    → /route-store → /pickup → /route-customer → /deliver → /completed
```

`HomeScreen` watches `OrderService.streamAvailable()` only when the courier toggles online. When orders appear, it auto-pushes `/new-order` with the first available order.

### Order status state machine

The `orders/` collection is shared with the user app. The courier app **extends** the user app's status flow with two new states:

```
pending → confirmed → preparing  ← user app writes these
       ↓
   accepted → picked_up → en_camino → entregado | cancelado  ← courier app writes these
```

`OrderService.acceptOrder()` uses a Firestore transaction to atomically claim an order — only succeeds if `courierId` is null. This prevents two couriers from grabbing the same order. Always go through this method, not a plain `update`.

### Firestore collections

```
users/{uid}                    ← user app's customers (do not write from courier app)
stores/{storeId}/products/...  ← shared catalog (read-only from courier app)
orders/{orderId}               ← shared; courier sets courierId + status mutations
couriers/{uid}                 ← courier-only; profile, online flag, totals
```

Courier-specific fields on orders: `courierId`, `acceptedAt`, `pickedUpAt`, `deliveredAt`. The user app may not set these; treat them as null when missing.

### Theme & widgets

`lib/theme.dart` — `CourierColors` palette (dark, distinct from the user app's light theme). Primary `#FF6B35` is shared with the user app; everything else is courier-specific. `buildCourierTheme()` uses Plus Jakarta Sans via `google_fonts`.

`lib/widgets.dart` — all reusable components live in one file: `CButton` (variants `primary`/`online`/`danger`/`surface`/`ghost`, sizes `md`/`lg`/`xl`), `CField` (works as static display *or* `TextField` when given a controller), `CTopBar`, `StatusPill`, `SectionLabel`, `SurfaceCard`, `IconBox`, `PulsingDot`, and `DarkMapBackground` (custom-painted faux map — the app has no real Google Maps integration yet).

### Services (all static, no instantiation)

- `AuthService` — Firebase Auth on `couriers/{uid}` (different collection from user app's `users/{uid}` — same Firebase project, different roles).
- `CourierService` — profile streaming, online toggle, delivery counter increment.
- `OrderService` — order streams (`streamAvailable`, `streamForCourier`, `streamActiveForCourier`), atomic `acceptOrder`, status transitions.

## Firebase config

Both apps use the same Firebase project (`delypuno-ddd2d`). The courier app's Android package `com.example.app_delivery_repartidor` was added to `google-services.json` reusing the existing `mobilesdk_app_id`. **For production releases**, register the courier package properly via `flutterfire configure` to issue a real Android app ID — the current setup is fine for development but not for App Store/Play Store distribution.

## Constraints

- **Never modify `app_delivery_usuario/`.** Its UI and Firestore writes are considered the source of truth for the customer side. If a contract change is needed, document it but do not edit.
- The courier app is **self-contained**: don't import from `../app_delivery_usuario/lib/`. If logic genuinely needs to be shared, copy it (the duplication is intentional).
- `flutter analyze` must stay clean — no warnings, no info-level lints. The repo currently reports zero issues.
