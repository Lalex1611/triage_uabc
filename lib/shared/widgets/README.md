# Sistema de diseño TRIAGE

Componentes y tokens del rediseño de Figma (página "Componentes · TRIAGE").
Todo se importa con una sola línea:

```dart
import 'package:sistema_triage/shared/widgets/triage_ui.dart';
```

## Qué componente usar

| Figma | Código |
|---|---|
| Botón | `TriageButton` (variantes `primary`, `secondary`, `subtle`, `danger`, `success`; tamaños `large`, `medium`; `isLoading`) |
| Chip | `TriageChip` |
| Pestañas | `TriageTabs` |
| Buscador | `TriageSearchBar` |
| Insignia de estado | `TriageStatusBadge`, `.patient(status)`, `.rejected()`, `.registered()`, `.deceased()`, `.active()`, `.closed()` |
| Encabezado de inicio / de detalle | `TriageHomeHeader` / `TriageDetailHeader` |
| Tarjeta de paciente (B07) / de sala (C05) | `TriagePatientCard` / `TriagePatientCard.room` |
| Tarjeta de incidente | `TriageIncidentCard` |
| Métrica | `TriageMetric`, `.level(level)`, `.role()` |
| Conteo | `TriageLevelCount` |
| Pastilla de color | `TriageLevelPill` |
| Barra de color | `TriageLevelBar` |
| Punto de color | Un `Container` con `level.color` |
| Banner del paciente (B13, C02, C06) | `TriagePatientBanner` |
| Franja del paciente en curso (B14 a B16) | `TriagePatientStrip` |
| Tarjeta de entrante (C01) | `TriageIncomingCard` |
| Notificación (C12) | `TriageNotificationCard` |
| Fila de dato | `TriageDataRow` |
| Campo (texto, área, selección) | `TriageField`, `TriageField.area`, `TriageSelectField` |
| Aviso | `TriageAlert` |
| Aviso breve | `showTriageToast` (o `showAppSnackBar`, que ya lo usa) |
| Íconos | `TriageIcon(TriageIcons.x)` |
| Navegación campo / hospital | `ParamedicoNavbar` / `MedicoNavbar` (sobre `AppModuleBottomNav`) |
| Paso | `TriageSteps` |
| Opción grande | `TriageLargeOption` (`neutral`, `highlighted`, `tinted`) |
| Foto | `TriagePhoto` |
| Hoja inferior con Agarre | `showTriageSheet` (`dismissible: false` en formularios a medias); `TriageSheet` solo en hojas fijas (mapa) |
| Selección única (C04, B14) | `TriageRadioOption` |
| Fila de opción en hojas | `TriageOptionRow`, `.check`, `.toggle` |
| Botón de color | `TriageLevelButton.start`, `.hospital` o con textos propios |
| Marcadores de mapa | `TriageIncidentMarker`, `TriagePatientMarker`, `TriageHospitalMarker`, `TriageUnitMarker`, `TriageUserMarker` |
| Diálogo | `showTriageConfirm`; `showDialog` con `TriageDialog` para más opciones |
| Mensaje de resultado a pantalla completa | `TriageResultMessage` |
| Tarjeta de sección | `TriageSectionCard`, con `TriageSectionAction` para "Editar" o "Añadir" |
| Barra de acciones inferior | `TriageActionBar` |
| Botón de solo ícono | `TriageIconButton` (variantes `sunken`, `surface`, `plain`, `onAccent`; tamaños `small`, `compact`, `large`) |
| Base de tarjetas tocables y de textos de opción (internas) | `TriageTapCard`, `TriageOptionText` |

La navegación ya tiene el aspecto de Figma, pero sus pestañas y rutas cambian al migrar las pantallas B01, B02, B19, B20, C01, C05 y C13.

## Tokens: nada de valores sueltos

No se escriben números ni colores a mano en pantallas ni componentes. Si falta
un valor, se añade a `core/theme/triage_tokens.dart`, no se pone a mano en la
pantalla.

| Para | Usar |
|---|---|
| Colores | `TriageColors` (texto, fondo, borde, señal, triage) |
| Color del rol (rojo campo / azul hospital) | `context.triageRole.accent` y `.soft` |
| Color de un nivel de triage | `level.color`, `level.background`, `level.onColor`, `level.label` |
| Nombre clínico de un nivel | `level.startName`, `level.startDetail`, `level.hospitalName`, `level.hospitalDetail` |
| Tono de un mensaje | `TriageTone` (`tone.color`, `tone.background`, `tone.icon`) |
| Texto | `TriageTextStyles` + `.copyWith(color: …)` |
| Márgenes y separaciones | `TriageSpacing` (`xxs` 2 · `xs` 4 · `sm` 8 · `md` 12 · `lg` 16 · `xl` 20 · `xxl` 24) |
| Esquinas | `TriageRadii` |
| Íconos, controles, bordes | `TriageSizes` |
| Opacidades | `TriageOpacity` |
| Sombras | `TriageShadows` |

Dar nombre a un número no lo hace adaptable. Las medidas decorativas que solo
tiene una pieza (íconos destacados, símbolos, márgenes) se reducen con
`context.rDim` de `AppResponsive`, nunca se escriben para un solo tamaño de
pantalla.

## Reglas de diseño

- **Alto mínimo, no fijo.** `BoxConstraints(minHeight: …)`, nunca `height:`
  en algo con texto. Todo debe verse bien con el texto al 200 %.
- **Ancho adaptable.** `Expanded`, `Flexible` o `Wrap` en vez de anchos fijos.
  Para una fila de métricas, `Expanded` en cada una.
- **`rDim` solo para lo decorativo.** Zonas táctiles y texto nunca se escalan
  con él: son mínimos de accesibilidad y preferencias del usuario.
- **El texto no se encoge ni se corta.** Nombres y datos clínicos pasan a otra
  línea; `FittedBox` solo como último recurso para una palabra que no cabe.
  La app se usa en vertical: se prueba de 280 a 800 de ancho y con texto al 200 %.
- **Sin posiciones fijas.** Alineaciones relativas en lugar de `Positioned` con
  valores.
- **Zona táctil.** Mínimo 48 (`TriageSizes.touchTarget`); 44 solo en chips y
  botón mediano.
- **Contraste.** Texto ≥ 4.5:1 e íconos ≥ 3:1. Por eso algunos colores difieren
  de Figma (`textSecondary` en vez de `textTertiary` para texto pequeño,
  `successText`/`warningText` para texto de señal).
- **Encabezados en el cuerpo.** `TriageHomeHeader`/`TriageDetailHeader` van
  como primer hijo del `body`, no en `Scaffold.appBar`.

## Cómo migrar una pantalla

1. **Edita el archivo de la pantalla que ya existe**; no crees otro. Se
   conservan la página, su controlador, las rutas, los objetos `*Data` y los
   repositorios: solo cambian las piezas visuales de dentro.
2. Cambia los widgets antiguos por los `Triage*`. Si un widget antiguo de la
   carpeta de la pantalla se usa en un solo sitio, puede quedarse como
   adaptador de pocas líneas (p. ej. `PatientCardData` → `TriagePatientCard`)
   o borrarse.
3. **No modifiques widgets antiguos compartidos** (`AppHeader`,
   `PatientLifecycleStatusBadge`, …) mientras otras pantallas los usen: se
   reemplazan cuando todas las que los usan estén migradas.
4. Los enums antiguos (`PatientStatus`, `TriageCategory`…) se convierten a
   `PatientLifecycleStatus` y `TriageLevel` en la pantalla o con una extensión;
   no hace falta tocar los controladores.
5. Revisa la pantalla con el texto al 200 % y en los dos roles.

## Ver los componentes sin abrir la app

Cada grupo tiene un sandbox con interruptores de rol y de texto al 200 %:

```
flutter run -t test/shared/widgets/triage_button_visual_test.dart
flutter run -t test/shared/widgets/triage_icon_visual_test.dart
flutter run -t test/shared/widgets/triage_chip_visual_test.dart
flutter run -t test/shared/widgets/triage_search_bar_visual_test.dart
flutter run -t test/shared/widgets/triage_status_badge_visual_test.dart
flutter run -t test/shared/widgets/triage_tabs_visual_test.dart
flutter run -t test/shared/widgets/triage_header_visual_test.dart
flutter run -t test/shared/widgets/triage_cards_visual_test.dart
flutter run -t test/shared/widgets/triage_forms_visual_test.dart
flutter run -t test/shared/widgets/app_module_bottom_nav_visual_test.dart
flutter run -t test/shared/widgets/triage_sheet_visual_test.dart
flutter run -t test/shared/widgets/triage_level_button_visual_test.dart
flutter run -t test/shared/widgets/triage_message_visual_test.dart
flutter run -t test/shared/widgets/triage_section_visual_test.dart
```

Con la app corriendo, `r` recarga los cambios al instante.

## Crear un componente nuevo

- Archivo `triage_<nombre>_widget.dart` en esta carpeta, clase `Triage<Nombre>`.
- Exportarlo en `triage_ui.dart` (lo comprueba `triage_ui_test.dart`).
- Test `test/shared/widgets/triage_<nombre>_widget_test.dart`: distribución,
  toque, lectura en pantalla, contraste y texto al 200 % sin desbordarse.
- Añadirlo a un sandbox `*_visual_test.dart` y a la tabla de arriba.
