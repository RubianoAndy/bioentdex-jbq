# Modelos 3D de las especies

Guarda aquí los modelos 3D hechos a mano, con el **id de la especie** como nombre de archivo:

```
animales/modelos/mariquita.glb
animales/modelos/libelula.glb
animales/modelos/garza_blanca.glb
```

El id es el campo `id` de la ficha en `especies/datos/<id>.tres` (sin tildes ni espacios).

## Cómo exportar desde Blender

1. El animal debe **mirar hacia -Y** en Blender (la vista frontal, tecla 1, lo muestra de frente)
   y estar **parado sobre el suelo** (los pies o las patas en Z = 0).
2. Archivo → Exportar → **glTF 2.0 (.glb/.gltf)**, formato **glTF Binary (.glb)**.
   Deja marcado "+Y Up" (viene así por defecto).
3. Si tiene animaciones, nómbralas `idle` (reposo) o `volar`; la app reproduce una en bucle.
4. Copia el `.glb` en esta carpeta y abre el proyecto en Godot para que lo importe.

El tamaño no importa: la app lo escala y centra sola. Mientras una especie no tenga modelo
aquí, la app usa uno generado con figuras simples (`especies/modelo_procedural.gd`).

Dónde aparecen: en la cámara al capturar insectos (realidad aumentada) y en las batallas.
