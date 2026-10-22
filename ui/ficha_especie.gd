class_name FichaEspecie
extends Control
## Ficha de una especie al estilo de la pantalla de detalle de Pokémon GO:
##   - Arriba, una escena con el hábitat desenfocado, el animal grande (al tocarlo salta) y un arco
##     que marca su riesgo de extinción (UICN), con su número de la Bioentdex.
##   - Abajo, una tarjeta blanca con nombre, registro, etiquetas, clasificación (orden, familia,
##     especie), botón a la guía macrofotográfica, datos rápidos e información para aprender.
## Se usa al capturar un insecto, al tocar un animal NPC en el mapa y desde la Bioentdex.

signal cerrada

const ALTO_ESCENA := 540.0
const TEXTO := Color(0.17, 0.24, 0.21)
const TEXTO_SUAVE := Color(0.53, 0.6, 0.57)
const LINEA := Color(0.88, 0.9, 0.89)

const COLOR_TIPO := {
	Especie.Tipo.AVE: Color(0.27, 0.56, 0.86), Especie.Tipo.INSECTO: Color(0.95, 0.66, 0.15),
	Especie.Tipo.ANFIBIO: Color(0.3, 0.72, 0.38), Especie.Tipo.REPTIL: Color(0.52, 0.62, 0.28),
	Especie.Tipo.MAMIFERO: Color(0.72, 0.47, 0.32), Especie.Tipo.PEZ: Color(0.2, 0.6, 0.72),
	Especie.Tipo.PLANTA: Color(0.33, 0.62, 0.27), Especie.Tipo.INVERTEBRADO: Color(0.86, 0.42, 0.58),
}
const ARCHIVO_TIPO := {
	Especie.Tipo.AVE: "ave", Especie.Tipo.INSECTO: "insecto", Especie.Tipo.ANFIBIO: "anfibio",
	Especie.Tipo.REPTIL: "reptil", Especie.Tipo.MAMIFERO: "mamifero", Especie.Tipo.PEZ: "pez",
	Especie.Tipo.PLANTA: "planta", Especie.Tipo.INVERTEBRADO: "invertebrado",
}
## Posición en el arco de riesgo (0 = sin riesgo, 1 = máximo). Las no evaluadas no tienen punto.
const RIESGO := {
	Especie.Estado.LC: 0.1, Especie.Estado.NT: 0.3, Especie.Estado.VU: 0.5,
	Especie.Estado.EN: 0.7, Especie.Estado.CR: 0.9,
}
const COLOR_ESTADO := {
	Especie.Estado.LC: Color(0.3, 0.68, 0.36), Especie.Estado.NT: Color(0.58, 0.72, 0.22),
	Especie.Estado.VU: Color(0.95, 0.7, 0.15), Especie.Estado.EN: Color(0.93, 0.45, 0.18),
	Especie.Estado.CR: Color(0.84, 0.2, 0.2), Especie.Estado.DD: Color(0.55, 0.58, 0.6),
	Especie.Estado.NE: Color(0.55, 0.58, 0.6),
}
const HORARIO := {Especie.Horario.SIEMPRE: "Día y noche", Especie.Horario.DIA: "De día", Especie.Horario.NOCHE: "De noche"}

# Desenfoque usando los mipmaps del fondo (como una cámara fuera de foco)
const SHADER_DESENFOQUE := """
shader_type canvas_item;
uniform float desenfoque = 3.2;
void fragment() {
	COLOR = textureLod(TEXTURE, UV, desenfoque);
}
"""

var _especie: Especie
var _titulo := ""
var _foto: Texture2D
var _color: Color

var _escena: Control
var _animal: TextureRect
var _tarjeta: PanelContainer
var _tiempo := 0.0
var _mostrando_foto := false
var _fuente_negrita: SystemFont


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
	_color = COLOR_TIPO.get(_especie.tipo, Color(0.4, 0.6, 0.5))
	_fuente_negrita = SystemFont.new()
	_fuente_negrita.font_names = PackedStringArray(["Nunito", "Segoe UI", "Roboto", "Arial"])
	_fuente_negrita.font_weight = 800

	_construir_escena()
	_construir_tarjeta()
	_construir_cerrar()
	_entrar()


func _process(delta: float) -> void:
	_tiempo += delta
	# El animal flota suavemente sobre su sombra
	_animal.position.y = ALTO_ESCENA - 110.0 - _animal.size.y + sin(_tiempo * 2.0) * 8.0


# --- Escena superior --------------------------------------------------------------------------

func _construir_escena() -> void:
	_escena = Control.new()
	_escena.clip_contents = true
	_escena.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_escena.offset_bottom = ALTO_ESCENA + 40.0
	add_child(_escena)

	# Hábitat desenfocado
	var fondo := TextureRect.new()
	fondo.texture = load("res://dataset/fondos/%s.svg" % _habitat())
	fondo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fondo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var desenfoque := ShaderMaterial.new()
	desenfoque.shader = Shader.new()
	desenfoque.shader.code = SHADER_DESENFOQUE
	fondo.material = desenfoque
	fondo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	fondo.modulate = Color(0.92, 0.92, 0.92)
	_escena.add_child(fondo)

	# Luces, arco de riesgo y sombra (se dibujan a mano)
	var decoracion := Decoracion.new()
	decoracion.ficha = self
	decoracion.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	decoracion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_escena.add_child(decoracion)

	# Número de la Bioentdex sobre el arco
	var numero := _etiqueta("N.º %03d" % _especie.numero, 56, Color.WHITE)
	numero.add_theme_font_override("font", _fuente_negrita)
	numero.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.35))
	numero.add_theme_constant_override("outline_size", 10)
	numero.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	numero.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	numero.offset_top = 72 if not _titulo.is_empty() else 40
	numero.offset_bottom = numero.offset_top + 70
	_escena.add_child(numero)
	var riesgo := _etiqueta(_texto_riesgo(), 20, Color(1, 1, 1, 0.92))
	riesgo.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.35))
	riesgo.add_theme_constant_override("outline_size", 6)
	riesgo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	riesgo.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	riesgo.offset_top = numero.offset_bottom - 4
	riesgo.offset_bottom = riesgo.offset_top + 30
	_escena.add_child(riesgo)

	# El animal: al tocarlo salta y suelta destellos
	_animal = TextureRect.new()
	_animal.texture = _foto if _foto and _mostrando_foto else _especie.obtener_imagen()
	_animal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_animal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_animal.size = Vector2(280, 280)
	_animal.pivot_offset = Vector2(140, 280)
	_animal.position = Vector2((get_viewport_rect().size.x - 280.0) / 2.0, ALTO_ESCENA - 390.0)
	_animal.gui_input.connect(_on_animal_input)
	_escena.add_child(_animal)

	# Título del momento ("¡Capturaste un insecto!", "¡Nuevo avistamiento!")
	if not _titulo.is_empty():
		var cinta := _pastilla(_titulo, Color(1, 0.8, 0.25), Color(0.25, 0.17, 0.02), 22)
		cinta.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
		cinta.offset_top = 10
		cinta.grow_horizontal = Control.GROW_DIRECTION_BOTH
		_escena.add_child(cinta)

	# Botón de cámara: cambia entre tu foto y la ilustración
	if _foto:
		var camara := Button.new()
		camara.icon = load("res://ui/icono_camara.svg")
		camara.expand_icon = true
		camara.flat = true
		camara.tooltip_text = "Ver tu foto / la ilustración"
		camara.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		camara.offset_left = -96
		camara.offset_top = 70
		camara.offset_right = -24
		camara.offset_bottom = 142
		camara.pressed.connect(_alternar_foto)
		_escena.add_child(camara)


func _on_animal_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var salto := create_tween()
		salto.tween_property(_animal, "scale", Vector2(1.12, 0.88), 0.08)
		salto.tween_property(_animal, "scale", Vector2(0.92, 1.1), 0.1)
		salto.tween_property(_animal, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		var giro := create_tween()
		giro.tween_property(_animal, "rotation", 0.12, 0.08)
		giro.tween_property(_animal, "rotation", -0.1, 0.1)
		giro.tween_property(_animal, "rotation", 0.0, 0.2)
		_destellos(_animal.position + Vector2(140, 140))


func _alternar_foto() -> void:
	_mostrando_foto = not _mostrando_foto
	_animal.texture = _foto if _mostrando_foto else _especie.obtener_imagen()
	_destellos(_animal.position + Vector2(140, 140))


func _destellos(centro: Vector2) -> void:
	var punto := GradientTexture2D.new()
	punto.width = 24
	punto.height = 24
	punto.fill = GradientTexture2D.FILL_RADIAL
	punto.fill_from = Vector2(0.5, 0.5)
	punto.fill_to = Vector2(0.5, 0.0)
	punto.gradient = Gradient.new()
	punto.gradient.colors = PackedColorArray([Color(1, 1, 0.85), Color(1, 0.9, 0.5, 0)])
	var particulas := CPUParticles2D.new()
	particulas.texture = punto
	particulas.position = centro
	particulas.amount = 22
	particulas.one_shot = true
	particulas.explosiveness = 1.0
	particulas.lifetime = 0.9
	particulas.spread = 180.0
	particulas.initial_velocity_min = 180.0
	particulas.initial_velocity_max = 380.0
	particulas.gravity = Vector2(0, 500)
	particulas.scale_amount_min = 0.6
	particulas.scale_amount_max = 1.4
	particulas.color = _color.lightened(0.4)
	_escena.add_child(particulas)
	particulas.emitting = true
	get_tree().create_timer(1.2).timeout.connect(particulas.queue_free)


func _habitat() -> String:
	var suelos := _especie.suelos_habitat
	if suelos.has(PaletaMapa.AGUA) or suelos.has(PaletaMapa.JUNCAL) or _especie.tipo == Especie.Tipo.ANFIBIO:
		return "agua"
	if suelos.has(PaletaMapa.BOSQUE) and not suelos.has(PaletaMapa.PRADERA):
		return "bosque"
	return "pradera"


func _texto_riesgo() -> String:
	return "Riesgo de extinción: %s" % _especie.nombre_estado().to_lower()


# --- Tarjeta blanca ---------------------------------------------------------------------------

func _construir_tarjeta() -> void:
	_tarjeta = PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.98, 0.98, 0.97)
	estilo.corner_radius_top_left = 30
	estilo.corner_radius_top_right = 30
	estilo.shadow_color = Color(0, 0, 0, 0.25)
	estilo.shadow_size = 18
	_tarjeta.add_theme_stylebox_override("panel", estilo)
	_tarjeta.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tarjeta.offset_top = ALTO_ESCENA - 30.0
	add_child(_tarjeta)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_tarjeta.add_child(scroll)
	var margen := MarginContainer.new()
	margen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for lado in ["left", "right"]:
		margen.add_theme_constant_override("margin_" + lado, 30)
	margen.add_theme_constant_override("margin_top", 26)
	margen.add_theme_constant_override("margin_bottom", 130)   # espacio para el botón de cerrar
	scroll.add_child(margen)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 16)
	margen.add_child(columna)

	# Nombre con el ícono de su tipo
	var fila_nombre := HBoxContainer.new()
	fila_nombre.alignment = BoxContainer.ALIGNMENT_CENTER
	fila_nombre.add_theme_constant_override("separation", 12)
	fila_nombre.add_child(_icono_tipo(40))
	var nombre := _etiqueta(_especie.nombre_comun, 40 if _especie.nombre_comun.length() <= 18 else 32, TEXTO)
	nombre.autowrap_mode = TextServer.AUTOWRAP_OFF
	nombre.add_theme_font_override("font", _fuente_negrita)
	fila_nombre.add_child(nombre)
	columna.add_child(fila_nombre)
	var cursiva := SystemFont.new()
	cursiva.font_italic = true
	var cientifico := _etiqueta(_especie.nombre_cientifico, 22, TEXTO_SUAVE)
	cientifico.add_theme_font_override("font", cursiva)
	cientifico.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	columna.add_child(cientifico)

	# Barra de registro (como la barra de PS)
	columna.add_child(_barra_registro())

	# Etiquetas de colores
	var etiquetas := HFlowContainer.new()
	etiquetas.alignment = FlowContainer.ALIGNMENT_CENTER
	etiquetas.add_theme_constant_override("h_separation", 10)
	etiquetas.add_theme_constant_override("v_separation", 10)
	etiquetas.add_child(_pastilla(_especie.nombre_tipo(), _color, Color.WHITE))
	if _especie.plus:
		etiquetas.add_child(_pastilla("Organismo Plus", Color(1, 0.8, 0.25), Color(0.3, 0.2, 0.02)))
	elif _especie.es_capturable():
		etiquetas.add_child(_pastilla("Capturable", Color(1, 0.8, 0.25), Color(0.3, 0.2, 0.02)))
	else:
		etiquetas.add_child(_pastilla("Solo observar", Color(0.62, 0.48, 0.85), Color.WHITE))
	etiquetas.add_child(_pastilla(_especie.nombre_estado(), COLOR_ESTADO[_especie.estado_conservacion], Color.WHITE))
	columna.add_child(etiquetas)
	columna.add_child(_separador())

	# Clasificación: familia | ícono / guía | orden
	columna.add_child(_fila_clasificacion())
	columna.add_child(_separador())

	# Datos rápidos 2x2
	var cuadricula := GridContainer.new()
	cuadricula.columns = 2
	cuadricula.add_theme_constant_override("h_separation", 16)
	cuadricula.add_theme_constant_override("v_separation", 18)
	var especie_texto := "Varias especies" if _especie.nombre_cientifico.begins_with("Familia") else _especie.nombre_cientifico
	cuadricula.add_child(_dato(especie_texto, "ESPECIE", _color))
	cuadricula.add_child(_dato(HORARIO[_especie.horario], "CUÁNDO SALE", Color(0.98, 0.72, 0.2)))
	cuadricula.add_child(_dato(_donde_vive(), "DÓNDE VIVE", Color(0.25, 0.6, 0.85)))
	cuadricula.add_child(_dato(_texto_registros(), "TUS REGISTROS", Color(0.86, 0.42, 0.58)))
	columna.add_child(cuadricula)
	columna.add_child(_separador())

	# Para aprender
	columna.add_child(_seccion("¿POR QUÉ ES IMPORTANTE?", _especie.importancia, _color))
	columna.add_child(_seccion("DESCRIPCIÓN", _especie.descripcion, Color(0.25, 0.6, 0.85)))
	if not _especie.consejo_macro.is_empty():
		columna.add_child(_seccion("CONSEJO PARA FOTOGRAFIARLO", _especie.consejo_macro, Color(0.98, 0.72, 0.2)))


func _barra_registro() -> Control:
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 4)
	var barra := ProgressBar.new()
	barra.show_percentage = false
	barra.custom_minimum_size = Vector2(0, 12)
	barra.max_value = 2
	var capturas := RegistroEspecies.capturas_de(_especie.id).size()
	var conocida := RegistroEspecies.esta_descubierta(_especie.id)
	# Media barra si solo se ha visto un insecto; llena si está capturado u observado
	barra.value = 2 if capturas > 0 or (conocida and not _especie.es_capturable()) else (1 if conocida else 0)
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = LINEA
	fondo.set_corner_radius_all(6)
	var relleno := StyleBoxFlat.new()
	relleno.bg_color = Color(0.36, 0.8, 0.55)
	relleno.set_corner_radius_all(6)
	barra.add_theme_stylebox_override("background", fondo)
	barra.add_theme_stylebox_override("fill", relleno)
	caja.add_child(barra)
	var texto := _etiqueta(_texto_estado(), 18, TEXTO_SUAVE)
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caja.add_child(texto)
	return caja


func _fila_clasificacion() -> Control:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 0)
	var familia := _dato(_especie.familia, "FAMILIA", null)
	familia.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	familia.size_flags_stretch_ratio = 1.0
	fila.add_child(familia)
	fila.add_child(_divisor_vertical())

	var centro := VBoxContainer.new()
	centro.custom_minimum_size = Vector2(180, 0)
	centro.alignment = BoxContainer.ALIGNMENT_CENTER
	centro.add_theme_constant_override("separation", 6)
	if _especie.pagina_guia > 0:
		# Botón redondo a la guía macrofotográfica (página de su familia)
		var guia := Button.new()
		guia.icon = load("res://ui/icono_guia.svg")
		guia.expand_icon = true
		guia.custom_minimum_size = Vector2(84, 84)
		guia.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var redondo := StyleBoxFlat.new()
		redondo.bg_color = Color(0.2, 0.62, 0.42)
		redondo.set_corner_radius_all(42)
		redondo.set_border_width_all(5)
		redondo.border_color = Color(0.85, 0.95, 0.88)
		redondo.shadow_color = Color(0, 0, 0, 0.2)
		redondo.shadow_size = 6
		redondo.set_content_margin_all(18)
		for estado in ["normal", "hover", "pressed", "focus"]:
			guia.add_theme_stylebox_override(estado, redondo)
		guia.pressed.connect(func() -> void: VisorGuia.abrir(self, _especie.pagina_guia))
		centro.add_child(guia)
		var leyenda := _etiqueta("VER EN LA GUÍA\n(pág. %d)" % _especie.pagina_guia, 15, TEXTO_SUAVE)
		leyenda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		centro.add_child(leyenda)
	else:
		centro.add_child(_icono_tipo(72))
		var leyenda := _etiqueta(_especie.nombre_tipo().to_upper(), 15, TEXTO_SUAVE)
		leyenda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		centro.add_child(leyenda)
	fila.add_child(centro)

	fila.add_child(_divisor_vertical())
	var orden := _dato(_especie.orden, "ORDEN", null)
	orden.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pagina_orden: int = VisorGuia.PAGINAS_ORDEN.get(_especie.orden, 0)
	if pagina_orden > 0:
		# El orden también se puede tocar para abrir su página en la guía
		var enlace := Button.new()
		enlace.flat = true
		enlace.text = "Ver orden ›"
		enlace.add_theme_font_size_override("font_size", 16)
		enlace.add_theme_color_override("font_color", Color(0.2, 0.55, 0.38))
		enlace.add_theme_color_override("font_hover_color", Color(0.15, 0.45, 0.3))
		enlace.pressed.connect(func() -> void: VisorGuia.abrir(self, pagina_orden))
		orden.add_child(enlace)
	fila.add_child(orden)
	return fila


func _dato(valor: String, leyenda: String, color_punto) -> VBoxContainer:
	var caja := VBoxContainer.new()
	caja.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caja.add_theme_constant_override("separation", 2)
	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 8)
	if color_punto != null:
		var punto := Panel.new()
		punto.custom_minimum_size = Vector2(14, 14)
		punto.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var estilo := StyleBoxFlat.new()
		estilo.bg_color = color_punto
		estilo.set_corner_radius_all(7)
		punto.add_theme_stylebox_override("panel", estilo)
		fila.add_child(punto)
	var texto := _etiqueta(valor, 24, TEXTO)
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto.add_theme_font_override("font", _fuente_negrita)
	texto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texto.custom_minimum_size = Vector2(120, 0)
	fila.add_child(texto)
	caja.add_child(fila)
	var abajo := _etiqueta(leyenda, 15, TEXTO_SUAVE)
	abajo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caja.add_child(abajo)
	return caja


func _seccion(titulo: String, texto: String, color: Color) -> Control:
	var panel := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = color.lerp(Color.WHITE, 0.88)
	estilo.border_width_left = 6
	estilo.border_color = color
	estilo.set_corner_radius_all(14)
	estilo.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", estilo)
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 6)
	var cabeza := _etiqueta(titulo, 16, color.darkened(0.35))
	cabeza.add_theme_font_override("font", _fuente_negrita)
	caja.add_child(cabeza)
	caja.add_child(_etiqueta(texto, 21, TEXTO))
	panel.add_child(caja)
	return panel


func _icono_tipo(tamano: float) -> Control:
	var circulo := PanelContainer.new()
	circulo.custom_minimum_size = Vector2(tamano, tamano)
	circulo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	circulo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = _color
	estilo.set_corner_radius_all(int(tamano / 2.0))
	estilo.set_content_margin_all(tamano * 0.16)
	circulo.add_theme_stylebox_override("panel", estilo)
	var icono := TextureRect.new()
	icono.texture = load("res://ui/tipos/%s.svg" % ARCHIVO_TIPO.get(_especie.tipo, "insecto"))
	icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	circulo.add_child(icono)
	return circulo


func _pastilla(texto: String, fondo: Color, letra: Color, tamano := 20) -> PanelContainer:
	var pastilla := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = fondo
	estilo.set_corner_radius_all(40)
	estilo.content_margin_left = 22
	estilo.content_margin_right = 22
	estilo.content_margin_top = 6
	estilo.content_margin_bottom = 6
	estilo.shadow_color = Color(0, 0, 0, 0.12)
	estilo.shadow_size = 3
	pastilla.add_theme_stylebox_override("panel", estilo)
	var etiqueta := _etiqueta(texto, tamano, letra)
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_OFF
	if _fuente_negrita:
		etiqueta.add_theme_font_override("font", _fuente_negrita)
	pastilla.add_child(etiqueta)
	return pastilla


func _separador() -> Control:
	var linea := ColorRect.new()
	linea.color = LINEA
	linea.custom_minimum_size = Vector2(0, 2)
	return linea


func _divisor_vertical() -> Control:
	var linea := ColorRect.new()
	linea.color = LINEA
	linea.custom_minimum_size = Vector2(2, 70)
	linea.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return linea


func _donde_vive() -> String:
	if _especie.plus:
		return "Muy escaso"
	var zonas := Expedicion.zonas.filter(func(z: Zona) -> bool: return z.especies.has(_especie))
	if zonas.is_empty():
		return "Todo el humedal"
	var nombres := zonas.map(func(z: Zona) -> String: return z.nombre.trim_prefix("Zona de ").trim_prefix("Zona "))
	return ", ".join(PackedStringArray(nombres.slice(0, 2))) + (" y más" if nombres.size() > 2 else "")


func _texto_registros() -> String:
	var capturas := RegistroEspecies.capturas_de(_especie.id).size()
	if capturas > 0:
		return "%d %s" % [capturas, "foto" if capturas == 1 else "fotos"]
	if RegistroEspecies.esta_observada(_especie.id):
		return "Observado"
	return "Nuevo"


func _texto_estado() -> String:
	var capturas := RegistroEspecies.capturas_de(_especie.id)
	if not capturas.is_empty():
		return "Capturado %d %s · primera vez: %s" % [capturas.size(), "vez" if capturas.size() == 1 else "veces",
			capturas[0].fecha.substr(0, 10)]
	if RegistroEspecies.esta_observada(_especie.id):
		return "Observado" if not _especie.es_capturable() else "Visto, aún sin capturar"
	return "Aún no registrado"


func _etiqueta(texto: String, tamano: int, color: Color) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etiqueta.add_theme_font_size_override("font_size", tamano)
	etiqueta.add_theme_color_override("font_color", color)
	return etiqueta


# --- Cerrar y animaciones ---------------------------------------------------------------------

func _construir_cerrar() -> void:
	var cerrar := Button.new()
	cerrar.text = "×"
	cerrar.add_theme_font_size_override("font_size", 52)
	cerrar.add_theme_color_override("font_color", Color.WHITE)
	cerrar.add_theme_color_override("font_hover_color", Color.WHITE)
	var redondo := StyleBoxFlat.new()
	redondo.bg_color = Color(0.2, 0.62, 0.42)
	redondo.set_corner_radius_all(42)
	redondo.shadow_color = Color(0, 0, 0, 0.3)
	redondo.shadow_size = 8
	redondo.content_margin_bottom = 8
	for estado in ["normal", "hover", "pressed", "focus"]:
		cerrar.add_theme_stylebox_override(estado, redondo)
	cerrar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	cerrar.offset_left = -42
	cerrar.offset_right = 42
	cerrar.offset_top = -112
	cerrar.offset_bottom = -28
	cerrar.pressed.connect(_cerrar)
	add_child(cerrar)


func _entrar() -> void:
	modulate.a = 0.0
	_tarjeta.position.y += 160
	_animal.scale = Vector2(0.5, 0.5)
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	tween.tween_property(_tarjeta, "position:y", _tarjeta.position.y - 160, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_animal, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT).set_delay(0.1)


func _cerrar() -> void:
	cerrada.emit()
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_property(_tarjeta, "position:y", _tarjeta.position.y + 160, 0.2)
	tween.chain().tween_callback(queue_free)


## Dibuja las luces del fondo (bokeh), el arco de riesgo de extinción y la sombra del animal.
class Decoracion extends Control:
	var ficha: FichaEspecie
	var _tiempo := 0.0

	func _process(delta: float) -> void:
		_tiempo += delta
		queue_redraw()

	func _draw() -> void:
		# Luces suaves que flotan
		for i in 9:
			var x := fmod(i * 97.0 + _tiempo * (6.0 + i), size.x + 120.0) - 60.0
			var y := 90.0 + fmod(i * 61.0, size.y * 0.6) + sin(_tiempo + i) * 10.0
			for capa in 3:
				draw_circle(Vector2(x, y), 34.0 - capa * 9.0, Color(1, 1, 0.9, 0.05))
		# Arco: de verde (sin riesgo) a rojo (en peligro crítico)
		var centro := Vector2(size.x / 2.0, ficha.ALTO_ESCENA - 80.0)
		var radio := size.x * 0.42
		var desde := PI + 0.35
		var hasta := TAU - 0.35
		var tramos := 40
		for k in tramos:
			var a1 := lerpf(desde, hasta, float(k) / tramos)
			var a2 := lerpf(desde, hasta, float(k + 1) / tramos)
			var c := Color(0.36, 0.8, 0.45).lerp(Color(0.95, 0.3, 0.25), float(k) / tramos)
			c.a = 0.85
			draw_arc(centro, radio, a1, a2, 3, c, 6.0, true)
		var estado := ficha._especie.estado_conservacion
		if ficha.RIESGO.has(estado):
			var punto := centro + Vector2.from_angle(lerpf(desde, hasta, ficha.RIESGO[estado])) * radio
			draw_circle(punto, 15.0, Color(0, 0, 0, 0.25))
			draw_circle(punto, 12.0, Color.WHITE)
			draw_circle(punto, 6.0, ficha.COLOR_ESTADO[estado])
		# Sombra del animal
		var sombra := Vector2(size.x / 2.0, ficha.ALTO_ESCENA - 104.0)
		draw_set_transform(sombra, 0.0, Vector2(1.0, 0.28))
		draw_circle(Vector2.ZERO, 120.0, Color(0, 0, 0, 0.22))
		draw_set_transform(Vector2.ZERO)
