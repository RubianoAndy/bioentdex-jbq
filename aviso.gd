class_name Aviso
## Mensaje corto que aparece abajo en pantalla y se desvanece solo.


static func mostrar(padre: Control, texto: String) -> void:
	var cartel := PanelContainer.new()
	cartel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.05, 0.12, 0.09, 0.88)
	estilo.border_color = Color(1, 0.84, 0.3, 0.6)
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(20)
	estilo.set_content_margin_all(16)
	cartel.add_theme_stylebox_override("panel", estilo)

	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etiqueta.add_theme_font_size_override("font_size", 26)
	cartel.add_child(etiqueta)

	padre.add_child(cartel)
	cartel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	cartel.offset_left = 32
	cartel.offset_right = -32
	cartel.offset_top = -400
	cartel.offset_bottom = -300
	cartel.grow_vertical = Control.GROW_DIRECTION_BEGIN

	var tween := cartel.create_tween()
	tween.tween_interval(2.5)
	tween.tween_property(cartel, "modulate:a", 0.0, 0.5)
	tween.tween_callback(cartel.queue_free)
