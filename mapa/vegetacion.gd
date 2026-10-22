extends Node3D
## Llena el mapa con vegetación y edificios según la máscara de colores: eneas en el juncal,
## árboles en el bosque, buchón en el agua, flores en la pradera y edificios en la ciudad.
## Usa MultiMesh: miles de plantas con muy pocas llamadas de dibujo (importante en el celular).

const PASO := 2   # se revisa 1 de cada 2 píxeles de la máscara

## Por cada tipo de suelo: [modelo, probabilidad de poner uno en cada punto revisado]
const REGLAS := {
	PaletaMapa.JUNCAL: [["enea", 0.30]],
	PaletaMapa.BOSQUE: [["arbol", 0.10], ["arbusto", 0.06]],
	PaletaMapa.PASTO: [["arbol", 0.006], ["arbusto", 0.012], ["flores", 0.02]],
	PaletaMapa.PRADERA: [["flores", 0.08], ["arbusto", 0.004]],
	PaletaMapa.FLOTANTES: [["buchon", 0.35]],
	PaletaMapa.AGUA: [["buchon", 0.004]],
	PaletaMapa.CIUDAD: [["edificio", 0.012]],
}

const COLORES_FLORES := [Color(1, 0.85, 0.2), Color(1, 1, 1), Color(0.75, 0.55, 0.95), Color(0.95, 0.35, 0.3)]
const COLORES_EDIFICIOS := [Color(0.62, 0.32, 0.22), Color(0.7, 0.4, 0.28), Color(0.75, 0.75, 0.72), Color(0.85, 0.8, 0.68)]


func generar(mascara: Texture2D, tamano: Vector2, zonas: Array) -> void:
	var img := mascara.get_image()
	var ancho := img.get_width()
	var alto := img.get_height()
	var tam_pixel := tamano / Vector2(ancho, alto)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2024   # semilla fija: el mapa siempre queda igual
	var cache_clases := {}
	var instancias := {}   # modelo -> [[Transform3D, Color], ...]

	for y in range(0, alto, PASO):
		for x in range(0, ancho, PASO):
			var clase := _clase(img, x, y, cache_clases)
			if not REGLAS.has(clase):
				continue
			for regla in REGLAS[clase]:
				if rng.randf() >= regla[1]:
					continue
				var modelo: String = regla[0]
				var pos := Vector2(x + rng.randf() * PASO, y + rng.randf() * PASO) * tam_pixel - tamano / 2.0
				if _cerca_de_zona(pos, zonas, modelo == "arbol"):
					break
				if modelo in ["arbol", "arbusto"] and _clase_cerca(img, x, y, 6, PaletaMapa.SENDERO, cache_clases):
					break
				# Edificios solo lejos del humedal, para que no tapen la vista
				if modelo == "edificio" and _clase_cerca(img, x, y, 16, -PaletaMapa.CIUDAD, cache_clases):
					break
				if not instancias.has(modelo):
					instancias[modelo] = []
				instancias[modelo].append(_instancia(modelo, pos, rng))
				break

	for modelo in instancias:
		_crear_multimesh(modelo, instancias[modelo])


func _instancia(modelo: String, pos: Vector2, rng: RandomNumberGenerator) -> Array:
	var giro := Basis(Vector3.UP, rng.randf() * TAU)
	var escala := Vector3.ONE * rng.randf_range(0.8, 1.3)
	var color := Color.WHITE
	match modelo:
		"edificio":
			escala = Vector3(rng.randf_range(2.0, 4.0), rng.randf_range(1.5, 4.0), rng.randf_range(2.0, 4.0))
			giro = Basis()   # las cuadras van alineadas
			color = COLORES_EDIFICIOS[rng.randi() % COLORES_EDIFICIOS.size()]
		"flores":
			color = COLORES_FLORES[rng.randi() % COLORES_FLORES.size()]
	return [Transform3D(giro.scaled(escala), Vector3(pos.x, 0, pos.y)), color]


func _crear_multimesh(modelo: String, lista: Array) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = modelo in ["flores", "edificio"]
	mm.mesh = ModelosMapa.crear(modelo)
	mm.instance_count = lista.size()
	for i in lista.size():
		mm.set_instance_transform(i, lista[i][0])
		if mm.use_colors:
			mm.set_instance_color(i, lista[i][1])
	var nodo := MultiMeshInstance3D.new()
	nodo.name = modelo.capitalize()
	nodo.multimesh = mm
	nodo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(nodo)


func _clase(img: Image, x: int, y: int, cache: Dictionary) -> int:
	var color := img.get_pixel(clampi(x, 0, img.get_width() - 1), clampi(y, 0, img.get_height() - 1))
	if not cache.has(color):
		cache[color] = PaletaMapa.clase(color)
	return cache[color]


## ¿Hay un píxel de esa clase a esa distancia (en 8 direcciones)? Con clase negativa busca
## cualquier píxel que NO sea de esa clase (-PaletaMapa.CIUDAD = "algo que no es ciudad").
func _clase_cerca(img: Image, x: int, y: int, radio: int, clase: int, cache: Dictionary) -> bool:
	for k in 9:
		var d := Vector2i.ZERO if k == 8 else Vector2i(Vector2.from_angle(TAU * k / 8.0) * radio)
		var encontrada := _clase(img, x + d.x, y + d.y, cache)
		if (clase >= 0 and encontrada == clase) or (clase < 0 and encontrada != -clase):
			return true
	return false


## Los árboles dejan más espacio, sobre todo hacia el sur (del lado de la cámara), para no tapar la zona.
func _cerca_de_zona(pos: Vector2, zonas: Array, es_alto: bool) -> bool:
	for zona in zonas:
		var d: Vector2 = pos - zona.posicion
		if es_alto and d.y > 0.0:
			d.y *= 0.4
		if d.length() < zona.radio + (2.5 if es_alto else 1.0):
			return true
	return false
