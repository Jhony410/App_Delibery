# 🛵 DeliPuno — Plataforma de Delivery

> Sistema integral de delivery para la ciudad de Puno, compuesto por tres aplicaciones Flutter conectadas a un único backend Firebase.

---

## 📖 Descripción

**DeliPuno** es un ecosistema de delivery multi-aplicación que conecta a **clientes**, **repartidores** y **administradores** alrededor de un mismo proyecto Firebase (`delypuno-ddd2d`). Cada actor del sistema cuenta con una aplicación dedicada, optimizada para su flujo de trabajo, pero todas comparten en tiempo real la misma base de datos de pedidos, tiendas y usuarios.

## 🎯 Objetivo

Ofrecer una solución completa de delivery local que permita:

- A los **clientes**, descubrir tiendas, hacer pedidos y seguir su entrega en vivo.
- A los **repartidores**, recibir órdenes, gestionar el flujo de recojo y entrega.
- A los **administradores**, supervisar la operación, aprobar repartidores, gestionar tiendas y analizar la actividad desde un panel web.

---

## 🧰 Tecnologías utilizadas

| Categoría | Tecnología |
|---|---|
| Lenguaje | **Dart** (Flutter 3.11+) |
| Framework UI | **Flutter** (Material 3) |
| Backend | **Firebase** — Auth + Cloud Firestore |
| Tipografía | Plus Jakarta Sans (`google_fonts`) |
| Plataformas | Android, iOS y Flutter Web |
| Estado | `StatefulWidget` / `setState` (sin librerías externas) |

---

## 🧩 Arquitectura del proyecto

El repositorio aloja **tres apps Flutter independientes** que comparten un único proyecto de Firebase:

```
Aplicacion Delibery Puno/
├── app_delivery_usuario/         → DeliPuno (cliente)
├── app_delivery_repartidor/      → Dely Repartidor (courier)
└── app_delivery_administrator/   → Runa Admin Panel (web)
```

Cada app es un paquete Dart autónomo. **No comparten código**: los modelos como `OrderModel` se duplican intencionalmente en cada proyecto para que evolucionen de forma aislada. Lo único compartido es la **base de datos Firestore**.

### Colecciones Firestore compartidas

```
users/{uid}                       ← clientes
  └─ addresses/{addressId}
stores/{storeId}                  ← catálogo de tiendas
  └─ products/{productId}
orders/{orderId}                  ← pedidos (escritos por cliente, repartidor y admin)
couriers/{uid}                    ← perfiles de repartidores
admins/{uid}                      ← perfiles de administradores
tickets/{ticketId}                ← soporte
```

### Máquina de estados de un pedido

```
pending → confirmed → preparing            (escritos por la app cliente)
       ↓
   accepted → picked_up → en_camino        (escritos por la app repartidor)
       ↓
   entregado | cancelado
```

---

## 📱 Aplicaciones

### 🟠 DeliPuno — App Cliente (`app_delivery_usuario/`)

App móvil para usuarios finales (Android/iOS, vertical, tema claro).

**Funcionalidades:**
- Registro y login con Firebase Auth.
- Exploración de tiendas y productos por categoría.
- Carrito de compras y selección de direcciones.
- Checkout con resumen y método de pago.
- Tracking en tiempo real del pedido.
- Calificación post-entrega e historial de pedidos.

### 🟡 Dely Repartidor — App Courier (`app_delivery_repartidor/`)

App móvil para repartidores (Android/iOS, vertical, tema oscuro).

**Funcionalidades:**
- Registro de repartidor con verificación administrativa.
- Toggle online/offline para recibir pedidos.
- Recepción de pedidos disponibles con temporizador de aceptación (15 s).
- Flujo guiado: ruta a tienda → recojo → ruta al cliente → entrega.
- Aceptación atómica de pedidos vía transacción Firestore (evita doble asignación).
- Billetera con historial de ganancias y perfil de courier.

### 🔵 Runa Admin Panel — Panel Web (`app_delivery_administrator/`)

Panel de administración (Flutter Web, tema claro estilo Stripe/Linear).

**Funcionalidades:**
- Dashboard con métricas clave y gráficos de ventas.
- Gestión de pedidos: cancelar, reasignar, ver detalle.
- Mapa en vivo de pedidos y repartidores.
- Aprobación/rechazo de repartidores y tiendas.
- Gestión de clientes, zonas, precios y promociones.
- Sistema de tickets de soporte.
- Administración de usuarios admin y roles.

---

## ⚙️ Requisitos

- **Flutter SDK** ≥ 3.11.4
- **Dart SDK** ≥ 3.11.4
- **Android Studio** o **VS Code** con extensión Flutter
- **Chrome** (para correr el panel admin web)
- Cuenta de **Firebase** con el proyecto `delypuno-ddd2d` configurado
- **Windows 11** (PowerShell) — el proyecto se desarrolló en este entorno, pero es multiplataforma

---

## 🚀 Instalación y ejecución

### 1. Clonar el repositorio

```bash
git clone <repo-url>
cd "Aplicacion Delibery Puno"
```

### 2. Elegir la app que deseas correr y entrar a su carpeta

```bash
cd app_delivery_usuario          # cliente
# o
cd app_delivery_repartidor       # repartidor
# o
cd app_delivery_administrator    # admin
```

### 3. Instalar dependencias

```bash
flutter pub get
```

### 4. Ejecutar la app

```bash
# Para cliente / repartidor (móvil)
flutter run

# Para el panel admin (web)
flutter run -d chrome
```

### 5. Comandos útiles

```bash
flutter analyze                        # lint (debe reportar "No issues found!")
flutter test                           # correr pruebas
flutter build apk --release            # compilar APK release (cliente / repartidor)
flutter build web --no-tree-shake-icons  # compilar build web (admin)
```

> **Nota PowerShell:** En Windows usa `;` y `if ($?) { ... }` para encadenar comandos. El operador `&&` no funciona en PowerShell 5.1.

---

## 📂 Estructura básica de carpetas

Las tres apps siguen una arquitectura común:

```
lib/
├── main.dart              → entry point + tabla de rutas
├── theme.dart             → paleta de colores y tema Material
├── firebase_options.dart  → config de Firebase (auto-generado)
├── models/                → clases Dart con fromMap / toMap
├── services/              → servicios estáticos (Auth, DB, etc.)
├── widgets.dart           → widgets reutilizables (en cliente y repartidor)
├── widgets/               → widgets reutilizables (en admin)
└── screens/               → una pantalla por archivo
```

---

## 📊 Estado actual del proyecto

| App | Estado |
|---|---|
| 🟠 Cliente | ✅ Funcional — flujo completo de pedido |
| 🟡 Repartidor | ✅ Funcional — flujo completo de entrega con aceptación atómica |
| 🔵 Admin | ✅ Funcional — todas las secciones visibles, mapas y gráficos como `CustomPainter` |

El sistema funciona end-to-end en desarrollo. Las tres apps están conectadas a la misma instancia Firestore y operan en tiempo real.

---

## 🔮 Posibles mejoras futuras

- Integración real con **Google Maps** (`google_maps_flutter`) en lugar de mapas pintados con `CustomPainter`.
- Reemplazar los gráficos placeholder por una librería real (`fl_chart`, `syncfusion_flutter_charts`).
- Pasarela de pagos integrada (Culqi, MercadoPago, Yape).
- Notificaciones push con **Firebase Cloud Messaging**.
- Reglas de seguridad robustas en Firestore para producción.
- Registro de cada app en Firebase como aplicación independiente vía `flutterfire configure` (actualmente comparten el `mobilesdk_app_id`).
- Internacionalización (es/en/qu).
- Migración a un manejador de estado (`Riverpod` o `Bloc`) si la app crece en complejidad.
- CI/CD con GitHub Actions para builds automáticos.

---

## 👥 Créditos

**Autor:** Jhon Aguilar
**Email:** jhonykey1415@gmail.com
**Proyecto Firebase:** `delypuno-ddd2d`
**Año:** 2026

---

## 📝 Licencia

Proyecto privado — todos los derechos reservados.
