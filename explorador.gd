extends Node3D
## Personaje del jugador. Camina siguiendo una ruta (toque) o se mueve directo (arrastre / teclado).
## No atraviesa agua, árboles ni casas: el Terreno le da las rutas y las colisiones.
## El modelo está hecho con figuras simples; se puede reemplazar por un modelo 3D dentro de "Modelo".

@export var velocidad := 6.0

var terreno: Terreno
var _camino := PackedVector2Array()
var _movio := false
var _fase_paso := 0.0
var _amplitud_paso := 0.0

@onready var modelo: Node3D = $Modelo
@onready var cadera_izq: Node3D = $Modelo/CaderaIzq
@onready var cadera_der: Node3D = $Modelo/CaderaDer
@onready var hombro_izq: Node3D = $Modelo/HombroIzq
@onready var hombro_der: Node3D = $Modelo/HombroDer


func ir_a(punto: Vector3) -> void:
	var destino := Vector2(punto.x, punto.z)
	if terreno:
		_camino = terreno.camino(_pos2d(), destino)
	else:
		_camino = PackedVector2Array([destino])


func mover(desplazamiento: Vector3) -> void:
	_camino.clear()
	var nueva := _pos2d() + Vector2(desplazamiento.x, desplazamiento.z)
	if terreno:
		nueva = terreno.mover(_pos2d(), Vector2(desplazamiento.x, desplazamiento.z))
	_avanzar(Vector3(nueva.x - position.x, 0, nueva.y - position.z), desplazamiento)


func _process(delta: float) -> void:
	if not _camino.is_empty():
		var hacia := Vector3(_camino[0].x - position.x, 0, _camino[0].y - position.z)
		var paso := velocidad * delta
		if hacia.length() <= paso:
			_avanzar(hacia, hacia)
			_camino.remove_at(0)
		else:
			_avanzar(hacia.normalized() * paso, hacia)
	_animar(delta)
	_movio = false


func _avanzar(desplazamiento: Vector3, mirar_hacia: Vector3) -> void:
	if mirar_hacia.length() > 0.0001:
		# Girar hacia donde quiere ir (el frente del modelo mira a -Z)
		modelo.rotation.y = lerp_angle(modelo.rotation.y, atan2(-mirar_hacia.x, -mirar_hacia.z), 0.25)
	if desplazamiento.length() < 0.0001:
		return
	position += desplazamiento
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


func _pos2d() -> Vector2:
	return Vector2(position.x, position.z)
