extends Control

# Velocidad de desplazamiento ajustable desde el Inspector
@export var velocidad_giro: float = 50.0

# Ancho total de tu textura o mapa para lograr el bucle perfecto
@export var ancho_mapa: float = 1920.0 

func _process(delta: float) -> void:
	# Desplazamos la posición horizontal de forma fluida
	position.x -= velocidad_giro * delta
	
	# Creamos el efecto de bucle infinito
	position.x = fmod(position.x, ancho_mapa)
	if position.x <= -ancho_mapa:
		position.x = 0.0
