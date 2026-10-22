class_name Aviso
## Mensaje corto que aparece abajo en pantalla y se desvanece solo.


static func mostrar(padre: Control, texto: String) -> void:
	var aviso := Label.new()
	aviso.text = texto
	aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	aviso.mouse_filter = Control.MOUSE_FILTER_IGNORE
	aviso.add_theme_font_size_override("font_size", 32)
	aviso.add_theme_constant_override("outline_size", 8)
	aviso.add_theme_color_override("font_outline_color", Color.BLACK)
	padre.add_child(aviso)
	aviso.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	aviso.offset_top = -240
	aviso.offset_bottom = -170

	var tween := aviso.create_tween()
	tween.tween_interval(1.5)
	tween.tween_property(aviso, "modulate:a", 0.0, 0.5)
	tween.tween_callback(aviso.queue_free)
