# Dataset de imágenes de la Bioentdex

## Insectos para la cámara de realidad aumentada — `dataset/insectos/<id>/`

Cada insecto tiene su carpeta con el mismo `id` de su ficha en `especies/datos/<id>.tres`.
La cámara elige al azar **una de las imágenes de la carpeta**, así que entre más imágenes, más variedad.

- Formatos: PNG o WebP con **fondo transparente** (también sirve SVG). JPG no sirve porque no tiene transparencia.
- Tamaño recomendado: 512×512 a 1024×1024, con el insecto centrado y ocupando la mayor parte.
- Para agregar una imagen, cópiala en la carpeta del insecto y abre el proyecto en Godot para que la importe.
- La primera imagen de la carpeta (en orden alfabético) es también la que se ve en el mapa.

Las imágenes actuales (`<id>_1.svg`, `<id>_2.svg`) son ilustraciones de prueba que emulan el dataset.

## Animales NPC del mapa — `animales/npc/<id>.svg` (o `.png`)

Una imagen por animal, de lado y **mirando a la derecha** (el juego la voltea cuando camina a la izquierda).

## Fondos de la cámara — `dataset/fondos/`

`agua.svg`, `pradera.svg` y `bosque.svg` se usan cuando el teléfono no tiene cámara disponible (o en el PC).

## Nuevo insecto capturable

1. Crea su ficha en `especies/datos/` (tipo **Insecto**, con familia, orden, importancia y `suelos_habitat`).
2. Crea la carpeta `dataset/insectos/<id>/` con sus imágenes.
3. Agrégalo a la lista de especies de las zonas donde vive (`zonas/datos/*.tres`).
