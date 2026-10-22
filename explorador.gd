extends Node3D
## Personaje del jugador. Camina hasta un destino (toque) o se mueve directo (arrastre / teclado).
## El modelo está hecho con figuras simples; se puede reemplazar por un modelo 3D dentro de "Modelo".

@export var velocidad := 5.0

var limites := Rect2(-1000, -1000, 2000, 2000)   # el mapa lo ajusta al tamaño del suelo
var _destino = null       # Vector3 o null
var _movio := false
var _fase_paso := 0.0
var _amplitud_paso := 0.0

@onready var modelo: Node3D = $Modelo
@onready var cadera_izq: Node3D = $Modelo/CaderaIzq
@onready var cadera_der: Node3D = $Modelo/CaderaDer
@onready var hombro_izq: Node3D = $Modelo/HombroIzq
@onready var hombro_der: Node3D = $Modelo/HombroDer


func ir_a(punto: Vector3) -> void:
	_destino = Vector3(
		clampf(punto.x, limites.position.x, limites.end.x), 0,
		clampf(punto.z, limites.position.y, limites.end.y))


func mover(desplazamiento: Vector3) -> void:
	_destino = null
	_avanzar(desplazamiento)


func _process(delta: float) -> void:
	if _destino != null:
		var hacia: Vector3 = _destino - position
		var paso := velocidad * delta
		if hacia.length() <= paso:
			_avanzar(hacia)
			_destino = null
		else:
			_avanzar(hacia.normalized() * paso)
	_animar(delta)
	_movio = false


func _avanzar(desplazamiento: Vector3) -> void:
	if desplazamiento.length() < 0.0001:
		return
	position.x = clampf(position.x + desplazamiento.x, limites.position.x, limites.end.x)
	position.z = clampf(position.z + desplazamiento.z, limites.position.y, limites.end.y)
	# Girar hacia donde camina (el frente del modelo mira a -Z)
	modelo.rotation.y = lerp_angle(modelo.rotation.y, atan2(-desplazamiento.x, -desplazamiento.z), 0.25)
	_movio = true


func _animar(delta: float) -> void:
	_amplitud_paso = move_toward(_amplitud_paso, 1.0 if _movio else 0.0, delta * 6.0)
	if _movio:
		_fase_paso += delta * 12.0
	var balanceo := sin(_fase_paso) * 0.6 * _amplitud_paso
	cadera_izq.rotation.x = balanceo
	cadera_der.rotation.x = -balanceo
	hombro_izq.rotation.x = -balanceo * 0.8
	hombro_der.rotation.x = balanceo * 0.8
	modelo.position.y = absf(sin(_fase_paso)) * 0.05 * _amplitud_paso
