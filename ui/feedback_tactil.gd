extends Node
## La vibración se puede desactivar aquí; las duraciones están en milisegundos.

@export var habilitada := true
@export_range(10, 100, 5) var duracion_interaccion_ms := 35
@export_range(50, 100, 5) var duracion_aparicion_ms := 75


func interaccion() -> void:
	_vibrar(duracion_interaccion_ms)


func aparicion_sorpresa() -> void:
	_vibrar(duracion_aparicion_ms)


func _vibrar(duracion_ms: int) -> void:
	if habilitada and OS.has_feature("mobile"):
		Input.vibrate_handheld(duracion_ms)
