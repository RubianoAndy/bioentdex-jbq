extends Node
## Carga los diálogos educativos y evita repetirlos hasta agotar los aplicables.

const ARCHIVO_DIALOGOS := "res://dialogos_colibri.json"
const CATEGORIAS := [
	"biomas",
	"ecologia",
	"biomimesis",
	"arte_cultura",
	"interaccion_flora_fauna",
]
const NOMBRES_CATEGORIA := {
	"biomas": "Biomas",
	"ecologia": "Ecología",
	"biomimesis": "Biomímesis",
	"arte_cultura": "Arte y cultura",
	"interaccion_flora_fauna": "Flora y fauna",
}

var _dialogos: Array[Dictionary] = []
var _vistos: Dictionary = {}


func _ready() -> void:
	_cargar_dialogos()


## Nombre bonito de una categoría, para mostrarlo en pantalla.
func nombre_categoria(categoria: String) -> String:
	return NOMBRES_CATEGORIA.get(categoria, categoria.replace("_", " ").capitalize())


func siguiente(zona_id: String) -> Dictionary:
	var candidatos: Array[Dictionary] = []
	for dialogo in _dialogos:
		var zonas: Array = dialogo["zonas"]
		if zonas.is_empty() or zona_id in zonas:
			candidatos.append(dialogo)

	if candidatos.is_empty():
		push_error("No hay diálogos del colibrí disponibles para la zona '%s'." % zona_id)
		return {}

	var disponibles: Array[Dictionary] = []
	for dialogo in candidatos:
		if not _vistos.has(dialogo["id"]):
			disponibles.append(dialogo)

	if disponibles.is_empty():
		for dialogo in candidatos:
			_vistos.erase(dialogo["id"])
		disponibles = candidatos

	var elegido: Dictionary = disponibles.pick_random()
	_vistos[elegido["id"]] = true
	return elegido.duplicate(true)


func _cargar_dialogos() -> void:
	if not FileAccess.file_exists(ARCHIVO_DIALOGOS):
		push_error("No se encontró el archivo de diálogos del colibrí: %s" % ARCHIVO_DIALOGOS)
		return

	var archivo := FileAccess.open(ARCHIVO_DIALOGOS, FileAccess.READ)
	if archivo == null:
		push_error("No se pudo abrir el archivo de diálogos del colibrí: %s" % ARCHIVO_DIALOGOS)
		return

	var json := JSON.new()
	var error := json.parse(archivo.get_as_text())
	if error != OK:
		push_error("Error en el JSON del colibrí, línea %d: %s" % [
			json.get_error_line(),
			json.get_error_message(),
		])
		return

	var documento: Variant = json.data
	if not documento is Dictionary or not documento.get("categorias") is Dictionary:
		push_error("El JSON del colibrí debe contener un objeto 'categorias'.")
		return

	var categorias: Dictionary = documento["categorias"]
	var ids: Dictionary = {}
	for categoria in CATEGORIAS:
		var mensajes: Variant = categorias.get(categoria)
		if not mensajes is Array or mensajes.is_empty():
			push_error("La categoría '%s' no contiene diálogos." % categoria)
			return
		for entrada in mensajes:
			if not entrada is Dictionary \
					or typeof(entrada.get("id")) != TYPE_STRING \
					or typeof(entrada.get("texto")) != TYPE_STRING \
					or not entrada.get("zonas") is Array:
				push_error("Hay un diálogo incompleto o inválido en la categoría '%s'." % categoria)
				return
			if entrada["id"].is_empty() or entrada["texto"].is_empty() or ids.has(entrada["id"]):
				push_error("El diálogo '%s' tiene un ID vacío o duplicado." % entrada["id"])
				return
			for zona_id in entrada["zonas"]:
				if typeof(zona_id) != TYPE_STRING:
					push_error("El diálogo '%s' tiene un ID de zona inválido." % entrada["id"])
					return
			var dialogo: Dictionary = entrada.duplicate(true)
			dialogo["categoria"] = categoria
			_dialogos.append(dialogo)
			ids[dialogo["id"]] = true
