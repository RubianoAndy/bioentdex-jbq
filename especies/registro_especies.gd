extends Node
## Autoload "RegistroEspecies": catálogo de especies + base de datos de la Bioentdex.
## Guarda en user://bioentdex.json:
##   - capturas: insectos fotografiados con la cámara (con la ruta de la foto),
##   - observaciones: animales NPC y plantas que el jugador ya conoció,
##   - misiones: respuestas cerradas y estado de las misiones de las zonas (y de los retos de foto del mapa),
##   - fotos: todas las fotos de misiones y retos (en "misiones" solo queda la última de cada una),
##   - batallas: resultado de cada batalla contra los depredadores.
## Todos los datos permanecen localmente en el dispositivo.

signal especie_descubierta(especie: Especie)            # primera captura u observación
signal especie_capturada(especie: Especie, captura: Dictionary)
signal especie_observada(especie: Especie, primera: bool)
signal mision_registrada(mision: Mision, registro: Dictionary)
signal batalla_registrada(registro: Dictionary)
## Un registro nuevo desbloqueó otra fase del ciclo de vida ("evolución"). anterior = "" si es la primera.
signal etapa_alcanzada(especie: Especie, anterior: String, nueva: String)

const CARPETA_ESPECIES := "res://especies/datos/"
const ARCHIVO_BD := "user://bioentdex.json"
const CARPETA_FOTOS := "user://fotos/"
const PUNTAJE_ECOLOGICO := preload("res://especies/puntaje_ecologico.gd")

var especies: Array[Especie] = []   # ordenadas por número
var _bd := {"version": 1, "capturas": [], "observaciones": {}, "misiones": {}, "fotos": [], "batallas": [],
	"anti_repeticion": {}, "ultima_pregunta_batalla": "",
	# Progreso del jugador (lo maneja el autoload Recompensas)
	"jugador": {"experiencia": 0, "semillas": 0, "plus": [], "misiones_premiadas": [],
		"misiones_muestras": [], "muestras_digitales": [], "nectar_hasta": 0}}
var _advertencias_catalogo := {}


func _ready() -> void:
	_cargar_especies()
	_cargar_bd()
	call_deferred("_validar_catalogo")


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
## calidad_foto va de 0 (borde del visor) a 1 (centro); 0.5 equivale al multiplicador neutro x1.
func registrar_captura(especie: Especie, zona_id: String, foto: Image, calidad_foto: float = 0.5) -> Dictionary:
	var primera := not esta_descubierta(especie.id)
	var etapa_antes := etapa_actual(especie)
	var capturas_fotograficas := capturas_de(especie.id).filter(
		func(c: Dictionary) -> bool: return not c.get("foto", "").is_empty())
	var puntaje := PUNTAJE_ECOLOGICO.calcular(especie, calidad_foto, not capturas_fotograficas.is_empty()) \
		if foto != null else {}
	var captura := {
		"especie": especie.id,
		"zona": zona_id,
		"fecha": Time.get_datetime_string_from_system(),
		"foto": _guardar_foto(foto, "captura_" + especie.id),
	}
	captura.merge(puntaje, true)
	_bd.capturas.append(captura)
	_guardar_bd()
	especie_capturada.emit(especie, captura)
	if primera:
		especie_descubierta.emit(especie)
	_revisar_evolucion(especie, etapa_antes)
	return captura


## Marca una especie como observada. Devuelve true solo la primera vez.
func registrar_observacion(especie: Especie) -> bool:
	var etapa_antes := etapa_actual(especie)
	if esta_observada(especie.id):
		_bd.observaciones[especie.id].veces += 1
		_guardar_bd()
		especie_observada.emit(especie, false)
		_revisar_evolucion(especie, etapa_antes)
		return false
	var primera := not esta_descubierta(especie.id)
	_bd.observaciones[especie.id] = {"primera_vez": Time.get_datetime_string_from_system(), "veces": 1}
	_guardar_bd()
	especie_observada.emit(especie, true)
	if primera:
		especie_descubierta.emit(especie)
	_revisar_evolucion(especie, etapa_antes)
	return true


## Fase del ciclo de vida que ya desbloqueó el jugador ("" si aún ninguna o la especie no tiene).
func etapa_actual(especie: Especie) -> String:
	var ciclo := progreso_ciclo_vida(especie)
	return ciclo.get("fase_actual", "")


func _revisar_evolucion(especie: Especie, antes: String) -> void:
	var ahora := etapa_actual(especie)
	if ahora != antes and not ahora.is_empty():
		etapa_alcanzada.emit(especie, antes, ahora)


## Guarda la respuesta a una misión (y la foto, si la misión es de tomar foto).
func registrar_mision(mision: Mision, zona_id: String, respuesta: String, correcta: bool, foto: Image = null) -> Dictionary:
	var anterior: Dictionary = _bd.misiones.get(mision.id, {})
	if mision.tipo == Mision.Tipo.PROPUESTA:
		# Conserva la respuesta antigua, pero nunca la reemplaza con texto nuevo.
		var registro_propuesta := anterior.duplicate(true)
		registro_propuesta["tipo"] = "PROPUESTA"
		registro_propuesta["correcta"] = correcta or anterior.get("correcta", false)
		_bd.misiones[mision.id] = registro_propuesta
		_guardar_bd()
		mision_registrada.emit(mision, registro_propuesta)
		return registro_propuesta
	var ruta_foto := _guardar_foto(foto, "mision_" + mision.id) if foto else ""
	if foto:
		_bd.fotos.append({"mision": mision.id, "zona": zona_id, "enunciado": mision.enunciado,
			"fecha": Time.get_datetime_string_from_system(), "foto": ruta_foto})
	var registro := {
		"zona": zona_id,
		"tipo": Mision.Tipo.keys()[mision.tipo],
		"respuesta": respuesta,
		"correcta": correcta or anterior.get("correcta", false),
		"intento_correcto": correcta,
		"intentos": anterior.get("intentos", 0) + 1,
		"fecha": Time.get_datetime_string_from_system(),
		"foto": ruta_foto if foto else anterior.get("foto", ""),
	}
	_bd.misiones[mision.id] = registro
	_guardar_bd()
	mision_registrada.emit(mision, registro)
	# Resolver una misión relacionada con una especie cuenta como haberla conocido (solo la
	# primera vez: repetir una misión ya resuelta no debe dar experiencia otra vez)
	if correcta and not anterior.get("correcta", false) and not mision.especie_id.is_empty():
		var especie := buscar(mision.especie_id)
		if especie:
			registrar_observacion(especie)
	return registro


## Guarda el resultado de una batalla contra un depredador.
func registrar_batalla(depredador: Especie, premio: Especie, zona_id: String, gano: bool,
		equipo: Array, aciertos: int, errores: int) -> Dictionary:
	var registro := {
		"depredador": depredador.id,
		"premio": premio.id if premio else "",
		"zona": zona_id,
		"gano": gano,
		"equipo": equipo.map(func(e: Especie) -> String: return e.id),
		"aciertos": aciertos,
		"errores": errores,
		"fecha": Time.get_datetime_string_from_system(),
	}
	_bd.batallas.append(registro)
	_guardar_bd()
	batalla_registrada.emit(registro)
	return registro


func registros_fotograficos_de(id: String) -> int:
	return capturas_de(id).filter(func(c: Dictionary) -> bool: return not c.get("foto", "").is_empty()).size()


func progreso_ciclo_vida(especie: Especie) -> Dictionary:
	if especie.etapas_ciclo_vida.is_empty():
		return {}
	var observaciones: Dictionary = _bd.observaciones.get(especie.id, {})
	var total := registros_fotograficos_de(especie.id) + int(observaciones.get("veces", 0))
	var umbral := maxi(1, especie.registros_por_etapa)
	var fases_completadas := int(total / umbral)
	var indice_actual := mini(fases_completadas - 1, especie.etapas_ciclo_vida.size() - 1)
	var indice_siguiente := indice_actual + 1
	if indice_siguiente >= especie.etapas_ciclo_vida.size():
		return {
			"fase_actual": especie.etapas_ciclo_vida[-1],
			"progreso": umbral,
			"umbral": umbral,
			"completado": true,
			"registros": total,
		}
	return {
		"fase_actual": especie.etapas_ciclo_vida[indice_actual] if indice_actual >= 0 else "",
		"fase_siguiente": especie.etapas_ciclo_vida[indice_siguiente],
		"progreso": total % umbral,
		"umbral": umbral,
		"completado": false,
		"registros": total,
	}


func ultima_pregunta_batalla() -> String:
	return _bd.get("ultima_pregunta_batalla", "")


func registrar_pregunta_batalla(id_pregunta: String) -> void:
	_bd.ultima_pregunta_batalla = id_pregunta
	_guardar_bd()


func batallas_ganadas() -> int:
	return _bd.batallas.filter(func(b: Dictionary) -> bool: return b.gano).size()


## Devuelve el siguiente ID de una cola aleatoria persistente, sin repetir hasta agotar el banco.
func siguiente_id_sin_repetir(clave: String, ids: Array) -> String:
	var disponibles: Array[String] = []
	for valor in ids:
		var id := str(valor)
		if not id.is_empty() and not disponibles.has(id):
			disponibles.append(id)
	if disponibles.is_empty():
		return ""

	if not (_bd.get("anti_repeticion", {}) is Dictionary):
		_bd["anti_repeticion"] = {}
	var bancos: Dictionary = _bd["anti_repeticion"]
	var estado = bancos.get(clave, {})
	if not (estado is Dictionary):
		estado = {}

	var ultimo := str(estado.get("ultimo", ""))
	var vistos: Array[String] = []
	var vistos_guardados = estado.get("vistos", [])
	if vistos_guardados is Array:
		for valor in vistos_guardados:
			var id_visto := str(valor)
			if disponibles.has(id_visto) and not vistos.has(id_visto):
				vistos.append(id_visto)

	var cola: Array[String] = []
	var cola_guardada = estado.get("cola", [])
	if cola_guardada is Array:
		for valor in cola_guardada:
			var id_cola := str(valor)
			if disponibles.has(id_cola) and not vistos.has(id_cola) and not cola.has(id_cola):
				cola.append(id_cola)
	var nuevos: Array[String] = []
	for id in disponibles:
		if not vistos.has(id) and not cola.has(id):
			nuevos.append(id)
	nuevos.shuffle()
	cola.append_array(nuevos)

	if cola.is_empty():
		cola = disponibles.duplicate()
		if cola.size() > 1:
			cola.erase(ultimo)
		cola.shuffle()
		vistos.clear()

	var elegido: String = cola.pop_front()
	vistos.append(elegido)
	bancos[clave] = {"cola": cola, "vistos": vistos, "ultimo": elegido}
	_bd["anti_repeticion"] = bancos
	_guardar_bd()
	return elegido


## Datos de progreso del jugador (experiencia, semillas...). Llamar a guardar() después de cambiarlos.
func jugador() -> Dictionary:
	return _bd.jugador


func guardar() -> void:
	_guardar_bd()


# --- Archivos ---------------------------------------------------------------------------------

func _guardar_foto(foto: Image, nombre: String) -> String:
	if foto == null:
		return ""
	var error_directorio := DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(CARPETA_FOTOS))
	if error_directorio != OK and error_directorio != ERR_ALREADY_EXISTS:
		push_error("No se pudo crear la carpeta de fotos (%s)." % error_string(error_directorio))
		return ""
	var base := "%s%s_%d" % [CARPETA_FOTOS, nombre, Time.get_unix_time_from_system()]
	var ruta := base + ".jpg"
	var indice := 1
	while FileAccess.file_exists(ruta):
		ruta = "%s_%d.jpg" % [base, indice]
		indice += 1
	var error_foto := foto.save_jpg(ruta, 0.85)
	if error_foto != OK:
		push_error("No se pudo guardar la foto de '%s' (%s)." % [nombre, error_string(error_foto)])
		return ""
	return ruta


func _cargar_especies() -> void:
	# list_directory también funciona en el juego exportado (a diferencia de DirAccess)
	for archivo in ResourceLoader.list_directory(CARPETA_ESPECIES):
		if archivo.ends_with(".tres"):
			var recurso = load(CARPETA_ESPECIES + archivo)
			var especie := recurso as Especie
			if especie:
				especies.append(especie)
			else:
				_advertir_catalogo("recurso:" + archivo,
					"Catálogo de especies: no se pudo cargar %s como Especie." % (CARPETA_ESPECIES + archivo))
	especies.sort_custom(func(a: Especie, b: Especie) -> bool: return a.numero < b.numero)


func _validar_catalogo() -> void:
	var ids := {}
	for especie in especies:
		var ruta := especie.resource_path if not especie.resource_path.is_empty() else "<recurso sin ruta>"
		if especie.id.strip_edges().is_empty():
			_advertir_catalogo("id_vacio:" + ruta,
				"Catálogo de especies: %s tiene un ID vacío." % ruta)
		elif ids.has(especie.id):
			_advertir_catalogo("id_duplicado:" + ruta,
				"Catálogo de especies: ID duplicado '%s' en %s (también aparece en %s)." %
				[especie.id, ruta, ids[especie.id]])
		else:
			ids[especie.id] = ruta

		var tiene_imagen := especie.imagen != null
		if not tiene_imagen:
			if especie.es_capturable():
				tiene_imagen = not especie.imagenes_dataset().is_empty()
			else:
				tiene_imagen = especie.imagen_mapa() is Texture2D
		if not tiene_imagen:
			_advertir_catalogo("imagen:" + ruta,
				"Catálogo de especies: %s (ID '%s') no tiene imagen válida ni una imagen por convención." %
				[ruta, especie.id])

	for zona in Expedicion.zonas:
		if not zona is Zona:
			continue
		for mision in zona.misiones:
			if not (mision is Mision) or mision.especie_id.strip_edges().is_empty():
				continue
			if not ids.has(mision.especie_id):
				var ruta_mision := mision.resource_path if not mision.resource_path.is_empty() else mision.id
				_advertir_catalogo("referencia:%s:%s" % [zona.id, ruta_mision],
					"Catálogo de especies: misión '%s' de la zona '%s' referencia la especie inexistente '%s'." %
					[mision.id, zona.id, mision.especie_id])


func _advertir_catalogo(clave: String, mensaje: String) -> void:
	if _advertencias_catalogo.has(clave):
		return
	_advertencias_catalogo[clave] = true
	push_warning(mensaje)


func _cargar_bd() -> void:
	var datos = _leer_json(ARCHIVO_BD)
	if not datos is Dictionary:
		# Archivo dañado (por ejemplo, la app se cerró mientras guardaba): se intenta con el
		# temporal de la última escritura y se conserva una copia del dañado para recuperarlo.
		var temporal = _leer_json(ARCHIVO_BD + ".tmp")
		if FileAccess.file_exists(ARCHIVO_BD) and not FileAccess.get_file_as_string(ARCHIVO_BD).is_empty():
			DirAccess.copy_absolute(ARCHIVO_BD, ARCHIVO_BD.replace(".json", ".danado.json"))
		if temporal is Dictionary:
			push_warning("La base de datos estaba dañada; se recuperó la última copia guardada.")
			datos = temporal
	if datos is Dictionary:
		for clave in _bd:
			if datos.has(clave):
				if _bd[clave] is Dictionary and clave == "jugador":
					_bd[clave].merge(datos[clave], true)   # conserva los campos nuevos
				else:
					_bd[clave] = datos[clave]


## Lee un JSON; devuelve null si no existe o no se puede interpretar.
func _leer_json(ruta: String):
	if not FileAccess.file_exists(ruta):
		return null
	return JSON.parse_string(FileAccess.get_file_as_string(ruta))


## Guarda primero en un archivo temporal y luego lo pone en lugar del bueno: si la app se cierra a
## mitad de la escritura (pasa en Android), el archivo anterior queda intacto.
func _guardar_bd() -> void:
	var temporal := ARCHIVO_BD + ".tmp"
	var archivo := FileAccess.open(temporal, FileAccess.WRITE)
	if archivo == null:
		push_error("No se pudo guardar la base de datos de la Bioentdex (%s)." %
			error_string(FileAccess.get_open_error()))
		return
	archivo.store_string(JSON.stringify(_bd, "\t"))
	archivo.close()
	if DirAccess.rename_absolute(temporal, ARCHIVO_BD) != OK:
		# Si el sistema no deja reemplazar al renombrar, se copia y se borra el temporal
		if DirAccess.copy_absolute(temporal, ARCHIVO_BD) == OK:
			DirAccess.remove_absolute(temporal)
		else:
			push_error("No se pudo reemplazar la base de datos de la Bioentdex.")
