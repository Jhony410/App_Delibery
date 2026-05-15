
# Análisis de los 4 Pilares de la POO en el Proyecto DeliPuno

> **Proyecto analizado:** Plataforma DeliPuno — tres apps Flutter sibling (`app_delivery_usuario/`, `app_delivery_repartidor/`, `app_delivery_administrator/`) que comparten el proyecto Firebase `delypuno-ddd2d`.
> **Lenguaje:** Dart 3 (Flutter 3.11+).
> **Fecha del análisis:** 2026-05-15.
> **Alcance:** Carpetas `lib/` de los 3 paquetes Dart. Se ignoraron `firebase_options.dart` (autogenerado), `build/`, `.dart_tool/`, dependencias externas y carpetas `.claude/worktrees/`.

---

## Resumen ejecutivo

| Pilar | ¿Existe? | Nivel | Evidencia principal |
|-------|----------|-------|---------------------|
| **Encapsulamiento** | ✅ Sí | Intermedio | Campos `final` privados, prefijo `_`, getters calculados, setters controlados (`acceptOrder`, `setStore`). |
| **Herencia** | ✅ Sí | Avanzado | Decenas de clases extienden `StatelessWidget`, `StatefulWidget`, `State<T>`, `CustomPainter`. Uso de mixins (`SingleTickerProviderStateMixin`). |
| **Polimorfismo** | ✅ Sí | Avanzado | Sobrescritura de `build()`, `paint()`, `shouldRepaint()`. Constructores `factory` que devuelven el mismo tipo desde fuentes distintas. Streams genéricos. |
| **Abstracción** | ✅ Sí | Intermedio | `CustomPainter` (clase abstracta) usada como contrato; `StatefulWidget` separa configuración inmutable de estado mutable; servicios estáticos esconden Firestore detrás de una API simple. |

**Conclusión general:** la arquitectura POO del proyecto es **sólida y consistente** entre las tres apps. Existen los 4 pilares con evidencias reales y funcionales, no decorativas. La principal área de mejora es el **encapsulamiento** del singleton `CartService`, que actualmente expone campos estáticos públicos sin validación.

---

## ==================================================
## PILAR: 1. ENCAPSULAMIENTO
## ==================================================

### ✔ Estado
**Encontrado.** Está presente en *todas* las clases de modelos y servicios.

### ✔ Explicación técnica
En Dart, el encapsulamiento se logra mediante:
1. El **prefijo `_`** que hace que un identificador sea **privado al archivo** (library-private).
2. La declaración de campos como `final` (inmutables tras la construcción).
3. La exposición de **getters calculados** en lugar de campos crudos.
4. La centralización de las mutaciones en **métodos estáticos controlados** que validan invariantes.

El proyecto aplica los cuatro mecanismos.

---

### Evidencia 1 — Servicio `OrderService`

✔ **Archivo:** [app_delivery_repartidor/lib/services/order_service.dart](app_delivery_repartidor/lib/services/order_service.dart)
✔ **Ubicación exacta:**
- Línea 5: campo privado `_db`.
- Líneas 53–67: método público `acceptOrder` — único punto autorizado para mutar `courierId` + `status`.

✔ **Fragmento de código:**
```dart
class OrderService {
  static final _db = FirebaseFirestore.instance;          // ← campo privado

  static Future<bool> acceptOrder(String orderId, String courierId) async {
    final ref = _db.collection('orders').doc(orderId);
    return _db.runTransaction<bool>((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return false;
      final data = snap.data()!;
      if (data['courierId'] != null) return false;        // ← invariante protegido
      tx.update(ref, {
        'courierId': courierId,
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });
      return true;
    });
  }
}
```

✔ **Análisis detallado:**
La instancia de Firestore (`_db`) es privada — el resto del programa **no puede** llamarle directamente; debe pasar por la API pública del servicio. El método `acceptOrder` encapsula la regla de negocio crítica *"solo un repartidor puede tomar un pedido"* dentro de una transacción atómica. Si fuera un campo público `db`, cualquier pantalla podría escribir directamente en `orders/{id}` y romper esa invariante.

✔ **Nivel:** **Intermedio.**

✔ **Recomendaciones:**
- Considerar inyección de dependencias (en lugar de `static final`) para facilitar pruebas unitarias mockeando `_db`.
- Validar que `courierId` no esté vacío antes de la transacción.

---

### Evidencia 2 — Estado privado de Widget `_HomeScreenState`

✔ **Archivo:** [app_delivery_repartidor/lib/screens/home_screen.dart](app_delivery_repartidor/lib/screens/home_screen.dart)
✔ **Ubicación exacta:**
- Línea 17: clase `_HomeScreenState` (privada).
- Líneas 18–20: campos privados `_online`, `_toggling`, `_newOrderShown`.
- Línea 22: getter privado `_uid`.

✔ **Fragmento de código:**
```dart
class _HomeScreenState extends State<HomeScreen> {
  bool _online = false;
  bool _toggling = false;
  bool _newOrderShown = false;

  String? get _uid => AuthService.currentUid;
```

✔ **Análisis detallado:**
La convención `_` esconde el estado interno del widget. Ninguna otra pantalla puede leer ni modificar `_online` directamente; el flujo correcto es escuchar el `Stream<CourierModel?>` de `CourierService`. Esto cumple el principio de *"oculta lo que cambia"*.

✔ **Nivel:** **Intermedio.**

✔ **Recomendaciones:** Documentar el invariante: "`_online` refleja el último valor recibido del stream salvo que `_toggling == true`".

---

### Evidencia 3 — Modelo inmutable `CourierModel`

✔ **Archivo:** [app_delivery_repartidor/lib/models/courier_model.dart](app_delivery_repartidor/lib/models/courier_model.dart)
✔ **Ubicación exacta:**
- Líneas 4–18: todos los campos son `final`.
- Líneas 38–46: getters calculados `initials` e `isVerified`.
- Líneas 85–111: método `copyWith` para mutaciones controladas.

✔ **Fragmento de código:**
```dart
class CourierModel {
  final String uid;
  final String name;
  final String status;          // pending_review | active | suspended
  final bool online;
  // ... resto de campos final ...

  bool get isVerified => status == 'active';

  CourierModel copyWith({String? name, String? status, bool? online, /*…*/}) =>
      CourierModel(
        uid: uid,
        name: name ?? this.name,
        status: status ?? this.status,
        online: online ?? this.online,
        // ...
      );
}
```

✔ **Análisis detallado:**
Los campos `final` impiden la mutación accidental. El estado del repartidor (verificado / no verificado) se expone como un *getter* derivado de `status`, no como un booleano almacenado — así no puede haber dos verdades inconsistentes (`status='suspended'` pero `isVerified=true`). `copyWith` permite "modificar" creando una nueva instancia, lo cual es el patrón inmutable estándar.

✔ **Nivel:** **Avanzado** (modelos inmutables + factoría + serialización + clonación segura).

✔ **Recomendaciones:** Implementar `==` y `hashCode` (vía `Equatable` o método manual) para comparaciones seguras en colecciones.

---

## ==================================================
## PILAR: 2. HERENCIA
## ==================================================

### ✔ Estado
**Encontrado.** Es el pilar **más utilizado** del proyecto — Flutter es un framework basado en herencia.

### ✔ Explicación técnica
La herencia se manifiesta en Dart con la palabra clave `extends`. El proyecto la usa de forma sistemática:
- Todo widget heredera de `StatelessWidget` o `StatefulWidget`.
- El estado de un widget hereda de `State<T>`.
- Los pintores personalizados heredan de `CustomPainter`.
- Se usan **mixins** (`with`) para añadir capacidades (animación con `SingleTickerProviderStateMixin`).

---

### Evidencia 1 — `CButton extends StatelessWidget`

✔ **Archivo:** [app_delivery_repartidor/lib/widgets.dart](app_delivery_repartidor/lib/widgets.dart)
✔ **Ubicación exacta:**
- Línea 8: `class CButton extends StatelessWidget`.
- Línea 27: sobrescritura de `build()` con `@override`.

✔ **Fragmento de código:**
```dart
class CButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final CButtonVariant variant;
  // ...

  @override
  Widget build(BuildContext context) {
    // ... construye un botón con tamaños/colores según variant y size ...
  }
}
```

✔ **Análisis detallado:**
`CButton` reutiliza toda la maquinaria de `StatelessWidget`: ciclo de vida, integración con el árbol de widgets, claves, etc. Solo aporta los datos específicos (`label`, `variant`) y la lógica visual mediante `build()`.

✔ **Nivel:** **Básico** (es el patrón canónico de Flutter, pero impecable).

---

### Evidencia 2 — Cadena `StatefulWidget` → `State<T>` con mixin

✔ **Archivo:** [app_delivery_repartidor/lib/widgets.dart](app_delivery_repartidor/lib/widgets.dart)
✔ **Ubicación exacta:**
- Línea 408: `class PulsingDot extends StatefulWidget`.
- Línea 417: `class _PulsingDotState extends State<PulsingDot> with SingleTickerProviderStateMixin`.

✔ **Fragmento de código:**
```dart
class PulsingDot extends StatefulWidget {
  final Color color;
  final double size;
  const PulsingDot({super.key, this.color = CourierColors.online, this.size = 22});

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();
```

✔ **Análisis detallado:**
- `PulsingDot` extiende `StatefulWidget` (configuración inmutable).
- `_PulsingDotState` extiende `State<PulsingDot>` y **además** mezcla (`with`) `SingleTickerProviderStateMixin` — un caso de **herencia múltiple controlada** (mixin) que provee el `vsync` para el `AnimationController`.

✔ **Nivel:** **Avanzado** (herencia + mixin + uso de tipos genéricos `State<PulsingDot>`).

✔ **Recomendaciones:** Ninguna — es un uso libro-de-texto de mixins.

---

### Evidencia 3 — `_DarkMapPainter extends CustomPainter`

✔ **Archivo:** [app_delivery_repartidor/lib/widgets.dart](app_delivery_repartidor/lib/widgets.dart)
✔ **Ubicación exacta:**
- Línea 337: `class _DarkMapPainter extends CustomPainter`.
- Líneas 342, 405: sobrescritura de `paint()` y `shouldRepaint()`.

✔ **Fragmento de código:**
```dart
class _DarkMapPainter extends CustomPainter {
  final bool withRoute;
  _DarkMapPainter({required this.withRoute});

  @override
  void paint(Canvas canvas, Size size) { /* dibuja calles, bloques, ruta */ }

  @override
  bool shouldRepaint(_DarkMapPainter old) => old.withRoute != withRoute;
}
```

✔ **Análisis detallado:**
`CustomPainter` es una clase **abstracta** del framework: define el contrato `paint` + `shouldRepaint`. `_DarkMapPainter` lo extiende e implementa ambos métodos. Existe otro hijo análogo (`_StripePainter` en [app_delivery_usuario/lib/widgets.dart:86](app_delivery_usuario/lib/widgets.dart:86)) que demuestra la *jerarquía*: dos hijos diferentes con distintas pinturas comparten el mismo padre.

✔ **Nivel:** **Avanzado.**

---

## ==================================================
## PILAR: 3. POLIMORFISMO
## ==================================================

### ✔ Estado
**Encontrado.** Hay polimorfismo de **subtipos** (override) y **paramétrico** (genéricos).

### ✔ Explicación técnica
El polimorfismo aparece en tres formas:
1. **Override**: el mismo método (`build`, `paint`) tiene comportamiento distinto en cada subclase.
2. **Constructores `factory`**: el mismo nombre de constructor crea instancias del mismo tipo desde fuentes diferentes.
3. **Genéricos**: `Stream<T>`, `Future<T>`, `State<T>` se especializan según el contexto.

---

### Evidencia 1 — Override de `build()` en distintas formas

✔ **Archivos involucrados:**
- [app_delivery_repartidor/lib/widgets.dart:27](app_delivery_repartidor/lib/widgets.dart:27) — `CButton.build`.
- [app_delivery_repartidor/lib/widgets.dart:248](app_delivery_repartidor/lib/widgets.dart:248) — `StatusPill.build`.
- [app_delivery_administrator/lib/widgets/admin_widgets.dart:30](app_delivery_administrator/lib/widgets/admin_widgets.dart:30) — `AdminCard.build`.
- [app_delivery_administrator/lib/widgets/admin_widgets.dart:62](app_delivery_administrator/lib/widgets/admin_widgets.dart:62) — `AdminBadge.build`.

✔ **Fragmento de código:**
```dart
// Mismo nombre y firma; comportamientos completamente distintos
@override
Widget build(BuildContext context) {        // CButton: construye un botón pintado
  /* ... */
}

@override
Widget build(BuildContext context) {        // StatusPill: construye un chip de estado
  return Container(/* tinte basado en color */);
}

@override
Widget build(BuildContext context) {        // AdminCard: construye una superficie tipo Stripe
  return Container(/* borde + radio */);
}
```

✔ **Análisis detallado:**
El framework Flutter llama internamente `widget.build(context)` sin saber qué subclase es. Esto es **polimorfismo dinámico**: el método ejecutado se decide en tiempo de ejecución según el tipo real del widget. Es lo que permite tratar a `CButton`, `StatusPill` y `AdminCard` como simples `Widget` en árboles de UI heterogéneos.

✔ **Nivel:** **Avanzado.**

---

### Evidencia 2 — Constructores `factory` polimórficos

✔ **Archivo:** [app_delivery_repartidor/lib/models/order_model.dart](app_delivery_repartidor/lib/models/order_model.dart)
✔ **Ubicación exacta:**
- Línea 18: `factory OrderItem.fromMap(...)`.
- Línea 86: `factory OrderModel.fromMap(...)`.

✔ **Fragmento de código:**
```dart
factory OrderModel.fromMap(String id, Map<String, dynamic> m) => OrderModel(
      id: id,
      userId: m['userId'] ?? '',
      // ...
      items: (m['items'] as List? ?? [])
          .map((i) => OrderItem.fromMap(Map<String, dynamic>.from(i)))   // ← polimorfismo en cascada
          .toList(),
      // ...
    );
```

✔ **Análisis detallado:**
`fromMap` es un *constructor con nombre* que reemplaza al constructor por defecto cuando los datos vienen de Firestore. La llamada `.map((i) => OrderItem.fromMap(...))` aplica el mismo factory a cada elemento sin saber su contenido — un caso clásico de polimorfismo paramétrico (vía genéricos `List<E>` y `Iterable.map<T>`).

✔ **Nivel:** **Intermedio.**

---

### Evidencia 3 — Switch expressions polimórficos en `OrderModel.statusLabel`

✔ **Archivo:** [app_delivery_repartidor/lib/models/order_model.dart](app_delivery_repartidor/lib/models/order_model.dart)
✔ **Ubicación exacta:** Líneas 116–125.

✔ **Fragmento de código:**
```dart
String get statusLabel => switch (status) {
      'accepted' => 'Aceptado',
      'picked_up' => 'Recogido',
      'en_camino' => 'En camino',
      'entregado' => 'Entregado',
      'cancelado' => 'Cancelado',
      'preparing' => 'Preparando',
      'confirmed' => 'Confirmado',
      _ => 'Pendiente',
    };
```

✔ **Análisis detallado:**
Aunque no es polimorfismo "puro de subtipos", la propiedad `statusLabel` **se comporta polimórficamente respecto al estado**: el mismo getter devuelve representaciones distintas según el valor interno. La misma técnica se replica en [admin_user_model.dart:20](app_delivery_administrator/lib/models/admin_user_model.dart:20) (`roleLabel`).

✔ **Nivel:** **Intermedio.**

✔ **Recomendaciones:** Migrar `status` a un `enum` Dart sealed para que el compilador exija exhaustividad.

---

## ==================================================
## PILAR: 4. ABSTRACCIÓN
## ==================================================

### ✔ Estado
**Encontrado.** Hay abstracción tanto **explícita** (extender clases abstractas del framework) como **arquitectónica** (servicios que esconden la complejidad de Firestore).

### ✔ Explicación técnica
La abstracción se manifiesta de dos formas:
1. **Clases abstractas heredadas**: `CustomPainter`, `StatelessWidget`, `StatefulWidget` y `State<T>` son abstractas en Flutter (no se pueden instanciar directamente; obligan a sobrescribir `paint`, `build`, etc.).
2. **Abstracción de capa de datos**: las clases `OrderService`, `CourierService`, `AuthService` exponen una **interfaz simple** (`acceptOrder`, `streamCourier`, `signIn`) y ocultan los detalles de Firestore (paths, transactions, snapshots, conversiones).

---

### Evidencia 1 — `CustomPainter` como contrato abstracto

✔ **Archivo:** [app_delivery_repartidor/lib/widgets.dart](app_delivery_repartidor/lib/widgets.dart)
✔ **Ubicación exacta:** Líneas 337–406 (`_DarkMapPainter`).

✔ **Fragmento de código:**
```dart
class _DarkMapPainter extends CustomPainter {
  // CustomPainter es ABSTRACTO: obliga a implementar paint() y shouldRepaint()
  @override
  void paint(Canvas canvas, Size size) { /* ... */ }

  @override
  bool shouldRepaint(_DarkMapPainter old) => old.withRoute != withRoute;
}
```

✔ **Análisis detallado:**
El consumidor del pintor (el widget `CustomPaint`) **no necesita conocer** cómo se pinta el mapa; solo invoca `painter.paint(canvas, size)`. Esto es la esencia de la abstracción: separar **qué hace** (pintar algo en un canvas) de **cómo lo hace** (calles, bloques, ruta de bezier).

✔ **Nivel:** **Avanzado.**

---

### Evidencia 2 — `AuthService` como fachada (Facade pattern)

✔ **Archivo:** [app_delivery_administrator/lib/services/auth_service.dart](app_delivery_administrator/lib/services/auth_service.dart)
✔ **Ubicación exacta:** Líneas 8–44 (toda la clase).

✔ **Fragmento de código:**
```dart
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<UserCredential> signIn(String email, String password) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  static Future<AdminUserModel?> currentAdminProfile() async {
    final uid = currentUid;
    if (uid == null) return null;
    final snap = await _db.collection('admins').doc(uid).get();
    if (!snap.exists) return null;
    return AdminUserModel.fromMap(uid, snap.data()!);
  }
}
```

✔ **Análisis detallado:**
Las pantallas (`LoginScreen`, `SplashScreen`) **no saben** que existe Firebase Auth ni Firestore. Solo llaman `AuthService.signIn(...)` o `AuthService.currentAdminProfile()`. Si mañana el backend cambia a Supabase o REST, basta con reescribir esta clase — el resto de la app no se entera.

✔ **Nivel:** **Intermedio.**

✔ **Recomendaciones:**
- Convertir `AuthService` en una clase abstracta + implementación concreta `FirebaseAuthService`. Eso permitiría inyectar un `MockAuthService` en tests.

---

### Evidencia 3 — `StatefulWidget` separa configuración inmutable de estado mutable

✔ **Archivo:** [app_delivery_repartidor/lib/screens/home_screen.dart](app_delivery_repartidor/lib/screens/home_screen.dart)
✔ **Ubicación exacta:** Líneas 10–17.

✔ **Fragmento de código:**
```dart
class HomeScreen extends StatefulWidget {                   // ← contrato público (immutable)
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();    // ← createState es ABSTRACTO
}

class _HomeScreenState extends State<HomeScreen> { /* estado mutable */ }
```

✔ **Análisis detallado:**
`StatefulWidget` es abstracta: declara `createState()` sin implementarlo. Cada subclase decide qué tipo concreto de `State` utilizar. Quien usa `HomeScreen` **solo ve la API pública** (constructor); el `_HomeScreenState` privado queda completamente oculto. Esta es **abstracción + encapsulamiento combinados**.

✔ **Nivel:** **Avanzado.**

---

## Tabla resumen

| Pilar | Existe | Archivo | Clase | Líneas |
|-------|--------|---------|-------|--------|
| Encapsulamiento | ✅ | `app_delivery_repartidor/lib/services/order_service.dart` | `OrderService` | 4–90 |
| Encapsulamiento | ✅ | `app_delivery_repartidor/lib/screens/home_screen.dart` | `_HomeScreenState` | 17–22 |
| Encapsulamiento | ✅ | `app_delivery_repartidor/lib/models/courier_model.dart` | `CourierModel` | 3–112 |
| Herencia | ✅ | `app_delivery_repartidor/lib/widgets.dart` | `CButton extends StatelessWidget` | 8–83 |
| Herencia | ✅ | `app_delivery_repartidor/lib/widgets.dart` | `_PulsingDotState extends State<PulsingDot> with SingleTickerProviderStateMixin` | 408–465 |
| Herencia | ✅ | `app_delivery_repartidor/lib/widgets.dart` | `_DarkMapPainter extends CustomPainter` | 337–406 |
| Polimorfismo | ✅ | varios `widgets.dart` | `build(BuildContext)` override | múltiples |
| Polimorfismo | ✅ | `app_delivery_repartidor/lib/models/order_model.dart` | `factory OrderModel.fromMap` | 86–112 |
| Polimorfismo | ✅ | `app_delivery_repartidor/lib/models/order_model.dart` | `get statusLabel` (switch expression) | 116–125 |
| Abstracción | ✅ | `app_delivery_repartidor/lib/widgets.dart` | `_DarkMapPainter` (de `CustomPainter`) | 337–406 |
| Abstracción | ✅ | `app_delivery_administrator/lib/services/auth_service.dart` | `AuthService` (Facade) | 8–44 |
| Abstracción | ✅ | `app_delivery_repartidor/lib/screens/home_screen.dart` | `HomeScreen extends StatefulWidget` | 10–17 |

---

## Conclusiones y recomendaciones globales

### Calidad general de la arquitectura POO
**Alta.** Los 4 pilares se aplican de forma natural y consistente, no como adornos. La separación **modelos / servicios / widgets / screens** alinea cada capa con un pilar dominante:
- **Modelos** → encapsulamiento (immutables) + polimorfismo (factories).
- **Servicios** → abstracción (esconden Firestore).
- **Widgets / Screens** → herencia + polimorfismo.

### Recomendaciones para fortalecer la POO
1. **Reemplazar `CartService` con un singleton encapsulado.** Hoy expone campos estáticos públicos (`storeId`, `items`) sin validación — un consumidor podría romper invariantes (`items.clear()` sin actualizar `storeId`).
2. **Migrar campos `status` (String) a `enum` Dart**. Se gana exhaustividad en `switch` y elimina valores inválidos.
3. **Definir interfaces (`abstract class IAuthService`)** para los servicios para facilitar mocks y tests.
4. **Implementar `==`/`hashCode`** o usar `Equatable` en los modelos para comparaciones seguras.
5. **Considerar un patrón Strategy** para los pintores (`CustomPainter`): hoy hay dos pintores hermanos casi idénticos (`_DarkMapPainter` y `_StripePainter`); podrían compartir una superclase abstracta `BasePainter` con utilidades comunes.

---
