extends Node3D
## Hace aparecer la fauna cerca del explorador, al estilo Pokémon GO pero académico:
##
## INSECTOS (capturables con la cámara)
##   - No siempre hay: cada cierto tiempo hay una probabilidad de que aparezca uno, y solo cerca del jugador.
##   - Se quedan un rato y se van; también se van si el jugador se aleja.
##   - Sin capturar: pueden aparecer en cualquier parte del mapa con su tipo de suelo (donde vive).
##   - Ya capturados: solo vuelven a aparecer en sus zonas.
##
## ANIMALES NPC (aves, ranas, mamíferos...)
##   - Viven en sus zonas. Cuando el jugador se acerca a una zona se decide al azar cuáles están
##     "en este momento" (y si es su horario: la chucha, por ejemplo, solo sale de noche).

signal insecto_seleccionado(insecto: Node3D)
signal npc_seleccionado(especie: Especie)
signal aviso(texto: String)

const INSECTO := preload("res://fauna/insecto_mapa.gd")
const NPC := preload("res://fauna/animal_npc.gd")
const MAPA := preload("res://mundo_3d.gd")

@export var intervalo := 6.0               # cada cuántos segundos se intenta hacer aparecer un insecto
@export_range(0.0, 1.0) var prob_aparicion := 0.4
@export var max_insectos := 2
@export var duracion_min := 60.0
@export var duracion_max := 150.0
@export var distancia_min := 4.0
@export var distancia_max := 11.0          # más lejos quedan fuera de la pantalla
@export var distancia_desaparicion := 30.0
@export var distancia_captura := 7.0       # qué tan cerca hay que estar para abrir la cámara
@export var distancia_zona_activa := 32.0  # a esta distancia de una zona aparecen sus animales
@export_range(0.0, 1.0) var prob_npc_presente := 0.7

var terreno: Terreno
var explorador: Node3D
var zonas: Array = []

var _reloj := 3.0
var _insectos: Array = []
var _npcs := {}   # id de zona -> animales que están ahora en ella


func configurar(nuevo_terreno: Terreno, nuevo_explorador: Node3D, nuevas_zonas: Array) -> void:
	terreno = nuevo_terreno
	explorador = nuevo_explorador
	zonas = nuevas_zonas


func _process(delta: float) -> void:
	if terreno == null:
		return
	var origen := _pos_explorador()
	for insecto in _insectos.duplicate():
		insecto.vida -= delta
		if insecto.vida <= 0.0 or MAPA.distancia_xz(origen, _pos2d(insecto)) > distancia_desaparicion:
			quitar_insecto(insecto)

	# Con el néctar atrayente de la tienda aparecen más insectos y más seguido
	var nectar := Recompensas.nectar_activo()
	_reloj -= delta
	if _reloj <= 0.0:
		_reloj = intervalo * (0.5 if nectar else 1.0)
		var maximo := max_insectos + (2 if nectar else 0)
		if _insectos.size() < maximo and randf() < (0.9 if nectar else prob_aparicion):
			_aparecer_insecto()

	_actualizar_npcs(origen)


# --- Insectos ---------------------------------------------------------------------------------

func _aparecer_insecto() -> void:
	var candidatos := RegistroEspecies.especies.filter(
		func(e: Especie) -> bool: return e.es_capturable() and not e.plus and e.activa_ahora())
	candidatos.shuffle()
	for especie in candidatos:
		if _insectos.any(func(i) -> bool: return i.especie == especie):
			continue
		var lugar = _buscar_lugar(especie)
		if lugar != null:
			var insecto := INSECTO.new()
			insecto.configurar(especie, lugar, randf_range(duracion_min, duracion_max))
			add_child(insecto)
			_insectos.append(insecto)
			FeedbackTactil.aparicion_sorpresa()
			return


func _buscar_lugar(especie: Especie):
	var origen := _pos_explorador()
	if RegistroEspecies.esta_capturada(especie.id):
		# Ya capturado: solo en sus zonas
		for zona in zonas:
			if not zona.especies.has(especie) or MAPA.distancia_xz(origen, zona.posicion) > distancia_max + zona.radio + 4.0:
				continue
			for intento in 12:
				var p: Vector2 = zona.posicion + Vector2.from_angle(randf() * TAU) * randf_range(0.0, zona.radio + 4.0)
				var d := MAPA.distancia_xz(origen, p)
				if d >= 3.0 and d <= distancia_max and _cerca_de_tierra(p):
					return p
		return null
	# Sin capturar: en cualquier lugar cercano con su tipo de suelo
	for intento in 20:
		var p := origen + Vector2.from_angle(randf() * TAU) * randf_range(distancia_min, distancia_max)
		if terreno.clase_en(p) in especie.suelos_habitat and _cerca_de_tierra(p):
			return p
	return null


## Para que el jugador pueda acercarse (los insectos del agua quedan cerca de la orilla).
func _cerca_de_tierra(p: Vector2) -> bool:
	if terreno.transitable(p):
		return true
	for k in 8:
		if terreno.transitable(p + Vector2.from_angle(TAU * k / 8.0) * 3.5):
			return true
	return false


func insecto_tocado(insecto: Node3D) -> void:
	if MAPA.distancia_xz(_pos_explorador(), _pos2d(insecto)) > distancia_captura:
		explorador.ir_a(insecto.position)
		aviso.emit("Acércate para fotografiarlo")
	else:
		insecto_seleccionado.emit(insecto)


func quitar_insecto(insecto: Node3D) -> void:
	_insectos.erase(insecto)
	insecto.desaparecer()


# --- Animales NPC -----------------------------------------------------------------------------

func _actualizar_npcs(origen: Vector2) -> void:
	for zona in zonas:
		var distancia := MAPA.distancia_xz(origen, zona.posicion)
		if distancia < distancia_zona_activa and not _npcs.has(zona.id):
			_npcs[zona.id] = _poblar_zona(zona)
		elif distancia > distancia_zona_activa + 10.0 and _npcs.has(zona.id):
			# Al alejarse se van; al volver se decide de nuevo quiénes están
			for npc in _npcs[zona.id]:
				npc.queue_free()
			_npcs.erase(zona.id)


func _poblar_zona(zona: Zona) -> Array:
	var animales := []
	for especie in zona.especies:
		if not especie.es_animal() or especie.es_capturable() or especie.movimiento == Especie.Movimiento.VOLAR:
			continue
		if not especie.activa_ahora() or randf() > prob_npc_presente:
			continue
		var area := zona.radio + 6.0
		for intento in 25:
			var p: Vector2 = zona.posicion + Vector2.from_angle(randf() * TAU) * randf_range(0.0, area)
			if terreno.clase_en(p) in especie.suelos_habitat:
				var npc := NPC.new()
				npc.configurar(especie, terreno, zona.posicion, area, p)
				add_child(npc)
				animales.append(npc)
				break
	return animales


func npc_tocado(especie: Especie) -> void:
	npc_seleccionado.emit(especie)


func _pos_explorador() -> Vector2:
	return Vector2(explorador.position.x, explorador.position.z)


func _pos2d(nodo: Node3D) -> Vector2:
	return Vector2(nodo.position.x, nodo.position.z)
