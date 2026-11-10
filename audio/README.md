# Audio

Coloca los archivos de audio en las rutas indicadas en `audio_manager.gd` o cambia
una ruta con `AudioManager.configurar_ruta("clave", "res://audio/carpeta/archivo.ogg")`.
Se aceptan recursos `AudioStream` compatibles con Godot; configura en el importador los
archivos de ambiente para que se repitan. No se incluyen clips de audio en el proyecto.

Claves incluidas:

| Clave | Uso | Ruta inicial |
|---|---|---|
| `musica_principal` | Musica de fondo | `musica/principal.ogg` |
| `humedal_aves` | Cantos de aves | `ambiente/aves.ogg` |
| `humedal_insectos` | Insectos | `ambiente/insectos.ogg` |
| `humedal_viento` | Viento | `ambiente/viento.ogg` |
| `humedal_agua` | Agua | `ambiente/agua.ogg` |
| `ui_click` | Botones de interfaz | `sfx/ui/click.ogg` |
| `camara_obturador` | Captura de foto | `sfx/camara/obturador.ogg` |
| `especie_registrada` | Primera especie descubierta | `sfx/logros/especie_registrada.ogg` |
| `logro_desbloqueado` | Subir de nivel | `sfx/logros/desbloqueado.ogg` |
| `aviso_colibri` | Interaccion con el colibri | `sfx/colibri/aviso.ogg` |

El mapa y el interior de zona inician las cuatro capas ambientales y las detienen al salir.
Para reproducir otra pista: `AudioManager.reproducir_musica("musica_principal")`.
El volumen lineal va de `0.0` a `1.0`; los canales aceptan `Master`, `BGM`/`Musica`,
`AMB`/`Ambiente` y `SFX`:

```gdscript
AudioManager.set_volumen_canal("BGM", 0.6)
AudioManager.silenciar_canal("AMB", true)
```

Si falta un archivo, el gestor emite una advertencia una sola vez por clave y no inicia
un reproductor vacio.
