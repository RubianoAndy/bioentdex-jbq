extends Node
## Autoload "Recompensas": experiencia, niveles, semillas (la moneda del humedal) y tienda.
##   - Capturar insectos da mucha experiencia (más si es una especie nueva); observar animales, un poco.
##   - Cumplir misiones da semillas (las especiales dan más) y algo de experiencia.
##   - Cada nivel nuevo regala semillas.
##   - Con semillas se compran, en la tienda, el néctar atrayente y los organismos Plus.
## Los datos se guardan en la base de datos de la Bioentdex (RegistroEspecies.jugador()).

signal cambio
signal subio_nivel(nivel: int)

const XP_CAPTURA := 100
const XP_CAPTURA_NUEVA := 150          # extra si es la primera vez que capturas esa especie
const XP_OBSERVACION := 15
const XP_OBSERVACION_NUEVA := 35
const XP_MISION := 40
const XP_MISION_ESPECIAL := 120
const SEMILLAS_MISION := 10
const SEMILLAS_MISION_ESPECIAL := 40
const SEMILLAS_POR_NIVEL := 20
const XP_BATALLA := 150
const SEMILLAS_BATALLA := 25
const XP_BATALLA_PERDIDA := 30         # por intentarlo
const DURACION_NECTAR := 180           # segundos
const PRECIO_NECTAR := 15
const ACTIVIDADES_PARA_MADURAR_MUESTRA := 3

const DORADO := Color(1, 0.84, 0.3)

var _capa: CanvasLayer
var _avisos_activos := 0


func _ready() -> void:
	_capa = CanvasLayer.new()
	_capa.layer = 60
	add_child(_capa)
	RegistroEspecies.especie_capturada.connect(_on_capturada)
	RegistroEspecies.especie_observada.connect(_on_observada)
	RegistroEspecies.mision_registrada.connect(_on_mision)


# --- Consultas --------------------------------------------------------------------------------

func experiencia() -> int:
	return RegistroEspecies.jugador().experiencia


func semillas() -> int:
	return RegistroEspecies.jugador().semillas


## Experiencia que pide cada nivel: 200, 300, 400...
func experiencia_para(nivel_actual: int) -> int:
	return 100 + 100 * nivel_actual


func nivel() -> int:
	var restante := experiencia()
	var n := 1
	while restante >= experiencia_para(n):
		restante -= experiencia_para(n)
		n += 1
	return n


## [experiencia dentro del nivel actual, experiencia que pide ese nivel]
func progreso_nivel() -> Vector2i:
	var restante := experiencia()
	var n := 1
	while restante >= experiencia_para(n):
		restante -= experiencia_para(n)
		n += 1
	return Vector2i(restante, experiencia_para(n))


func tiene_plus(id: String) -> bool:
	return RegistroEspecies.jugador().plus.has(id)


func resumen_muestra(mision_id: String) -> String:
	var muestras: Array = RegistroEspecies.jugador().muestras_digitales
	for muestra in muestras:
		if muestra.mision_id != mision_id:
			continue
		var nombre := "Muestra de campo digital" if muestra.tipo == Mision.RecompensaDigital.MUESTRA_CAMPO else "Ooteca digital"
		if muestra.madura:
			return "%s · madura" % nombre
		return "%s · actividad %d/%d" % [nombre, muestra.progreso, ACTIVIDADES_PARA_MADURAR_MUESTRA]
	return ""


func nectar_activo() -> bool:
	return segundos_nectar() > 0


func segundos_nectar() -> int:
	return maxi(0, int(RegistroEspecies.jugador().nectar_hasta - Time.get_unix_time_from_system()))


# --- Tienda -----------------------------------------------------------------------------------

func comprar_nectar() -> bool:
	if not _pagar(PRECIO_NECTAR):
		return false
	var jugador := RegistroEspecies.jugador()
	jugador.nectar_hasta = maxf(jugador.nectar_hasta, Time.get_unix_time_from_system()) + DURACION_NECTAR
	_guardar()
	mostrar_aviso("¡Néctar activo! Aparecerán más insectos", DORADO)
	return true


func comprar_plus(especie: Especie) -> bool:
	if tiene_plus(especie.id) or not _pagar(especie.precio):
		return false
	RegistroEspecies.jugador().plus.append(especie.id)
	_guardar()
	RegistroEspecies.registrar_observacion(especie)   # queda en la Bioentdex
	return true


# --- Batallas ---------------------------------------------------------------------------------

## Premio de un duelo: registra conocimiento sobre la especie sin simular recolección física.
func premiar_batalla(gano: bool, premio: Especie, _zona_id: String) -> void:
	if not gano:
		_ganar(XP_BATALLA_PERDIDA, 0, "¡Buen intento!")
		return
	if premio and premio.plus and not tiene_plus(premio.id):
		RegistroEspecies.jugador().plus.append(premio.id)
		_guardar()
		RegistroEspecies.registrar_observacion(premio)
	elif premio and not RegistroEspecies.esta_descubierta(premio.id):
		RegistroEspecies.registrar_observacion(premio)
	_ganar(XP_BATALLA, SEMILLAS_BATALLA, "¡Batalla ganada!")


func _pagar(precio: int) -> bool:
	if semillas() < precio:
		return false
	RegistroEspecies.jugador().semillas -= precio
	return true


# --- Ganancias --------------------------------------------------------------------------------

func _on_capturada(especie: Especie, _captura: Dictionary) -> void:
	_avanzar_muestras_digitales()
	var nueva := RegistroEspecies.capturas_de(especie.id).size() == 1
	_ganar(XP_CAPTURA + (XP_CAPTURA_NUEVA if nueva else 0), 0,
		"¡Especie nueva capturada!" if nueva else "Captura")


func _on_observada(especie: Especie, primera: bool) -> void:
	_avanzar_muestras_digitales()
	if especie.plus:
		return   # los Plus se compran: no dan experiencia
	_ganar(XP_OBSERVACION_NUEVA if primera else XP_OBSERVACION, 0, "Avistamiento")


func _on_mision(mision: Mision, registro: Dictionary) -> void:
	if not registro.get("intento_correcto", registro.correcta):
		return
	# Una misión vinculada registra también su observación; esa señal cuenta esta misma actividad.
	var observacion_automatica := not mision.especie_id.is_empty() \
		and RegistroEspecies.buscar(mision.especie_id) != null
	if not observacion_automatica:
		_avanzar_muestras_digitales()
	var jugador := RegistroEspecies.jugador()
	var misiones_muestras: Array = jugador.misiones_muestras
	if mision.recompensa_digital != Mision.RecompensaDigital.NINGUNA and not misiones_muestras.has(mision.id):
		misiones_muestras.append(mision.id)
		jugador.muestras_digitales.append({
			"mision_id": mision.id,
			"tipo": mision.recompensa_digital,
			"progreso": 0,
			"madura": false,
		})
		var nombre := "Muestra de campo digital" if mision.recompensa_digital == Mision.RecompensaDigital.MUESTRA_CAMPO else "Ooteca digital"
		mostrar_aviso("%s ganada: realiza %d actividades para que madure." % [
			nombre, ACTIVIDADES_PARA_MADURAR_MUESTRA], DORADO)
	var premiadas: Array = RegistroEspecies.jugador().misiones_premiadas
	if premiadas.has(mision.id):
		_guardar()
		return   # cada misión se premia una sola vez
	premiadas.append(mision.id)
	if mision.especial:
		_ganar(XP_MISION_ESPECIAL, SEMILLAS_MISION_ESPECIAL, "¡Misión especial cumplida!")
	else:
		_ganar(XP_MISION, SEMILLAS_MISION, "Misión cumplida")


func _avanzar_muestras_digitales() -> void:
	var muestras: Array = RegistroEspecies.jugador().muestras_digitales
	var maduradas: Array[String] = []
	var cambio_muestras := false
	for muestra in muestras:
		if muestra.madura:
			continue
		muestra.progreso = mini(int(muestra.progreso) + 1, ACTIVIDADES_PARA_MADURAR_MUESTRA)
		cambio_muestras = true
		if muestra.progreso >= ACTIVIDADES_PARA_MADURAR_MUESTRA:
			muestra.madura = true
			maduradas.append("Muestra de campo digital" if muestra.tipo == Mision.RecompensaDigital.MUESTRA_CAMPO else "Ooteca digital")
	if cambio_muestras:
		_guardar()
		for nombre in maduradas:
			mostrar_aviso("¡%s madura!" % nombre, DORADO)


func _ganar(xp: int, nuevas_semillas: int, motivo: String) -> void:
	var antes := nivel()
	var jugador := RegistroEspecies.jugador()
	jugador.experiencia += xp
	jugador.semillas += nuevas_semillas
	var despues := nivel()
	for n in range(antes + 1, despues + 1):
		jugador.semillas += SEMILLAS_POR_NIVEL
	_guardar()

	var texto := "%s  +%d XP" % [motivo, xp]
	if nuevas_semillas > 0:
		texto += "  +%d semillas" % nuevas_semillas
	mostrar_aviso(texto, Color.WHITE)
	if despues > antes:
		subio_nivel.emit(despues)
		_celebrar_nivel(despues)


func _guardar() -> void:
	RegistroEspecies.guardar()
	cambio.emit()


# --- Avisos en pantalla -----------------------------------------------------------------------

## Texto que sube y se desvanece en la parte de arriba de la pantalla (sobre cualquier escena).
func mostrar_aviso(texto: String, color: Color) -> void:
	var cartel := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.06, 0.14, 0.1, 0.92)
	estilo.border_color = DORADO
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(30)
	estilo.content_margin_left = 24
	estilo.content_margin_right = 24
	estilo.content_margin_top = 10
	estilo.content_margin_bottom = 10
	cartel.add_theme_stylebox_override("panel", estilo)
	cartel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.add_theme_font_size_override("font_size", 24)
	etiqueta.add_theme_color_override("font_color", color)
	cartel.add_child(etiqueta)
	_capa.add_child(cartel)

	var ancho := cartel.get_combined_minimum_size().x
	var y := 150.0 + _avisos_activos * 70.0
	_avisos_activos += 1
	cartel.position = Vector2((cartel.get_viewport_rect().size.x - ancho) / 2.0, y + 30.0)
	cartel.modulate.a = 0.0
	var tween := cartel.create_tween()
	tween.tween_property(cartel, "modulate:a", 1.0, 0.2)
	tween.parallel().tween_property(cartel, "position:y", y, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(1.8)
	tween.tween_property(cartel, "modulate:a", 0.0, 0.4)
	tween.parallel().tween_property(cartel, "position:y", y - 30.0, 0.4)
	tween.tween_callback(func() -> void:
		_avisos_activos -= 1
		cartel.queue_free())


## Celebración de nivel nuevo: insignia grande con destellos.
func _celebrar_nivel(nuevo: int) -> void:
	var fondo := ColorRect.new()
	fondo.color = Color(0, 0, 0, 0.55)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_capa.add_child(fondo)

	var caja := VBoxContainer.new()
	caja.alignment = BoxContainer.ALIGNMENT_CENTER
	caja.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caja.add_theme_constant_override("separation", 12)
	fondo.add_child(caja)

	var insignia := PanelContainer.new()
	insignia.custom_minimum_size = Vector2(220, 220)
	insignia.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = DORADO
	estilo.set_corner_radius_all(110)
	estilo.set_border_width_all(10)
	estilo.border_color = Color.WHITE
	estilo.shadow_color = Color(1, 0.8, 0.3, 0.6)
	estilo.shadow_size = 30
	insignia.add_theme_stylebox_override("panel", estilo)
	var numero := Label.new()
	numero.text = str(nuevo)
	numero.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	numero.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	numero.add_theme_font_size_override("font_size", 110)
	numero.add_theme_color_override("font_color", Color(0.3, 0.2, 0.02))
	insignia.add_child(numero)
	caja.add_child(insignia)

	for linea in [["¡Subiste de nivel!", 44, Color.WHITE], ["+%d semillas de regalo" % SEMILLAS_POR_NIVEL, 28, DORADO]]:
		var texto := Label.new()
		texto.text = linea[0]
		texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		texto.add_theme_font_size_override("font_size", linea[1])
		texto.add_theme_color_override("font_color", linea[2])
		texto.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.5))
		texto.add_theme_constant_override("outline_size", 8)
		caja.add_child(texto)

	var confeti := CPUParticles2D.new()
	confeti.position = Vector2(fondo.get_viewport_rect().size.x / 2.0, fondo.get_viewport_rect().size.y * 0.42)
	confeti.amount = 60
	confeti.one_shot = true
	confeti.explosiveness = 1.0
	confeti.lifetime = 1.6
	confeti.spread = 180.0
	confeti.initial_velocity_min = 300.0
	confeti.initial_velocity_max = 700.0
	confeti.gravity = Vector2(0, 700)
	confeti.scale_amount_min = 6.0
	confeti.scale_amount_max = 12.0
	confeti.color_ramp = Gradient.new()
	confeti.color_ramp.colors = PackedColorArray([DORADO, Color(0.4, 0.9, 0.6), Color(1, 1, 1, 0)])
	fondo.add_child(confeti)
	confeti.emitting = true

	insignia.pivot_offset = Vector2(110, 110)
	insignia.scale = Vector2(0.2, 0.2)
	fondo.modulate.a = 0.0
	var tween := fondo.create_tween()
	tween.tween_property(fondo, "modulate:a", 1.0, 0.2)
	tween.parallel().tween_property(insignia, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_interval(2.0)
	tween.tween_property(fondo, "modulate:a", 0.0, 0.4)
	tween.tween_callback(fondo.queue_free)
	fondo.gui_input.connect(func(evento: InputEvent) -> void:
		if evento is InputEventMouseButton and evento.pressed:
			fondo.queue_free())
