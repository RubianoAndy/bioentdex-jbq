extends Node
## Autoload "Expedicion": zonas del humedal y estado del recorrido al cambiar de escena.

const CARPETA_ZONAS := "res://zonas/datos/"
const POSICION_INICIAL := Vector3(-2.6, 0, 9.4)   # sendero al sur del mapa

var zonas: Array[Zona] = []
var zona_actual: Zona = null
var posicion_explorador := POSICION_INICIAL   # para volver al mismo punto al salir de una zona


func _ready() -> void:
	for archivo in ResourceLoader.list_directory(CARPETA_ZONAS):
		if archivo.ends_with(".tres"):
			var zona := load(CARPETA_ZONAS + archivo) as Zona
			if zona:
				zonas.append(zona)


func entrar_a_zona(zona: Zona, posicion: Vector3) -> void:
	zona_actual = zona
	posicion_explorador = posicion
	get_tree().change_scene_to_file("res://ZonaInterior.tscn")


func volver_al_mapa() -> void:
	get_tree().change_scene_to_file("res://MapaExpedicion.tscn")
