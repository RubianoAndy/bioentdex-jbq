class_name DueloEsquiva
extends Node
## Ventana de evasión que acepta tanto toque como teclado.

signal resuelta(esquivo: bool)

var duracion := 2.0
var restante := 0.0
var _abierta := false


func abrir(segundos: float = 2.0) -> void:
	duracion = maxf(segundos, 0.1)
	restante = duracion
	_abierta = true
	set_process(true)


func esquivar() -> void:
	if not _abierta:
		return
	_abierta = false
	set_process(false)
	resuelta.emit(true)


func _process(delta: float) -> void:
	if not _abierta:
		return
	restante = maxf(0.0, restante - delta)
	if restante == 0.0:
		_abierta = false
		set_process(false)
		resuelta.emit(false)
