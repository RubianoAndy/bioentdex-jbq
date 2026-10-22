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

## Insectos capturables y la guía

Los 20 insectos capturables salen de la *Guía macrofotográfica sobre insectos del Humedal Jaboque*
(`guia/Guia.pdf`): uno por cada familia o suborden registrado en el humedal (10 órdenes). Cada ficha guarda
en `pagina_guia` la página de su familia, y la ficha del juego tiene botones que abren la guía ahí.

## Nuevo insecto capturable

1. Crea su ficha en `especies/datos/` (tipo **Insecto**, con familia, orden, importancia, `suelos_habitat`
   y `pagina_guia`).
2. Crea la carpeta `dataset/insectos/<id>/` con sus imágenes.
3. Agrégalo a la lista de especies de las zonas donde vive (`zonas/datos/*.tres`).

## Si cambia la guía

Las páginas que muestra la app están en `guia/paginas/` (una imagen por página). Para regenerarlas desde un
PDF nuevo (necesita Python con PyMuPDF):

```
python -c "import pymupdf; d=pymupdf.open('guia/Guia.pdf'); [p.get_pixmap(matrix=pymupdf.Matrix(1100/595,1100/595)).save(f'guia/paginas/pagina_{i+1:03d}.jpg', jpg_quality=78) for i,p in enumerate(d)]"
```

Si cambia el número de páginas o la ubicación de las familias, actualiza `TOTAL_PAGINAS`, `PAGINAS_ORDEN` e
`INDICE` en `guia_macro.gd`, y `pagina_guia` en las fichas de los insectos.
