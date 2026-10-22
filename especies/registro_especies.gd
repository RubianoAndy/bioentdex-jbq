extends Node
## Autoload "RegistroEspecies": catálogo de especies + base de datos de la Bioentdex.
## Guarda en user://bioentdex.json:
##   - capturas: insectos fotografiados con la cámara (con la ruta de la foto),
##   - observaciones: animales NPC y plantas que el jugador ya conoció,
##   - misiones: respuestas a las misiones de las zonas.
## Cada registro es un diccionario simple, listo para enviarlo a un servidor más adelante.

signal especie_descubierta(especie: Especie)            # primera captura u observación
signal especie_capturada(especie: Especie, captura: Dictionary)
signal especie_observada(especie: Especie, primera: bool)
signal mision_registrada(mision: Mision, registro: Dictionary)

const CARPETA_ESPECIES := "res://especies/datos/"
const ARCHIVO_BD := "user://bioentdex.json"
const CARPETA_FOTOS := "user://fotos/"

var especies: Array[Especie] = []   # ordenadas por número
var _bd := {"version": 1, "capturas": [], "observaciones": {}, "misiones": {},
	# Progreso del jugador (lo maneja el autoload Recompensas)
	"jugador": {"experiencia": 0, "semillas": 0, "plus": [], "misiones_premiadas": [], "nectar_hasta": 0}}


func _ready() -> void:
	_cargar_especies()
	_cargar_bd()


# --- Consultas --------------------------------------------------------------------------------

func buscar(id: String) -> Especie:
	for especie in especies:
		if especie.id == id:
			return especie
	return null


func esta_capturada(id: String) -> bool:
	return not capturas_de(id).is_empty()


func esta_observada(id: String) -> bool:
	return _bd.observaciones.has(id)


## Capturada (insectos) u observada (el resto).
func esta_descubierta(id: String) -> bool:
	return esta_capturada(id) or esta_observada(id)


func capturas_de(id: String) -> Array:
	return _bd.capturas.filter(func(c: Dictionary) -> bool: return c.especie == id)


func cantidad_descubiertas() -> int:
	return especies.filter(func(e: Especie) -> bool: return esta_descubierta(e.id)).size()


func mision_resuelta(id: String) -> bool:
	return _bd.misiones.has(id) and _bd.misiones[id].correcta


func registro_mision(id: String) -> Dictionary:
	return _bd.misiones.get(id, {})


func cantidad_misiones_resueltas() -> int:
	return _bd.misiones.values().filter(func(r: Dictionary) -> bool: return r.correcta).size()


## Foto de una captura como textura (o null si el archivo ya no existe).
static func cargar_foto(ruta: String) -> Texture2D:
	if ruta.is_empty() or not FileAccess.file_exists(ruta):
		return null
	var img := Image.load_from_file(ruta)
	return ImageTexture.create_from_image(img) if img else null


# --- Registro ---------------------------------------------------------------------------------

## Guarda la captura de un insecto con su foto. Devuelve el registro creado.
func registrar_captura(especie: Especie, zona_id: String, foto: Image) -> Dictionary:
	var primera := not esta_descubierta(especie.id)
	var captura := {
		"especie": especie.id,
		"zona": zona_id,
		"fecha": Time.get_datetime_string_from_system(),
		"foto": _guardar_foto(foto, "captura_" + especie.id),
	}
	_bd.capturas.append(captura)
	_guardar_bd()
	especie_capturada.emit(especie, captura)
	if primera:
		especie_descubierta.emit(especie)
	return captura


## Marca una especie como observada. Devuelve true solo la primera vez.
func registrar_observacion(especie: Especie) -> bool:
	if esta_observada(especie.id):
		_bd.observaciones[especie.id].veces += 1
		_guardar_bd()
		especie_observada.emit(especie, false)
		return false
	var primera := not esta_descubierta(especie.id)
	_bd.observaciones[especie.id] = {"primera_vez": Time.get_datetime_string_from_system(), "veces": 1}
	_guardar_bd()
	especie_observada.emit(especie, true)
	if primera:
		especie_descubierta.emit(especie)
	return true


## Guarda la respuesta a una misión (y la foto, si la misión es de tomar foto).
func registrar_mision(mision: Mision, zona_id: String, respuesta: String, correcta: bool, foto: Image = null) -> Dictionary:
	var anterior: Dictionary = _bd.misiones.get(mision.id, {})
	var registro := {
		"zona": zona_id,
		"tipo": Mision.Tipo.keys()[mision.tipo],
		"respuesta": respuesta,
		"correcta": correcta or anterior.get("correcta", false),
		"intentos": anterior.get("intentos", 0) + 1,
		"fecha": Time.get_datetime_string_from_system(),
		"foto": _guardar_foto(foto, "mision_" + mision.id) if foto else anterior.get("foto", ""),
	}
	_bd.misiones[mision.id] = registro
	_guardar_bd()
	mision_registrada.emit(mision, registro)
	# Resolver una misión relacionada con una especie cuenta como haberla conocido
	if correcta and not mision.especie_id.is_empty():
		var especie := buscar(mision.especie_id)
		if especie:
			registrar_observacion(especie)
	return registro


## Datos de progreso del jugador (experiencia, semillas...). Llamar a guardar() después de cambiarlos.
func jugador() -> Dictionary:
	return _bd.jugador


func guardar() -> void:
	_guardar_bd()


# --- Archivos ---------------------------------------------------------------------------------

func _guardar_foto(foto: Image, nombre: String) -> String:
	if foto == null:
		return ""
	DirAccess.make_dir_recursive_absolute(CARPETA_FOTOS)
	var ruta := "%s%s_%d.jpg" % [CARPETA_FOTOS, nombre, Time.get_unix_time_from_system()]
	foto.save_jpg(ruta, 0.85)
	return ruta


func _cargar_especies() -> void:
	# list_directory también funciona en el juego exportado (a diferencia de DirAccess)
	for archivo in ResourceLoader.list_directory(CARPETA_ESPECIES):
		if archivo.ends_with(".tres"):
			var especie := load(CARPETA_ESPECIES + archivo) as Especie
			if especie:
				especies.append(especie)
	especies.sort_custom(func(a: Especie, b: Especie) -> bool: return a.numero < b.numero)


func _cargar_bd() -> void:
	if not FileAccess.file_exists(ARCHIVO_BD):
		return
	var datos = JSON.parse_string(FileAccess.get_file_as_string(ARCHIVO_BD))
	if datos is Dictionary:
		for clave in _bd:
			if datos.has(clave):
				if _bd[clave] is Dictionary and clave == "jugador":
					_bd[clave].merge(datos[clave], true)   # conserva los campos nuevos
				else:
					_bd[clave] = datos[clave]


func _guardar_bd() -> void:
	var archivo := FileAccess.open(ARCHIVO_BD, FileAccess.WRITE)
	if archivo:
		archivo.store_string(JSON.stringify(_bd, "\t"))
