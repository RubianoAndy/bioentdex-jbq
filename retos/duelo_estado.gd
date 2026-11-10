class_name DueloEstado
extends RefCounted
## Máquina de estados pequeña para impedir respuestas y acciones en momentos incompatibles.

enum Estado { PREPARACION, PREGUNTA, HABILIDAD_CARGADA, ANIMACION, ESQUIVA, FINALIZADO }

const TRANSICIONES := {
	Estado.PREPARACION: [Estado.PREGUNTA, Estado.FINALIZADO],
	Estado.PREGUNTA: [Estado.PREGUNTA, Estado.HABILIDAD_CARGADA, Estado.ANIMACION, Estado.FINALIZADO],
	Estado.HABILIDAD_CARGADA: [Estado.PREGUNTA, Estado.ANIMACION, Estado.FINALIZADO],
	Estado.ANIMACION: [Estado.ESQUIVA, Estado.PREGUNTA, Estado.HABILIDAD_CARGADA, Estado.FINALIZADO],
	Estado.ESQUIVA: [Estado.ANIMACION, Estado.FINALIZADO],
	Estado.FINALIZADO: [],
}

var actual := Estado.PREPARACION


func cambiar(nuevo: Estado) -> bool:
	var permitidos: Array = TRANSICIONES.get(actual, [])
	if not permitidos.has(nuevo):
		return false
	actual = nuevo
	return true


func activo() -> bool:
	return actual != Estado.FINALIZADO
