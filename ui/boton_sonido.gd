class_name BotonSonido
extends Button
## Botón redondo para quitar o devolver el sonido de toda la app (AudioManager.alternar_silencio).
## Dibuja su propio ícono: un parlante con ondas, o tachado cuando está en silencio.

const TAMANO := 56.0

var lado := TAMANO   # se puede achicar antes de agregarlo (por ejemplo en la barra del mapa)


func _ready() -> void:
	custom_minimum_size = Vector2(lado, lado)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	focus_mode = Control.FOCUS_NONE
	pressed.connect(AudioManager.alternar_silencio)
	AudioManager.silencio_cambiado.connect(_actualizar)
	_actualizar(AudioManager.silenciado)


func _actualizar(silenciado: bool) -> void:
	tooltip_text = "Activar el sonido" if silenciado else "Quitar el sonido"
	queue_redraw()


func _draw() -> void:
	var c := size / 2.0
	var color := Color(1, 1, 1, 0.95)
	var u := minf(size.x, size.y) / TAMANO   # escala del dibujo
	# Parlante
	draw_rect(Rect2(c + Vector2(-14, -6) * u, Vector2(7, 12) * u), color)
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-7, -6) * u, c + Vector2(2, -14) * u, c + Vector2(2, 14) * u, c + Vector2(-7, 6) * u]), color)
	if AudioManager.silenciado:
		var rojo := Color(1, 0.45, 0.4)
		draw_line(c + Vector2(7, -7) * u, c + Vector2(17, 7) * u, rojo, 4 * u, true)
		draw_line(c + Vector2(17, -7) * u, c + Vector2(7, 7) * u, rojo, 4 * u, true)
	else:
		for radio in [9.0, 15.0]:
			draw_arc(c + Vector2(2, 0) * u, radio * u, -0.8, 0.8, 12, color, 3 * u, true)
