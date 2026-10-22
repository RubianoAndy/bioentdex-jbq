extends Node
## Autoload "RegistroEspecies": carga todas las especies y recuerda cuáles ya descubrió el jugador.

signal especie_descubierta(especie: Especie)

const CARPETA_ESPECIES := "res://especies/datos/"
const ARCHIVO_PROGRESO := "user://progreso.cfg"

var especies: Array[Especie] = []   # ordenadas por número
var _descubiertas := {}             # id -> true


func _ready() -> void:
	_cargar_especies()
	_cargar_progreso()


func esta_descubierta(id: String) -> bool:
	return _descubiertas.has(id)


func cantidad_descubiertas() -> int:
	return _descubiertas.size()


## Marca la especie como descubierta. Devuelve true solo la primera vez.
func descubrir(id: String) -> bool:
	if esta_descubierta(id):
		return false
	var especie := buscar(id)
	if especie == null:
		push_warning("Especie desconocida: %s" % id)
		return false
	_descubiertas[id] = true
	_guardar_progreso()
	especie_descubierta.emit(especie)
	return true


func buscar(id: String) -> Especie:
	for especie in especies:
		if especie.id == id:
			return especie
	return null


func _cargar_especies() -> void:
	# list_directory también funciona en el juego exportado (a diferencia de DirAccess)
	for archivo in ResourceLoader.list_directory(CARPETA_ESPECIES):
		if archivo.ends_with(".tres"):
			var especie := load(CARPETA_ESPECIES + archivo) as Especie
			if especie:
				especies.append(especie)
	especies.sort_custom(func(a: Especie, b: Especie) -> bool: return a.numero < b.numero)


func _cargar_progreso() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(ARCHIVO_PROGRESO) != OK:
		return
	for id in cfg.get_value("progreso", "descubiertas", PackedStringArray()):
		_descubiertas[id] = true


func _guardar_progreso() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progreso", "descubiertas", PackedStringArray(_descubiertas.keys()))
	cfg.save(ARCHIVO_PROGRESO)
