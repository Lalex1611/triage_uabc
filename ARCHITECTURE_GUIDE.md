# Guía de Arquitectura - SISTEMA TRIAGE

Documento de referencia para establecer los lineamientos arquitectónicos del Sistema Triage y asegurar la escalabilidad y mantenibilidad del proyecto.

---

## 1. Clean Architecture 

La estructura del directorio `lib/` se divide en tres capas principales:

### 1.1 `lib/core/` (Elementos Compartidos)
Contiene los elementos comunes y de alcance global de la aplicación:
*   **`constants/`**: Definición de la paleta oficial (`app_colors.dart`) y rutas de recursos SVGs (`app_icons.dart`). Se debe evitar la declaración de strings de recursos (assets) directamente en los widgets.
*   **`theme/`**: Configuración global del tema y `app_text_styles.dart`. Toda la tipografía implementa la fuente *Encode Sans Condensed* (identificada con el prefijo `ESC_`).

### 1.2 `lib/features/` (Módulos)
Los módulos funcionales se organizan en función del actor o usuario final:
*   `paramedico/`
*   `medico/`
*   `consulta_externa/`

A su vez, cada una de estas carpetas de rol (o feature) está subdividida internamente en tres capas principales:
*   **`domain/`:** Contiene la lógica central y las reglas de negocio. Aquí se encuentran los modelos de datos (`entities/`) y los catálogos o valores fijos (`constants/`). Esta capa no depende de la base de datos ni de la interfaz gráfica.
*   **`data/` :** Es la capa encargada de la comunicación con el exterior. Aquí viven los repositorios (`repositories/`) que se conectan con Supabase y las funciones que convierten el JSON de la base de datos a las entidades manejables por el dominio.
*   **`presentation/` :** Contiene todo lo visual. Se divide en las pantallas o vistas principales (`_page.dart` o `_screen.dart`), los componentes reutilizables de la interfaz (`widgets/`) y los controladores de estado que manejan la interacción del usuario.

Cada módulo implementa su propia estructura interna subdividida en las capas `domain`, `data` y `presentation`.

---

## 2. Capas y Responsabilidades

*   **Dominio (`domain/`)**: Capa central de la aplicación. Contiene las reglas de negocio, modelos de datos (`entities/`) y catálogos o constantes globales (`constants/`). Los valores estáticos y listas de opciones (por ejemplo, categorías de triage) deben definirse en esta capa mediante enumeradores o clases, evitando hardcodearlos en la Ui.
*   **Datos (`data/`)**: Capa responsable de la comunicación con los servicios externos (Supabase), la implementación de los repositorios y la conversión de estructuras JSON hacia las entidades del dominio.
*   **Presentación (`presentation/`)**: Capa correspondiente a la ui. Almacena las pantallas, controladores de estado y widgets visuales.

---

## 3. Desarrollo Orientado a la Interfaz (UI-First) y Mocks

Para facilitar el desarrollo de la interfaz de manera paralela y sin depender de la disponibilidad del backend, las vistas se diseñan inicialmente utilizando datos simulados (mocks). Las páginas (`_page.dart`) se construyen recibiendo información temporal para evaluar la usabilidad y diseño. Posteriormente, tras establecer la conexión con la base de datos, estos mocks se reemplazan por la integración formal con el repositorio de datos.

---

## 4. Diseño de Interfaz y Elementos Fijos 

Para optimizar la usabilidad del sistema durante situaciones de emergencia:
*   Los botones de acción principal (por ejemplo, "Guardar" o "Iniciar") deben fijarse en la parte inferior de la pantalla, empleando estructuras como `Stack` o botones flotantes.
*   Se debe incluir un margen inferior (por ejemplo, `SizedBox(height: 120)`) al final de las listas desplazables (`scrolls`) para evitar que el contenido quede oculto detrás de los componentes fijos.

---

## 5. Sandboxes y Pruebas Visuales

Metodología establecida para el desarrollo modular de interfaces:
1. Crear el componente dentro del directorio `presentation/.../widgets/nombre_del_componente_widget.dart`.
2. Incluir documentación en la cabecera del archivo detallando el propósito del widget.
3. Desarrollar un archivo de pruebas en el directorio `test/` (por ejemplo, `nombre_del_componente_visual_test.dart`) implementando datos simulados para evaluar el comportamiento y diseño de la interfaz de manera aislada en el emulador.
4. (Opcional) Proveer el comando de terminal necesario para ejecutar dicha prueba rápida mediante un comentario en el código.
5. Integrar los componentes previamente validados dentro de la vista o página principal.

---

## 6. Convenciones de Nomenclatura

Reglas para la denominación de archivos y clases:
*   **Páginas**: El nombre del archivo debe incluir el sufijo `_page.dart`.
*   **Componentes visuales**: El nombre del archivo debe incluir el sufijo `_widget.dart` y ubicarse dentro de un subdirectorio `/widgets/`.
*   **Pruebas visuales**: El nombre del archivo debe incluir el sufijo `_visual_test.dart`.

Se requiere el uso exclusivo de `snake_case` para el nombre de los archivos y `PascalCase` para el nombre de las clases, conforme a los estándares oficiales de Dart y Flutter.

---

## 7. Flujo de Trabajo y Control de Versiones

Directrices para mantener la integridad del repositorio:
1. La rama principal de integración continua es `develop`.
2. Las nuevas ramas de desarrollo deben seguir la nomenclatura: `feature/T<numero>-descripcion` para nuevas funcionalidades, o `fix/...` para correcciones de errores.
3. Todo cambio introducido debe someterse a revisión mediante un Pull Request (PR). Es obligatorio aplicar el comando `flutter format .` sobre el código fuente antes de enviar los cambios al repositorio.

