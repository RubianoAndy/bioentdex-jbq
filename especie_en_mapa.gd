extends TextureRect
## Especie visible en el mapa: al tocarla se registra en la Bioentdex.

@export var especie: Especie


func _gui_input(event: InputEvent) -> void:
	# En el celular el toque también llega como clic (emulación de mouse activada por defecto)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if especie and RegistroEspecies.descubrir(especie.id):
			_mostrar_aviso()


func _mostrar_aviso() -> void:
	var aviso := Label.new()
	aviso.text = "¡Nueva especie: %s!" % especie.nombre_comun
	aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aviso.add_theme_font_size_override("font_size", 32)
	aviso.add_theme_constant_override("outline_size", 8)
	aviso.add_theme_color_override("font_outline_color", Color.BLACK)
	owner.add_child(aviso)
	aviso.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	aviso.offset_top = -200
	aviso.offset_bottom = -140

	var tween := aviso.create_tween()
	tween.tween_interval(1.5)
	tween.tween_property(aviso, "modulate:a", 0.0, 0.5)
	tween.tween_callback(aviso.queue_free)
