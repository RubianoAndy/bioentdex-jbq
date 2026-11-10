class_name DueloCombate3D
extends Control
## Duelo educativo, no letal, con modelos geométricos de reemplazo.

signal resultado(gano: bool, aciertos: int, errores: int, equipo_final: int)

const MODELO_PROTOTIPO := preload("res://retos/modelo_duelo_prototipo.tscn")
const MAX_VIDA_JUGADOR := 2
const VENTANA_ESQUIVA := 2.4
const HABILIDADES := ["polen", "control"]
const NOMBRES_HABILIDAD := ["Pulso de Polen", "Control Biológico"]
const VERDE := Color(0.35, 0.9, 0.55)
const ROJO := Color(0.95, 0.35, 0.32)

@export var modelo_jugador: PackedScene = MODELO_PROTOTIPO
@export var modelo_oponente: PackedScene = MODELO_PROTOTIPO

var equipo: Array[Especie] = []
var depredador: Especie
var preguntas: Array = []
var vida_oponente := 3
var aciertos := 0
var errores := 0
var equipo_actual := 0

var _vida_jugador := MAX_VIDA_JUGADOR
var _cargas := [0, 0]
var _pregunta_actual := {}
var _estado := DueloEstado.new()
var _actor_jugador: Node3D
var _actor_oponente: Node3D
var _barra_jugador: ProgressBar
var _barra_oponente: ProgressBar
var _etiqueta_jugador: Label
var _atributos_jugador: Label
var _opciones: VBoxContainer
var _botones_habilidad: Array[Button] = []

@onready var _arena: Node3D = $Vista3D/SubViewport/Arena
@onready var _camara: DueloCamara3D = $Vista3D/SubViewport/Arena/CameraRig
@onready var _fila_rivales: HBoxContainer = $HUD/FilaRivales
@onready var _etiqueta_turno: Label = $HUD/EtiquetaTurno
@onready var _panel_pregunta: PanelContainer = $HUD/Pregunta
@onready var _boton_esquiva: Button = $Esquivar
@onready var _carga_esquiva: ProgressBar = $CargaEsquiva
@onready var _feedback: Label = $Feedback
@onready var _esquiva: DueloEsquiva = $DueloEsquiva


func _ready() -> void:
	if equipo.is_empty() or equipo_actual >= equipo.size() or depredador == null:
		push_error("DueloCombate3D requiere un rival y al menos una especie para el equipo.")
		queue_free()
		return
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_esquiva.resuelta.connect(_resolver_esquiva)
	_boton_esquiva.pressed.connect(_esquiva.esquivar)
	_botones_habilidad = [$Acciones/HabilidadPolinizacion, $Acciones/HabilidadRegulacion]
	for indice in _botones_habilidad.size():
		_botones_habilidad[indice].pressed.connect(_pulsar_habilidad.bind(indice))
		_estilizar_habilidad(_botones_habilidad[indice], indice)
		_agregar_indicador_carga(_botones_habilidad[indice])
	_opciones = $HUD/Pregunta/Contenido
	_configurar_actores()
	_configurar_barras()
	_actualizar_hud()
	_camara.restablecer()
	_estado.cambiar(DueloEstado.Estado.PREGUNTA)


func _process(_delta: float) -> void:
	if _boton_esquiva.visible:
		_carga_esquiva.value = _esquiva.restante
		_etiqueta_turno.text = "Ventana de evasión · %.1f s" % _esquiva.restante


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		_esquiva.esquivar()


func _configurar_actores() -> void:
	var punto_jugador: Marker3D = _arena.get_node("PlayerSpawn")
	var punto_oponente: Marker3D = _arena.get_node("OpponentSpawn")
	_actor_jugador = _instanciar_actor(modelo_jugador, punto_jugador, Color.WHITE)
	_actor_oponente = _instanciar_actor(modelo_oponente, punto_oponente, Color(1.0, 0.72, 0.62))
	_actualizar_tinte_ecologico()


func _instanciar_actor(escena: PackedScene, punto: Marker3D, tinte: Color) -> Node3D:
	var actor := (escena if escena else MODELO_PROTOTIPO).instantiate() as Node3D
	if actor == null:
		push_error("El modelo del duelo debe tener una raíz Node3D.")
		return Node3D.new()
	punto.add_child(actor)
	actor.position = Vector3.ZERO
	for nodo in actor.find_children("*", "MeshInstance3D", true, false):
		var malla := nodo as MeshInstance3D
		var material := StandardMaterial3D.new()
		material.albedo_color = tinte
		material.roughness = 0.7
		malla.material_override = material
	return actor


func _configurar_barras() -> void:
	var tarjeta_jugador := _crear_barra(
		equipo[equipo_actual].nombre_comun, MAX_VIDA_JUGADOR, VERDE, equipo[equipo_actual])
	var tarjeta_oponente := _crear_barra(depredador.nombre_comun, vida_oponente, ROJO)
	_fila_rivales.add_child(tarjeta_jugador)
	_fila_rivales.add_child(_espaciador_horizontal())
	_fila_rivales.add_child(tarjeta_oponente)
	_etiqueta_jugador = tarjeta_jugador.get_child(0)
	_barra_jugador = tarjeta_jugador.get_child(1)
	_atributos_jugador = tarjeta_jugador.get_child(2)
	_barra_oponente = tarjeta_oponente.get_child(1)


func _crear_barra(nombre: String, maximo: int, color: Color, especie: Especie = null) -> VBoxContainer:
	var caja := VBoxContainer.new()
	caja.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var etiqueta := Label.new()
	etiqueta.text = nombre
	etiqueta.add_theme_font_size_override("font_size", 22)
	etiqueta.add_theme_color_override("font_color", Color.WHITE)
	etiqueta.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	etiqueta.add_theme_constant_override("outline_size", 4)
	caja.add_child(etiqueta)
	var barra := ProgressBar.new()
	barra.custom_minimum_size = Vector2(0, 22)
	barra.max_value = maximo
	barra.value = maximo
	barra.show_percentage = false
	barra.add_theme_stylebox_override("fill", _estilo_barra(color))
	barra.add_theme_stylebox_override("background", _estilo_barra(Color(0.08, 0.12, 0.1, 0.9)))
	caja.add_child(barra)
	if especie:
		var atributos := Label.new()
		atributos.text = "IA %d · RH %d · VP %d" % [
			roundi(especie.impacto_ecologico),
			roundi(especie.resistencia_habitat),
			roundi(especie.vitalidad_poblacional)]
		atributos.tooltip_text = "IA: Impacto Ecológico · RH: Resistencia al Hábitat · VP: Vitalidad Poblacional"
		atributos.add_theme_font_size_override("font_size", 15)
		atributos.add_theme_color_override("font_color", Color(0.9, 0.95, 0.91))
		caja.add_child(atributos)
	return caja


func _estilo_barra(color: Color) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = color
	estilo.set_corner_radius_all(10)
	return estilo


func _espaciador_horizontal() -> Control:
	var espacio := Control.new()
	espacio.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return espacio


func _estilizar_habilidad(boton: Button, indice: int) -> void:
	boton.custom_minimum_size = Vector2(210, 210)
	boton.add_theme_stylebox_override("normal", _estilo_circular(
		Color(0.18, 0.45, 0.33, 0.96) if indice == 0 else Color(0.23, 0.36, 0.58, 0.96)))
	boton.add_theme_stylebox_override("hover", _estilo_circular(Color(0.35, 0.6, 0.48)))
	boton.add_theme_stylebox_override("pressed", _estilo_circular(Color(0.12, 0.3, 0.24)))
	boton.add_theme_stylebox_override("disabled", _estilo_circular(Color(0.22, 0.24, 0.24)))
	boton.add_theme_color_override("font_color", Color.WHITE)
	boton.add_theme_color_override("font_disabled_color", Color(0.75, 0.78, 0.76))
	boton.tooltip_text = "Responde una pregunta ecológica para cargar y luego activa esta habilidad."


func _estilo_circular(color: Color) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = color
	estilo.border_color = Color(0.88, 0.94, 0.88)
	estilo.set_border_width_all(4)
	estilo.set_corner_radius_all(110)
	estilo.set_content_margin_all(22)
	estilo.shadow_color = Color(0, 0, 0, 0.35)
	estilo.shadow_size = 8
	return estilo


func _agregar_indicador_carga(boton: Button) -> void:
	var carga := ProgressBar.new()
	carga.name = "IndicadorCarga"
	carga.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	carga.offset_left = 22
	carga.offset_right = -22
	carga.offset_top = -27
	carga.offset_bottom = -14
	carga.mouse_filter = Control.MOUSE_FILTER_IGNORE
	carga.max_value = 100
	carga.value = 0
	carga.show_percentage = false
	carga.add_theme_stylebox_override("fill", _estilo_barra(Color(0.9, 0.86, 0.47)))
	carga.add_theme_stylebox_override("background", _estilo_barra(Color(0.08, 0.12, 0.1)))
	boton.add_child(carga)


func _pulsar_habilidad(indice: int) -> void:
	if not _estado.activo() or _estado.actual in [DueloEstado.Estado.ANIMACION, DueloEstado.Estado.ESQUIVA]:
		return
	if _cargas[indice] >= 100:
		_ejecutar_habilidad(indice)
	else:
		_mostrar_pregunta(indice)


func _mostrar_pregunta(indice: int) -> void:
	_preguntas_si_vacias()
	if preguntas.is_empty():
		_feedback.text = "No hay preguntas de relaciones ecológicas disponibles."
		return
	var candidatas: Array = preguntas.filter(func(p: Dictionary) -> bool: return p.habilidad == HABILIDADES[indice])
	if candidatas.is_empty():
		candidatas = preguntas
	var ids: Array[String] = []
	for candidata in candidatas:
		ids.append(PreguntasBatalla.id_estable(candidata))
	var tema_banco := HABILIDADES[indice] if candidatas.size() > 0 else "general"
	var id_pregunta := RegistroEspecies.siguiente_id_sin_repetir(
		"preguntas_batalla:duelo:%s" % tema_banco, ids)
	_pregunta_actual = {}
	for candidata in candidatas:
		if PreguntasBatalla.id_estable(candidata) == id_pregunta:
			_pregunta_actual = candidata
			break
	if _pregunta_actual.is_empty():
		push_error("Duelo: no se pudo seleccionar una pregunta del banco '%s'." % tema_banco)
		_feedback.text = "No se pudo cargar una pregunta ecológica."
		return
	preguntas.erase(_pregunta_actual)
	RegistroEspecies.registrar_pregunta_batalla(id_pregunta)
	_vaciar_pregunta()
	var titulo := Label.new()
	titulo.text = "%s · responde para cargar al 100%%" % NOMBRES_HABILIDAD[indice]
	titulo.add_theme_font_size_override("font_size", 22)
	titulo.add_theme_color_override("font_color", Color(0.88, 0.76, 0.35))
	_opciones.add_child(titulo)
	var enunciado := Label.new()
	enunciado.text = _pregunta_actual.pregunta
	enunciado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	enunciado.add_theme_font_size_override("font_size", 23)
	_opciones.add_child(enunciado)
	for opcion in _pregunta_actual.opciones.size():
		var boton := Button.new()
		boton.text = _pregunta_actual.opciones[opcion]
		boton.custom_minimum_size = Vector2(0, 52)
		boton.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		boton.add_theme_font_size_override("font_size", 19)
		boton.pressed.connect(_responder_pregunta.bind(indice, opcion))
		_opciones.add_child(boton)
	_panel_pregunta.show()
	_estado.cambiar(DueloEstado.Estado.PREGUNTA)


func _preguntas_si_vacias() -> void:
	if preguntas.is_empty():
		preguntas = PreguntasBatalla.relacionales()


func _responder_pregunta(indice: int, opcion: int) -> void:
	if _estado.actual != DueloEstado.Estado.PREGUNTA:
		return
	var correcta: bool = opcion == _pregunta_actual.correcta
	var tema := str(_pregunta_actual.get("tema", "general"))
	AnaliticaPedagogica.registrar_opcion_reto(tema, opcion)
	_panel_pregunta.hide()
	_vaciar_pregunta()
	if correcta:
		aciertos += 1
		_cargas[indice] = 100
		_actualizar_cargas()
		_etiqueta_turno.text = "Habilidad cargada · tócala otra vez para ejecutarla"
		_feedback.text = "¡Correcto! %s" % _pregunta_actual.explicacion
		FeedbackTactil.interaccion()
		_estado.cambiar(DueloEstado.Estado.HABILIDAD_CARGADA)
	else:
		errores += 1
		AnaliticaPedagogica.registrar_error_tema(tema)
		_feedback.text = "Todavía no: %s" % _pregunta_actual.explicacion
		_estado.cambiar(DueloEstado.Estado.ANIMACION)
		_contraataque_oponente()


func _vaciar_pregunta() -> void:
	for hijo in _opciones.get_children():
		hijo.queue_free()


func _actualizar_cargas() -> void:
	for indice in _botones_habilidad.size():
		var carga: ProgressBar = _botones_habilidad[indice].get_node("IndicadorCarga")
		carga.value = _cargas[indice]
		_botones_habilidad[indice].text = "%s\n%d%%" % [NOMBRES_HABILIDAD[indice], _cargas[indice]]


func _ejecutar_habilidad(indice: int) -> void:
	if _cargas[indice] < 100:
		return
	_cargas[indice] = 0
	_actualizar_cargas()
	_estado.cambiar(DueloEstado.Estado.ANIMACION)
	_etiqueta_turno.text = "%s ejecuta %s" % [equipo[equipo_actual].nombre_comun, NOMBRES_HABILIDAD[indice]]
	_feedback.text = "¡Habilidad ecológica activada!"
	await _animar_ataque()
	if not _estado.activo():
		return
	vida_oponente = maxi(0, vida_oponente - 1)
	_animar_vida(_barra_oponente, vida_oponente)
	if vida_oponente <= 0:
		_finalizar(true)
		return
	_contraataque_oponente()


func _animar_ataque() -> void:
	var origen := _actor_jugador.global_position
	var destino := _actor_oponente.global_position
	_camara.enfocar(_actor_jugador, _actor_oponente)
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_actor_jugador, "global_position", destino + Vector3(-0.7, 0, 0.6), 0.35)
	tween.tween_callback(_crear_particulas.bind(_actor_oponente.global_position + Vector3(0, 1.2, 0)))
	tween.tween_property(_actor_oponente, "scale", Vector3(0.84, 1.12, 0.84), 0.14)
	tween.tween_property(_actor_oponente, "scale", Vector3.ONE, 0.18)
	tween.tween_property(_actor_jugador, "global_position", origen, 0.3)
	await tween.finished
	_camara.restablecer()


func _crear_particulas(posicion: Vector3) -> void:
	var particulas := GPUParticles3D.new()
	var material := ParticleProcessMaterial.new()
	var especie := equipo[equipo_actual]
	material.color = Color(
		especie.impacto_ecologico / 100.0,
		especie.resistencia_habitat / 100.0,
		especie.vitalidad_poblacional / 100.0, 1.0)
	material.direction = Vector3(0, 1, 0)
	material.spread = 180.0
	material.initial_velocity_min = 1.4
	material.initial_velocity_max = 4.0
	material.gravity = Vector3(0, -2.0, 0)
	particulas.process_material = material
	var esfera := SphereMesh.new()
	esfera.radius = 0.08
	esfera.height = 0.16
	esfera.radial_segments = 6
	esfera.rings = 3
	var brillo := StandardMaterial3D.new()
	brillo.albedo_color = material.color
	brillo.emission_enabled = true
	brillo.emission = material.color
	esfera.material = brillo
	particulas.draw_pass_1 = esfera
	particulas.amount = 40
	particulas.lifetime = 0.8
	particulas.explosiveness = 0.9
	particulas.one_shot = true
	_arena.add_child(particulas)
	particulas.global_position = posicion
	particulas.emitting = true
	get_tree().create_timer(1.5).timeout.connect(particulas.queue_free)


func _contraataque_oponente() -> void:
	if vida_oponente <= 0:
		_finalizar(true)
		return
	_camara.reaccionar(_actor_oponente, _actor_jugador)
	var origen := _actor_oponente.global_position
	var embestida := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	embestida.tween_property(_actor_oponente, "global_position",
		_actor_jugador.global_position + Vector3(0.6, 0, -0.5), 0.3)
	embestida.tween_property(_actor_oponente, "global_position", origen, 0.25)
	await embestida.finished
	if not _estado.activo():
		return
	_etiqueta_turno.text = "Atención: ventana de evasión"
	_feedback.text = "Toca «¡Esquivar!» o pulsa Espacio antes de que termine el indicador."
	_boton_esquiva.show()
	_carga_esquiva.max_value = VENTANA_ESQUIVA
	_carga_esquiva.value = VENTANA_ESQUIVA
	_carga_esquiva.show()
	_estado.cambiar(DueloEstado.Estado.ESQUIVA)
	_esquiva.abrir(VENTANA_ESQUIVA)


func _resolver_esquiva(esquivo: bool) -> void:
	if _estado.actual != DueloEstado.Estado.ESQUIVA:
		return
	_boton_esquiva.hide()
	_carga_esquiva.hide()
	_estado.cambiar(DueloEstado.Estado.ANIMACION)
	if esquivo:
		_feedback.text = "¡Esquiva a tiempo! No recibes daño."
		await _animar_evasion()
	else:
		var adaptacion := equipo[equipo_actual].adaptacion_defensiva_documentada
		var mitigacion := equipo[equipo_actual].defensa_morfologica_qte
		if not adaptacion.is_empty() and randf() < mitigacion:
			_feedback.text = "La adaptación «%s» evita el impacto." % adaptacion
		else:
			_vida_jugador = maxi(0, _vida_jugador - 1)
			_feedback.text = "La ventana terminó. Recibes daño%s." % (
				" (sin adaptación defensiva documentada)" if adaptacion.is_empty() else "")
			_animar_vida(_barra_jugador, _vida_jugador)
			await _animar_golpe(_actor_jugador)
	if _vida_jugador <= 0:
		if equipo_actual + 1 >= equipo.size():
			_finalizar(false)
			return
		equipo_actual += 1
		_vida_jugador = MAX_VIDA_JUGADOR
		_actor_jugador.queue_free()
		var punto: Marker3D = _arena.get_node("PlayerSpawn")
		_actor_jugador = _instanciar_actor(modelo_jugador, punto, Color.WHITE)
		_actualizar_tinte_ecologico()
		_etiqueta_jugador.text = equipo[equipo_actual].nombre_comun
		_atributos_jugador.text = "IA %d · RH %d · VP %d" % [
			roundi(equipo[equipo_actual].impacto_ecologico),
			roundi(equipo[equipo_actual].resistencia_habitat),
			roundi(equipo[equipo_actual].vitalidad_poblacional)]
		_animar_vida(_barra_jugador, _vida_jugador)
		_feedback.text += " Entra %s con salud completa." % equipo[equipo_actual].nombre_comun
	_camara.restablecer()
	_estado.cambiar(DueloEstado.Estado.HABILIDAD_CARGADA if _cargas.has(100) else DueloEstado.Estado.PREGUNTA)


func _animar_evasion() -> void:
	var inicio := _actor_jugador.position
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_actor_jugador, "position", inicio + Vector3(-0.7, 0.2, 0.3), 0.2)
	tween.tween_property(_actor_jugador, "position", inicio, 0.24)
	await tween.finished


func _animar_golpe(actor: Node3D) -> void:
	var inicio := actor.position
	var tween := create_tween()
	for paso in 4:
		tween.tween_property(actor, "position:x", inicio.x + (0.13 if paso % 2 == 0 else -0.13), 0.05)
	tween.tween_property(actor, "position", inicio, 0.08)
	await tween.finished


func _actualizar_tinte_ecologico() -> void:
	var especie := equipo[equipo_actual]
	var base := Color(
		especie.impacto_ecologico / 100.0,
		especie.resistencia_habitat / 100.0,
		especie.vitalidad_poblacional / 100.0)
	var color := base.lerp(Color.WHITE, 0.35)
	for malla in _actor_jugador.find_children("*", "MeshInstance3D", true, false):
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		malla.material_override = material


func _actualizar_hud() -> void:
	_actualizar_cargas()
	_etiqueta_turno.text = "Relaciones del humedal · rival %d · equipo %d/%d" % [
		vida_oponente, equipo_actual + 1, equipo.size()]
	_boton_esquiva.hide()
	_carga_esquiva.hide()


func _animar_vida(barra: ProgressBar, valor: int) -> void:
	var porcentaje := float(valor) / barra.max_value
	var color := ROJO.lerp(VERDE, porcentaje)
	var estilo := _estilo_barra(color)
	barra.add_theme_stylebox_override("fill", estilo)
	create_tween().tween_property(barra, "value", valor, 0.35)


func _finalizar(gano: bool) -> void:
	if not _estado.cambiar(DueloEstado.Estado.FINALIZADO):
		return
	_boton_esquiva.hide()
	_carga_esquiva.hide()
	_panel_pregunta.hide()
	_etiqueta_turno.text = "Simulación completada" if gano else "Fin de la simulación"
	_feedback.text = "Duelo educativo no letal: las especies no se recolectan." if gano else "Puedes volver a intentarlo en otra batalla."
	resultado.emit(gano, aciertos, errores, equipo_actual)
	queue_free()
