extends Node3D
## Colibrí NPC, el amigo acompañante del explorador.
## Cada cierto tiempo llega volando desde fuera de la pantalla, se queda revoloteando junto al
## explorador mientras cuenta un dato curioso (lo muestra la burbuja del mapa) y luego sigue
## volando hasta perderse de vista. Es un NPC (no se captura): al tocarlo se abre su ficha.

signal tocado(especie: Especie)
signal vuelo_cercano      # llegó junto al explorador: empieza el dato curioso
signal se_despide         # terminó la visita: la burbuja debe cerrarse

enum Estado { AUSENTE, LLEGANDO, ACOMPANANDO, SALIENDO }

@export var especie: Especie
@export var velocidad := 9.0
@export var altura := 2.2
@export var duracion_visita := 20.0                        # segundos que dura el dato curioso
@export var espera_entre_visitas := Vector2(35.0, 70.0)    # segundos (mínimo, máximo) sin colibrí
@export var espera_primera_visita := Vector2(6.0, 10.0)
@export var distancia_aparicion := 15.0                    # nace fuera de la pantalla
@export var distancia_salida := 22.0

var limites := Rect2(-10, -10, 20, 20)   # el mapa lo ajusta al tamaño del suelo
var explorador: Node3D
var estado := Estado.AUSENTE

var _objetivo := Vector3.ZERO
var _lado := 1.0               # a qué lado del explorador revolotea
var _hueco := Vector3.ZERO     # posición relativa al explorador mientras lo acompaña
var _cambio_hueco := 0.0
var _cuenta := 0.0             # tiempo restante del estado actual
var _tiempo := 0.0
var _capa_toque := 0

@onready var sprite: Sprite3D = $Sprite3D
@onready var sombra: MeshInstance3D = $Sombra
@onready var area: Area3D = $Area3D


func _ready() -> void:
	position.y = altura
	var textura := especie.imagen_mapa()
	if textura:
		sprite.texture = textura
		sprite.pixel_size = 1.2 / textura.get_width()
	# Siempre visible, aunque pase detrás de un árbol: es el compañero del explorador
	sprite.no_depth_test = true
	sprite.render_priority = 10
	_capa_toque = area.collision_layer
	_ausentarse(randf_range(espera_primera_visita.x, espera_primera_visita.y))


## Segundos que le quedan al dato curioso (0 si no está acompañando).
func tiempo_restante_visita() -> float:
	return _cuenta if estado == Estado.ACOMPANANDO else 0.0


## Termina la visita antes de tiempo (por ejemplo, al tocar la burbuja).
func despedirse() -> void:
	if estado == Estado.LLEGANDO or estado == Estado.ACOMPANANDO:
		_salir()


func _process(delta: float) -> void:
	_tiempo += delta
	match estado:
		Estado.AUSENTE:
			_cuenta -= delta
			if _cuenta <= 0.0 and is_instance_valid(explorador):
				_llegar()
		Estado.LLEGANDO:
			_objetivo = _junto_al_explorador()
			if _volar_hacia(_objetivo, velocidad * 1.3, delta):
				estado = Estado.ACOMPANANDO
				_cuenta = duracion_visita
				vuelo_cercano.emit()
		Estado.ACOMPANANDO:
			_cuenta -= delta
			_cambio_hueco -= delta
			if _cambio_hueco <= 0.0:
				_nuevo_hueco()
			# Lo sigue con suavidad, como si revoloteara a su lado
			_volar_hacia(_junto_al_explorador(), velocidad, delta, 0.05)
			sprite.flip_h = _lado > 0.0   # mira hacia el explorador mientras le habla
			if _cuenta <= 0.0:
				_salir()
		Estado.SALIENDO:
			_cuenta -= delta
			if _volar_hacia(_objetivo, velocidad * 1.4, delta) or _cuenta <= 0.0:
				_ausentarse(randf_range(espera_entre_visitas.x, espera_entre_visitas.y))

	# Aleteo: sube y baja rápido; la sombra se queda pegada al suelo
	sprite.position.y = sin(_tiempo * 9.0) * 0.08
	sombra.position.y = -position.y + 0.02


func al_tocar(_quien: Node3D) -> void:
	if estado == Estado.AUSENTE:
		return
	tocado.emit(especie)
	_salir()   # se asusta y sigue su vuelo


# --- Estados ------------------------------------------------------------------------------------

func _llegar() -> void:
	_lado = -1.0 if randf() < 0.5 else 1.0
	_nuevo_hueco()
	# Entra por el costado de la pantalla del lado donde se va a quedar
	var desde := Vector2(explorador.position.x, explorador.position.z) \
		+ Vector2(_lado, randf_range(-0.6, 0.4)).normalized() * distancia_aparicion
	desde = desde.clamp(limites.position, limites.end)
	position = Vector3(desde.x, altura, desde.y)
	_mostrar(true)
	estado = Estado.LLEGANDO


func _salir() -> void:
	if estado == Estado.ACOMPANANDO or estado == Estado.LLEGANDO:
		se_despide.emit()
	estado = Estado.SALIENDO
	_cuenta = 6.0   # por si el destino queda fuera del mapa
	# Sigue volando hacia el lado contrario por donde llegó, un poco hacia arriba del mapa
	var direccion := Vector2(-_lado, randf_range(-0.9, -0.2)).normalized()
	var hasta := Vector2(position.x, position.z) + direccion * distancia_salida
	_objetivo = Vector3(hasta.x, altura + 1.0, hasta.y)
	area.collision_layer = 0   # mientras se va, ya no se puede tocar


func _ausentarse(segundos: float) -> void:
	estado = Estado.AUSENTE
	_cuenta = segundos
	_mostrar(false)


func _mostrar(si: bool) -> void:
	visible = si
	area.collision_layer = _capa_toque if si else 0


# --- Movimiento ---------------------------------------------------------------------------------

func _nuevo_hueco() -> void:
	# Un punto a un costado del explorador, algo adelante, para no taparlo
	_hueco = Vector3(_lado * randf_range(1.4, 2.2), 0.0, randf_range(-1.2, 0.2))
	_cambio_hueco = randf_range(1.5, 3.0)


func _junto_al_explorador() -> Vector3:
	return Vector3(explorador.position.x, altura, explorador.position.z) + _hueco


## Avanza hacia el punto; devuelve true al llegar (a menos de "margen").
func _volar_hacia(punto: Vector3, rapidez: float, delta: float, margen := 0.1) -> bool:
	var hacia := punto - position
	if hacia.length() <= margen:
		return true
	position += hacia.limit_length(rapidez * delta)
	if absf(hacia.x) > 0.05:
		sprite.flip_h = hacia.x < 0.0   # la imagen mira a la derecha
	return hacia.length() <= rapidez * delta
