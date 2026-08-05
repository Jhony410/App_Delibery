# Icono de la app

`icon.png` (1254×1254) es el logo original de DeliPuno: **pin + palabra
"DeliPuno"**. **No tiene canal alfa**: las esquinas redondeadas son negro sólido,
así que no se puede usar tal cual como icono de launcher (saldría con esquinas
negras). Dentro de la app sí se usa entero (splash, cabeceras).

Los otros tres PNG son derivados generados por `generate_source_icons.ps1`, y
llevan **solo el pin**, sin la palabra: un icono de launcher se ve a ~48dp y a
ese tamaño el texto del logo completo queda ilegible.

| Archivo | Qué es | Lo consume |
|---|---|---|
| `icon_android.png` | 1024², pin centrado sobre cuadrado blanco de esquinas redondeadas transparentes | `image_path_android` (mipmap legacy) |
| `icon_ios.png` | 1024², pin centrado sobre blanco de borde a borde, sin alfa | `image_path` (iOS, web, Windows) |
| `icon_foreground.png` | 1024², pin centrado sobre transparente | `adaptive_icon_foreground` |

## Regenerar

```powershell
# 1) rehacer los tres derivados desde icon.png
.\assets\icon\generate_source_icons.ps1

# 2) rehacer los recursos de cada plataforma
dart run flutter_launcher_icons
```

La configuración vive en el bloque `flutter_launcher_icons:` de `pubspec.yaml`.
El icono solo entra en la app al **recompilar**: si cambias esto y sigues
repartiendo un APK viejo, en el celular se sigue viendo el icono anterior.

## Cómo se recorta el pin

`Symbol()` no tiene coordenadas hardcodeadas. Cuenta los píxeles con color real
(azul/cian) por columna y busca la primera franja de columnas vacías que supere
el 2% del ancho: esa es la separación entre el pin y la palabra. En el `icon.png`
actual mide 34px, mientras que los huecos entre letras miden 9–25px, así que el
corte cae en el sitio correcto. El símbolo resultante es el de x=48..472,
y=343..837 — el pin más las líneas de velocidad.

Si algún día cambia el logo y el corte sale mal, ajusta el `minGapRatio` con el
que se llama a `Symbol()` al final del script.

## Sobre la escala del foreground

Un icono adaptativo de Android mide 108dp pero el launcher solo muestra los 72dp
centrales (zona segura recomendada: 66dp). Encima, flutter_launcher_icons envuelve
el drawable en `<inset android:inset="16%">`, dejando el 68% del lienzo.

Por eso el script dibuja el pin al **79%** del PNG: `0.79 × 0.68 ≈ 0.54`, o sea
~58dp de 108dp — cómodo dentro de los 66dp de zona segura, incluso con máscara
circular. Si algún día cambia ese inset, ajustar ese 0.79.

Los otros dos derivados no pasan por el inset, así que van al **72%** del lienzo,
que es la proporción habitual de un icono de iOS.
