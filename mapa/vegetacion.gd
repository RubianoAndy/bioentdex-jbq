extends Node3D
## Llena el mapa según la máscara: eneas y juncos en la transición, alisos, eucaliptos y sauces
## en la ronda, buchón en el agua, kikuyo, basura y la ciudad (casas con tanque de agua).
## Usa MultiMesh por bloques: miles de objetos con pocas llamadas de dibujo, y los bloques fuera
## de la cámara no se dibujan (importante en el celular).

const PASO := 2                 # se revisa 1 de cada 2 píxeles de la máscara
const TAM_BLOQUE := 40.0        # tamaño de cada bloque de MultiMesh
const SEPARACION_CASAS := 8     # píxeles entre casa y casa

## Por cada tipo de suelo: [modelo, probabilidad de poner uno en cada punto revisado]
const REGLAS := {
	PaletaMapa.JUNCAL: [["enea", 0.12], ["junco", 0.1]],
	PaletaMapa.BOSQUE: [["aliso", 0.08], ["eucalipto", 0.03], ["sauce", 0.025], ["arbusto", 0.05]],
	PaletaMapa.PASTO: [["aliso", 0.003], ["arbusto", 0.008], ["flores", 0.012]],
	PaletaMapa.PRADERA: [["flores", 0.06]],
	PaletaMapa.FLOTANTES: [["buchon", 0.35]],
	PaletaMapa.AGUA: [["buchon", 0.003]],
	PaletaMapa.KIKUYO: [["pasto_alto", 0.3]],
	PaletaMapa.BASURAL: [["basura", 0.2], ["llanta", 0.03]],
}

## Objetos que no se pueden atravesar, con su radio
const OBSTACULOS := {"aliso": 0.5, "eucalipto": 0.35, "sauce": 0.75}
## Plantas que no se ponen encima de senderos, puentes ni calles
const NO_EN_CAMINOS := ["aliso", "eucalipto", "sauce", "arbusto"]

const COLORES_FLORES := [Color(1, 0.85, 0.2), Color(1, 1, 1), Color(0.75, 0.55, 0.95), Color(0.95, 0.35, 0.3)]
const COLORES_BASURA := [Color(0.1, 0.1, 0.1), Color(0.95, 0.95, 0.95), Color(0.2, 0.4, 0.85), Color(0.2, 0.6, 0.3)]
# Casas bogotanas: casi todas de ladrillo, algunas pintadas
const COLORES_CASAS := [
	Color(0.62, 0.3, 0.2), Color(0.68, 0.36, 0.24), Color(0.58, 0.28, 0.2), Color(0.66, 0.4, 0.3),
	Color(0.85, 0.82, 0.72), Color(0.9, 0.78, 0.55), Color(0.75, 0.8, 0.82),
]
const COLORES_TANQUES := [Color(0.15, 0.3, 0.7), Color(0.12, 0.12, 0.12)]


## Crea los MultiMesh con lo que calculó calcular().
func construir(instancias: Dictionary) -> void:
	for clave in instancias:
		_crear_multimesh(clave.get_slice("|", 0), instancias[clave])


## Decide dónde va cada planta y casa, y marca los obstáculos en el terreno. Solo usa datos (no
## nodos), así que se puede llamar desde otro hilo: el mapa se precalcula al abrir la app.
static func calcular(terreno: Terreno, zonas: Array) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2024   # semilla fija: el mapa siempre queda igual
	var celda := terreno.tamano_celda()
	var instancias := {}   # "modelo|bloque" -> [[Transform3D, Color], ...]

	for y in range(0, terreno.alto, PASO):
		for x in range(0, terreno.ancho, PASO):
			var clase := terreno.clase_celda(x, y)
			if clase == PaletaMapa.MANZANA:
				if x % SEPARACION_CASAS == 0 and y % SEPARACION_CASAS == 0 and _cabe_casa(terreno, x, y):
					_agregar_casa(instancias, terreno.a_mundo(Vector2i(x, y)), rng)
				continue
			if not REGLAS.has(clase):
				continue
			for regla in REGLAS[clase]:
				if rng.randf() >= regla[1]:
					continue
				var modelo: String = regla[0]
				var pos := terreno.a_mundo(Vector2i(x, y)) + Vector2(rng.randf() - 0.5, rng.randf() - 0.5) * PASO * celda
				if _cerca_de_zona(pos, zonas, OBSTACULOS.has(modelo)):
					break
				if modelo in NO_EN_CAMINOS and _camino_cerca(terreno, x, y):
					break
				var escala := rng.randf_range(0.8, 1.3)
				var color := Color.WHITE
				if modelo == "flores":
					color = COLORES_FLORES[rng.randi() % COLORES_FLORES.size()]
				elif modelo == "basura":
					color = COLORES_BASURA[rng.randi() % COLORES_BASURA.size()]
				_agregar(instancias, modelo, pos, Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * escala), 0.0, color)
				if OBSTACULOS.has(modelo):
					terreno.bloquear_circulo(pos, OBSTACULOS[modelo] * escala)
				break
	return instancias


static func _agregar_casa(instancias: Dictionary, pos: Vector2, rng: RandomNumberGenerator) -> void:
	var pisos: int = [1, 2, 2, 3, 3, 3, 4][rng.randi() % 7]
	var alto_casa := pisos * 1.25
	var color: Color = COLORES_CASAS[rng.randi() % COLORES_CASAS.size()]
	_agregar(instancias, "casa", pos, Basis.from_scale(Vector3(2.3, alto_casa, 2.3)), 0.0, color)
	if rng.randf() < 0.5:
		var tanque := pos + Vector2(rng.randf_range(-0.6, 0.6), rng.randf_range(-0.6, 0.6))
		_agregar(instancias, "tanque", tanque, Basis(), alto_casa, COLORES_TANQUES[rng.randi() % 2])


static func _agregar(instancias: Dictionary, modelo: String, pos: Vector2, base: Basis, altura: float, color: Color) -> void:
	var bloque := Vector2i(((pos + Vector2.ONE * 1000.0) / TAM_BLOQUE).floor())
	var clave := "%s|%d,%d" % [modelo, bloque.x, bloque.y]
	if not instancias.has(clave):
		instancias[clave] = []
	instancias[clave].append([Transform3D(base, Vector3(pos.x, altura, pos.y)), color])


func _crear_multimesh(modelo: String, lista: Array) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = modelo in ["flores", "casa", "tanque", "basura"]
	mm.mesh = _malla(modelo)
	mm.instance_count = lista.size()
	for i in lista.size():
		mm.set_instance_transform(i, lista[i][0])
		if mm.use_colors:
			mm.set_instance_color(i, lista[i][1])
	var nodo := MultiMeshInstance3D.new()
	nodo.name = modelo.capitalize()
	nodo.multimesh = mm
	nodo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(nodo, true)


var _mallas := {}
func _malla(modelo: String) -> ArrayMesh:
	if not _mallas.has(modelo):
		_mallas[modelo] = ModelosMapa.crear(modelo)
	return _mallas[modelo]


## La casa cabe si toda su base cae dentro de la manzana.
static func _cabe_casa(terreno: Terreno, x: int, y: int) -> bool:
	for d in [Vector2i(-4, -4), Vector2i(4, -4), Vector2i(-4, 4), Vector2i(4, 4)]:
		if terreno.clase_celda(x + d.x, y + d.y) != PaletaMapa.MANZANA:
			return false
	return true


static func _camino_cerca(terreno: Terreno, x: int, y: int) -> bool:
	for k in 9:
		var d := Vector2i.ZERO if k == 8 else Vector2i(Vector2.from_angle(TAU * k / 8.0) * 5.0)
		var clase := terreno.clase_celda(x + d.x, y + d.y)
		if clase in [PaletaMapa.SENDERO, PaletaMapa.PUENTE, PaletaMapa.CALLE]:
			return true
	return false


## Los árboles dejan más espacio, sobre todo hacia el sur (del lado de la cámara), para no tapar la zona.
static func _cerca_de_zona(pos: Vector2, zonas: Array, es_alto: bool) -> bool:
	for zona in zonas:
		var d: Vector2 = pos - zona.posicion
		if es_alto and d.y > 0.0:
			d.y *= 0.5
		if d.length() < zona.radio + (1.0 if es_alto else 0.5):
			return true
	return false
