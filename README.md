# Bioentdex

**Bioentdex** es un juego educativo para celular, al estilo de Pokémon GO pero académico, para explorar el
**Humedal Jaboque** y los humedales de Bogotá. El jugador recorre un mapa 3D del humedal, encuentra insectos y
los "captura" con la cámara, observa la fauna nativa, resuelve misiones en cada zona y va armando su
**Bioentdex**, una base de datos de todo lo que ha descubierto.

El contenido de los insectos se basa en la **Guía macrofotográfica sobre insectos del Humedal Jaboque**
(Michelle Valentina Rodríguez Cordero, Universidad Pedagógica Nacional, Grupo de Investigación Enseñanza de la
Biología y Diversidad Cultural), que viene incluida en la app.

> Creado por Michelle Rodríguez.

---

## Funcionalidades

| | |
|---|---|
| **Mapa del humedal** | Mapa 3D de 200×200 al estilo Google Maps: espejos de agua, juncales, ronda hídrica, senderos, pasarelas de madera, el río Bogotá y la ciudad alrededor. El explorador camina tocando el mapa, arrastrándolo o con las flechas, y no atraviesa agua, árboles ni casas (rutas con A*). |
| **11 zonas** | Agua abierta, transición, neófita, terrestre, ronda hídrica, avistamiento de aves, materia orgánica, basuras excesivas, monolitos históricos, urbana y corredor ambiental. |
| **Insectos capturables** | 20 insectos, uno por familia o suborden de la guía (10 órdenes). Aparecen cerca del jugador por poco tiempo, no siempre, y en el tipo de suelo donde viven. Los ya capturados solo vuelven a aparecer en sus zonas. Se distinguen por un anillo dorado y un ícono de cámara. |
| **Fauna NPC** | Aves, ranas, mamíferos y lombrices que viven en sus zonas y se mueven según su especie (nadan, caminan, saltan). No se capturan, se observan. Algunos tienen horario (la chucha solo sale de noche). |
| **Captura con cámara** | Realidad aumentada sencilla: el insecto aparece sobre la imagen de la cámara y hay que encuadrarlo en el visor. Se apunta con el giroscopio, el dedo o el mouse. Sin cámara se usa un fondo simulado. |
| **Ficha de la especie** | Al estilo de la pantalla de detalle de Pokémon GO: hábitat, arco de riesgo de extinción (UICN), taxonomía, importancia, descripción, consejo de fotografía y botones que abren la guía en la página de su familia y de su orden. |
| **Misiones** | 37 misiones (preguntas, identificar especies, tomar fotos y escribir propuestas). 5 son **misiones especiales**, marcadas con bandera en la zona y en el mapa. |
| **Guía macrofotográfica** | La guía completa (121 páginas) dentro de la app, con zoom, índice y saltos a cada orden y familia. |
| **Recompensas** | Experiencia y niveles (sobre todo por capturar), **semillas** como moneda (por misiones y por subir de nivel) y una **tienda** con *néctar atrayente* y 4 **organismos Plus**: especies raras que no aparecen en el mapa. |
| **Personalización** | Nombre, piel, camisa, pantalón, sombrero o gorra y mochila del explorador. |
| **Bioentdex** | Todas las especies (las que faltan aparecen como silueta), con tus fotos, y el historial de misiones. |

---

## Requisitos

- **[Godot Engine 4.7](https://godotengine.org/download)**, versión *Standard* (no .NET). El proyecto usa
  solo GDScript.
- Renderizador **Mobile**, pantalla vertical de 720×1280.
- Opcional: **Visual Studio Code** con la extensión *godot-tools* para editar los scripts.
- Opcional, para regenerar el mapa o las páginas de la guía: **Python 3** con `numpy`, `Pillow` y `PyMuPDF`.

## Cómo ejecutarlo

1. Clona el repositorio:
   ```bash
   git clone https://github.com/RubianoAndy/bioentdex-jbq.git
   ```
2. Abre Godot 4.7 → **Importar** → elige `project.godot`. La primera importación tarda un poco porque
   procesa las páginas de la guía y las imágenes.
3. Presiona **F5**. La escena inicial es `MenuPrincipal.tscn`.

En el PC, el mouse funciona como un dedo: tocar para caminar, arrastrar para mover el mapa y la rueda para
hacer zoom en la guía. En la cámara de captura, mover el mouse equivale a mover el teléfono.

### Exportar a Android

Necesitas las plantillas de exportación de Godot, el Android SDK y un JDK 17 (ver la
[documentación de Godot](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html)).
En el preset de exportación **activa el permiso `Camera`**: la vista de captura lo pide la primera vez.

> La cámara real y el giroscopio solo se han probado en el PC. En Android puede ser necesario ajustar la
> orientación o el formato de la imagen en `captura/camara_dispositivo.gd`.

---

## Estructura del proyecto

```
├── MenuPrincipal.tscn        Pantalla de inicio
├── MapaExpedicion.tscn       Mapa del humedal (mundo 3D + interfaz)
├── ZonaInterior.tscn         Interior de una zona: misiones y especies
├── Bioentdex.tscn            La Bioentdex (especies y misiones del jugador)
├── GuiaMacro.tscn            Visor de la guía macrofotográfica
├── Tienda.tscn               Tienda (néctar y organismos Plus)
├── Personalizar.tscn         Personalización del explorador
├── Explorador.tscn           Personaje del jugador
├── Colibri.tscn              Colibrí NPC que vuela por todo el humedal
│
├── especies/                 Especies: especie.gd (ficha) y datos/*.tres (una por especie)
│   └── registro_especies.gd    Autoload: catálogo + base de datos del jugador
├── zonas/                    Zonas: zona.gd, mision.gd y datos/*.tres (una por zona, con sus misiones)
│   └── expedicion.gd           Autoload: zonas y estado del recorrido
├── mapa/                     Mapa 3D: máscara de colores, shader del suelo, terreno y rutas,
│   │                           vegetación, modelos low-poly y decoración de zonas
│   └── herramientas/           generar_mascara.py (genera el mapa desde cero)
├── fauna/                    Aparición de insectos y animales NPC en el mapa
├── captura/                  Vista de captura con cámara / realidad aumentada
├── ui/                       Tema visual, ficha de especie, insignia del jugador, íconos, nubes y
│                               fondos/fondo_inicio.jpg (fondo de la pantalla de inicio)
├── animales/npc/             Ilustraciones de los animales NPC y de los organismos Plus
├── dataset/
│   ├── insectos/<id>/          Imágenes de cada insecto para la cámara (ilustraciones de prueba)
│   ├── fondos/                 Fondos simulados de la cámara (agua, pradera, bosque)
│   ├── insectos reales/        143 fotografías reales organizadas por orden/familia (originales)
│   └── fotos_app/<id>/         Copias livianas que muestra la ficha (botón de cámara tras capturar)
├── guia/
│   ├── Guia.pdf                La guía original
│   └── paginas/                Las 121 páginas en imagen (lo que muestra la app)
│
├── perfil.gd                 Autoload: apariencia del explorador
└── recompensas.gd            Autoload: experiencia, niveles, semillas y tienda
```

### Autoloads

| Nombre | Archivo | Qué hace |
|---|---|---|
| `RegistroEspecies` | `especies/registro_especies.gd` | Carga las especies y guarda la base de datos del jugador (capturas, observaciones, misiones, progreso). |
| `Expedicion` | `zonas/expedicion.gd` | Carga las zonas y recuerda dónde estaba el explorador al cambiar de pantalla. |
| `Perfil` | `perfil.gd` | Nombre y apariencia del explorador. |
| `Recompensas` | `recompensas.gd` | Experiencia, niveles, semillas, tienda y avisos de recompensa. |

---

## Cómo editar el contenido

La mayoría del contenido son **recursos `.tres`** que se pueden editar desde el inspector de Godot sin tocar
código.

- **Especies** (`especies/datos/*.tres`): nombre, taxonomía, estado UICN, descripción, importancia, consejo de
  foto, página en la guía, horario, movimiento y tipos de suelo donde aparece. `plus = true` la vuelve un
  organismo Plus de la tienda, con su `precio`.
- **Imágenes de las especies** (por convención, según el `id`):
  - animales del mapa: `animales/npc/<id>.svg` (o `.png`), de lado y mirando a la derecha;
  - insectos para la cámara: todas las imágenes de `dataset/insectos/<id>/`, en PNG con fondo transparente.
    Ver [dataset/LEEME.md](dataset/LEEME.md).
- **Zonas y misiones** (`zonas/datos/*.tres`): nombre, descripción, color, posición en el mapa, especies que
  viven ahí y misiones. Una misión puede ser `PREGUNTA`, `IDENTIFICAR`, `FOTO` o `PROPUESTA`, y
  `especial = true` le pone la bandera.
- **Mapa** (`mapa/mascara_humedal.png`): es una imagen pintada con colores planos (agua, juncal, pasto,
  bosque, sendero, calle, casas…). Se puede repintar en cualquier editor de imágenes con los colores de
  [`mapa/paleta_mapa.gd`](mapa/paleta_mapa.gd); el suelo, la vegetación y las colisiones se arman solos. Si
  algo se mueve, actualiza la `posicion` de las zonas.
- **Guía**: si cambia el PDF, regenera `guia/paginas/` y ajusta las páginas en `guia_macro.gd` y en las
  especies. Ver [dataset/LEEME.md](dataset/LEEME.md).
- **Recompensas**: las cantidades de experiencia, semillas y precios están al inicio de
  [`recompensas.gd`](recompensas.gd).

## Datos del jugador

Todo se guarda en el dispositivo, en la carpeta de usuario de Godot (`user://`; en Windows,
`%APPDATA%\Godot\app_userdata\Bioentdex Jbq\`):

- `bioentdex.json`: capturas, observaciones, respuestas de misiones y progreso (experiencia, semillas, Plus).
  Cada registro es un diccionario simple, listo para enviarlo a un servidor más adelante.
- `fotos/`: fotos de las capturas y de las misiones de foto.
- `perfil.cfg`: apariencia del explorador.

---

## Pendientes

- Probar en un celular Android real (cámara, giroscopio, rendimiento).
- Validar con una persona experta los textos de especies y misiones, y la identificación de las fotos de
  `dataset/insectos reales/`.
- Recortar con fondo transparente las fotos reales para usarlas también en la cámara de realidad aumentada.
- Definir el contenido final de las 5 misiones especiales.
- Conectar la base de datos a un servidor si se quiere compartir el progreso (por ejemplo, para docentes).

### Archivos antiguos sin uso

`contenedor_mapa.gd` y `lienzo_mapa.gd` son de las primeras versiones del mapa y ya no los usa ninguna escena;
se pueden borrar.

## Créditos

- **Guía macrofotográfica sobre insectos del Humedal Jaboque**: Michelle Valentina Rodríguez Cordero
  (fotografías, edición y diseño, con Kimberly Alape). Universidad Pedagógica Nacional, Grupo de
  Investigación Enseñanza de la Biología y Diversidad Cultural.
- Hecho con [Godot Engine](https://godotengine.org).
