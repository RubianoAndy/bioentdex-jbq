class_name DueloCombate3D
extends Control
## Duelo educativo, no letal. Cada especie se ve con su modelo 3D (ModelosEspecies: el hecho a
## mano en animales/modelos/<id>.glb o, si no hay, el generado); el prototipo geométrico queda
## solo para especies sin modelo.

signal resultado(gano: bool, aciertos: int, errores: int, equipo_final: int)

const MODELO_PROTOTIPO := preload("res://retos/modelo_duelo_prototipo.tscn")
const MAX_VIDA_JUGADOR := 2
const TAMANO_INSECTO := 1.7      # medida mayor del modelo en la arena
const TAMANO_DEPREDADOR := 2.5
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
var _modelo_jugador: Node3D
var _modelo_oponente: Node3D
var _tiempo_reposo := 0.0
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
	# Sin foco de teclado: si no, Espacio "presiona" el último botón tocado y la esquiva no llega
	_boton_esquiva.focus_mode = Control.FOCUS_NONE
	for boton in _botones_habilidad:
		boton.focus_mode = Control.FOCUS_NONE
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
	_tiempo_reposo += _delta
	_animar_reposo(_modelo_jugador, 0.0)
	_animar_reposo(_modelo_oponente, 1.4)
	if _boton_esquiva.visible:
		_carga_esquiva.value = _esquiva.restante
		_etiqueta_turno.text = "Ventana de evasión · %.1f s" % _esquiva.restante


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		_esquiva.esquivar()
		get_viewport().set_input_as_handled()   # Espacio también es "aceptar": que no llegue al mapa


func _configurar_actores() -> void:
	var punto_jugador: Marker3D = _arena.get_node("PlayerSpawn")
	var punto_oponente: Marker3D = _arena.get_node("OpponentSpawn")
	_actor_jugador = _instanciar_actor(equipo[equipo_actual], modelo_jugador, punto_jugador, TAMANO_INSECTO)
	_actor_oponente = _instanciar_actor(depredador, modelo_oponente, punto_oponente, TAMANO_DEPREDADOR)
	_mirarse()
	_modelo_jugador = _actor_jugador.get_node("MovimientoSuave")
	_modelo_oponente = _actor_oponente.get_node("MovimientoSuave")
	_actualizar_tinte_ecologico()


func _animar_reposo(modelo: Node3D, fase: float) -> void:
	if not is_instance_valid(modelo):
		return
	modelo.position.y = sin(_tiempo_reposo * 1.7 + fase) * 0.035
	modelo.rotation.z = sin(_tiempo_reposo * 0.9 + fase) * 0.035
	modelo.rotation.y = sin(_tiempo_reposo * 0.65 + fase) * 0.06


func _instanciar_actor(especie: Especie, escena: PackedScene, punto: Marker3D, tamano: float) -> Node3D:
	var actor := Node3D.new()
	actor.name = "ActorDuelo"
	punto.add_child(actor)
	var sombra := MeshInstance3D.new()
	var forma_sombra := CylinderMesh.new()
	forma_sombra.top_radius = 0.46
	forma_sombra.bottom_radius = 0.46
	forma_sombra.height = 0.012
	forma_sombra.radial_segments = 16
	sombra.mesh = forma_sombra
	sombra.position.y = 0.07
	sombra.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material_sombra := StandardMaterial3D.new()
	material_sombra.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material_sombra.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material_sombra.albedo_color = Color(0.08, 0.12, 0.07, 0.32)
	sombra.material_override = material_sombra
	actor.add_child(sombra)
	var movimiento := Node3D.new()
	movimiento.name = "MovimientoSuave"
	actor.add_child(movimiento)

	# Modelo de la especie; el prototipo solo si se asignó otra escena a mano o no hay modelo
	var actor_modelo: Node3D = null
	if escena and escena != MODELO_PROTOTIPO:
		actor_modelo = escena.instantiate() as Node3D
	if actor_modelo == null:
		actor_modelo = ModelosEspecies.crear(especie, tamano)
	if actor_modelo == null:
		actor_modelo = MODELO_PROTOTIPO.instantiate() as Node3D
	actor_modelo.position = Vector3.ZERO
	movimiento.add_child(actor_modelo)
	return actor


## Los dos animales se miran, girados un poco hacia la cámara para que se vean de tres cuartos.
func _mirarse() -> void:
	for par in [[_actor_jugador, _actor_oponente], [_actor_oponente, _actor_jugador]]:
		var hacia: Vector3 = par[1].global_position - par[0].global_position
		var angulo := atan2(hacia.x, hacia.z)   # los modelos miran a +Z
		par[0].rotation.y = lerp_angle(angulo, 0.0, 0.35)


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
	var tema_banco: String = str(HABILIDADES[indice]) if not candidatas.is_empty() else "general"
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
	_panel_pregunta.hide()   # si había otra pregunta abierta, se cierra al usar la habilidad
	_vaciar_pregunta()
	_estado.cambiar(DueloEstado.Estado.ANIMACION)
	_etiqueta_turno.text = "%s ejecuta %s" % [equipo[equipo_actual].nombre_comun, NOMBRES_HABILIDAD[indice]]
	_feedback.text = "¡Habilidad ecológica activada!"
	await _animar_ataque(indice)
	if not _estado.activo():
		return
	vida_oponente = maxi(0, vida_oponente - 1)
	_animar_vida(_barra_oponente, vida_oponente)
	if vida_oponente <= 0:
		_finalizar(true)
		return
	_contraataque_oponente()


func _animar_ataque(indice: int) -> void:
	await _animar_rafaga(_actor_jugador, _actor_oponente, equipo[equipo_actual], indice)


func _animar_rafaga(atacante: Node3D, defensor: Node3D, especie: Especie, habilidad: int) -> void:
	if atacante == _actor_oponente:
		_camara.reaccionar(atacante, defensor)
	else:
		_camara.enfocar(atacante, defensor)
	var color := _color_rafaga(especie, habilidad)
	var origen := atacante.global_position + Vector3(0, 1.2, 0)
	var destino := defensor.global_position + Vector3(0, 1.2, 0)
	var proyectil := _crear_proyectil(color)
	_arena.add_child(proyectil)
	proyectil.global_position = origen
	var recorrido := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	recorrido.tween_property(proyectil, "global_position", destino, 0.52)
	recorrido.parallel().tween_property(proyectil, "rotation:y", TAU, 0.52)
	await recorrido.finished
	proyectil.queue_free()
	_crear_particulas(destino, color)
	var escala_original := defensor.scale
	var impacto := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	impacto.tween_property(defensor, "scale", escala_original * Vector3(1.08, 0.92, 1.08), 0.1)
	impacto.tween_property(defensor, "scale", escala_original, 0.14)
	await impacto.finished
	_camara.restablecer()


func _crear_proyectil(color: Color) -> Node3D:
	var proyectil := Node3D.new()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color

	var nucleo := MeshInstance3D.new()
	var esfera_nucleo := SphereMesh.new()
	esfera_nucleo.radius = 0.17
	esfera_nucleo.height = 0.34
	esfera_nucleo.radial_segments = 8
	esfera_nucleo.rings = 4
	nucleo.mesh = esfera_nucleo
	nucleo.material_override = material
	proyectil.add_child(nucleo)

	for indice in 5:
		var perla := MeshInstance3D.new()
		var esfera_perla := SphereMesh.new()
		esfera_perla.radius = 0.065
		esfera_perla.height = 0.13
		esfera_perla.radial_segments = 6
		esfera_perla.rings = 3
		perla.mesh = esfera_perla
		perla.material_override = material
		var angulo := TAU * float(indice) / 5.0
		perla.position = Vector3(cos(angulo) * 0.22, sin(angulo) * 0.18, 0)
		proyectil.add_child(perla)
	return proyectil


func _color_rafaga(especie: Especie, habilidad: int) -> Color:
	if habilidad == 0:
		return Color(1.0, 0.74, 0.22)
	if habilidad == 1:
		return Color(0.35, 0.92, 0.58)
	match especie.tipo:
		Especie.Tipo.PEZ, Especie.Tipo.ANFIBIO:
			return Color(0.25, 0.78, 1.0)
		Especie.Tipo.AVE:
			return Color(0.68, 0.88, 1.0)
		Especie.Tipo.INSECTO:
			return Color(1.0, 0.64, 0.24)
		Especie.Tipo.MAMIFERO:
			return Color(1.0, 0.47, 0.3)
		Especie.Tipo.REPTIL:
			return Color(0.68, 0.9, 0.3)
	return Color(0.92, 0.84, 0.55)


func _crear_particulas(posicion: Vector3, color: Color) -> void:
	var particulas := GPUParticles3D.new()
	var material := ParticleProcessMaterial.new()
	material.color = color
	material.direction = Vector3(0, 1, 0)
	material.spread = 180.0
	material.initial_velocity_min = 0.8
	material.initial_velocity_max = 2.8
	material.gravity = Vector3.ZERO
	particulas.process_material = material
	var esfera := SphereMesh.new()
	esfera.radius = 0.08
	esfera.height = 0.16
	esfera.radial_segments = 6
	esfera.rings = 3
	var brillo := StandardMaterial3D.new()
	brillo.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	brillo.albedo_color = color
	brillo.emission_enabled = true
	brillo.emission = color
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
	await _animar_rafaga(_actor_oponente, _actor_jugador, depredador, -1)
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
		_actor_jugador = _instanciar_actor(equipo[equipo_actual], modelo_jugador, punto, TAMANO_INSECTO)
		_modelo_jugador = _actor_jugador.get_node("MovimientoSuave")
		_mirarse()
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
	# El color ecológico va en un anillo en el suelo: así el modelo conserva sus colores reales
	var color := base.lerp(Color.WHITE, 0.35)
	var anillo := _actor_jugador.get_node_or_null("AnilloEcologico") as MeshInstance3D
	if anillo == null:
		anillo = MeshInstance3D.new()
		anillo.name = "AnilloEcologico"
		var toro := TorusMesh.new()
		toro.inner_radius = 0.62
		toro.outer_radius = 0.74
		toro.rings = 32
		toro.ring_segments = 6
		anillo.mesh = toro
		anillo.position.y = 0.09
		anillo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_actor_jugador.add_child(anillo)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	anillo.material_override = material


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
