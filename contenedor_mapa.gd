extends Control

var arrastrando: bool = false
var velocidad_inercia: Vector2 = Vector2.ZERO
var factor_inercia: float = 0.92

# Tamaños
var ancho_lienzo: float = 2560.0
var alto_lienzo: float = 2560.0
var ancho_pantalla: float = 720.0
var alto_pantalla: float = 1280.0

func _input(event: InputEvent) -> void:
	# Usamos _input global para capturar el arrastre sin importar dónde toque el mouse
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			arrastrando = event.pressed
			if arrastrando:
				velocidad_inercia = Vector2.ZERO
				
	elif event is InputEventScreenTouch:
		arrastrando = event.pressed
		if arrastrando:
			velocidad_inercia = Vector2.ZERO

	elif event is InputEventMouseMotion and arrastrando:
		mover_directo(event.relative)

	elif event is InputEventScreenDrag and arrastrando:
		mover_directo(event.relative)

func mover_directo(delta_movimiento: Vector2) -> void:
	position += delta_movimiento
	velocidad_inercia = delta_movimiento
	restringir_posicion()

func _process(delta: float) -> void:
	if not arrastrando:
		if velocidad_inercia.length() > 0.2:
			position += velocidad_inercia
			velocidad_inercia *= factor_inercia
			restringir_posicion()
		else:
			velocidad_inercia = Vector2.ZERO

func restringir_posicion() -> void:
	# Bucle horizontal infinito (360°)
	if position.x > 0:
		position.x = fmod(position.x, ancho_lienzo) - ancho_lienzo
	elif position.x < -ancho_lienzo:
		position.x = fmod(position.x, ancho_lienzo)

	# Límites verticales para que no se salga de la pantalla arriba/abajo
	var min_y = alto_pantalla - alto_lienzo
	position.y = clamp(position.y, min_y, 0)
