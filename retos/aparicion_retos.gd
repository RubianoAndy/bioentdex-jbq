extends Node3D
## Hace aparecer retos cerca del explorador de vez en cuando, igual que los insectos:
##
## RETO DE FOTO (cámara azul)
##   - Toma una misión de foto de las zonas (o un reto general) y abre la cámara del teléfono.
##   - Las fotos quedan en la base de datos de la Bioentdex.
##
## EMBOSCADA (globo de los depredadores)
##   - Un globo baja del cielo con un depredador (aves, ranas, ratas...) que tiene atrapado un
##     insecto especial. Para rescatarlo hay que ganarle una batalla de preguntas con los
##     insectos capturados (si aún no tiene, la guía le presta uno).

signal reto_foto_seleccionado(marcador: Node3D)
signal batalla_seleccionada(globo: Node3D)
signal aviso(texto: String)

const MARCADOR_FOTO := preload("res://retos/marcador_reto_foto.gd")
const GLOBO := preload("res://retos/globo_depredador.gd")

## Depredadores que comen insectos y pueden llegar en el globo
const DEPREDADORES := ["mirla_patiamarilla", "copeton", "garza_blanca", "monjita_bogotana",
	"rana_sabanera", "rata_parda", "chucha"]

## Retos de foto que sirven en cualquier parte del mapa: [id, enunciado, explicación]
const RETOS_GENERALES := [
	["reto_foto_flor", "Encuentra una flor del humedal y tómale una foto de cerca.",
		"Las flores alimentan a abejorros, mariposas y colibríes: sin ellas no habría polinizadores."],
	["reto_foto_agua", "Fotografía el agua del humedal. ¿Ves plantas flotando o aves cerca?",
		"El espejo de agua es el corazón del humedal: allí comen y descansan las aves acuáticas."],
	["reto_foto_arbol", "Toma una foto de un árbol de la ronda (aliso, sauce o eucalipto).",
		"Los alisos y sauces nativos protegen la orilla y dan refugio a las aves."],
	["reto_foto_hoja", "Busca una hoja mordida por insectos y fotografíala.",
		"Los mordiscos en las hojas son pistas: ahí comió una oruga, un escarabajo o un saltamontes."],
	["reto_foto_ave", "Fotografía un ave del humedal, aunque esté lejos.",
		"Registrar las aves ayuda a los científicos a saber cuántas viven en el humedal."],
	["reto_foto_rastro", "Busca huellas, plumas o rastros de animales y tómales una foto.",
		"Los rastros cuentan qué animales pasaron por aquí, aunque no los veamos."],
	["reto_foto_basura", "Si ves basura en el humedal, fotografíala para reportarla (sin tocarla).",
		"Reportar la basura ayuda a limpiar el humedal y a proteger a los animales."],
]

@export var intervalo := 15.0               # cada cuántos segundos se intenta hacer aparecer un reto
@export_range(0.0, 1.0) var prob_foto := 0.35
@export_range(0.0, 1.0) var prob_batalla := 0.3
@export var duracion_min := 120.0
@export var duracion_max := 240.0
@export var distancia_min := 7.0
@export var distancia_max := 14.0
@export var distancia_desaparicion := 35.0
@export var distancia_interaccion := 7.0    # qué tan cerca hay que estar para empezar el reto

var terreno: Terreno
var explorador: Node3D
var zonas: Array = []

var _reloj := 8.0   # el primer intento llega pronto
var _reto_foto: Node3D = null
var _globo: Node3D = null
var _retos_generales: Array[Mision] = []


func configurar(nuevo_terreno: Terreno, nuevo_explorador: Node3D, nuevas_zonas: Array) -> void:
	terreno = nuevo_terreno
	explorador = nuevo_explorador
	zonas = nuevas_zonas
	for datos in RETOS_GENERALES:
		var mision := Mision.new()
		mision.id = datos[0]
		mision.tipo = Mision.Tipo.FOTO
		mision.enunciado = datos[1]
		mision.explicacion = datos[2]
		_retos_generales.append(mision)


func _process(delta: float) -> void:
	if terreno == null:
		return
	for reto in [_reto_foto, _globo]:
		if reto == null:
			continue
		reto.vida -= delta
		if reto.vida <= 0.0 or _pos_explorador().distance_to(_pos2d(reto)) > distancia_desaparicion:
			quitar(reto)

	_reloj -= delta
	if _reloj <= 0.0:
		_reloj = intervalo
		if _globo == null and randf() < prob_batalla:
			_aparecer_globo()
		elif _reto_foto == null and randf() < prob_foto:
			_aparecer_reto_foto()


func quitar(reto: Node3D) -> void:
	if reto == _reto_foto:
		_reto_foto = null
	elif reto == _globo:
		_globo = null
	reto.desaparecer()


# --- Reto de foto -----------------------------------------------------------------------------

func _aparecer_reto_foto() -> void:
	var lugar = _buscar_lugar()
	if lugar == null:
		return
	var zona_id := _zona_cercana(lugar)
	# Primero las misiones de foto de la zona cercana y los retos generales que no se han hecho
	var candidatos := []
	for zona in zonas:
		if zona.id == zona_id:
			for mision in zona.misiones:
				if mision.tipo == Mision.Tipo.FOTO:
					candidatos.append(mision)
	candidatos.append_array(_retos_generales)
	var pendientes := candidatos.filter(func(m: Mision) -> bool: return not RegistroEspecies.mision_resuelta(m.id))
	var mision: Mision = (pendientes if not pendientes.is_empty() else candidatos).pick_random()

	_reto_foto = MARCADOR_FOTO.new()
	_reto_foto.configurar(mision, zona_id, lugar, randf_range(duracion_min, duracion_max))
	add_child(_reto_foto)


func reto_foto_tocado(marcador: Node3D) -> void:
	if _acercarse(marcador, "Acércate a la cámara azul para hacer el reto de foto"):
		reto_foto_seleccionado.emit(marcador)


# --- Emboscada --------------------------------------------------------------------------------

func _aparecer_globo() -> void:
	var lugar = _buscar_lugar()
	var depredadores := DEPREDADORES.map(func(id: String) -> Especie: return RegistroEspecies.buscar(id)) \
		.filter(func(e: Especie) -> bool: return e != null and e.activa_ahora() and e.imagen_mapa() != null)
	var premio := _elegir_premio()
	if lugar == null or depredadores.is_empty() or premio == null:
		return
	_globo = GLOBO.new()
	_globo.configurar(depredadores.pick_random(), premio, lugar, randf_range(duracion_min, duracion_max))
	add_child(_globo)
	aviso.emit("¡Un globo de depredadores está bajando cerca de ti!")


## El insecto especial que trae atrapado: primero los Plus que no tiene, luego los que no ha capturado.
func _elegir_premio() -> Especie:
	var insectos := RegistroEspecies.especies.filter(func(e: Especie) -> bool: return e.es_capturable())
	var plus := insectos.filter(func(e: Especie) -> bool: return e.plus and not Recompensas.tiene_plus(e.id))
	if not plus.is_empty():
		return plus.pick_random()
	var nuevos := insectos.filter(func(e: Especie) -> bool: return not e.plus and not RegistroEspecies.esta_capturada(e.id))
	if not nuevos.is_empty():
		return nuevos.pick_random()
	return insectos.pick_random() if not insectos.is_empty() else null


func globo_tocado(globo: Node3D) -> void:
	if _acercarse(globo, "Acércate al globo para enfrentar al depredador"):
		batalla_seleccionada.emit(globo)


# --- Utilidades -------------------------------------------------------------------------------

## true si el explorador está cerca; si no, camina hacia el reto y avisa.
func _acercarse(reto: Node3D, texto: String) -> bool:
	if _pos_explorador().distance_to(_pos2d(reto)) <= distancia_interaccion:
		return true
	explorador.ir_a(reto.position)
	aviso.emit(texto)
	return false


func _buscar_lugar():
	var origen := _pos_explorador()
	for intento in 20:
		var p := origen + Vector2.from_angle(randf() * TAU) * randf_range(distancia_min, distancia_max)
		if terreno.libre(p, 1.0):
			return p
	return null


func _zona_cercana(p: Vector2) -> String:
	var mejor := "mapa"
	var menor := INF
	for zona in zonas:
		var d: float = p.distance_to(zona.posicion) - zona.radio
		if d < 12.0 and d < menor:
			menor = d
			mejor = zona.id
	return mejor


func _pos_explorador() -> Vector2:
	return Vector2(explorador.position.x, explorador.position.z)


func _pos2d(nodo: Node3D) -> Vector2:
	return Vector2(nodo.position.x, nodo.position.z)
