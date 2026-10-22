# Dataset de insectos reales (fotografías)

74 fotografías organizadas por **Orden / Familia**, con los nombres de la *Guía macrofotográfica sobre insectos
del Humedal Jaboque*. **Todavía no se usan en la app.**

`indice.csv` (se abre con Excel) tiene una fila por foto: el archivo actual, el **nombre original de WhatsApp**,
el orden, la familia, si la familia está en la guía, el insecto del juego al que corresponde, el estadio
(adulto, larva, pupa, huevo, ninfa), la **confianza de la identificación** y una nota.

> La identificación es preliminar, hecha mirando las fotos. Debe validarla una persona experta, sobre todo las
> de confianza **media** o **baja**. Para corregir una foto, muévela a la carpeta correcta y actualiza su fila
> en `indice.csv`.

## Estructura

| Carpeta | Fotos | En la guía | Insecto del juego |
|---|---|---|---|
| Diptera/Tachinidae | 5 | sí | taquinido |
| Diptera/Syrphidae | 4 | sí | sirfido |
| Diptera/Calliphoridae | 1 | sí | mosca_metalica |
| Diptera/Tipulidae | 1 | sí | tipula |
| Diptera/_familia_por_confirmar | 4 | – | – |
| Hemiptera/Cicadellidae | 1 | no | – |
| Hemiptera/_familia_por_confirmar | 3 | – | – |
| Psocodea/Psocidae | 1 | sí | psocido (dudosa) |
| Odonata/Anisoptera | 2 | sí | libelula |
| Odonata/Zygoptera | 1 | sí | caballito_del_diablo |
| Hymenoptera/Formicidae | 6 | sí | hormiga |
| Hymenoptera/Apidae | 4 | sí | abejorro (son abejas melíferas) |
| Hymenoptera/Vespidae | 1 | sí | avispa |
| Hymenoptera/Ichneumonidae | 2 | no | – |
| Hymenoptera/_familia_por_confirmar | 1 | – | – |
| Lepidoptera/Nymphalidae | 8 | sí | ninfalida (y 1 mariposa_monarca) |
| Lepidoptera/Pieridae | 1 | sí | mariposa_blanca (es una *Phoebis* amarilla) |
| Lepidoptera/_familia_por_confirmar | 2 | – | – |
| Coleoptera/Coccinellidae | 1 | sí | mariquita (larva) |
| Coleoptera/Curculionidae | 6 | no | – |
| Coleoptera/_familia_por_confirmar | 2 | – | – |
| Dermaptera/Forficulidae | 1 | sí | tijereta |
| Neuroptera/Chrysopidae | 1 | sí | crisopa |
| Zygentoma/Lepismatidae | 1 | sí | pececillo_plata |
| Orthoptera/_familia_por_confirmar | 2 | no (orden fuera de la guía) | – |
| Blattodea/Termitidae | 1 | no (orden fuera de la guía) | – |
| _por_revisar | 10 | – | fotos que no se pudieron identificar |
| _duplicados | 1 | – | copia exacta de otra foto (no se borró) |

## Familias del juego que aún no tienen foto real

- Culicidae (zancudo)
- Miridae (chinche_planta): quizá `Hemiptera/_familia_por_confirmar/hemiptera_02.jpeg`
- Geometridae (polilla_geometra): quizá `Lepidoptera/_familia_por_confirmar/lepidoptera_01.jpeg`
- Chrysomelidae (crisomelido)
- Coccinellidae solo tiene una larva; falta un adulto.

## Para usarlas en la cámara de la app

La cámara de realidad aumentada pone el insecto encima de la imagen de la cámara, así que necesita imágenes
**recortadas con fondo transparente** (PNG). Estas fotos tienen fondo, así que habría que recortarlas, o
usarlas de otra forma, por ejemplo como foto real en la ficha.
