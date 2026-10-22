extends Node3D
## Colibrí NPC: vuela por todo el humedal con vuelos rápidos y pausas flotando.
## Es un NPC (no se captura): al tocarlo se abre su ficha y sale volando.

signal tocado(especie: Especie)

@export var especie: Especie
@export var velocidad := 9.0
@export var altura := 2.2
@export_range(0.0, 1.0) var prob_cerca_explorador := 0.5   # para que de vez en cuando pase cerca

var limites := Rect2(-10, -10, 20, 20)   # el mapa lo ajusta al tamaño del suelo
var explorador: Node3D
var _objetivo := Vector3.ZERO
var _espera := 0.0
var _tiempo := 0.0

@onready var sprite: Sprite3D = $Sprite3D
@onready var sombra: MeshInstance3D = $Sombra


func _ready() -> void:
	position.y = altura
	var textura := especie.imagen_mapa()
	if textura:
		sprite.texture = textura
		sprite.pixel_size = 1.2 / textura.get_width()
	_elegir_objetivo()


func _process(delta: float) -> void:
	_tiempo += delta
	if _espera > 0.0:
		_espera -= delta   # flotando en el sitio, como liba una flor
	else:
		var hacia := _objetivo - position
		if hacia.length() < 0.1:
			_espera = randf_range(0.8, 2.5)
			_elegir_objetivo()
		else:
			position += hacia.limit_length(velocidad * delta)
			if absf(hacia.x) > 0.05:
				sprite.flip_h = hacia.x < 0.0   # la imagen mira a la derecha

	# Aleteo: sube y baja rápido; la sombra se queda pegada al suelo
	sprite.position.y = sin(_tiempo * 9.0) * 0.08
	sombra.position.y = -position.y + 0.02


func al_tocar(_quien: Node3D) -> void:
	tocado.emit(especie)
	# Se asusta y sale volando lejos
	_espera = 0.0
	_elegir_objetivo(false)


func _elegir_objetivo(puede_ir_cerca := true) -> void:
	var punto: Vector2
	if puede_ir_cerca and explorador and randf() < prob_cerca_explorador:
		punto = Vector2(explorador.position.x, explorador.position.z) \
			+ Vector2.from_angle(randf() * TAU) * randf_range(2.0, 6.0)
	else:
		punto = Vector2(
			randf_range(limites.position.x, limites.end.x),
			randf_range(limites.position.y, limites.end.y))
	punto = punto.clamp(limites.position, limites.end)
	_objetivo = Vector3(punto.x, altura, punto.y)
