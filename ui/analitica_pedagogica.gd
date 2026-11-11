extends Node
## Solo guarda contadores de aprendizaje agregados; nunca texto, perfiles ni eventos fechados.

const ARCHIVO_DATOS := "user://analitica_pedagogica.json"
const ARCHIVO_PIN := "user://docente_pin.cfg"
const ITERACIONES_HASH := 20000
const MAX_INTENTOS := 5
const SEGUNDOS_BLOQUEO := 60
const MINIMO_RECURRENTES := 3
const MAX_OPCIONES_RETO := 5
const TOPICOS := {
	"agua_ecosistemas": "Agua y ecosistemas",
	"observacion_etica": "Observación responsable",
	"residuos_humedal": "Residuos y contaminación",
	"conectividad": "Conectividad ecológica",
	"ciclos_nutrientes": "Ciclos y descomposición",
	"memoria_cultural": "Memoria cultural",
	"especies_invasoras": "Especies invasoras",
	"ronda_hidrica": "Ronda hídrica",
	"polinizacion": "Polinización",
	"biodiversidad_humedal": "Biodiversidad del humedal",
	"general": "Conceptos generales",
	"ave": "Aves",
	"anfibio": "Anfibios",
	"mamifero": "Mamíferos",
}
const TEMA_ZONA := {
	"agua_abierta": "agua_ecosistemas",
	"avistamiento_aves": "observacion_etica",
	"basuras": "residuos_humedal",
	"corredor_ambiental": "conectividad",
	"materia_organica": "ciclos_nutrientes",
	"monolitos": "memoria_cultural",
	"neofita": "especies_invasoras",
	"ronda_hidrica": "ronda_hidrica",
	"terrestre": "polinizacion",
	"transicion": "biodiversidad_humedal",
	"urbana": "residuos_humedal",
}

var _especies_descubiertas := 0
var _errores_por_tema: Dictionary = {}
var _opciones_reto_por_tema: Dictionary = {}
var _participaciones_propuesta := 0
var _pin_salt := PackedByteArray()
var _pin_verificador := PackedByteArray()
var _intentos_fallidos := 0
var _bloqueado_hasta := 0
var _sesion_docente_activa := false
var _mensaje_pin := ""


func _ready() -> void:
	_cargar_datos()
	_cargar_pin()
	if not FileAccess.file_exists(ARCHIVO_DATOS):
		_especies_descubiertas = RegistroEspecies.cantidad_descubiertas()
		_guardar_datos()
	RegistroEspecies.especie_descubierta.connect(_on_especie_descubierta)


func tema_de_mision(id_mision: String) -> String:
	for prefijo in TEMA_ZONA:
		if id_mision.begins_with(prefijo + "_"):
			return TEMA_ZONA[prefijo]
	return "general"


func registrar_error_tema(tema: String) -> void:
	if not TOPICOS.has(tema):
		return
	_errores_por_tema[tema] = int(_errores_por_tema.get(tema, 0)) + 1
	_guardar_datos()


func registrar_opcion_reto(tema: String, opcion: int) -> void:
	if not TOPICOS.has(tema) or opcion < 0 or opcion >= MAX_OPCIONES_RETO:
		return
	var opciones: Dictionary = _opciones_reto_por_tema.get(tema, {})
	var clave := str(opcion)
	opciones[clave] = int(opciones.get(clave, 0)) + 1
	_opciones_reto_por_tema[tema] = opciones
	_guardar_datos()


func registrar_participacion_propuesta() -> void:
	_participaciones_propuesta += 1
	_guardar_datos()


func pin_configurado() -> bool:
	return not _pin_salt.is_empty() and not _pin_verificador.is_empty()


func configurar_pin(pin: String) -> bool:
	_mensaje_pin = ""
	if pin_configurado():
		_mensaje_pin = "Ya existe un PIN docente configurado."
		return false
	if not _pin_valido(pin):
		_mensaje_pin = "Usa un PIN de al menos 6 dígitos."
		return false
	_pin_salt = Crypto.new().generate_random_bytes(16)
	if _pin_salt.is_empty():
		_mensaje_pin = "No se pudo generar la sal local del PIN."
		return false
	_pin_verificador = _derivar_verificador(pin, _pin_salt)
	if _pin_verificador.is_empty():
		_pin_salt.clear()
		_mensaje_pin = "No se pudo derivar el verificador local del PIN."
		return false
	_intentos_fallidos = 0
	_bloqueado_hasta = 0
	if not _guardar_pin():
		_pin_salt.clear()
		_pin_verificador.clear()
		_mensaje_pin = "No se pudo guardar la configuración local del PIN."
		return false
	return true


func autenticar(pin: String) -> bool:
	_mensaje_pin = ""
	if not pin_configurado() or segundos_bloqueo() > 0:
		_mensaje_pin = "Configura un PIN docente o espera a que termine el bloqueo."
		return false
	if _verificador_coincide(_derivar_verificador(pin, _pin_salt), _pin_verificador):
		_intentos_fallidos = 0
		_bloqueado_hasta = 0
		_sesion_docente_activa = true
		if _guardar_pin():
			return true
		_sesion_docente_activa = false
		_mensaje_pin = "No se pudo guardar el estado del PIN; acceso cancelado."
		return false
	_intentos_fallidos += 1
	if _intentos_fallidos >= MAX_INTENTOS:
		_intentos_fallidos = 0
		_bloqueado_hasta = int(Time.get_unix_time_from_system()) + SEGUNDOS_BLOQUEO
	_mensaje_pin = "PIN incorrecto." if _guardar_pin() else "No se pudo guardar el estado del PIN."
	return false


func mensaje_pin() -> String:
	return _mensaje_pin


func segundos_bloqueo() -> int:
	return maxi(0, _bloqueado_hasta - int(Time.get_unix_time_from_system()))


func cerrar_sesion_docente() -> void:
	_sesion_docente_activa = false


func resumen_legible() -> String:
	if not _sesion_docente_activa:
		return "Acceso docente requerido."
	var lineas := ["Especies descubiertas y registradas: %d" % _especies_descubiertas,
		"Errores conceptuales (solo respuestas incorrectas):"]
	for tema in TOPICOS:
		var cantidad := int(_errores_por_tema.get(tema, 0))
		if cantidad >= MINIMO_RECURRENTES:
			lineas.append("• %s: %d" % [TOPICOS[tema], cantidad])
	lineas.append("Selecciones cerradas en retos (posición de opción):")
	for tema in TOPICOS:
		var opciones: Dictionary = _opciones_reto_por_tema.get(tema, {})
		for opcion in MAX_OPCIONES_RETO:
			var cantidad := int(opciones.get(str(opcion), 0))
			if cantidad >= MINIMO_RECURRENTES:
				lineas.append("• %s · opción %d: %d" % [TOPICOS[tema], opcion + 1, cantidad])
	lineas.append("Envíos de propuestas de texto libre (no personas únicas): %d" % _participaciones_propuesta)
	return "\n".join(lineas)


func exportar_json_docente() -> String:
	if not _sesion_docente_activa:
		return "Ingresa el PIN docente antes de exportar."
	var errores_exportables := {}
	for tema in TOPICOS:
		var cantidad := int(_errores_por_tema.get(tema, 0))
		if cantidad >= MINIMO_RECURRENTES:
			errores_exportables[tema] = cantidad
	var opciones_exportables := {}
	for tema in TOPICOS:
		var opciones: Dictionary = _opciones_reto_por_tema.get(tema, {})
		var conteos := {}
		for opcion in MAX_OPCIONES_RETO:
			var cantidad := int(opciones.get(str(opcion), 0))
			if cantidad >= MINIMO_RECURRENTES:
				conteos[str(opcion)] = cantidad
		if not conteos.is_empty():
			opciones_exportables[tema] = conteos
	var datos := {
		"version": 1,
		"especies_descubiertas_registradas": _especies_descubiertas,
		"errores_recurrentes_por_tema": errores_exportables,
		"selecciones_retos_por_tema_y_opcion": opciones_exportables,
		"participaciones_propuesta": _participaciones_propuesta if _participaciones_propuesta >= MINIMO_RECURRENTES else 0,
	}
	var indice := 1
	var ruta := "user://analitica_docente_%03d.json" % indice
	while FileAccess.file_exists(ruta):
		indice += 1
		ruta = "user://analitica_docente_%03d.json" % indice
	var archivo := FileAccess.open(ruta, FileAccess.WRITE)
	if archivo == null:
		return "No se pudo crear el archivo JSON (%s)." % error_string(FileAccess.get_open_error())
	archivo.store_string(JSON.stringify(datos, "\t"))
	archivo.close()
	return "Exportación local creada: %s" % ruta.get_file()


func _on_especie_descubierta(_especie: Especie) -> void:
	_especies_descubiertas += 1
	_guardar_datos()


func _cargar_datos() -> void:
	if not FileAccess.file_exists(ARCHIVO_DATOS):
		return
	var cargados = JSON.parse_string(FileAccess.get_file_as_string(ARCHIVO_DATOS))
	if not cargados is Dictionary:
		return
	_especies_descubiertas = maxi(0, int(cargados.get("especies_descubiertas", 0)))
	_participaciones_propuesta = maxi(0, int(cargados.get("participaciones_propuesta", 0)))
	var errores = cargados.get("errores_por_tema", {})
	if errores is Dictionary:
		for tema in TOPICOS:
			if errores.has(tema):
				_errores_por_tema[tema] = maxi(0, int(errores[tema]))
	var opciones_cargadas = cargados.get("opciones_reto_por_tema", {})
	if opciones_cargadas is Dictionary:
		for tema in TOPICOS:
			var opciones = opciones_cargadas.get(tema, {})
			if opciones is Dictionary:
				var conteos := {}
				for opcion in MAX_OPCIONES_RETO:
					var clave := str(opcion)
					if opciones.has(clave):
						conteos[clave] = maxi(0, int(opciones[clave]))
				if not conteos.is_empty():
					_opciones_reto_por_tema[tema] = conteos


func _guardar_datos() -> void:
	var archivo := FileAccess.open(ARCHIVO_DATOS, FileAccess.WRITE)
	if archivo == null:
		push_error("No se pudo guardar la analítica local: %s" % error_string(FileAccess.get_open_error()))
		return
	archivo.store_string(JSON.stringify({
		"especies_descubiertas": _especies_descubiertas,
		"errores_por_tema": _errores_por_tema,
		"opciones_reto_por_tema": _opciones_reto_por_tema,
		"participaciones_propuesta": _participaciones_propuesta,
	}, "\t"))


func _cargar_pin() -> void:
	var config := ConfigFile.new()
	if config.load(ARCHIVO_PIN) != OK:
		return
	_pin_salt = Marshalls.base64_to_raw(str(config.get_value("docente", "salt", "")))
	_pin_verificador = Marshalls.base64_to_raw(str(config.get_value("docente", "verificador", "")))
	_intentos_fallidos = maxi(0, int(config.get_value("docente", "intentos", 0)))
	_bloqueado_hasta = maxi(0, int(config.get_value("docente", "bloqueado_hasta", 0)))


func _guardar_pin() -> bool:
	var config := ConfigFile.new()
	config.set_value("docente", "salt", Marshalls.raw_to_base64(_pin_salt))
	config.set_value("docente", "verificador", Marshalls.raw_to_base64(_pin_verificador))
	config.set_value("docente", "intentos", _intentos_fallidos)
	config.set_value("docente", "bloqueado_hasta", _bloqueado_hasta)
	var error := config.save(ARCHIVO_PIN)
	if error != OK:
		push_error("No se pudo guardar la configuración local del PIN docente: %s" % error_string(error))
		return false
	return true


func _derivar_verificador(pin: String, salt: PackedByteArray) -> PackedByteArray:
	var actual := salt.duplicate()
	actual.append_array(pin.to_utf8_buffer())
	for _i in range(ITERACIONES_HASH):
		var contexto := HashingContext.new()
		var error := contexto.start(HashingContext.HASH_SHA256)
		if error != OK:
			push_error("No se pudo iniciar SHA-256 para el PIN docente.")
			return PackedByteArray()
		contexto.update(actual)
		actual = contexto.finish()
	return actual


func _verificador_coincide(primero: PackedByteArray, segundo: PackedByteArray) -> bool:
	if primero.size() != segundo.size() or primero.is_empty():
		return false
	var diferencia := 0
	for i in primero.size():
		diferencia |= primero[i] ^ segundo[i]
	return diferencia == 0


func _pin_valido(pin: String) -> bool:
	if pin.length() < 6:
		return false
	for caracter in pin:
		if not caracter.is_valid_int():
			return false
	return true
