# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## Workspace layout

This directory holds **three sibling Flutter apps plus a Cloud Functions backend** that share one Firebase project (`delypuno-ddd2d`):

| Folder | App | Status |
|---|---|---|
| `app_delivery_usuario/` | DeliPuno — customer app (orders food, tracks delivery) | Active. Modified in recent sessions (tracking screen with return-to-menu buttons). See `app_delivery_usuario/AGENTS.md` for its architecture. |
| `app_delivery_repartidor/` | Dely Repartidor — courier/driver app | Active project. Most work happens here. |
| `app_delivery_administrator/` | Runa Admin Panel — admin app (Flutter Web) | Active. Order management, reassignment, courier/store approval. |
| `functions/` | Cloud Functions (Node.js, Firebase Admin SDK) | Active. Round-robin courier dispatch logic. |

Additional shared files at the workspace root: `firestore.rules` (Firestore security rules) and `firestore.indexes.json` (Firestore indexes).

The three apps are **independent Dart packages** (not a monorepo with shared code) — they only share the Firestore database. The courier app duplicates models like `OrderModel` locally rather than importing from the user app, so each app can evolve independently.

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
  /new-order (modal, 30s timer)
    → accept → /order-detail
    → /route-store → /pickup → /route-customer → /deliver → /completed
```

`HomeScreen` watches for orders where `assignedCourierId == uid` of the logged-in courier (the order assigned to it by the Cloud Function), only while the courier is toggled online. When such an order appears, it auto-pushes `/new-order` with it. The courier no longer pulls from a broadcast `streamAvailable()` — assignment is driven server-side by `offerToNextCourier` (see Cloud Functions).

### Order status state machine

The `orders/` collection is shared with the user app. The courier app **extends** the user app's status flow with two new states:

```
pending → confirmed → preparing  ← user app writes these
       ↓
   accepted → picked_up → en_camino → entregado | cancelado  ← courier app writes these
```

Assignment is no longer broadcast. A Cloud Function (`offerToNextCourier`) offers each order to one online courier at a time via these `orders/{orderId}` fields:

```
assignedCourierId    ← courier the order is currently offered to
assignmentExpiresAt  ← timestamp the offer expires (30s window)
rejectedCouriers     ← list of couriers who rejected or let the offer expire
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

## Cloud Functions

Logic lives in `functions/index.js` (Node.js, Firebase Admin SDK). It does **not** use FCM — the mechanism is Firestore-as-bus.

Main functions:
- `offerToNextCourier(orderRef)`: assigns the order to the next online courier in round-robin rotation. Restarts the cycle if everyone rejected (continuous rotation).
- `offerOrderOnCreate` (onCreate trigger): fires the first offer when an order is created.
- `offerOrderOnReleased` (onUpdate trigger): rotates to the next courier when an order is rejected, expires, or is reassigned manually. Only fires on the false→true edge of the `needsCourier` predicate.
- `reclaimExpiredOffers` (scheduled, every 1 min): releases expired offers when the courier didn't respond (app closed).

Deploy: `firebase deploy --only functions` (from the workspace root, not from `functions/`).

## Firebase config

Both apps use the same Firebase project (`delypuno-ddd2d`). The courier app's Android package `com.example.app_delivery_repartidor` was added to `google-services.json` reusing the existing `mobilesdk_app_id`. **For production releases**, register the courier package properly via `flutterfire configure` to issue a real Android app ID — the current setup is fine for development but not for App Store/Play Store distribution.

## Constraints

- The courier app is **self-contained**: don't import from `../app_delivery_usuario/lib/`. If logic genuinely needs to be shared, copy it (the duplication is intentional).
- **Never write the `assignedCourierId` / `assignmentExpiresAt` / `rejectedCouriers` fields directly from Flutter.** These are managed exclusively by `functions/index.js`. Writing them from a client breaks the round-robin invariant.
- The admin's **Reasignar** button writes to Firestore directly (`order_service.dart` `reassign()`). That write indirectly triggers `offerOrderOnReleased`, which rotates to the next courier. Do not create an alternative path for reassignment.
- `flutter analyze` must stay clean — no warnings, no info-level lints. The repo currently reports zero issues.
