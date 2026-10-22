class_name ModelosMapa
## Modelos low-poly de la vegetación y los edificios del mapa, hechos con figuras simples.
## Cada modelo se arma juntando primitivas; las piezas del mismo color quedan en una sola superficie.


static func crear(nombre: String) -> ArrayMesh:
	match nombre:
		"arbol": return _arbol()
		"arbusto": return _arbusto()
		"enea": return _enea()
		"buchon": return _buchon()
		"flores": return _flores()
		"edificio": return _edificio()
	push_error("Modelo desconocido: %s" % nombre)
	return null


static func _arbol() -> ArrayMesh:
	var tronco := CylinderMesh.new()
	tronco.top_radius = 0.12
	tronco.bottom_radius = 0.18
	tronco.height = 1.2
	tronco.radial_segments = 6
	var copa := _esfera(0.9, 1.6)
	var copa_chica := _esfera(0.6, 1.0)
	return _construir([
		[tronco, Transform3D(Basis(), Vector3(0, 0.6, 0)), Color(0.4, 0.28, 0.18)],
		[copa, Transform3D(Basis(), Vector3(0, 1.8, 0)), Color(0.22, 0.5, 0.25)],
		[copa_chica, Transform3D(Basis(), Vector3(0.4, 2.3, 0.2)), Color(0.3, 0.58, 0.28)],
	])


static func _arbusto() -> ArrayMesh:
	return _construir([
		[_esfera(0.5, 0.7), Transform3D(Basis(), Vector3(0, 0.3, 0)), Color(0.28, 0.52, 0.26)],
		[_esfera(0.35, 0.5), Transform3D(Basis(), Vector3(0.35, 0.25, 0.1)), Color(0.28, 0.52, 0.26)],
	])


## Enea (Typha): tallos altos y delgados con espigas cafés.
static func _enea() -> ArrayMesh:
	var tallo := CylinderMesh.new()
	tallo.top_radius = 0.02
	tallo.bottom_radius = 0.04
	tallo.height = 1.6
	tallo.radial_segments = 4
	tallo.rings = 1
	var espiga := CylinderMesh.new()
	espiga.top_radius = 0.06
	espiga.bottom_radius = 0.06
	espiga.height = 0.3
	espiga.radial_segments = 5
	espiga.rings = 1
	var partes := []
	for i in 5:
		var angulo := TAU * i / 5.0
		var inclinacion := Basis(Vector3(cos(angulo), 0, sin(angulo)).cross(Vector3.UP), -0.12)
		var base := Vector3(cos(angulo), 0, sin(angulo)) * 0.12
		partes.append([tallo, Transform3D(inclinacion, base + inclinacion * Vector3(0, 0.8, 0)), Color(0.35, 0.55, 0.25)])
		if i % 2 == 0:
			partes.append([espiga, Transform3D(inclinacion, base + inclinacion * Vector3(0, 1.3, 0)), Color(0.4, 0.25, 0.12)])
	return _construir(partes)


## Buchón de agua: hojas flotantes con una flor lila.
static func _buchon() -> ArrayMesh:
	var hoja := CylinderMesh.new()
	hoja.top_radius = 0.25
	hoja.bottom_radius = 0.25
	hoja.height = 0.03
	hoja.radial_segments = 7
	hoja.rings = 1
	return _construir([
		[hoja, Transform3D(Basis(), Vector3(0, 0.02, 0)), Color(0.3, 0.6, 0.3)],
		[hoja, Transform3D(Basis(), Vector3(0.35, 0.02, 0.1)), Color(0.3, 0.6, 0.3)],
		[hoja, Transform3D(Basis(), Vector3(0.1, 0.02, 0.35)), Color(0.3, 0.6, 0.3)],
		[_esfera(0.1, 0.2), Transform3D(Basis(), Vector3(0.15, 0.12, 0.15)), Color(0.72, 0.56, 0.86)],
	])


## Flores: puntos de color (el color lo pone cada instancia).
static func _flores() -> ArrayMesh:
	var flor := _esfera(0.08, 0.16)
	return _construir([
		[flor, Transform3D(Basis(), Vector3(0, 0.08, 0)), Color.WHITE],
		[flor, Transform3D(Basis(), Vector3(0.2, 0.08, 0.1)), Color.WHITE],
		[flor, Transform3D(Basis(), Vector3(-0.1, 0.08, 0.2)), Color.WHITE],
	])


## Edificio: una caja de 1x1x1 apoyada en el suelo; el tamaño y el color los pone cada instancia.
static func _edificio() -> ArrayMesh:
	var caja := BoxMesh.new()
	return _construir([[caja, Transform3D(Basis(), Vector3(0, 0.5, 0)), Color.WHITE]])


static func _esfera(radio: float, alto: float) -> SphereMesh:
	var esfera := SphereMesh.new()
	esfera.radius = radio
	esfera.height = alto
	esfera.radial_segments = 8
	esfera.rings = 4
	return esfera


## partes: [[PrimitiveMesh, Transform3D, Color], ...]
static func _construir(partes: Array) -> ArrayMesh:
	var por_color := {}
	for parte in partes:
		var color: Color = parte[2]
		if not por_color.has(color):
			var nuevo := SurfaceTool.new()
			nuevo.begin(Mesh.PRIMITIVE_TRIANGLES)
			por_color[color] = nuevo
		por_color[color].append_from(parte[0], 0, parte[1])

	var malla := ArrayMesh.new()
	for color in por_color:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.vertex_color_use_as_albedo = true   # permite dar color por instancia (flores, edificios)
		var st: SurfaceTool = por_color[color]
		st.set_material(mat)
		st.commit(malla)
	return malla
