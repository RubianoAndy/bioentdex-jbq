extends Control
## Tienda del humedal: se paga con las semillas que dan las misiones.
##   - Néctar atrayente: por unos minutos aparecen más insectos cerca del explorador.
##   - Organismos Plus: especies raras y emblemáticas que no aparecen en el mapa.

const DORADO := Color(1, 0.84, 0.3)

var _lista: VBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var fondo := ColorRect.new()
	fondo.color = Color(0.09, 0.17, 0.13)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)

	var margen := MarginContainer.new()
	margen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "top", "right", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 22)
	add_child(margen)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 16)
	margen.add_child(columna)

	var encabezado := HBoxContainer.new()
	encabezado.add_theme_constant_override("separation", 16)
	var volver := Button.new()
	volver.text = "← Volver"
	volver.custom_minimum_size = Vector2(140, 56)
	volver.pressed.connect(func() -> void: get_tree().change_scene_to_file(Perfil.volver_a))
	encabezado.add_child(volver)
	var titulo := Label.new()
	titulo.text = "Tienda del humedal"
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 32)
	encabezado.add_child(titulo)
	columna.add_child(encabezado)

	var insignia := InsigniaJugador.new()
	insignia.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	columna.add_child(insignia)
	var ayuda := Label.new()
	ayuda.text = "Gana semillas cumpliendo misiones (las especiales dan más) y subiendo de nivel al capturar insectos."
	ayuda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ayuda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ayuda.add_theme_font_size_override("font_size", 20)
	ayuda.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	columna.add_child(ayuda)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	columna.add_child(scroll)
	_lista = VBoxContainer.new()
	_lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lista.add_theme_constant_override("separation", 14)
	scroll.add_child(_lista)

	Recompensas.cambio.connect(_construir)
	_construir()


func _construir() -> void:
	for hijo in _lista.get_children():
		hijo.queue_free()

	_lista.add_child(_titulo("Objetos"))
	_lista.add_child(_articulo(load("res://ui/nectar.svg"), "Néctar atrayente",
		"Durante 3 minutos aparecen más insectos cerca de ti.", Recompensas.PRECIO_NECTAR, false,
		func() -> void: Recompensas.comprar_nectar()))

	_lista.add_child(_titulo("Organismos Plus"))
	for especie in RegistroEspecies.especies:
		if not especie.plus:
			continue
		var obtenido := Recompensas.tiene_plus(especie.id)
		_lista.add_child(_articulo(especie.obtener_imagen(), especie.nombre_comun, especie.descripcion,
			especie.precio, obtenido, _comprar_plus.bind(especie), especie))


func _comprar_plus(especie: Especie) -> void:
	if Recompensas.comprar_plus(especie):
		var ficha := FichaEspecie.new()
		ficha.mostrar(self, especie, "¡Organismo Plus obtenido!")


func _articulo(icono: Texture2D, nombre: String, descripcion: String, precio: int, obtenido: bool,
		al_comprar: Callable, especie: Especie = null) -> Control:
	var tarjeta := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.97, 0.97, 0.95)
	estilo.set_corner_radius_all(22)
	estilo.set_content_margin_all(14)
	estilo.shadow_color = Color(0, 0, 0, 0.25)
	estilo.shadow_size = 6
	if especie:
		estilo.border_color = DORADO
		estilo.set_border_width_all(3)
	tarjeta.add_theme_stylebox_override("panel", estilo)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 14)
	tarjeta.add_child(fila)
	var imagen := TextureRect.new()
	imagen.texture = icono
	imagen.custom_minimum_size = Vector2(120, 120)
	imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	fila.add_child(imagen)

	var textos := VBoxContainer.new()
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.alignment = BoxContainer.ALIGNMENT_CENTER
	var titulo := Label.new()
	titulo.text = nombre
	titulo.add_theme_font_size_override("font_size", 26)
	titulo.add_theme_color_override("font_color", Color(0.17, 0.24, 0.21))
	textos.add_child(titulo)
	var detalle := Label.new()
	detalle.text = descripcion
	detalle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detalle.add_theme_font_size_override("font_size", 18)
	detalle.add_theme_color_override("font_color", Color(0.4, 0.47, 0.44))
	textos.add_child(detalle)
	fila.add_child(textos)

	var comprar := Button.new()
	comprar.custom_minimum_size = Vector2(130, 64)
	comprar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if obtenido:
		comprar.text = "Ver"
		comprar.pressed.connect(func() -> void:
			var ficha := FichaEspecie.new()
			ficha.mostrar(self, especie))
	else:
		comprar.text = str(precio)
		comprar.icon = load("res://ui/semilla.svg")
		comprar.expand_icon = true
		comprar.add_theme_constant_override("icon_max_width", 34)
		comprar.disabled = Recompensas.semillas() < precio
		comprar.pressed.connect(al_comprar)
	fila.add_child(comprar)
	return tarjeta


func _titulo(texto: String) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.add_theme_font_size_override("font_size", 26)
	etiqueta.add_theme_color_override("font_color", DORADO)
	return etiqueta
