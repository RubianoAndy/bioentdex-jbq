extends Node3D
## Personaje del jugador. Camina siguiendo una ruta (toque) o se mueve directo (arrastre / teclado).
## No atraviesa agua, árboles ni casas: el Terreno le da las rutas y las colisiones.
## El modelo se arma con figuras simples dentro de "Modelo" según el Perfil (género, colores, sombrero).
## El frente del modelo mira a -Z.

@export var velocidad := 7.0

# Colores fijos del atuendo (cuero, botas, rostro…)
const CUERO := Color(0.56, 0.39, 0.22)
const CUERO_OSCURO := Color(0.36, 0.24, 0.13)
const BOTA := Color(0.5, 0.31, 0.17)
const SUELA := Color(0.17, 0.12, 0.09)
const BLANCO := Color(0.95, 0.94, 0.9)
const OJO := Color(0.2, 0.12, 0.08)
const MEJILLA := Color(0.95, 0.52, 0.55)
const BOCA := Color(0.62, 0.26, 0.28)
const LEGGINGS := Color(0.13, 0.12, 0.14)
const FLOR := Color(0.92, 0.42, 0.85)
const CENTRO_FLOR := Color(1, 0.85, 0.35)
const METAL := Color(0.8, 0.78, 0.72)
const CINTURON_ELLA := Color(0.62, 0.26, 0.2)

var terreno: Terreno
var _camino := PackedVector2Array()
var _movio := false
var _fase_paso := 0.0
var _amplitud_paso := 0.0

var cadera_izq: Node3D
var cadera_der: Node3D
var hombro_izq: Node3D
var hombro_der: Node3D

var _grupos := {}             # grupo de color -> [MeshInstance3D]
var _con_sombrero: Array = []
var _con_gorra: Array = []
var _sin_sombrero: Array = []  # piezas que chocarían con el sombrero o la gorra
var _sin_gorra: Array = []     # piezas que solo chocan con la gorra

@onready var modelo: Node3D = $Modelo


func _ready() -> void:
	aplicar_perfil()


## Arma el modelo con el género, los colores y el sombrero elegidos en "Personalizar explorador".
func aplicar_perfil() -> void:
	_construir(Perfil.genero == 1)

	var piel: Color = Perfil.PIELES[Perfil.piel]
	var camisa: Color = Perfil.CAMISAS[Perfil.camisa]
	var pantalon: Color = Perfil.PANTALONES[Perfil.pantalon]
	var mochila: Color = Perfil.MOCHILAS[Perfil.mochila]
	var sombrero: Color = Perfil.COLORES_SOMBRERO[Perfil.color_sombrero]
	var colores := {
		"piel": piel, "piel_oscura": piel.darkened(0.12),
		"camisa": camisa, "camisa_oscura": camisa.darkened(0.25), "acento": camisa.lightened(0.15),
		"pantalon": pantalon, "pantalon_oscuro": pantalon.darkened(0.3),
		"cabello": Perfil.CABELLOS[Perfil.cabello],
		"mochila": mochila, "mochila_oscura": mochila.darkened(0.3),
		"sombrero": sombrero, "cinta": sombrero.darkened(0.5),
		"cuero": CUERO, "cuero_oscuro": CUERO_OSCURO, "bota": BOTA, "suela": SUELA, "blanco": BLANCO,
		"ojo": OJO, "mejilla": MEJILLA, "boca": BOCA, "leggings": LEGGINGS, "flor": FLOR,
		"centro_flor": CENTRO_FLOR, "metal": METAL, "cinturon_ella": CINTURON_ELLA,
	}
	for grupo in _grupos:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = colores.get(grupo, Color.MAGENTA)
		mat.roughness = 0.85
		if grupo in ["ojo", "metal"]:
			mat.roughness = 0.3
		for pieza in _grupos[grupo]:
			pieza.material_override = mat

	for pieza in _con_sombrero:
		pieza.visible = Perfil.sombrero == 0
	for pieza in _con_gorra:
		pieza.visible = Perfil.sombrero == 1
	for pieza in _sin_sombrero:
		pieza.visible = Perfil.sombrero == 2
	for pieza in _sin_gorra:
		pieza.visible = Perfil.sombrero != 1


# --- Construcción del modelo --------------------------------------------------------------------

func _construir(ella: bool) -> void:
	for hijo in modelo.get_children():
		modelo.remove_child(hijo)
		hijo.queue_free()
	_grupos.clear()
	_con_sombrero.clear()
	_con_gorra.clear()
	_sin_sombrero.clear()
	_sin_gorra.clear()

	cadera_izq = _articulacion("CaderaIzq", Vector3(-0.1, 0.62, 0))
	cadera_der = _articulacion("CaderaDer", Vector3(0.1, 0.62, 0))
	for cadera in [cadera_izq, cadera_der]:
		_pierna(cadera, ella)

	_torso(ella)

	var x_hombro := 0.235 if ella else 0.25
	hombro_izq = _articulacion("HombroIzq", Vector3(-x_hombro, 1.06, 0))
	hombro_der = _articulacion("HombroDer", Vector3(x_hombro, 1.06, 0))
	_brazo(hombro_izq, ella, true)
	_brazo(hombro_der, ella, false)

	_cabeza(ella)
	_mochila()
	_sombreros()


func _pierna(cadera: Node3D, ella: bool) -> void:
	var lado := signf(cadera.position.x)
	if ella:
		_pieza(cadera, _capsula(0.075, 0.5), "leggings", Vector3(0, -0.25, 0))
		_pieza(cadera, _cilindro(0.1, 0.112, 0.16), "pantalon", Vector3(0, -0.06, 0))
		_pieza(cadera, _toro(0.1, 0.122), "blanco", Vector3(0, -0.14, 0))
		_pieza(cadera, _cilindro(0.088, 0.09, 0.09), "acento", Vector3(0, -0.43, 0))
	else:
		_pieza(cadera, _capsula(0.088, 0.5), "pantalon", Vector3(0, -0.25, 0))
		# Bolsillo cargo a un lado del muslo
		_pieza(cadera, _caja(Vector3(0.03, 0.1, 0.09)), "pantalon_oscuro", Vector3(lado * 0.085, -0.2, 0))
		_pieza(cadera, _caja(Vector3(0.035, 0.025, 0.095)), "pantalon_oscuro", Vector3(lado * 0.087, -0.145, 0))
	# Bota de cuero con suela y doblez
	_pieza(cadera, _cilindro(0.092, 0.095, 0.14), "bota", Vector3(0, -0.52, 0))
	_pieza(cadera, _toro(0.085, 0.11), "cuero_oscuro", Vector3(0, -0.45, 0))
	_pieza(cadera, _caja(Vector3(0.15, 0.08, 0.23)), "bota", Vector3(0, -0.565, -0.045))
	_pieza(cadera, _caja(Vector3(0.16, 0.025, 0.245)), "suela", Vector3(0, -0.605, -0.045))
	# Cordones
	for i in 3:
		_pieza(cadera, _caja(Vector3(0.06, 0.008, 0.01)), "suela", Vector3(0, -0.47 - i * 0.035, -0.093))


func _torso(ella: bool) -> void:
	var ancho := 0.92 if ella else 1.0
	_pieza(modelo, _capsula(0.2, 0.5), "camisa", Vector3(0, 0.9, 0), Vector3.ZERO, Vector3(ancho, 1, 1), "Torso")
	# Cadera / pantalón
	_pieza(modelo, _esfera(0.2), "pantalon", Vector3(0, 0.66, 0), Vector3.ZERO, Vector3(ancho, 0.55, 0.9))
	_pieza(modelo, _cilindro(0.065, 0.07, 0.1), "piel", Vector3(0, 1.18, 0))

	if ella:
		# Chaleco corto abierto
		_pieza(modelo, _cilindro(0.208, 0.214, 0.3), "cuero", Vector3(0, 0.95, 0), Vector3.ZERO, Vector3(0.95, 1, 1))
		_pieza(modelo, _caja(Vector3(0.11, 0.3, 0.01)), "camisa", Vector3(0, 0.95, -0.212))
		for lado: float in [-1.0, 1.0]:
			_pieza(modelo, _caja(Vector3(0.012, 0.3, 0.008)), "cuero_oscuro", Vector3(lado * 0.058, 0.95, -0.213))
		# Cinturón rojizo con hebilla morada, un poco caído
		_pieza(modelo, _toro(0.18, 0.215), "cinturon_ella", Vector3(0, 0.69, 0), Vector3(0, 0, 0.08))
		_pieza(modelo, _caja(Vector3(0.07, 0.05, 0.02)), "acento", Vector3(0, 0.695, -0.212))
		# Gargantilla
		_pieza(modelo, _toro(0.062, 0.075), "suela", Vector3(0, 1.17, 0))
	else:
		# Capucha del buzo detrás del cuello y cordones
		_pieza(modelo, _esfera(0.15), "camisa", Vector3(0, 1.13, 0.1), Vector3.ZERO, Vector3(1.3, 0.6, 0.85))
		for lado: float in [-1.0, 1.0]:
			_pieza(modelo, _cilindro(0.008, 0.008, 0.13), "blanco", Vector3(lado * 0.035, 1.02, -0.198))
		# Chaleco con cremallera y bolsillos
		_pieza(modelo, _cilindro(0.215, 0.222, 0.4), "cuero", Vector3(0, 0.87, 0))
		_pieza(modelo, _toro(0.19, 0.225), "cuero_oscuro", Vector3(0, 1.07, 0))
		_pieza(modelo, _caja(Vector3(0.09, 0.4, 0.01)), "camisa", Vector3(0, 0.87, -0.219))
		for lado: float in [-1.0, 1.0]:
			_pieza(modelo, _caja(Vector3(0.008, 0.4, 0.008)), "metal", Vector3(lado * 0.047, 0.87, -0.221))
			_pieza(modelo, _caja(Vector3(0.075, 0.075, 0.012)), "cuero_oscuro", Vector3(lado * 0.105, 0.97, -0.193), Vector3(0, -lado * 0.5, 0))
			_pieza(modelo, _caja(Vector3(0.08, 0.025, 0.016)), "cuero_oscuro", Vector3(lado * 0.106, 1.0, -0.196), Vector3(0, -lado * 0.5, 0))
			_pieza(modelo, _caja(Vector3(0.085, 0.09, 0.012)), "cuero_oscuro", Vector3(lado * 0.11, 0.77, -0.191), Vector3(0, -lado * 0.52, 0))
		# Camiseta blanca asomando bajo el chaleco y cinturón
		_pieza(modelo, _cilindro(0.2, 0.205, 0.04), "blanco", Vector3(0, 0.665, 0))
		_pieza(modelo, _toro(0.185, 0.215), "cuero_oscuro", Vector3(0, 0.63, 0))


func _brazo(hombro: Node3D, ella: bool, izquierdo: bool) -> void:
	if ella:
		# Manga abombada caída del hombro y antebrazo descubierto
		_pieza(hombro, _esfera(0.085), "camisa", Vector3(0, -0.1, 0), Vector3.ZERO, Vector3(1, 1.15, 1))
		_pieza(hombro, _toro(0.07, 0.09), "camisa_oscura", Vector3(0, -0.17, 0))
		_pieza(hombro, _capsula(0.05, 0.3), "piel", Vector3(0, -0.27, 0))
		if izquierdo:
			_pieza(hombro, _cilindro(0.056, 0.058, 0.06), "cuero_oscuro", Vector3(0, -0.36, 0))
	else:
		_pieza(hombro, _capsula(0.062, 0.4), "camisa", Vector3(0, -0.18, 0))
		_pieza(hombro, _cilindro(0.064, 0.064, 0.05), "camisa_oscura", Vector3(0, -0.355, 0))
		if izquierdo:
			# Pañoleta amarrada a la muñeca
			_pieza(hombro, _toro(0.055, 0.078), "acento", Vector3(0, -0.385, 0))
			_pieza(hombro, _caja(Vector3(0.03, 0.03, 0.03)), "acento", Vector3(-0.075, -0.385, 0))
			_pieza(hombro, _caja(Vector3(0.04, 0.02, 0.018)), "acento", Vector3(-0.09, -0.4, 0.012), Vector3(0, 0.3, -0.7))
			_pieza(hombro, _caja(Vector3(0.035, 0.02, 0.018)), "acento", Vector3(-0.088, -0.38, -0.012), Vector3(0, -0.3, 0.5))
		else:
			_pieza(hombro, _cilindro(0.058, 0.058, 0.04), "cuero_oscuro", Vector3(0, -0.39, 0))
	_pieza(hombro, _esfera(0.055), "piel", Vector3(0, -0.44, 0), Vector3.ZERO, Vector3(0.9, 1.1, 1))


func _cabeza(ella: bool) -> void:
	var y := 1.38
	_pieza(modelo, _esfera(0.2), "piel", Vector3(0, y, 0), Vector3.ZERO, Vector3.ONE, "Cabeza")
	for lado: float in [-1.0, 1.0]:
		_pieza(modelo, _esfera(0.042), "piel", Vector3(lado * 0.195, y - 0.01, 0.005))
		# Ojos grandes con brillo
		_pieza(modelo, _esfera(0.032), "ojo", Vector3(lado * 0.07, y, -0.176), Vector3.ZERO, Vector3(1, 1.25, 0.5))
		_pieza(modelo, _esfera(0.01), "blanco", Vector3(lado * 0.06, y + 0.014, -0.193))
		# Cejas (él: más rectas y marcadas)
		var inclinacion := -lado * (0.12 if ella else 0.25)
		_pieza(modelo, _caja(Vector3(0.06, 0.012 if ella else 0.016, 0.012)), "cabello", Vector3(lado * 0.072, y + 0.05, -0.182), Vector3(0, 0, inclinacion))
		_pieza(modelo, _esfera(0.03), "mejilla", Vector3(lado * 0.11, y - 0.05, -0.157), Vector3.ZERO, Vector3(1, 0.6, 0.3))
		if ella:
			_pieza(modelo, _caja(Vector3(0.05, 0.012, 0.01)), "ojo", Vector3(lado * 0.078, y + 0.03, -0.186), Vector3(0, 0, lado * 0.2))
			_pieza(modelo, _toro(0.018, 0.026), "metal", Vector3(lado * 0.205, y - 0.055, 0.0), Vector3(0, 0, PI / 2))
	_pieza(modelo, _esfera(0.018), "piel_oscura", Vector3(0, y - 0.025, -0.195))
	_pieza(modelo, _caja(Vector3(0.05, 0.012, 0.01)), "boca", Vector3(0, y - 0.075, -0.186))

	# Base del cabello: casquete inclinado hacia atrás para dejar ver la frente
	_pieza(modelo, _esfera(0.215, true), "cabello", Vector3(0, y, 0), Vector3(0.45, 0, 0))
	_pieza(modelo, _esfera(0.2), "cabello", Vector3(0, y - 0.02, 0.09), Vector3.ZERO, Vector3(0.98, 0.85, 0.8))
	if ella:
		_cabello_ella(y)
	else:
		_cabello_el(y)


func _cabello_el(y: float) -> void:
	# Puntas despeinadas: arriba (se ocultan con sombrero) y fleco al frente
	var arriba := [
		[Vector3(0, y + 0.2, 0.0), Vector3(0.3, 0, 0)],
		[Vector3(-0.08, y + 0.19, -0.05), Vector3(-0.25, 0, 0.55)],
		[Vector3(0.08, y + 0.19, -0.05), Vector3(-0.25, 0, -0.55)],
		[Vector3(0, y + 0.17, 0.1), Vector3(0.9, 0, 0)],
		[Vector3(-0.12, y + 0.13, 0.06), Vector3(0.5, 0, 0.95)],
		[Vector3(0.12, y + 0.13, 0.06), Vector3(0.5, 0, -0.95)],
		[Vector3(0.04, y + 0.2, -0.08), Vector3(-0.6, 0, -0.2)],
	]
	for punta in arriba:
		_sin_sombrero.append(_pieza(modelo, _cono(0.06, 0.17), "cabello", punta[0], punta[1]))
	var fleco := [
		[Vector3(-0.08, y + 0.11, -0.165), Vector3(-2.0, 0, 0.35)],
		[Vector3(0.0, y + 0.12, -0.175), Vector3(-2.1, 0, -0.1)],
		[Vector3(0.08, y + 0.11, -0.165), Vector3(-2.0, 0, -0.4)],
	]
	for punta in fleco:
		_sin_gorra.append(_pieza(modelo, _cono(0.045, 0.12), "cabello", punta[0], punta[1]))


func _cabello_ella(y: float) -> void:
	# Fleco suave
	for i in 4:
		var x := -0.09 + i * 0.06
		_pieza(modelo, _esfera(0.05), "cabello", Vector3(x, y + 0.1, -0.15 + absf(x) * 0.25), Vector3.ZERO, Vector3(1, 0.7, 0.6))
	# Melena ondulada por la espalda y mechones que enmarcan la cara
	for i in 4:
		var x := -0.15 + i * 0.1
		_pieza(modelo, _capsula(0.07, 0.36), "cabello", Vector3(x, y - 0.16, 0.1 + (0.03 if i in [1, 2] else 0.0)), Vector3(0.12, 0, -x * 0.6))
	for lado: float in [-1.0, 1.0]:
		_pieza(modelo, _capsula(0.045, 0.28), "cabello", Vector3(lado * 0.185, y - 0.11, -0.035), Vector3(0, 0, lado * 0.12))
		# Moños con flores (se ocultan con sombrero o gorra)
		_sin_sombrero.append(_pieza(modelo, _esfera(0.095), "cabello", Vector3(lado * 0.13, y + 0.19, 0.03)))
		var centro := Vector3(lado * 0.1, y + 0.19, -0.06)
		_sin_sombrero.append(_pieza(modelo, _esfera(0.017), "centro_flor", centro + Vector3(0, 0, -0.012)))
		for p in 5:
			var ang := TAU * p / 5.0
			_sin_sombrero.append(_pieza(modelo, _esfera(0.022), "flor", centro + Vector3(cos(ang) * 0.028, sin(ang) * 0.028, 0)))


func _mochila() -> void:
	_pieza(modelo, _caja(Vector3(0.3, 0.34, 0.14)), "mochila", Vector3(0, 0.9, 0.25), Vector3.ZERO, Vector3.ONE, "Mochila")
	_pieza(modelo, _caja(Vector3(0.31, 0.13, 0.15)), "mochila_oscura", Vector3(0, 1.03, 0.255))
	_pieza(modelo, _caja(Vector3(0.18, 0.1, 0.05)), "mochila_oscura", Vector3(0, 0.82, 0.335))
	_pieza(modelo, _caja(Vector3(0.04, 0.03, 0.02)), "metal", Vector3(0, 0.98, 0.335))
	for lado: float in [-1.0, 1.0]:
		# Correas sobre los hombros
		_pieza(modelo, _caja(Vector3(0.05, 0.03, 0.34)), "mochila_oscura", Vector3(lado * 0.13, 1.115, 0.02))
		_pieza(modelo, _caja(Vector3(0.05, 0.16, 0.025)), "mochila_oscura", Vector3(lado * 0.15, 1.03, -0.16), Vector3(0.25, -lado * 0.7, 0))


func _sombreros() -> void:
	_con_sombrero.append(_pieza(modelo, _cilindro(0.34, 0.34, 0.03), "sombrero", Vector3(0, 1.5, 0)))
	_con_sombrero.append(_pieza(modelo, _cilindro(0.15, 0.18, 0.15), "sombrero", Vector3(0, 1.585, 0)))
	_con_sombrero.append(_pieza(modelo, _cilindro(0.172, 0.182, 0.035), "cinta", Vector3(0, 1.535, 0)))
	_con_gorra.append(_pieza(modelo, _esfera(0.222, true), "sombrero", Vector3(0, 1.41, 0.01), Vector3(0.2, 0, 0)))
	_con_gorra.append(_pieza(modelo, _caja(Vector3(0.25, 0.025, 0.17)), "sombrero", Vector3(0, 1.455, -0.25), Vector3(-0.15, 0, 0)))
	_con_gorra.append(_pieza(modelo, _esfera(0.025), "cinta", Vector3(0, 1.63, 0.03)))


# --- Utilidades de construcción ------------------------------------------------------------------

func _articulacion(nombre: String, posicion: Vector3) -> Node3D:
	var nodo := Node3D.new()
	nodo.name = nombre
	nodo.position = posicion
	modelo.add_child(nodo)
	return nodo


func _pieza(padre: Node3D, malla: Mesh, grupo: String, posicion: Vector3, rotacion := Vector3.ZERO,
		escala := Vector3.ONE, nombre := "") -> MeshInstance3D:
	var pieza := MeshInstance3D.new()
	pieza.mesh = malla
	pieza.position = posicion
	pieza.rotation = rotacion
	pieza.scale = escala
	if not nombre.is_empty():
		pieza.name = nombre
	padre.add_child(pieza)
	if not _grupos.has(grupo):
		_grupos[grupo] = []
	_grupos[grupo].append(pieza)
	return pieza


func _esfera(radio: float, hemisferio := false) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = radio
	m.height = radio if hemisferio else radio * 2.0
	m.is_hemisphere = hemisferio
	m.radial_segments = 24
	m.rings = 12
	return m


func _capsula(radio: float, alto: float) -> CapsuleMesh:
	var m := CapsuleMesh.new()
	m.radius = radio
	m.height = alto
	m.radial_segments = 16
	m.rings = 6
	return m


func _cilindro(arriba: float, abajo: float, alto: float) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = arriba
	m.bottom_radius = abajo
	m.height = alto
	m.radial_segments = 24
	m.rings = 1
	return m


func _cono(radio: float, alto: float) -> CylinderMesh:
	var m := _cilindro(0.0, radio, alto)
	m.radial_segments = 6
	return m


func _caja(tamano: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = tamano
	return m


func _toro(interior: float, exterior: float) -> TorusMesh:
	var m := TorusMesh.new()
	m.inner_radius = interior
	m.outer_radius = exterior
	m.rings = 24
	m.ring_segments = 8
	return m


# --- Movimiento ----------------------------------------------------------------------------------

func ir_a(punto: Vector3) -> void:
	var destino := Vector2(punto.x, punto.z)
	if terreno:
		_camino = terreno.camino(_pos2d(), destino)
	else:
		_camino = PackedVector2Array([destino])
	FeedbackTactil.interaccion()


## Deja de seguir la ruta que llevaba.
func detener() -> void:
	_camino.clear()


func mover(desplazamiento: Vector3) -> void:
	_camino.clear()
	var nueva := _pos2d() + Vector2(desplazamiento.x, desplazamiento.z)
	if terreno:
		nueva = terreno.mover(_pos2d(), Vector2(desplazamiento.x, desplazamiento.z))
	_avanzar(Vector3(nueva.x - position.x, 0, nueva.y - position.z), desplazamiento)


func _process(delta: float) -> void:
	if not _camino.is_empty():
		var hacia := Vector3(_camino[0].x - position.x, 0, _camino[0].y - position.z)
		var paso := velocidad * delta
		if hacia.length() <= paso:
			_avanzar(hacia, hacia)
			_camino.remove_at(0)
		else:
			_avanzar(hacia.normalized() * paso, hacia)
	_animar(delta)
	_movio = false


func _avanzar(desplazamiento: Vector3, mirar_hacia: Vector3) -> void:
	if mirar_hacia.length() > 0.0001:
		# Girar hacia donde quiere ir (el frente del modelo mira a -Z)
		modelo.rotation.y = lerp_angle(modelo.rotation.y, atan2(-mirar_hacia.x, -mirar_hacia.z), 0.25)
	if desplazamiento.length() < 0.0001:
		return
	position += desplazamiento
	_movio = true


func _animar(delta: float) -> void:
	_amplitud_paso = move_toward(_amplitud_paso, 1.0 if _movio else 0.0, delta * 6.0)
	if _movio:
		_fase_paso += delta * 12.0
	var balanceo := sin(_fase_paso) * 0.6 * _amplitud_paso
	cadera_izq.rotation.x = balanceo
	cadera_der.rotation.x = -balanceo
	hombro_izq.rotation.x = -balanceo * 0.8
	hombro_der.rotation.x = balanceo * 0.8
	modelo.position.y = absf(sin(_fase_paso)) * 0.05 * _amplitud_paso


func _pos2d() -> Vector2:
	return Vector2(position.x, position.z)
