extends Control
## Interior de una zona: sus misiones (preguntas, identificar especies, tomar fotos) y sus especies.
## Las respuestas y las fotos se guardan en la base de datos de la Bioentdex.

const CAPTURA := preload("res://captura/CapturaAR.tscn")
const VALIDADOR_MISION := preload("res://zonas/validador_mision.gd")
const NOMBRES_TIPO := ["Pregunta", "¿Quién es?", "Foto", "Propuesta"]
const DORADO := Color(1, 0.84, 0.3)
## Fondo simulado de la cámara para las misiones de foto de cada zona
const FONDOS := {
	"agua_abierta": "agua", "transicion": "agua", "avistamiento_aves": "agua",
	"ronda_hidrica": "bosque", "materia_organica": "bosque", "corredor_ambiental": "bosque",
}

var zona: Zona

@onready var contenido: VBoxContainer = $Margen/VBox/Scroll/Contenido


func _ready() -> void:
	AudioManager.reproducir_paisaje_humedal()
	# Si se abre la escena sola desde el editor (F6), se usa la primera zona
	zona = Expedicion.zona_actual if Expedicion.zona_actual else Expedicion.zonas[0]
	$Fondo.color = zona.color.darkened(0.7)
	$Margen/VBox/Encabezado/Titulo.text = zona.nombre
	$Margen/VBox/Descripcion.text = zona.descripcion
	$Margen/VBox/CompaneroColibri.establecer_contexto(zona.id)
	$Margen/VBox/Encabezado/BtnVolver.pressed.connect(Expedicion.volver_al_mapa)
	RegistroEspecies.especie_descubierta.connect(_on_especie_descubierta)
	_construir()
	AudioManager.conectar_botones(self)


func _exit_tree() -> void:
	AudioManager.detener_paisaje_humedal()


func _construir() -> void:
	for hijo in contenido.get_children():
		hijo.queue_free()

	var resueltas := zona.misiones.filter(func(m: Mision) -> bool: return RegistroEspecies.mision_resuelta(m.id)).size()
	# Primero las misiones especiales (con bandera), luego las demás
	var especiales := zona.misiones.filter(func(m: Mision) -> bool: return m.especial)
	if not especiales.is_empty():
		contenido.add_child(_titulo_seccion("Misión especial"))
		for mision in especiales:
			contenido.add_child(_tarjeta_mision(mision))
	contenido.add_child(_titulo_seccion("Misiones (%d/%d)" % [resueltas, zona.misiones.size()]))
	for mision in zona.misiones:
		if not mision.especial:
			contenido.add_child(_tarjeta_mision(mision))

	contenido.add_child(_titulo_seccion("Especies de esta zona"))
	var grilla := GridContainer.new()
	grilla.columns = 3
	grilla.add_theme_constant_override("h_separation", 12)
	grilla.add_theme_constant_override("v_separation", 12)
	for especie in zona.especies:
		grilla.add_child(_tarjeta_especie(especie))
	contenido.add_child(grilla)


func _tarjeta_mision(mision: Mision) -> Button:
	var resuelta := RegistroEspecies.mision_resuelta(mision.id)
	var tarjeta := Button.new()
	tarjeta.custom_minimum_size = Vector2(0, 100)
	tarjeta.alignment = HORIZONTAL_ALIGNMENT_LEFT
	tarjeta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tarjeta.add_theme_font_size_override("font_size", 22)
	tarjeta.text = "%s · %s\n%s" % [NOMBRES_TIPO[mision.tipo], "Resuelta" if resuelta else "Pendiente", mision.enunciado]
	if resuelta:
		tarjeta.modulate = Color(0.7, 1.0, 0.75)
	if mision.especial:
		_resaltar(tarjeta)
	tarjeta.pressed.connect(_abrir_mision.bind(mision))
	return tarjeta


## Misión especial: bandera y borde dorado.
static func _resaltar(tarjeta: Button) -> void:
	if ResourceLoader.exists("res://ui/bandera.svg"):
		tarjeta.icon = load("res://ui/bandera.svg")
		tarjeta.expand_icon = true
		tarjeta.add_theme_constant_override("icon_max_width", 56)
	for estado in ["normal", "hover", "pressed"]:
		var estilo: StyleBoxFlat = tarjeta.get_theme_stylebox(estado).duplicate()
		estilo.bg_color = estilo.bg_color.lerp(Color(0.45, 0.32, 0.08), 0.55)
		estilo.border_color = DORADO
		estilo.set_border_width_all(4)
		tarjeta.add_theme_stylebox_override(estado, estilo)


func _tarjeta_especie(especie: Especie) -> Button:
	var conocida := RegistroEspecies.esta_descubierta(especie.id)
	var tarjeta := Button.new()
	tarjeta.custom_minimum_size = Vector2(196, 230)
	tarjeta.icon = especie.obtener_imagen()
	tarjeta.expand_icon = true
	tarjeta.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tarjeta.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	tarjeta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tarjeta.add_theme_font_size_override("font_size", 20)
	if conocida:
		tarjeta.text = especie.nombre_comun
	else:
		tarjeta.text = "???" + ("\n(insecto)" if especie.es_capturable() else "")
		tarjeta.add_theme_color_override("icon_normal_color", Color.BLACK)
		tarjeta.add_theme_color_override("icon_hover_color", Color.BLACK)
		tarjeta.add_theme_color_override("icon_pressed_color", Color.BLACK)
	tarjeta.pressed.connect(_ver_especie.bind(especie))
	return tarjeta


func _ver_especie(especie: Especie) -> void:
	if not RegistroEspecies.esta_descubierta(especie.id):
		var como := "Búscalo en el mapa: los insectos con anillo dorado se pueden fotografiar." if especie.es_capturable() \
			else "Búscala en el mapa o resuelve las misiones de esta zona."
		Aviso.mostrar(self, "Aún no la conoces. " + como)
		return
	var capturas := RegistroEspecies.capturas_de(especie.id)
	var foto := RegistroEspecies.cargar_foto(capturas[-1].foto) if not capturas.is_empty() else null
	FichaEspecie.mostrar(self, especie, "", foto)


# --- Misiones ---------------------------------------------------------------------------------

func _abrir_mision(mision: Mision) -> void:
	var capa := Control.new()
	capa.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	capa.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(capa)
	var sombra := ColorRect.new()
	sombra.color = Color(0, 0, 0, 0.6)
	sombra.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	capa.add_child(sombra)
	var panel := PanelContainer.new()
	capa.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 28
	panel.offset_right = -28
	panel.offset_top = 90
	panel.offset_bottom = -70
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 14)
	panel.add_child(caja)

	caja.add_child(_etiqueta(("Misión especial · " if mision.especial else "") + NOMBRES_TIPO[mision.tipo], 24, DORADO))
	caja.add_child(_etiqueta(mision.enunciado, 30, Color.WHITE))

	if mision.tipo == Mision.Tipo.IDENTIFICAR:
		var especie := RegistroEspecies.buscar(mision.especie_id)
		var imagen := TextureRect.new()
		imagen.texture = especie.obtener_imagen() if especie else null
		imagen.custom_minimum_size = Vector2(0, 320)
		imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		imagen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		caja.add_child(imagen)

	var resultado := _etiqueta("", 24, Color.WHITE)
	if mision.tipo == Mision.Tipo.PROPUESTA:
		var aviso_texto := _etiqueta(
			"El texto nuevo solo estará en esta sesión y no se guardará. Las propuestas guardadas antes de esta actualización se conservan.",
			18, Color(1.0, 0.88, 0.66))
		caja.add_child(aviso_texto)
		var texto := TextEdit.new()
		texto.placeholder_text = "Escribe aquí tu propuesta… (no se guardará)"
		texto.custom_minimum_size = Vector2(0, 300)
		texto.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
		texto.add_theme_font_size_override("font_size", 24)
		texto.text = RegistroEspecies.registro_mision(mision.id).get("respuesta", "")
		caja.add_child(texto)
		var enviar := Button.new()
		enviar.text = "Registrar participación"
		enviar.custom_minimum_size = Vector2(0, 68)
		enviar.pressed.connect(_guardar_propuesta.bind(mision, texto, resultado))
		caja.add_child(enviar)
	elif mision.tipo == Mision.Tipo.FOTO:
		var abrir := Button.new()
		abrir.text = "Abrir cámara"
		abrir.custom_minimum_size = Vector2(0, 72)
		abrir.pressed.connect(_tomar_foto_mision.bind(mision, resultado))
		caja.add_child(abrir)
	else:
		var botones: Array[Button] = []
		for i in mision.opciones.size():
			var opcion := Button.new()
			opcion.text = mision.opciones[i]
			opcion.custom_minimum_size = Vector2(0, 68)
			opcion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			botones.append(opcion)
			caja.add_child(opcion)
		for i in botones.size():
			botones[i].pressed.connect(_responder.bind(mision, i, botones, resultado))
	if RegistroEspecies.mision_resuelta(mision.id):
		resultado.text = "Ya resolviste esta misión. " + mision.explicacion
	caja.add_child(resultado)

	var espacio := Control.new()
	espacio.size_flags_vertical = Control.SIZE_EXPAND_FILL
	caja.add_child(espacio)
	var cerrar := Button.new()
	cerrar.text = "Cerrar"
	cerrar.custom_minimum_size = Vector2(0, 64)
	cerrar.pressed.connect(func() -> void:
		capa.queue_free()
		_construir())
	caja.add_child(cerrar)


func _responder(mision: Mision, elegida: int, botones: Array[Button], resultado: Label) -> void:
	var correcta := elegida == mision.correcta
	AnaliticaPedagogica.registrar_opcion_reto(AnaliticaPedagogica.tema_de_mision(mision.id), elegida)
	RegistroEspecies.registrar_mision(mision, zona.id, mision.opciones[elegida], correcta)
	if correcta:
		botones[elegida].modulate = Color(0.5, 1.0, 0.55)
		for boton in botones:
			boton.disabled = boton != botones[elegida]
		resultado.text = "¡Correcto! " + mision.explicacion
	else:
		AnaliticaPedagogica.registrar_error_tema(AnaliticaPedagogica.tema_de_mision(mision.id))
		botones[elegida].modulate = Color(1.0, 0.5, 0.5)
		botones[elegida].disabled = true
		resultado.text = "No es correcto. Intenta de nuevo."


func _guardar_propuesta(mision: Mision, texto: TextEdit, resultado: Label) -> void:
	var propuesta := texto.text.strip_edges()
	if propuesta.length() < 20:
		resultado.text = "Cuéntanos un poco más: escribe al menos una o dos frases."
		return
	if not mision.conceptos_obligatorios.is_empty():
		var faltantes := VALIDADOR_MISION.conceptos_faltantes(propuesta, mision.conceptos_obligatorios)
		if not faltantes.is_empty():
			resultado.text = "Para completar tu propuesta, menciona: %s." % ", ".join(faltantes)
			return
	RegistroEspecies.registrar_mision(mision, zona.id, propuesta, true)
	AnaliticaPedagogica.registrar_participacion_propuesta()
	resultado.text = "Participación registrada; el texto no se guardó. " + mision.explicacion


func _tomar_foto_mision(mision: Mision, resultado: Label) -> void:
	var camara := CAPTURA.instantiate()
	camara.tipo_fondo = FONDOS.get(zona.id, "pradera")
	camara.texto_mision = mision.enunciado
	camara.zona_id = zona.id
	camara.foto_tomada.connect(func(foto: Image) -> void:
		RegistroEspecies.registrar_mision(mision, zona.id, "foto", true, foto)
		resultado.text = "¡Foto guardada en tu Bioentdex! " + mision.explicacion)
	add_child(camara)


func _titulo_seccion(texto: String) -> Label:
	return _etiqueta(texto, 28, Color(1, 0.84, 0.3))


func _etiqueta(texto: String, tamano: int, color: Color) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etiqueta.add_theme_font_size_override("font_size", tamano)
	etiqueta.add_theme_color_override("font_color", color)
	return etiqueta


func _on_especie_descubierta(especie: Especie) -> void:
	Aviso.mostrar(self, "¡Nueva especie en tu Bioentdex: %s!" % especie.nombre_comun)
