class_name ModelosEspecies
## Modelo 3D de cada especie para la cámara (realidad aumentada) y las batallas.
##
## MODELOS HECHOS A MANO (Blender u otro programa):
##   Exporta el modelo como glTF binario (.glb) y guárdalo con el id de la especie:
##       res://animales/modelos/<id>.glb      por ejemplo: res://animales/modelos/mariquita.glb
##   (también sirve .gltf o una escena .tscn). Al abrir el proyecto en Godot se importa solo.
##   - El animal debe mirar hacia adelante (+Z de Godot = la exportación por defecto de Blender
##     con el animal mirando hacia -Y) y estar parado sobre el suelo.
##   - El tamaño no importa: aquí se escala y se centra automáticamente.
##   - Si trae animaciones, se reproduce en bucle la llamada "idle", "reposo" o "volar"
##     (o la primera que tenga).
##
## Si la especie no tiene modelo propio se usa uno generado con figuras (ModeloProcedural).

const CARPETA := "res://animales/modelos/"
const EXTENSIONES := ["glb", "gltf", "tscn", "scn"]
const ANIMACIONES_PREFERIDAS := ["idle", "reposo", "volar", "fly", "caminar", "walk"]


## Ruta del modelo hecho a mano, o "" si no hay.
static func ruta_modelo(especie: Especie) -> String:
	for extension in EXTENSIONES:
		var ruta := "%s%s.%s" % [CARPETA, especie.id, extension]
		if ResourceLoader.exists(ruta):
			return ruta
	return ""


static func tiene_modelo_propio(especie: Especie) -> bool:
	return not ruta_modelo(especie).is_empty()


## Modelo listo para usar: mira a +Z, parado en y = 0, centrado y con "tamano" como medida mayor.
## Devuelve null si la especie no tiene modelo (ni propio ni generado), por ejemplo las plantas.
static func crear(especie: Especie, tamano := 1.0) -> Node3D:
	var modelo: Node3D = null
	var ruta := ruta_modelo(especie)
	if not ruta.is_empty():
		var escena := load(ruta) as PackedScene
		if escena:
			modelo = escena.instantiate() as Node3D
		if modelo == null:
			push_warning("El modelo %s no tiene una raíz 3D; se usa el generado." % ruta)
	if modelo == null:
		modelo = ModeloProcedural.crear(especie)
	if modelo == null:
		return null

	# contenedor -> ajuste (escala y centra) -> modelo (con su propia transformación intacta)
	var contenedor := Node3D.new()
	contenedor.name = "Modelo_" + especie.id
	var ajuste := Node3D.new()
	ajuste.name = "Ajuste"
	contenedor.add_child(ajuste)
	ajuste.add_child(modelo)
	var caja := _caja(ajuste)
	if caja.size != Vector3.ZERO:
		var escala := tamano / maxf(caja.size.x, maxf(caja.size.y, caja.size.z))
		var centro := caja.get_center()
		ajuste.scale = Vector3.ONE * escala
		ajuste.position = Vector3(-centro.x, -caja.position.y, -centro.z) * escala
	_animar(modelo)
	return contenedor


## Caja que encierra todas las mallas del modelo (sin necesidad de que esté en la escena).
static func _caja(raiz: Node3D) -> AABB:
	var caja := AABB()
	var primera := true
	for nodo in raiz.find_children("*", "VisualInstance3D", true, false):
		var visual := nodo as VisualInstance3D
		var transformacion := Transform3D()
		var actual: Node = visual
		while actual != raiz and actual is Node3D:
			transformacion = (actual as Node3D).transform * transformacion
			actual = actual.get_parent()
		var parte := transformacion * visual.get_aabb()
		caja = parte if primera else caja.merge(parte)
		primera = false
	return caja


static func _animar(modelo: Node3D) -> void:
	var reproductores := modelo.find_children("*", "AnimationPlayer", true, false)
	if reproductores.is_empty():
		return
	var reproductor := reproductores[0] as AnimationPlayer
	var lista := reproductor.get_animation_list()
	if lista.is_empty():
		return
	var elegida := lista[0]
	for preferida in ANIMACIONES_PREFERIDAS:
		for nombre in lista:
			if nombre.to_lower().contains(preferida):
				elegida = nombre
				break
		if elegida != lista[0]:
			break
	reproductor.get_animation(elegida).loop_mode = Animation.LOOP_LINEAR
	reproductor.play(elegida)
