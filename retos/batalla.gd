class_name Batalla
extends Control
## Batalla contra un depredador del humedal que llegó en su globo con un insecto especial atrapado.
##   1. El depredador se presenta y la guía del humedal explica qué hacer.
##   2. El jugador elige hasta MAX_EQUIPO de sus insectos capturados.
##   3. Preguntas: cada respuesta correcta lanza un poder del insecto; cada error, un ataque del
##      depredador. Se gana con VIDA_DEPREDADOR aciertos; cada insecto aguanta VIDA_INSECTO errores.
##   4. Si gana, rescata al insecto especial (Recompensas.premiar_batalla). Todo queda registrado.

signal terminada(peleo: bool)   # false si huyó antes de pelear (el globo se queda en el mapa)

const DORADO := Color(1, 0.84, 0.3)
const ROJO := Color(0.95, 0.3, 0.32)
const VERDE := Color(0.45, 0.95, 0.55)
const VIDA_DEPREDADOR := 3
const VIDA_INSECTO := 2
const MAX_EQUIPO := 3
const GUIA := "Guía del humedal"

## Poder que lanza cada insecto al acertar (los demás usan "Ataque sorpresa")
const PODERES := {
	"abejorro": "Zumbido aturdidor", "avispa": "Aguijón certero", "libelula": "Picada en picada",
	"caballito_del_diablo": "Vuelo relámpago", "mariquita": "Escudo de puntos", "hormiga": "Ejército de hormigas",
	"zancudo": "Zumbido nocturno", "mosca_metalica": "Destello metálico", "sirfido": "Disfraz de avispa",
	"mariposa_blanca": "Polvo de escamas", "mariposa_monarca": "Alas venenosas", "ninfalida": "Ojos falsos",
	"polilla_geometra": "Camuflaje de rama", "tipula": "Patas largas", "crisopa": "Alas de encaje",
	"chinche_planta": "Olor apestoso", "tijereta": "Pinzas de tijera", "crisomelido": "Caparazón brillante",
	"taquinido": "Vuelo zigzag", "psocido": "Salto diminuto", "pececillo_plata": "Escape plateado",
}
const ATAQUES := {Especie.Tipo.AVE: "Picotazo", Especie.Tipo.ANFIBIO: "Lengua pegajosa", Especie.Tipo.MAMIFERO: "Mordisco"}

var depredador: Especie
var premio: Especie
var zona_id := ""
var tipo_fondo := "pradera"

var _equipo: Array[Especie] = []
var _actual := 0
var _vida_depredador := VIDA_DEPREDADOR
var _vida_insecto := VIDA_INSECTO
var _preguntas := []
var _aciertos := 0
var _errores := 0

var _img_depredador: TextureRect
var _barra_depredador: ProgressBar
var _img_premio: Control
var _atrapado: Label
var _img_insecto: TextureRect
var _tarjeta_insecto: VBoxContainer
var _nombre_insecto: Label
var _barra_insecto: ProgressBar
var _caja: VBoxContainer   # contenido del panel de abajo (diálogos, preguntas...)


static func mostrar(padre: Node, nuevo_depredador: Especie, nuevo_premio: Especie, nueva_zona_id: String, fondo: String) -> Batalla:
	var batalla := Batalla.new()
	batalla.depredador = nuevo_depredador
	batalla.premio = nuevo_premio
	batalla.zona_id = nueva_zona_id
	batalla.tipo_fondo = fondo
	padre.add_child(batalla)
	return batalla


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_preguntas = PreguntasBatalla.para(depredador)
	_construir()
	_dialogo(_presentacion(), _elegir_equipo)


# --- Interfaz ---------------------------------------------------------------------------------

func _construir() -> void:
	var fondo := TextureRect.new()
	var ruta := "res://dataset/fondos/%s.svg" % tipo_fondo
	if ResourceLoader.exists(ruta):
		fondo.texture = load(ruta)
	fondo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fondo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fondo.modulate = Color(0.75, 0.7, 0.75)
	add_child(fondo)
	var tinte := ColorRect.new()
	tinte.color = Color(0.3, 0.04, 0.1, 0.35)   # ambiente de emboscada
	tinte.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(tinte)

	var titulo := _etiqueta("¡Emboscada!", 40, ROJO)
	titulo.autowrap_mode = TextServer.AUTOWRAP_OFF
	titulo.position = Vector2(32, 28)
	titulo.add_theme_color_override("font_outline_color", Color.BLACK)
	titulo.add_theme_constant_override("outline_size", 10)
	add_child(titulo)

	# Depredador: tarjeta con su vida arriba a la izquierda y la imagen a la derecha
	var tarjeta := _tarjeta_vida(depredador.nombre_comun, VIDA_DEPREDADOR, ROJO)
	tarjeta.position = Vector2(32, 100)
	add_child(tarjeta)
	_barra_depredador = tarjeta.get_child(1)
	_img_depredador = _imagen(depredador.imagen_mapa(), Vector2(300, 300))
	_img_depredador.position = Vector2(390, 120)
	_img_depredador.pivot_offset = Vector2(150, 150)
	add_child(_img_depredador)

	# El insecto especial atrapado, en una burbuja junto al depredador
	_img_premio = PanelContainer.new()
	var burbuja := StyleBoxFlat.new()
	burbuja.bg_color = Color(1, 1, 1, 0.85)
	burbuja.set_corner_radius_all(70)
	burbuja.border_color = DORADO
	burbuja.set_border_width_all(5)
	_img_premio.add_theme_stylebox_override("panel", burbuja)
	_img_premio.add_child(_imagen(premio.obtener_imagen(), Vector2(130, 130)))
	_img_premio.position = Vector2(220, 260)
	_img_premio.pivot_offset = Vector2(70, 70)
	add_child(_img_premio)
	_atrapado = _etiqueta("Atrapado", 20, DORADO)
	_atrapado.autowrap_mode = TextServer.AUTOWRAP_OFF
	_atrapado.position = Vector2(236, 410)
	add_child(_atrapado)

	# Insecto del jugador (aparece al empezar el combate)
	_img_insecto = _imagen(null, Vector2(240, 240))
	_img_insecto.position = Vector2(40, 470)
	_img_insecto.pivot_offset = Vector2(120, 120)
	_img_insecto.hide()
	add_child(_img_insecto)
	_tarjeta_insecto = _tarjeta_vida("", VIDA_INSECTO, VERDE)
	_tarjeta_insecto.position = Vector2(300, 560)
	_tarjeta_insecto.hide()
	add_child(_tarjeta_insecto)
	_nombre_insecto = _tarjeta_insecto.get_child(0)
	_barra_insecto = _tarjeta_insecto.get_child(1)

	# Panel de abajo
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 20
	panel.offset_right = -20
	panel.offset_top = -480
	panel.offset_bottom = -20
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN   # si el contenido no cabe, crece hacia arriba
	add_child(panel)
	var margen := MarginContainer.new()
	for lado in ["left", "right", "top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 22)
	panel.add_child(margen)
	_caja = VBoxContainer.new()
	_caja.add_theme_constant_override("separation", 12)
	margen.add_child(_caja)

	# El depredador entra desde la derecha
	_img_depredador.position.x += 400
	create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT) \
		.tween_property(_img_depredador, "position:x", 390.0, 0.6)


func _tarjeta_vida(nombre: String, maximo: int, color: Color) -> VBoxContainer:
	var tarjeta := VBoxContainer.new()
	tarjeta.custom_minimum_size = Vector2(360, 0)
	var etiqueta := _etiqueta(nombre, 28, Color.WHITE)
	etiqueta.add_theme_color_override("font_outline_color", Color.BLACK)
	etiqueta.add_theme_constant_override("outline_size", 8)
	tarjeta.add_child(etiqueta)
	var barra := ProgressBar.new()
	barra.custom_minimum_size = Vector2(0, 28)
	barra.max_value = maximo
	barra.value = maximo
	barra.show_percentage = false
	var lleno := StyleBoxFlat.new()
	lleno.bg_color = color
	lleno.set_corner_radius_all(14)
	var vacio := StyleBoxFlat.new()
	vacio.bg_color = Color(0, 0, 0, 0.55)
	vacio.set_corner_radius_all(14)
	vacio.border_color = Color.WHITE
	vacio.set_border_width_all(2)
	barra.add_theme_stylebox_override("fill", lleno)
	barra.add_theme_stylebox_override("background", vacio)
	tarjeta.add_child(barra)
	return tarjeta


# --- 1. Presentación --------------------------------------------------------------------------

func _presentacion() -> Array:
	var nombre := depredador.nombre_comun
	var frase := "Buscando comida encontré un insecto muy especial."
	match depredador.tipo:
		Especie.Tipo.AVE: frase = "Desde el aire vi a todos tus insectos… y atrapé uno muy especial."
		Especie.Tipo.ANFIBIO: frase = "Mi lengua pegajosa nunca falla: mira el insecto especial que atrapé."
		Especie.Tipo.MAMIFERO: frase = "Husmeando entre la hierba encontré un insecto muy especial."
	return [
		[nombre, "¡Alto ahí, explorador! Aquí %s, de la banda de depredadores del humedal." % nombre],
		[nombre, "%s Tengo atrapado: %s. ¡Si lo quieres, demuestra cuánto sabes!" % [frase, premio.nombre_comun]],
		[GUIA, "Los depredadores no son malos: comen para vivir y así mantienen el equilibrio del humedal. Pero podemos rescatar a %s." % premio.nombre_comun],
		[GUIA, "Elige hasta %d de tus insectos. Cada respuesta correcta lanza un poder; cada error le da un ataque al depredador. Acierta %d veces para ganar." % [MAX_EQUIPO, VIDA_DEPREDADOR]],
	]


func _dialogo(lineas: Array, al_terminar: Callable, indice := 0) -> void:
	_limpiar()
	var hablante: String = lineas[indice][0]
	_caja.add_child(_etiqueta(hablante, 26, DORADO if hablante == GUIA else ROJO))
	_caja.add_child(_etiqueta(lineas[indice][1], 30, Color.WHITE))
	_caja.add_child(_espacio())
	if indice + 1 < lineas.size():
		_caja.add_child(_boton("Siguiente ▸", _dialogo.bind(lineas, al_terminar, indice + 1)))
	else:
		_caja.add_child(_boton("Continuar ▸", al_terminar))


# --- 2. Elegir equipo -------------------------------------------------------------------------

func _elegir_equipo() -> void:
	_limpiar()
	var capturados := RegistroEspecies.especies.filter(func(e: Especie) -> bool:
		return e.es_capturable() and RegistroEspecies.esta_capturada(e.id))
	if capturados.is_empty():
		_caja.add_child(_etiqueta("Aún no tienes insectos. Captura alguno con la cámara y vuelve a enfrentar al depredador.", 28, Color.WHITE))
		_caja.add_child(_espacio())
		_caja.add_child(_boton("Volver al mapa", _terminar.bind(false)))
		return

	_caja.add_child(_etiqueta("Elige tu equipo (hasta %d)" % MAX_EQUIPO, 28, DORADO))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_caja.add_child(scroll)
	var grilla := GridContainer.new()
	grilla.columns = 3
	grilla.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grilla.add_theme_constant_override("h_separation", 10)
	grilla.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grilla)

	var pelear := _boton("¡A pelear!", _empezar_combate)
	pelear.disabled = true
	var seleccion: Array[Especie] = []
	for especie in capturados:
		var opcion := Button.new()
		opcion.toggle_mode = true
		opcion.custom_minimum_size = Vector2(0, 170)
		opcion.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		opcion.icon = especie.obtener_imagen()
		opcion.expand_icon = true
		opcion.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		opcion.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		opcion.text = especie.nombre_comun
		opcion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		opcion.add_theme_font_size_override("font_size", 18)
		opcion.toggled.connect(func(activo: bool) -> void:
			if activo and seleccion.size() >= MAX_EQUIPO:
				opcion.set_pressed_no_signal(false)
				return
			if activo:
				seleccion.append(especie)
			else:
				seleccion.erase(especie)
			opcion.modulate = VERDE if activo else Color.WHITE
			pelear.disabled = seleccion.is_empty()
			_equipo = seleccion.duplicate())
		grilla.add_child(opcion)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	var huir := _boton("Huir", _terminar.bind(false))
	huir.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pelear.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(huir)
	fila.add_child(pelear)
	_caja.add_child(fila)


# --- 3. Combate -------------------------------------------------------------------------------

func _empezar_combate() -> void:
	_actual = 0
	_entrar_insecto()
	_siguiente_pregunta()


func _entrar_insecto() -> void:
	var insecto := _equipo[_actual]
	_vida_insecto = VIDA_INSECTO
	_img_insecto.texture = insecto.obtener_imagen()
	_img_insecto.modulate = Color.WHITE
	_img_insecto.rotation = 0.0
	_img_insecto.show()
	_tarjeta_insecto.show()
	_nombre_insecto.text = insecto.nombre_comun
	_barra_insecto.value = VIDA_INSECTO
	_img_insecto.position.x = -260
	create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT) \
		.tween_property(_img_insecto, "position:x", 40.0, 0.5)


func _siguiente_pregunta() -> void:
	if _preguntas.is_empty():
		_preguntas = PreguntasBatalla.para(depredador)
	var pregunta: Dictionary = _preguntas.pop_front()
	_limpiar()
	_caja.add_child(_etiqueta("Pregunta · aciertos %d/%d" % [_aciertos, VIDA_DEPREDADOR], 22, DORADO))
	_caja.add_child(_etiqueta(pregunta.pregunta, 28, Color.WHITE))
	var botones: Array[Button] = []
	var orden := range(pregunta.opciones.size())
	orden.shuffle()
	for i in orden:
		var opcion := _boton(pregunta.opciones[i], Callable())
		opcion.custom_minimum_size.y = 58
		opcion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		opcion.add_theme_font_size_override("font_size", 22)
		opcion.set_meta("indice", i)
		botones.append(opcion)
		_caja.add_child(opcion)
	for boton in botones:
		boton.pressed.connect(_responder.bind(pregunta, boton.get_meta("indice"), botones))


func _responder(pregunta: Dictionary, elegida: int, botones: Array[Button]) -> void:
	var correcta: bool = elegida == pregunta.correcta
	for boton in botones:
		boton.mouse_filter = Control.MOUSE_FILTER_IGNORE   # no "disabled": se verían apagados
		boton.focus_mode = Control.FOCUS_NONE
		if boton.get_meta("indice") == pregunta.correcta:
			boton.modulate = VERDE
		elif boton.get_meta("indice") == elegida:
			boton.modulate = ROJO

	if correcta:
		_aciertos += 1
		_vida_depredador -= 1
		await _ataque_insecto()
		_animar_barra(_barra_depredador, _vida_depredador)
	else:
		_errores += 1
		_vida_insecto -= 1
		await _ataque_depredador()
		_animar_barra(_barra_insecto, _vida_insecto)

	_caja.add_child(_etiqueta(("¡Correcto! " if correcta else "No era esa. ") + pregunta.explicacion, 22,
		VERDE if correcta else Color(1, 0.8, 0.8)))
	if _vida_depredador <= 0:
		_caja.add_child(_boton("Continuar ▸", _victoria))
	elif _vida_insecto <= 0:
		_caja.add_child(_boton("Continuar ▸", _insecto_cansado))
	else:
		_caja.add_child(_boton("Siguiente pregunta ▸", _siguiente_pregunta))


func _insecto_cansado() -> void:
	var cansado := _equipo[_actual]
	var tween := create_tween().set_parallel()
	tween.tween_property(_img_insecto, "rotation", -1.2, 0.4)
	tween.tween_property(_img_insecto, "modulate:a", 0.0, 0.4)
	await tween.finished
	if _actual + 1 >= _equipo.size():
		_derrota()
		return
	_actual += 1
	_dialogo([[GUIA, "¡%s está muy cansado! Entra %s." % [cansado.nombre_comun, _equipo[_actual].nombre_comun]]],
		func() -> void:
			_entrar_insecto()
			_siguiente_pregunta())


# --- 4. Final ---------------------------------------------------------------------------------

func _victoria() -> void:
	RegistroEspecies.registrar_batalla(depredador, premio, zona_id, true, _equipo, _aciertos, _errores)
	Recompensas.premiar_batalla(true, premio, zona_id)
	# El depredador se va y el insecto especial queda libre
	_atrapado.hide()
	var tween := create_tween().set_parallel()
	tween.tween_property(_img_depredador, "position:y", -400.0, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(_img_premio, "position", Vector2(290, 200), 0.6)
	tween.tween_property(_img_premio, "scale", Vector2(1.5, 1.5), 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_destellos(_img_premio.position + Vector2(70, 70), DORADO)
	_limpiar()
	_caja.add_child(_etiqueta("¡Ganaste!", 40, DORADO))
	_caja.add_child(_etiqueta("%s soltó a %s. Ahora está en tu Bioentdex." % [depredador.nombre_comun, premio.nombre_comun], 28, Color.WHITE))
	_caja.add_child(_espacio())
	_caja.add_child(_boton("Ver al insecto rescatado", func() -> void:
		var ficha := FichaEspecie.mostrar(self, premio, "¡Insecto rescatado!")
		ficha.cerrada.connect(_terminar.bind(true))))


func _derrota() -> void:
	RegistroEspecies.registrar_batalla(depredador, premio, zona_id, false, _equipo, _aciertos, _errores)
	Recompensas.premiar_batalla(false, premio, zona_id)
	_limpiar()
	_caja.add_child(_etiqueta("El depredador ganó esta vez", 34, ROJO))
	_caja.add_child(_etiqueta("%s se fue con %s. ¡Repasa lo aprendido y vuelve a intentarlo cuando aparezca otro globo!" % [depredador.nombre_comun, premio.nombre_comun], 26, Color.WHITE))
	_caja.add_child(_espacio())
	_caja.add_child(_boton("Volver al mapa", _terminar.bind(true)))


func _terminar(peleo: bool) -> void:
	terminada.emit(peleo)
	queue_free()


# --- Animaciones ------------------------------------------------------------------------------

func _ataque_insecto() -> void:
	var insecto := _equipo[_actual]
	_texto_flotante("¡%s!" % PODERES.get(insecto.id, "Ataque sorpresa"), _img_insecto.position + Vector2(0, -40), DORADO)
	await _embestida(_img_insecto, Vector2(40, -20))
	await _proyectil(_centro(_img_insecto), _centro(_img_depredador), DORADO)
	_golpe(_img_depredador)


func _ataque_depredador() -> void:
	_texto_flotante("¡%s!" % ATAQUES.get(depredador.tipo, "Ataque"), _img_depredador.position + Vector2(0, -40), ROJO)
	await _embestida(_img_depredador, Vector2(-40, 20))
	await _proyectil(_centro(_img_depredador), _centro(_img_insecto), ROJO)
	_golpe(_img_insecto)


func _embestida(nodo: Control, hacia: Vector2) -> void:
	var inicio := nodo.position
	var tween := create_tween()
	tween.tween_property(nodo, "position", inicio + hacia, 0.12)
	tween.tween_property(nodo, "position", inicio, 0.15)
	await tween.finished


func _proyectil(desde: Vector2, hasta: Vector2, color: Color) -> void:
	var bola := Panel.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = color
	estilo.set_corner_radius_all(30)
	estilo.border_color = Color.WHITE
	estilo.set_border_width_all(4)
	estilo.shadow_color = Color(color, 0.6)
	estilo.shadow_size = 16
	bola.add_theme_stylebox_override("panel", estilo)
	bola.size = Vector2(60, 60)
	bola.position = desde - bola.size / 2.0
	bola.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bola)
	var tween := create_tween()
	tween.tween_property(bola, "position", hasta - bola.size / 2.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	bola.queue_free()
	_destellos(hasta, color)


## Sacudida y destello rojo del que recibe el golpe.
func _golpe(nodo: Control) -> void:
	var inicio := nodo.position
	var tween := create_tween()
	nodo.modulate = Color(1, 0.4, 0.4)
	for i in 4:
		tween.tween_property(nodo, "position:x", inicio.x + (12.0 if i % 2 == 0 else -12.0), 0.05)
	tween.tween_property(nodo, "position:x", inicio.x, 0.05)
	tween.tween_property(nodo, "modulate", Color.WHITE, 0.2)


func _animar_barra(barra: ProgressBar, valor: int) -> void:
	create_tween().tween_property(barra, "value", float(maxi(valor, 0)), 0.4)


func _destellos(posicion: Vector2, color: Color) -> void:
	var chispas := CPUParticles2D.new()
	chispas.position = posicion
	chispas.amount = 24
	chispas.one_shot = true
	chispas.explosiveness = 1.0
	chispas.lifetime = 0.7
	chispas.spread = 180.0
	chispas.initial_velocity_min = 150.0
	chispas.initial_velocity_max = 350.0
	chispas.gravity = Vector2(0, 300)
	chispas.scale_amount_min = 5.0
	chispas.scale_amount_max = 10.0
	chispas.color = color
	add_child(chispas)
	chispas.emitting = true
	get_tree().create_timer(1.0).timeout.connect(chispas.queue_free)


func _texto_flotante(texto: String, posicion: Vector2, color: Color) -> void:
	var etiqueta := _etiqueta(texto, 32, color)
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_OFF
	etiqueta.add_theme_color_override("font_outline_color", Color.BLACK)
	etiqueta.add_theme_constant_override("outline_size", 10)
	etiqueta.position = posicion
	etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(etiqueta)
	var tween := create_tween()
	tween.tween_property(etiqueta, "position:y", posicion.y - 60.0, 1.0)
	tween.parallel().tween_property(etiqueta, "modulate:a", 0.0, 1.0).set_delay(0.5)
	tween.tween_callback(etiqueta.queue_free)


# --- Utilidades -------------------------------------------------------------------------------

func _centro(nodo: Control) -> Vector2:
	return nodo.position + nodo.size / 2.0


func _imagen(textura: Texture2D, tamano: Vector2) -> TextureRect:
	var imagen := TextureRect.new()
	imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE   # antes de la textura: si no, toma su tamaño
	imagen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	imagen.texture = textura
	imagen.custom_minimum_size = tamano
	imagen.size = tamano
	imagen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return imagen


func _limpiar() -> void:
	for hijo in _caja.get_children():
		_caja.remove_child(hijo)
		hijo.queue_free()


func _espacio() -> Control:
	var espacio := Control.new()
	espacio.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return espacio


func _boton(texto: String, accion: Callable) -> Button:
	var boton := Button.new()
	boton.text = texto
	boton.custom_minimum_size = Vector2(0, 68)
	boton.add_theme_font_size_override("font_size", 26)
	if accion.is_valid():
		boton.pressed.connect(accion)
	return boton


func _etiqueta(texto: String, tamano: int, color: Color) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etiqueta.add_theme_font_size_override("font_size", tamano)
	etiqueta.add_theme_color_override("font_color", color)
	return etiqueta
