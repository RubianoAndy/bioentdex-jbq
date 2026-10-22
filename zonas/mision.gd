class_name Mision
extends Resource
## Misión de una zona. Las respuestas se guardan en la base de datos de la Bioentdex.
##   PREGUNTA:    pregunta con opciones.
##   IDENTIFICAR: muestra la imagen de la especie (especie_id) y hay que elegir cuál es.
##   FOTO:        tomar una foto con la cámara (se guarda en la base de datos).
##   PROPUESTA:   escribir una propuesta o solución (texto libre).
## Las misiones especiales se resaltan con una bandera en la zona y en el mapa.

enum Tipo { PREGUNTA, IDENTIFICAR, FOTO, PROPUESTA }

@export var id: String = ""
@export var tipo: Tipo = Tipo.PREGUNTA
@export var especial: bool = false
@export_multiline var enunciado: String = ""
@export var opciones: PackedStringArray = []
@export var correcta: int = 0
## Especie relacionada: al resolver la misión queda registrada como observada
@export var especie_id: String = ""
@export_multiline var explicacion: String = ""   # se muestra después de responder
