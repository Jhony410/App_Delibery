
# Pseudocódigo educativo — Los 4 pilares de la POO

> Material complementario a `POO_ANALISIS.md`.
> Todos los ejemplos están escritos en pseudocódigo neutral (independiente de Dart, Java, Python o C#) y reflejan situaciones reales del proyecto **DeliPuno**.

---

## ==================================================
## 1. ENCAPSULAMIENTO
## ==================================================

> Ocultar el estado interno de un objeto y exponer **solo** las operaciones controladas para modificarlo.

```pseudocodigo
Clase Repartidor

    // Atributos PRIVADOS — nadie fuera de la clase puede tocarlos directamente
    atributo privado uid
    atributo privado nombre
    atributo privado estado            // pending_review | active | suspended
    atributo privado totalEntregas

    // Constructor — única forma de crear el objeto
    constructor Repartidor(uid, nombre)
        este.uid = uid
        este.nombre = nombre
        este.estado = "pending_review"
        este.totalEntregas = 0
    fin constructor

    // Getter calculado — deriva del estado, no se almacena por separado
    método público estaVerificado()
        retornar (estado == "active")
    fin método

    // Setter CONTROLADO — valida la regla de negocio antes de mutar
    método público registrarEntrega()
        si estado != "active" entonces
            lanzar Error("Solo repartidores activos pueden entregar")
        fin si
        totalEntregas = totalEntregas + 1
    fin método

fin Clase
```

**Explicación:**
- Los atributos son **privados** ⇒ el resto del código no puede hacer `repartidor.estado = "active"` arbitrariamente.
- `estaVerificado()` es un **getter derivado**: no hay un campo booleano `verificado` que pudiera quedar desincronizado con `estado`.
- `registrarEntrega()` es un **setter validado**: garantiza la invariante *"solo activos suman entregas"*. Si el atributo fuera público, cualquier pantalla podría sumar entregas a un repartidor suspendido.

**Equivalente real en el proyecto:** [app_delivery_repartidor/lib/models/courier_model.dart:46](app_delivery_repartidor/lib/models/courier_model.dart:46) (`isVerified`) y [app_delivery_repartidor/lib/services/courier_service.dart:24](app_delivery_repartidor/lib/services/courier_service.dart:24) (`incrementDelivery`).

--------------------------------------------------

## ==================================================
## 2. HERENCIA
## ==================================================

> Una clase **hijo** reutiliza atributos y comportamientos de una clase **padre**, y agrega o redefine los suyos propios.

```pseudocodigo
// ── Clase PADRE ───────────────────────────────────
Clase Pantalla

    atributo título
    atributo colorFondo

    constructor Pantalla(título)
        este.título = título
        este.colorFondo = "blanco"
    fin constructor

    método mostrarBarraSuperior()
        imprimir "[" + título + "]"
    fin método

    método construir()
        // Método que cada hijo debe implementar a su manera
        lanzar Error("Debe ser implementado por la subclase")
    fin método

fin Clase


// ── Clase HIJO 1: hereda de Pantalla ──────────────
Clase PantallaInicio HEREDA DE Pantalla

    constructor PantallaInicio()
        super("Inicio Repartidor")     // llama al constructor padre
    fin constructor

    método construir()                  // sobrescribe el método del padre
        mostrarBarraSuperior()          // ← usa método HEREDADO
        imprimir "Bienvenido, listo para recibir pedidos"
    fin método

fin Clase


// ── Clase HIJO 2 ──────────────────────────────────
Clase PantallaPedido HEREDA DE Pantalla

    atributo idPedido

    constructor PantallaPedido(idPedido)
        super("Pedido #" + idPedido)
        este.idPedido = idPedido
    fin constructor

    método construir()
        mostrarBarraSuperior()
        imprimir "Detalle del pedido " + idPedido
    fin método

fin Clase
```

**Explicación:**
- `PantallaInicio` y `PantallaPedido` **no repiten** la lógica de `mostrarBarraSuperior()` — la heredan gratis.
- Ambas redefinen `construir()` con su propio comportamiento.
- Si mañana se cambia `colorFondo` por defecto en `Pantalla`, **todos los hijos** lo heredan sin tocar nada.

**Equivalente real en el proyecto:** Cualquier widget como [app_delivery_repartidor/lib/widgets.dart:8](app_delivery_repartidor/lib/widgets.dart:8) (`CButton extends StatelessWidget`).

--------------------------------------------------

## ==================================================
## 3. POLIMORFISMO
## ==================================================

> El **mismo mensaje** (nombre de método) provoca **distintos comportamientos** según el tipo real del objeto que lo recibe.

```pseudocodigo
// Reutilizamos la jerarquía anterior: Pantalla → PantallaInicio, PantallaPedido

// Función genérica que NO sabe qué tipo concreto recibe:
función renderizar(p : Pantalla)
    p.construir()       // ← se decide en TIEMPO DE EJECUCIÓN
fin función


// Programa principal
inicio
    pantallas = [
        nuevo PantallaInicio(),
        nuevo PantallaPedido("PED-007"),
        nuevo PantallaPedido("PED-008")
    ]

    para cada p en pantallas
        renderizar(p)   // misma llamada → 3 salidas distintas
    fin para
fin
```

**Salida esperada:**
```
[Inicio Repartidor]
Bienvenido, listo para recibir pedidos
[Pedido #PED-007]
Detalle del pedido PED-007
[Pedido #PED-008]
Detalle del pedido PED-008
```

**Explicación:**
- `renderizar()` recibe el tipo abstracto `Pantalla`. **No le importa** si es `PantallaInicio` o `PantallaPedido`.
- En tiempo de ejecución, el sistema busca la versión correcta de `construir()` según el objeto real (despacho dinámico).
- Esto permite **agregar nuevos hijos sin modificar `renderizar()`** — principio Open/Closed.

**Equivalente real en el proyecto:** Flutter llama `widget.build(context)` polimórficamente sobre cualquier subclase de `Widget` — ver [app_delivery_repartidor/lib/widgets.dart:27](app_delivery_repartidor/lib/widgets.dart:27), [app_delivery_repartidor/lib/widgets.dart:248](app_delivery_repartidor/lib/widgets.dart:248), [app_delivery_administrator/lib/widgets/admin_widgets.dart:62](app_delivery_administrator/lib/widgets/admin_widgets.dart:62).

--------------------------------------------------

## ==================================================
## 4. ABSTRACCIÓN
## ==================================================

> Definir un **contrato** (qué se debe hacer) sin atarse a la **implementación** (cómo se hace).

```pseudocodigo
// ── Clase ABSTRACTA: define el contrato ───────────
Clase Abstracta ServicioPedidos

    // Métodos abstractos: sin cuerpo. Las hijas DEBEN implementarlos.
    método abstracto obtenerPedido(id) : Pedido
    método abstracto aceptarPedido(idPedido, idRepartidor) : booleano

    // Método concreto compartido por todas las implementaciones
    método final esCancelable(pedido)
        retornar (pedido.estado == "pending" o pedido.estado == "confirmed")
    fin método

fin Clase


// ── Implementación concreta 1: producción con Firebase ──
Clase ServicioPedidosFirebase HEREDA DE ServicioPedidos

    atributo privado db = ConexiónFirestore.instancia()

    método obtenerPedido(id)
        documento = db.coleccion("orders").doc(id).leer()
        retornar Pedido.desdeMapa(documento.datos)
    fin método

    método aceptarPedido(idPedido, idRepartidor)
        // Lógica transaccional real (como OrderService.acceptOrder)
        ejecutarTransacción(()
            doc = db.leer(idPedido)
            si doc.courierId != null entonces retornar falso
            db.actualizar(idPedido, { courierId: idRepartidor, status: "accepted" })
            retornar verdadero
        )
    fin método

fin Clase


// ── Implementación concreta 2: para tests ─────────
Clase ServicioPedidosFalso HEREDA DE ServicioPedidos

    atributo memoria = mapa vacío

    método obtenerPedido(id)
        retornar memoria[id]
    fin método

    método aceptarPedido(idPedido, idRepartidor)
        memoria[idPedido].courierId = idRepartidor
        retornar verdadero
    fin método

fin Clase


// ── Código cliente: depende del CONTRATO, no de la implementación ──
función procesarSiguientePedido(servicio : ServicioPedidos, idRepartidor)
    pedido = servicio.obtenerPedido("PED-001")
    si servicio.esCancelable(pedido) entonces
        imprimir "Pedido aún cancelable, esperar..."
    sino
        servicio.aceptarPedido(pedido.id, idRepartidor)
    fin si
fin función
```

**Explicación:**
- `ServicioPedidos` es **abstracto**: no se puede instanciar directamente. Solo declara qué operaciones existen.
- `ServicioPedidosFirebase` y `ServicioPedidosFalso` ofrecen **implementaciones distintas** del mismo contrato.
- `procesarSiguientePedido` depende del **tipo abstracto** ⇒ se le puede inyectar el real (en producción) o el falso (en tests) sin cambiar una línea.
- Esto separa el **qué** (tomar un pedido) del **cómo** (Firestore vs. memoria) — la esencia de la abstracción.

**Equivalente real en el proyecto:** [app_delivery_administrator/lib/services/auth_service.dart](app_delivery_administrator/lib/services/auth_service.dart) actúa como fachada que esconde Firebase Auth + Firestore tras una API simple. La clase `CustomPainter` del framework es literalmente abstracta y `_DarkMapPainter` ([app_delivery_repartidor/lib/widgets.dart:337](app_delivery_repartidor/lib/widgets.dart:337)) la implementa.

--------------------------------------------------

## Tabla mnemotécnica final

| Pilar | Pregunta clave | Palabra clave en pseudocódigo |
|-------|---------------|-------------------------------|
| Encapsulamiento | *¿Quién puede modificar este dato?* | `atributo privado` + métodos validadores |
| Herencia | *¿Puedo reutilizar lo que ya hace otra clase?* | `HEREDA DE` / `extends` / `super` |
| Polimorfismo | *¿Puedo tratar a varios tipos como uno solo?* | `método abstracto` + override en subclases |
| Abstracción | *¿Qué expongo y qué oculto?* | `Clase Abstracta` + métodos sin cuerpo |

---
