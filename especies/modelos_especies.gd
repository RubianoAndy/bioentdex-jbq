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
##   - Fases del ciclo de vida ("evoluciones"): <id>_huevo.glb, <id>_larva.glb, <id>_pupa.glb,
##     <id>_ninfa.glb (por ejemplo mariquita_larva.glb). El adulto es <id>.glb.
##
## Si la especie no tiene modelo propio se usa uno generado con figuras (ModeloProcedural).

const CARPETA := "res://animales/modelos/"
const EXTENSIONES := ["glb", "gltf", "tscn", "scn"]
const ANIMACIONES_PREFERIDAS := ["idle", "reposo", "volar", "fly", "caminar", "walk"]


## Ruta del modelo hecho a mano, o "" si no hay.
static func ruta_modelo(especie: Especie, etapa := "") -> String:
	var nombre := especie.id
	if not etapa.is_empty() and etapa.to_lower() != "adulto":
		nombre += "_" + etapa.to_lower()
	for extension in EXTENSIONES:
		var ruta := "%s%s.%s" % [CARPETA, nombre, extension]
		if ResourceLoader.exists(ruta):
			return ruta
	return ""


static func tiene_modelo_propio(especie: Especie) -> bool:
	return not ruta_modelo(especie).is_empty()


## Modelo listo para usar: mira a +Z, parado en y = 0, centrado y con "tamano" como medida mayor.
## Devuelve null si la especie no tiene modelo (ni propio ni generado), por ejemplo las plantas.
## "etapa" es una fase del ciclo de vida ("Huevo", "Larva"...); vacía o "Adulto" = el adulto.
static func crear(especie: Especie, tamano := 1.0, etapa := "") -> Node3D:
	var modelo: Node3D = null
	var ruta := ruta_modelo(especie, etapa)
	if not ruta.is_empty():
		var escena := load(ruta) as PackedScene
		if escena:
			modelo = escena.instantiate() as Node3D
		if modelo == null:
			push_warning("El modelo %s no tiene una raíz 3D; se usa el generado." % ruta)
	if modelo == null:
		modelo = ModeloProcedural.crear_etapa(especie, etapa)
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


## Dibuja unos modelos en un SubViewport invisible durante unos cuadros para que el celular compile
## sus materiales antes de que se necesiten (si no, la primera captura o batalla se congela un
## momento mientras compila). Se llama al abrir el mapa.
static func precalentar(padre: Node) -> void:
	var vista := SubViewport.new()
	vista.size = Vector2i(64, 64)
	vista.transparent_bg = true
	vista.own_world_3d = true
	vista.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	padre.add_child(vista)
	var camara := Camera3D.new()
	camara.position = Vector3(0, 1, 4)
	vista.add_child(camara)
	vista.add_child(DirectionalLight3D.new())
	# Variedad de materiales: opacos, metálicos, alas transparentes y brillos sin luz
	for id in ["mariquita", "mosca_metalica", "mariposa_monarca", "garza_blanca"]:
		var especie := RegistroEspecies.buscar(id)
		if especie:
			var modelo := crear(especie, 1.0)
			if modelo:
				vista.add_child(modelo)
	for i in 3:
		await RenderingServer.frame_post_draw
	if is_instance_valid(vista):
		vista.queue_free()
