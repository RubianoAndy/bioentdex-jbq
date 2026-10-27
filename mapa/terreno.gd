class_name Terreno
extends RefCounted
## Lo que hay en cada punto del mapa (según la máscara) y por dónde se puede caminar.
## Calcula rutas con A* para que el explorador rodee el agua, los árboles y las casas.

const RADIO_EXPLORADOR := 0.25

var ancho: int
var alto: int
var tamano: Vector2                    # tamaño del mapa en unidades de Godot
var clases := PackedByteArray()        # una clase de PaletaMapa por píxel de la máscara
var _astar := AStarGrid2D.new()


## Recibe la imagen (no la textura) para poder construirse en un hilo aparte (ver zonas/expedicion.gd).
func _init(mascara: Image, tamano_mapa: Vector2) -> void:
	tamano = tamano_mapa
	var img := mascara.duplicate() as Image
	img.convert(Image.FORMAT_RGB8)
	ancho = img.get_width()
	alto = img.get_height()

	# Clasificar cada píxel (con caché: la máscara solo tiene unos pocos colores distintos)
	var datos := img.get_data()
	var cache := {}
	clases.resize(ancho * alto)
	for i in ancho * alto:
		var clave := (datos[i * 3] << 16) | (datos[i * 3 + 1] << 8) | datos[i * 3 + 2]
		if not cache.has(clave):
			cache[clave] = PaletaMapa.clase(Color8(datos[i * 3], datos[i * 3 + 1], datos[i * 3 + 2]))
		clases[i] = cache[clave]

	_astar.region = Rect2i(0, 0, ancho, alto)
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_astar.jumping_enabled = true
	_astar.update()

	# Agua y casas no se pueden cruzar (se marcan por tramos para que sea rápido)
	var bloquea := PackedByteArray()
	bloquea.resize(PaletaMapa.COLORES.size())
	for clase in PaletaMapa.NO_TRANSITABLE:
		bloquea[clase] = 1
	for y in alto:
		var inicio := -1
		for x in ancho + 1:
			var solido := x < ancho and bloquea[clases[y * ancho + x]] == 1
			if solido and inicio < 0:
				inicio = x
			elif not solido and inicio >= 0:
				_astar.fill_solid_region(Rect2i(inicio, y, x - inicio, 1))
				inicio = -1


# --- Conversión entre posiciones del mapa y píxeles de la máscara ---------------------------

func a_celda(pos: Vector2) -> Vector2i:
	return Vector2i(((pos + tamano / 2.0) / tamano * Vector2(ancho, alto)).floor())


func a_mundo(celda: Vector2i) -> Vector2:
	return (Vector2(celda) + Vector2(0.5, 0.5)) / Vector2(ancho, alto) * tamano - tamano / 2.0


func tamano_celda() -> float:
	return tamano.x / ancho


func clase_celda(x: int, y: int) -> int:
	return clases[clampi(y, 0, alto - 1) * ancho + clampi(x, 0, ancho - 1)]


func clase_en(pos: Vector2) -> int:
	var celda := a_celda(pos)
	return clase_celda(celda.x, celda.y)


# --- Colisiones -----------------------------------------------------------------------------

func transitable(pos: Vector2) -> bool:
	var celda := a_celda(pos)
	return _astar.is_in_boundsv(celda) and not _astar.is_point_solid(celda)


## ¿Cabe el explorador en ese punto?
func libre(pos: Vector2, radio := RADIO_EXPLORADOR) -> bool:
	return transitable(pos) and transitable(pos + Vector2(radio, 0)) and transitable(pos - Vector2(radio, 0)) \
		and transitable(pos + Vector2(0, radio)) and transitable(pos - Vector2(0, radio))


## Marca un obstáculo redondo (árbol, mirador, monolito...).
func bloquear_circulo(pos: Vector2, radio: float) -> void:
	var desde := a_celda(pos - Vector2(radio, radio))
	var hasta := a_celda(pos + Vector2(radio, radio))
	for y in range(desde.y, hasta.y + 1):
		for x in range(desde.x, hasta.x + 1):
			var celda := Vector2i(x, y)
			if _astar.is_in_boundsv(celda) and a_mundo(celda).distance_to(pos) <= radio:
				_astar.set_point_solid(celda)


## Mueve desde un punto evitando obstáculos: si choca, se desliza a lo largo de ellos.
func mover(desde: Vector2, desplazamiento: Vector2) -> Vector2:
	for intento in [desplazamiento, Vector2(desplazamiento.x, 0), Vector2(0, desplazamiento.y)]:
		if intento != Vector2.ZERO and libre(desde + intento):
			return desde + intento
	return desde


# --- Rutas ----------------------------------------------------------------------------------

## Ruta caminable de un punto a otro. Si el destino es agua u obstáculo, llega lo más cerca posible.
func camino(desde: Vector2, hasta: Vector2) -> PackedVector2Array:
	var inicio = _celda_libre_cercana(a_celda(desde))
	var fin = _celda_libre_cercana(a_celda(hasta))
	if inicio == null or fin == null:
		return PackedVector2Array()
	var puntos := PackedVector2Array()
	for celda in _astar.get_id_path(inicio, fin, true):
		puntos.append(a_mundo(celda))
	if not puntos.is_empty() and fin == a_celda(hasta) and libre(hasta):
		puntos[puntos.size() - 1] = hasta
	return _suavizar(desde, puntos)


## Quita los zigzags de la cuadrícula: va directo al punto más lejano que se vea sin obstáculos.
func _suavizar(desde: Vector2, puntos: PackedVector2Array) -> PackedVector2Array:
	var resultado := PackedVector2Array()
	var actual := desde
	var i := 0
	while i < puntos.size():
		var j := i
		while j + 1 < puntos.size() and _linea_libre(actual, puntos[j + 1]):
			j += 1
		resultado.append(puntos[j])
		actual = puntos[j]
		i = j + 1
	return resultado


func _linea_libre(a: Vector2, b: Vector2) -> bool:
	var pasos := ceili(a.distance_to(b) / (tamano_celda() * 0.5))
	for k in range(1, pasos + 1):
		if not libre(a.lerp(b, float(k) / pasos), RADIO_EXPLORADOR * 0.8):
			return false
	return true


func _celda_libre_cercana(celda: Vector2i):
	celda = celda.clamp(Vector2i.ZERO, Vector2i(ancho - 1, alto - 1))
	if not _astar.is_point_solid(celda):
		return celda
	for radio in range(1, 60):
		var mejor = null
		var menor := INF
		for dy in range(-radio, radio + 1):
			for dx in range(-radio, radio + 1):
				if maxi(absi(dx), absi(dy)) != radio:
					continue
				var vecina := celda + Vector2i(dx, dy)
				if _astar.is_in_boundsv(vecina) and not _astar.is_point_solid(vecina):
					var d := Vector2(dx, dy).length_squared()
					if d < menor:
						menor = d
						mejor = vecina
		if mejor != null:
			return mejor
	return null
