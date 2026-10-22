# Dataset de insectos reales (fotografías)

143 fotografías organizadas por **Orden / Familia**, con los nombres de la *Guía macrofotográfica sobre
insectos del Humedal Jaboque*. **Todavía no se usan en la app.** La carpeta tiene un archivo `.gdignore` para
que Godot no importe estas fotos (algunas pesan 3 MB) mientras no se integren.

`indice.csv` (se abre con Excel) tiene una fila por foto: el archivo actual, el **nombre original** (de WhatsApp,
de la cámara o de `bichines guia.zip`), el orden, la familia, si la familia está en la guía, el insecto del juego al que corresponde, el
estadio (adulto, larva, pupa, huevo, ninfa), la **confianza de la identificación** y una nota.

> La identificación es preliminar, hecha mirando las fotos (salvo las que el equipo ya traía nombradas, como
> `miridae` y `psocidae`). Debe validarla una persona experta, sobre todo las de confianza **media** o **baja**.
> Para corregir una foto, muévela a la carpeta correcta y actualiza su fila en `indice.csv`.

## Estructura

| Carpeta | Fotos | En la guía | Insecto del juego |
|---|---|---|---|
| Blattodea/Termitidae | 1 | no (orden fuera de la guía) | – |
| Blattodea/_familia_por_confirmar | 1 | no (orden fuera de la guía) | – |
| Coleoptera/Chrysomelidae | 2 | sí | crisomelido |
| Coleoptera/Coccinellidae | 4 | sí | mariquita |
| Coleoptera/Curculionidae | 7 | no | – |
| Coleoptera/_familia_por_confirmar | 3 | – | – |
| Dermaptera/Forficulidae | 4 | sí | tijereta |
| Diptera/Calliphoridae | 1 | sí | mosca_metalica |
| Diptera/Culicidae | 1 | sí | zancudo |
| Diptera/Syrphidae | 6 | sí | sirfido |
| Diptera/Tachinidae | 6 | sí | taquinido |
| Diptera/Tipulidae | 2 | sí | tipula |
| Diptera/_familia_por_confirmar | 6 | – | – |
| Hemiptera/Cicadellidae | 3 | no | – |
| Hemiptera/Miridae | 3 | sí | chinche_planta |
| Hemiptera/_familia_por_confirmar | 9 | – | – |
| Hymenoptera/Apidae | 6 | sí | abejorro |
| Hymenoptera/Formicidae | 10 | sí | hormiga |
| Hymenoptera/Ichneumonidae | 3 | no | – |
| Hymenoptera/Vespidae | 4 | sí | avispa |
| Hymenoptera/_familia_por_confirmar | 1 | – | – |
| Lepidoptera/Nymphalidae | 9 | sí | ninfalida (8), mariposa_monarca (1) |
| Lepidoptera/Pieridae | 2 | sí | mariposa_blanca |
| Lepidoptera/_familia_por_confirmar | 8 | – | – |
| Neuroptera/Chrysopidae | 3 | sí | crisopa |
| Odonata/Anisoptera | 3 | sí | libelula |
| Odonata/Zygoptera | 2 | sí | caballito_del_diablo |
| Orthoptera/_familia_por_confirmar | 12 | no (orden fuera de la guía) | – |
| Psocodea/Psocidae | 6 | sí | psocido |
| Zygentoma/Lepismatidae | 1 | sí | pececillo_plata |
| _por_revisar | 14 | – | fotos que no se pudieron identificar |

Se borraron 3 fotos que eran **copias exactas** de otras (mismo archivo byte a byte). Del zip `bichines guia.zip`
no se agregaron 4 imágenes que eran la misma foto que ya estaba (mismo contenido y resolución); el zip se borró
después de organizar todo su contenido.

**Recortes listos para la cámara** (fondo transparente): `Lepidoptera/_familia_por_confirmar/lepidoptera_05.png`, `Lepidoptera/_familia_por_confirmar/lepidoptera_06.png`.

## Familias del juego que aún no tienen foto real

- Geometridae (polilla_geometra): quizá alguna de `Lepidoptera/_familia_por_confirmar/`

Las otras 19 familias y subórdenes del juego ya tienen al menos una foto.

## Para usarlas en la cámara de la app

La cámara de realidad aumentada pone el insecto encima de la imagen de la cámara, así que necesita imágenes
**recortadas con fondo transparente** (PNG). Estas fotos tienen fondo, así que habría que recortarlas, o
usarlas de otra forma, por ejemplo como foto real en la ficha.
