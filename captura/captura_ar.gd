extends Control
## Vista de captura con la cámara (realidad aumentada sencilla): el insecto, tomado del dataset de
## imágenes (res://dataset/insectos/<id>/), aparece sobre la imagen de la cámara y revolotea.
## Hay que encuadrarlo en el visor y tomar la foto; mover el teléfono (giroscopio), arrastrar el dedo
## o, en el PC, mover el mouse cambia hacia dónde apunta la cámara.
## Sin insecto (especie = null) sirve para las misiones de foto.

signal terminada(capturado: bool)
signal foto_tomada(foto: Image)

const INTENTOS := 3
const RADIO_VISOR := 150.0
## Qué tan rápido revolotea cada insecto (1 = normal)
const RAPIDEZ := {"mosca_metalica": 1.6, "zancudo": 1.5, "libelula": 1.3, "sirfido": 1.2, "caballito_del_diablo": 1.1, "mariquita": 0.6, "hormiga": 0.6, "psocido": 0.5, "pececillo_plata": 0.8, "tijereta": 0.6}

@export_range(0.1, 3.0, 0.1) var sensibilidad_arrastre := 1.0
@export_range(0.0, 1500.0, 10.0) var sensibilidad_giroscopio := 700.0
@export_range(0.1, 20.0, 0.1) var suavizado_apuntado := 8.0
@export_range(0.0, 2.0, 0.05) var retorno_al_centro := 0.3
@export_range(0.1, 2.0, 0.1) var sensibilidad_mouse := 0.8
@export var sensibilidad_camara := 1.0

var especie: Especie            # null = misión de foto
var zona_id := ""
var tipo_fondo := "pradera"     # fondo simulado si no hay cámara: agua, pradera o bosque
var texto_mision := ""

var _intentos := INTENTOS
var _tiempo := 0.0
var _semilla := randf() * 100.0
var _apuntar := Vector2.ZERO    # desplazamiento de la escena al mover la cámara
var _apuntar_objetivo := Vector2.ZERO
var _bloqueado := false
var _camara := CamaraDispositivo.new()

@onready var fondo: TextureRect = $Fondo
@onready var insecto: TextureRect = $Insecto
@onready var visor: Control = $Visor
@onready var flash: ColorRect = $Flash
@onready var hud: Control = $HUD
@onready var estado: Label = $HUD/Estado
@onready var intentos: Label = $HUD/Intentos


func _ready() -> void:
	add_child(_camara)
	AudioManager.conectar_botones(self)
	visor.draw.connect(_dibujar_visor)
	$HUD/BtnVolver.pressed.connect(_terminar.bind(false))
	$HUD/BtnFoto.pressed.connect(_disparar)

	var ruta_fondo := "res://dataset/fondos/%s.svg" % tipo_fondo
	if ResourceLoader.exists(ruta_fondo):
		fondo.texture = load(ruta_fondo)

	if especie:
		var imagenes := especie.imagenes_dataset()
		insecto.texture = imagenes.pick_random() if not imagenes.is_empty() else especie.obtener_imagen()
		FeedbackTactil.aparicion_sorpresa()
		$HUD/Cartel/VBox/Nombre.text = especie.nombre_comun
		_actualizar_intentos()
	else:
		insecto.hide()
		intentos.hide()
		$HUD/Cartel/VBox/Nombre.text = "Misión de foto"
		$HUD/Cartel/VBox/Instruccion.text = texto_mision

	await _camara.iniciar(fondo)   # si no hay cámara se queda el fondo simulado


func _process(delta: float) -> void:
	_tiempo += delta
	_actualizar_apuntado(delta)
	if especie and not _bloqueado:
		var t := _tiempo * float(RAPIDEZ.get(especie.id, 1.0))
		var vuelo := Vector2(
			sin(t * 0.7 + _semilla) * 0.32 + sin(t * 1.9 + _semilla * 2.0) * 0.08,
			cos(t * 0.5 + _semilla * 1.3) * 0.25 + sin(t * 2.3) * 0.05) * size
		insecto.position = size / 2.0 + vuelo + _apuntar - insecto.size / 2.0
		insecto.rotation = sin(t * 3.0) * 0.12
	visor.queue_redraw()


func _gui_input(event: InputEvent) -> void:
	# Arrastrar el dedo también sirve para apuntar (por si el teléfono no tiene giroscopio)
	if event is InputEventScreenDrag:
		_apuntar_objetivo += event.relative * sensibilidad_arrastre


func _actualizar_apuntado(delta: float) -> void:
	if DisplayServer.is_touchscreen_available():
		_apuntar_objetivo += _camara.desplazamiento_giroscopio(
			delta, sensibilidad_giroscopio * sensibilidad_camara)
		_apuntar_objetivo = _apuntar_objetivo.lerp(Vector2.ZERO, minf(1.0, retorno_al_centro * delta))
	else:
		# En el PC el mouse hace de teléfono: la escena se mueve al contrario del mouse
		_apuntar_objetivo = -(get_local_mouse_position() - size / 2.0) \
			* sensibilidad_mouse * sensibilidad_camara
	var peso := 1.0 - exp(-suavizado_apuntado * delta)
	_apuntar = _apuntar.lerp(_apuntar_objetivo, peso)
	_apuntar_objetivo = _apuntar_objetivo.clamp(-size * 0.45, size * 0.45)
	_apuntar = _apuntar.clamp(-size * 0.45, size * 0.45)


func _en_visor() -> bool:
	var centro_insecto := insecto.position + insecto.size / 2.0
	return centro_insecto.distance_to(size / 2.0) < RADIO_VISOR * 0.8


func _calidad_foto() -> float:
	var centro_insecto := insecto.position + insecto.size / 2.0
	var distancia := centro_insecto.distance_to(size / 2.0)
	return clampf(1.0 - distancia / (RADIO_VISOR * 0.8), 0.0, 1.0)


func _dibujar_visor() -> void:
	var centro := size / 2.0
	var color := Color(0.4, 1.0, 0.5) if especie and _en_visor() else Color(1, 1, 1, 0.9)
	visor.draw_arc(centro, RADIO_VISOR, 0, TAU, 64, Color(0, 0, 0, 0.35), 10, true)
	visor.draw_arc(centro, RADIO_VISOR, 0, TAU, 64, color, 5, true)
	for angulo in [0.0, PI / 2.0, PI, PI * 1.5]:
		var dir := Vector2.from_angle(angulo)
		visor.draw_line(centro + dir * (RADIO_VISOR - 22), centro + dir * (RADIO_VISOR + 22), color, 5, true)


func _disparar() -> void:
	if _bloqueado:
		return
	FeedbackTactil.interaccion()
	if especie == null:
		_bloqueado = true
		AudioManager.reproducir_sfx("camara_obturador")
		foto_tomada.emit(await _tomar_foto())
		_terminar(true)
		return

	if _en_visor():
		_bloqueado = true
		var calidad_foto := _calidad_foto()
		AudioManager.reproducir_sfx("camara_obturador")
		var foto := await _tomar_foto()
		var captura := RegistroEspecies.registrar_captura(especie, zona_id, foto, calidad_foto)
		var ficha := FichaEspecie.new()
		ficha.mostrar(self, especie, "¡Capturaste un insecto!",
			ImageTexture.create_from_image(foto), captura)
		ficha.cerrada.connect(_terminar.bind(true))
		return

	_intentos -= 1
	_actualizar_intentos()
	_semilla += 2.0   # el insecto da un salto
	if _intentos > 0:
		_mostrar_estado("¡Se movió! Encuádralo en el círculo")
		return
	_bloqueado = true
	_mostrar_estado("Se escapó…")
	var huida := create_tween().set_parallel()
	huida.tween_property(insecto, "position", insecto.position + Vector2(size.x * 0.8, -size.y * 0.6), 0.8)
	huida.tween_property(insecto, "scale", Vector2(0.3, 0.3), 0.8)
	await huida.finished
	await get_tree().create_timer(0.8).timeout
	_terminar(false)


## Toma la foto de lo que se ve (sin los botones), recortada en un cuadrado alrededor del visor.
func _tomar_foto() -> Image:
	hud.hide()
	visor.hide()
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	hud.show()
	visor.show()
	flash.color.a = 0.9
	create_tween().tween_property(flash, "color:a", 0.0, 0.4)

	var lado := int(mini(img.get_width(), img.get_height()) * 0.9)
	img = img.get_region(Rect2i((img.get_width() - lado) / 2, (img.get_height() - lado) / 2, lado, lado))
	if lado > 720:
		img.resize(720, 720)
	return img


func _actualizar_intentos() -> void:
	intentos.text = "Intentos: %d/%d" % [_intentos, INTENTOS]


func _mostrar_estado(texto: String) -> void:
	estado.text = texto
	estado.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(1.2)
	tween.tween_property(estado, "modulate:a", 0.0, 0.4)


func _terminar(capturado: bool) -> void:
	_camara.detener()
	terminada.emit(capturado)
	queue_free()
