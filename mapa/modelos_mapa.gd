class_name ModelosMapa
## Modelos low-poly del humedal y la ciudad, hechos con figuras simples.
## Cada modelo se arma juntando primitivas; las piezas del mismo color quedan en una sola superficie.

const MADERA := Color(0.55, 0.38, 0.22)
const MADERA_OSCURA := Color(0.35, 0.24, 0.15)


static func crear(nombre: String) -> ArrayMesh:
	match nombre:
		"aliso": return _aliso()
		"eucalipto": return _eucalipto()
		"sauce": return _sauce()
		"arbusto": return _arbusto()
		"enea": return _enea()
		"junco": return _junco()
		"pasto_alto": return _pasto_alto()
		"buchon": return _buchon()
		"flores": return _flores()
		"casa": return _casa()
		"tanque": return _tanque()
		"basura": return _basura()
		"llanta": return _llanta()
		"mirador": return _mirador()
		"monolito": return _monolito()
		"compostera": return _compostera()
	push_error("Modelo desconocido: %s" % nombre)
	return null


# --- Árboles de la ronda --------------------------------------------------------------------

## Aliso: árbol nativo de copa redonda.
static func _aliso() -> ArrayMesh:
	return _construir([
		[_cilindro(0.12, 0.18, 1.2, 6), _t(Vector3(0, 0.6, 0)), Color(0.4, 0.28, 0.18)],
		[_esfera(0.9, 1.6), _t(Vector3(0, 1.8, 0)), Color(0.2, 0.45, 0.22)],
		[_esfera(0.6, 1.0), _t(Vector3(0.4, 2.3, 0.2)), Color(0.27, 0.52, 0.25)],
	])


## Eucalipto: alto y delgado, de corteza clara y follaje verde azulado (muy común en Bogotá).
static func _eucalipto() -> ArrayMesh:
	return _construir([
		[_cilindro(0.09, 0.16, 3.8, 6), _t(Vector3(0, 1.9, 0)), Color(0.7, 0.65, 0.55)],
		[_esfera(0.9, 1.0), _t(Vector3(0, 4.2, 0), Vector3(1, 2.4, 1)), Color(0.36, 0.5, 0.42)],
		[_esfera(0.6, 1.0), _t(Vector3(0.35, 3.4, 0.1), Vector3(1, 1.8, 1)), Color(0.4, 0.54, 0.45)],
	])


## Sauce: copa ancha con ramas que cuelgan.
static func _sauce() -> ArrayMesh:
	var cortina := _cilindro(1.15, 1.4, 1.3, 10)
	cortina.cap_top = false
	cortina.cap_bottom = false
	return _construir([
		[_cilindro(0.15, 0.22, 1.4, 6), _t(Vector3(0, 0.7, 0)), Color(0.38, 0.28, 0.2)],
		[_esfera(1.2, 1.4), _t(Vector3(0, 2.2, 0)), Color(0.45, 0.6, 0.3)],
		[cortina, _t(Vector3(0, 1.4, 0)), Color(0.5, 0.65, 0.32)],
	])


static func _arbusto() -> ArrayMesh:
	return _construir([
		[_esfera(0.5, 0.7), _t(Vector3(0, 0.3, 0)), Color(0.26, 0.48, 0.24)],
		[_esfera(0.35, 0.5), _t(Vector3(0.35, 0.25, 0.1)), Color(0.26, 0.48, 0.24)],
	])


# --- Plantas del humedal --------------------------------------------------------------------

## Enea (Typha): tallos altos con espigas cafés.
static func _enea() -> ArrayMesh:
	var tallo := _cilindro(0.02, 0.04, 1.6, 4)
	var espiga := _cilindro(0.06, 0.06, 0.3, 5)
	var partes := []
	for i in 5:
		var inclinado := _inclinado(TAU * i / 5.0, 0.12)
		var base := Vector3(cos(TAU * i / 5.0), 0, sin(TAU * i / 5.0)) * 0.12
		partes.append([tallo, Transform3D(inclinado, base + inclinado * Vector3(0, 0.8, 0)), Color(0.35, 0.55, 0.25)])
		if i % 2 == 0:
			partes.append([espiga, Transform3D(inclinado, base + inclinado * Vector3(0, 1.3, 0)), Color(0.4, 0.25, 0.12)])
	return _construir(partes)


## Junco: tallos delgados, redondos y oscuros.
static func _junco() -> ArrayMesh:
	var tallo := _cilindro(0.015, 0.03, 1.5, 3)
	var partes := []
	for i in 7:
		var angulo := TAU * i / 7.0
		var inclinado := _inclinado(angulo, 0.08 + 0.05 * (i % 3))
		var base := Vector3(cos(angulo), 0, sin(angulo)) * 0.1
		partes.append([tallo, Transform3D(inclinado, base + inclinado * Vector3(0, 0.75, 0)), Color(0.2, 0.4, 0.2)])
	return _construir(partes)


## Mata de kikuyo alto (pasto invasor).
static func _pasto_alto() -> ArrayMesh:
	var hoja := _cilindro(0.0, 0.07, 0.7, 3)
	var partes := []
	for i in 4:
		var inclinado := _inclinado(TAU * i / 4.0 + 0.4, 0.3)
		partes.append([hoja, Transform3D(inclinado, inclinado * Vector3(0, 0.35, 0)), Color(0.6, 0.62, 0.28)])
	return _construir(partes)


## Buchón de agua: hojas flotantes con una flor lila.
static func _buchon() -> ArrayMesh:
	var hoja := _cilindro(0.25, 0.25, 0.03, 7)
	return _construir([
		[hoja, _t(Vector3(0, 0.02, 0)), Color(0.3, 0.55, 0.28)],
		[hoja, _t(Vector3(0.35, 0.02, 0.1)), Color(0.3, 0.55, 0.28)],
		[hoja, _t(Vector3(0.1, 0.02, 0.35)), Color(0.3, 0.55, 0.28)],
		[_esfera(0.1, 0.2), _t(Vector3(0.15, 0.12, 0.15)), Color(0.72, 0.56, 0.86)],
	])


## Flores: puntos de color (el color lo pone cada instancia).
static func _flores() -> ArrayMesh:
	var flor := _esfera(0.08, 0.16)
	return _construir([
		[flor, _t(Vector3(0, 0.08, 0)), Color.WHITE],
		[flor, _t(Vector3(0.2, 0.08, 0.1)), Color.WHITE],
		[flor, _t(Vector3(-0.1, 0.08, 0.2)), Color.WHITE],
	])


# --- Ciudad ---------------------------------------------------------------------------------

## Casa: caja de 1x1x1 apoyada en el suelo; el tamaño y el color los pone cada instancia.
static func _casa() -> ArrayMesh:
	return _construir([[BoxMesh.new(), _t(Vector3(0, 0.5, 0)), Color.WHITE]])


## Tanque de agua en la terraza (el color lo pone cada instancia).
static func _tanque() -> ArrayMesh:
	return _construir([[_cilindro(0.32, 0.32, 0.55, 8), _t(Vector3(0, 0.27, 0)), Color.WHITE]])


# --- Objetos de las zonas -------------------------------------------------------------------

## Bolsa de basura (el color lo pone cada instancia).
static func _basura() -> ArrayMesh:
	return _construir([[_esfera(0.22, 0.3), _t(Vector3(0, 0.12, 0)), Color.WHITE]])


static func _llanta() -> ArrayMesh:
	var llanta := TorusMesh.new()
	llanta.inner_radius = 0.18
	llanta.outer_radius = 0.35
	llanta.rings = 10
	llanta.ring_segments = 6
	return _construir([[llanta, _t(Vector3(0, 0.09, 0)), Color(0.08, 0.08, 0.08)]])


## Mirador de madera para observar aves.
static func _mirador() -> ArrayMesh:
	var partes := []
	var poste := _cilindro(0.1, 0.1, 4.2, 6)
	for esquina in [Vector3(1.1, 0, 1.1), Vector3(-1.1, 0, 1.1), Vector3(1.1, 0, -1.1), Vector3(-1.1, 0, -1.1)]:
		partes.append([poste, _t(esquina + Vector3(0, 2.1, 0)), MADERA_OSCURA])
	partes.append([_caja(Vector3(2.8, 0.2, 2.8)), _t(Vector3(0, 3.2, 0)), MADERA])
	for lado in [Vector3(0, 0, 1.35), Vector3(0, 0, -1.35)]:
		partes.append([_caja(Vector3(2.8, 0.5, 0.08)), _t(lado + Vector3(0, 3.55, 0)), MADERA])
	partes.append([_caja(Vector3(0.08, 0.5, 2.8)), _t(Vector3(-1.35, 3.55, 0)), MADERA])
	var techo := _cilindro(0.0, 2.1, 1.0, 4)
	partes.append([techo, Transform3D(Basis(Vector3.UP, PI / 4.0), Vector3(0, 4.7, 0)), Color(0.3, 0.2, 0.12)])
	# Escalera: rampa del suelo (x = 2.9) hasta el borde de la plataforma (x = 1.4, y = 3.2)
	partes.append([_caja(Vector3(3.6, 0.12, 0.8)), Transform3D(Basis(Vector3.BACK, -1.13), Vector3(2.15, 1.6, 0.8)), MADERA])
	return _construir(partes)


static func _monolito() -> ArrayMesh:
	return _construir([
		[_caja(Vector3(0.7, 2.2, 0.5)), _t(Vector3(0, 1.1, 0)), Color(0.5, 0.5, 0.47)],
		[_caja(Vector3(0.5, 0.2, 0.36)), _t(Vector3(0, 2.25, 0)), Color(0.45, 0.46, 0.42)],
	])


## Cajón de compost o lombricultivo.
static func _compostera() -> ArrayMesh:
	return _construir([
		[_caja(Vector3(1.6, 0.8, 1.0)), _t(Vector3(0, 0.4, 0)), MADERA],
		[_caja(Vector3(1.45, 0.1, 0.85)), _t(Vector3(0, 0.82, 0)), Color(0.22, 0.15, 0.1)],
	])


# --- Utilidades -----------------------------------------------------------------------------

static func _esfera(radio: float, alto: float) -> SphereMesh:
	var esfera := SphereMesh.new()
	esfera.radius = radio
	esfera.height = alto
	esfera.radial_segments = 8
	esfera.rings = 4
	return esfera


static func _cilindro(arriba: float, abajo: float, alto: float, lados: int) -> CylinderMesh:
	var cilindro := CylinderMesh.new()
	cilindro.top_radius = arriba
	cilindro.bottom_radius = abajo
	cilindro.height = alto
	cilindro.radial_segments = lados
	cilindro.rings = 1
	return cilindro


static func _caja(tamano: Vector3) -> BoxMesh:
	var caja := BoxMesh.new()
	caja.size = tamano
	return caja


static func _t(posicion: Vector3, escala := Vector3.ONE) -> Transform3D:
	return Transform3D(Basis.from_scale(escala), posicion)


## Rotación que inclina un tallo hacia afuera en la dirección del ángulo dado.
static func _inclinado(angulo: float, cuanto: float) -> Basis:
	var hacia_afuera := Vector3(cos(angulo), 0, sin(angulo))
	return Basis(hacia_afuera.cross(Vector3.UP).normalized(), -cuanto)


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
		mat.vertex_color_use_as_albedo = true   # permite dar color por instancia (flores, casas...)
		var st: SurfaceTool = por_color[color]
		st.set_material(mat)
		st.commit(malla)
	return malla
