# Icono de la app

`icon.png` (1254×1254) es el logo original de DeliPuno. **No tiene canal alfa**:
las esquinas redondeadas son negro sólido, así que no se puede usar tal cual como
icono de launcher (saldría con esquinas negras).

Los otros tres PNG son derivados generados por `generate_source_icons.ps1`:

| Archivo | Qué es | Lo consume |
|---|---|---|
| `icon_android.png` | 1024², esquinas negras → transparentes | `image_path_android` (mipmap legacy) |
| `icon_ios.png` | 1024², esquinas negras → blancas, sin alfa | `image_path` (iOS, web, Windows) |
| `icon_foreground.png` | 1024², logo recortado y centrado sobre transparente | `adaptive_icon_foreground` |

## Regenerar

```powershell
# 1) rehacer los tres derivados desde icon.png
.\assets\icon\generate_source_icons.ps1

# 2) rehacer los recursos de cada plataforma
dart run flutter_launcher_icons
```

La configuración vive en el bloque `flutter_launcher_icons:` de `pubspec.yaml`.

## Sobre la escala del foreground

Un icono adaptativo de Android mide 108dp pero el launcher solo muestra los 72dp
centrales (zona segura recomendada: 66dp). Encima, flutter_launcher_icons envuelve
el drawable en `<inset android:inset="16%">`, dejando el 68% del lienzo.

Por eso el script dibuja el logo al **79%** del PNG: `0.79 × 0.68 ≈ 0.54`, o sea
~58dp de 108dp — cómodo dentro de los 66dp de zona segura, incluso con máscara
circular. Si algún día cambia ese inset, ajustar la constante `safe` del script.
