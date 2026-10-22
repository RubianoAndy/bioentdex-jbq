class_name FichaEspecie
extends Control
## Ficha de una especie: foto, taxonomía (familia, orden, especie), importancia y una descripción corta.
## Se usa al capturar un insecto, al tocar un animal NPC en el mapa y desde la Bioentdex.

signal cerrada

var _especie: Especie
var _titulo := ""
var _foto: Texture2D


static func mostrar(padre: Node, especie: Especie, titulo := "", foto: Texture2D = null) -> FichaEspecie:
	var ficha := FichaEspecie.new()
	ficha._especie = especie
	ficha._titulo = titulo
	ficha._foto = foto
	padre.add_child(ficha)
	return ficha


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var fondo := ColorRect.new()
	fondo.color = Color(0, 0, 0, 0.6)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)

	var panel := PanelContainer.new()
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 28
	panel.offset_right = -28
	panel.offset_top = 70
	panel.offset_bottom = -50

	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 10)
	panel.add_child(columna)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	columna.add_child(scroll)
	var contenido := VBoxContainer.new()
	contenido.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contenido.add_theme_constant_override("separation", 10)
	scroll.add_child(contenido)

	if not _titulo.is_empty():
		contenido.add_child(_etiqueta(_titulo, 30, Color(1, 0.84, 0.3), true))

	var imagen := TextureRect.new()
	imagen.texture = _foto if _foto else _especie.obtener_imagen()
	imagen.custom_minimum_size = Vector2(0, 340)
	imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	contenido.add_child(imagen)

	contenido.add_child(_etiqueta(_especie.nombre_comun, 38, Color.WHITE, true))
	contenido.add_child(_etiqueta(_especie.nombre_cientifico, 24, Color(0.75, 0.88, 0.78), true))

	# Taxonomía en dos columnas
	var datos := GridContainer.new()
	datos.columns = 2
	datos.add_theme_constant_override("h_separation", 16)
	datos.add_theme_constant_override("v_separation", 6)
	for par in [["Tipo", _especie.nombre_tipo()], ["Orden", _especie.orden], ["Familia", _especie.familia],
			["Especie", _especie.nombre_cientifico], ["Estado UICN", _especie.nombre_estado()]]:
		var clave := _etiqueta(par[0], 22, Color(0.7, 0.8, 0.74))
		clave.autowrap_mode = TextServer.AUTOWRAP_OFF
		datos.add_child(clave)
		var valor := _etiqueta(par[1], 22, Color.WHITE)
		valor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		datos.add_child(valor)
	contenido.add_child(datos)

	contenido.add_child(_seccion("¿Por qué es importante?", _especie.importancia))
	contenido.add_child(_seccion("Descripción", _especie.descripcion))

	var estado := _texto_estado()
	if not estado.is_empty():
		contenido.add_child(_etiqueta(estado, 20, Color(1, 0.84, 0.3), true))

	var cerrar := Button.new()
	cerrar.text = "Cerrar"
	cerrar.custom_minimum_size = Vector2(0, 64)
	cerrar.pressed.connect(_cerrar)
	columna.add_child(cerrar)

	# Entrada con un pequeño "pop"
	modulate.a = 0.0
	panel.pivot_offset = get_viewport_rect().size / 2.0
	panel.scale = Vector2(0.92, 0.92)
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "modulate:a", 1.0, 0.18)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _texto_estado() -> String:
	var capturas := RegistroEspecies.capturas_de(_especie.id)
	if not capturas.is_empty():
		return "Capturado %d %s · primera vez: %s" % [capturas.size(), "vez" if capturas.size() == 1 else "veces",
			capturas[0].fecha.substr(0, 10)]
	if RegistroEspecies.esta_observada(_especie.id):
		return "Observado" if not _especie.es_capturable() else "Visto, aún sin capturar"
	return ""


func _seccion(titulo: String, texto: String) -> Control:
	var caja := VBoxContainer.new()
	caja.add_child(_etiqueta(titulo, 24, Color(1, 0.84, 0.3)))
	caja.add_child(_etiqueta(texto, 22, Color.WHITE))
	return caja


func _etiqueta(texto: String, tamano: int, color: Color, centrado := false) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etiqueta.add_theme_font_size_override("font_size", tamano)
	etiqueta.add_theme_color_override("font_color", color)
	if centrado:
		etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return etiqueta


func _cerrar() -> void:
	cerrada.emit()
	queue_free()
