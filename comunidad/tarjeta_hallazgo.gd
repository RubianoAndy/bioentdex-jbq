extends Control
## Tarjeta local de exploración: no muestra ni exporta el nombre ni otros datos del perfil.

const CARPETA_TARJETAS := "user://tarjetas/"
const VERDE := Color(0.06, 0.16, 0.12)
const DORADO := Color(1.0, 0.82, 0.32)

var _foto: TextureRect
var _selector: OptionButton
var _acciones: Control
var _estado: Label
var _rutas_fotos: Array[String] = []


func _ready() -> void:
	_construir_interfaz()
	_cargar_fotos()
	_actualizar_tarjeta()


func _construir_interfaz() -> void:
	var fondo := ColorRect.new()
	fondo.color = Color(0.025, 0.09, 0.07)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)

	var margen := MarginContainer.new()
	margen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margen.add_theme_constant_override("margin_left", 24)
	margen.add_theme_constant_override("margin_top", 22)
	margen.add_theme_constant_override("margin_right", 24)
	margen.add_theme_constant_override("margin_bottom", 22)
	add_child(margen)

	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 14)
	margen.add_child(columna)

	var titulo := _etiqueta("Tarjeta de exploración", 34, DORADO)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	columna.add_child(titulo)

	var tarjeta := PanelContainer.new()
	tarjeta.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = VERDE
	estilo.border_color = DORADO
	estilo.set_border_width_all(4)
	estilo.set_corner_radius_all(28)
	estilo.content_margin_left = 22
	estilo.content_margin_top = 18
	estilo.content_margin_right = 22
	estilo.content_margin_bottom = 18
	tarjeta.add_theme_stylebox_override("panel", estilo)
	columna.add_child(tarjeta)

	var contenido := VBoxContainer.new()
	contenido.alignment = BoxContainer.ALIGNMENT_CENTER
	contenido.add_theme_constant_override("separation", 12)
	tarjeta.add_child(contenido)

	var insignia := PanelContainer.new()
	insignia.custom_minimum_size = Vector2(118, 118)
	insignia.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var estilo_insignia := StyleBoxFlat.new()
	estilo_insignia.bg_color = DORADO
	estilo_insignia.border_color = Color.WHITE
	estilo_insignia.set_border_width_all(5)
	estilo_insignia.set_corner_radius_all(59)
	insignia.add_theme_stylebox_override("panel", estilo_insignia)
	var nivel := _etiqueta(str(Recompensas.nivel()), 56, Color(0.25, 0.17, 0.02))
	nivel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nivel.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	insignia.add_child(nivel)
	contenido.add_child(insignia)

	var subtitulo := _etiqueta("Insignia de nivel", 21, Color.WHITE)
	subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	contenido.add_child(subtitulo)

	var progreso := _etiqueta(
		"%d especies conocidas de %d" % [RegistroEspecies.cantidad_descubiertas(), RegistroEspecies.especies.size()],
		24, Color(0.78, 0.94, 0.79))
	progreso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progreso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	contenido.add_child(progreso)

	_foto = TextureRect.new()
	_foto.custom_minimum_size = Vector2(0, 300)
	_foto.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_foto.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_foto.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	contenido.add_child(_foto)

	var aviso := _etiqueta(Privacidad.advertencia_tarjeta(), 17, Color(1.0, 0.88, 0.66))
	aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	contenido.add_child(aviso)

	_acciones = VBoxContainer.new()
	_acciones.add_theme_constant_override("separation", 8)
	columna.add_child(_acciones)

	_selector = OptionButton.new()
	_selector.custom_minimum_size.y = 56
	_selector.add_item("Elige una foto guardada en tu Bioentdex")
	_selector.item_selected.connect(_seleccionar_foto)
	_acciones.add_child(_selector)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	_acciones.add_child(fila)

	var exportar := Button.new()
	exportar.text = "Guardar tarjeta PNG"
	exportar.custom_minimum_size.y = 60
	exportar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	exportar.pressed.connect(_exportar_tarjeta)
	fila.add_child(exportar)

	var volver := Button.new()
	volver.text = "Volver"
	volver.custom_minimum_size.y = 60
	volver.pressed.connect(func() -> void: get_tree().change_scene_to_file(Perfil.volver_a))
	fila.add_child(volver)

	_estado = _etiqueta("", 16, Color.WHITE)
	_estado.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_acciones.add_child(_estado)


func _cargar_fotos() -> void:
	_selector.clear()
	_rutas_fotos.clear()
	for especie in RegistroEspecies.especies:
		var capturas := RegistroEspecies.capturas_de(especie.id)
		for captura in capturas:
			var ruta := str(captura.get("foto", ""))
			if ruta.is_empty() or not FileAccess.file_exists(ruta):
				continue
			_rutas_fotos.append(ruta)
			_selector.add_item("Foto guardada · %s" % especie.nombre_comun)
			_selector.set_item_metadata(_selector.get_item_count() - 1, ruta)
	if _rutas_fotos.is_empty():
		_selector.add_item("Aún no hay fotos de exploración guardadas")
		_selector.disabled = true
	else:
		_selector.disabled = false
		_selector.select(_selector.get_item_count() - 1)


func _seleccionar_foto(indice: int) -> void:
	if indice < 0 or indice >= _selector.get_item_count():
		return
	var ruta := str(_selector.get_item_metadata(indice))
	var imagen := Image.load_from_file(ruta)
	_foto.texture = ImageTexture.create_from_image(imagen) if imagen and not imagen.is_empty() else null


func _actualizar_tarjeta() -> void:
	if not _rutas_fotos.is_empty():
		_seleccionar_foto(_selector.get_selected())


func _exportar_tarjeta() -> void:
	if _foto.texture == null:
		_estado.text = "Elige una foto guardada antes de exportar."
		return
	_acciones.hide()
	Recompensas.ocultar_avisos(true)   # que los avisos de arriba no queden en la imagen
	await RenderingServer.frame_post_draw   # esperar a que el cuadro ya se dibuje sin los botones
	var imagen := get_viewport().get_texture().get_image()
	_acciones.show()
	Recompensas.ocultar_avisos(false)
	if imagen == null or imagen.is_empty():
		_estado.text = "No se pudo capturar la tarjeta."
		return
	var error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CARPETA_TARJETAS))
	if error != OK and error != ERR_ALREADY_EXISTS:
		_estado.text = "No se pudo crear la carpeta local de tarjetas (%s)." % error_string(error)
		return
	var ruta := _siguiente_ruta()
	error = imagen.save_png(ruta)
	if error != OK:
		_estado.text = "No se pudo guardar la tarjeta (%s)." % error_string(error)
		return
	_estado.text = "Tarjeta guardada localmente: %s" % ruta.get_file()


func _siguiente_ruta() -> String:
	var indice := 1
	while FileAccess.file_exists(CARPETA_TARJETAS + "tarjeta_explorador_%03d.png" % indice):
		indice += 1
	return CARPETA_TARJETAS + "tarjeta_explorador_%03d.png" % indice


func _etiqueta(texto: String, tamano: int, color: Color) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.add_theme_font_size_override("font_size", tamano)
	etiqueta.add_theme_color_override("font_color", color)
	return etiqueta
