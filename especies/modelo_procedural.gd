class_name ModeloProcedural
## Modelos 3D "de caricatura" hechos con figuras simples para cada animal del humedal, con los
## colores y rasgos de su especie (como la mariquita de Michelle: formas suaves, brillo y ojos
## grandes). Se usan mientras no exista el modelo hecho a mano en res://animales/modelos/<id>.glb
## (ver ModelosEspecies).
##
## Convención (la misma de los .glb): el animal mira hacia +Z y está parado sobre y = 0.
## Las alas cuelgan de nodos "AlaIzq*" / "AlaDer*" para que AnimacionModelo las haga aletear.

const ANIMACION := preload("res://especies/animacion_modelo.gd")

const NEGRO := Color(0.07, 0.07, 0.09)
const BLANCO := Color(0.96, 0.96, 0.94)

## Insectos: plan del cuerpo y colores. cuerpo = abdomen, torax/cabeza (por defecto = cuerpo),
## ala (con alfa = transparencia), bandas = franjas del abdomen, manchas = puntos de los élitros.
const INSECTOS := {
	"mariquita": {"plan": "escarabajo", "cuerpo": Color(0.95, 0.32, 0.08), "torax": NEGRO, "cabeza": NEGRO,
		"manchas": NEGRO, "manchas_cabeza": BLANCO},
	"crisomelido": {"plan": "escarabajo", "cuerpo": Color(0.2, 0.62, 0.32), "torax": Color(0.18, 0.5, 0.3),
		"cabeza": Color(0.15, 0.42, 0.28), "metal": true},
	"chinche_planta": {"plan": "chinche", "cuerpo": Color(0.45, 0.72, 0.25), "cabeza": Color(0.38, 0.6, 0.2),
		"patas": Color(0.5, 0.65, 0.3)},
	"abejorro": {"plan": "abeja", "cuerpo": NEGRO, "bandas": Color(1.0, 0.8, 0.15), "torax": Color(1.0, 0.8, 0.15),
		"ala": Color(0.85, 0.9, 1.0, 0.35)},
	"avispa": {"plan": "avispa", "cuerpo": Color(1.0, 0.82, 0.1), "bandas": NEGRO, "torax": NEGRO,
		"ala": Color(0.55, 0.45, 0.3, 0.45)},
	"hormiga": {"plan": "hormiga", "cuerpo": Color(0.18, 0.08, 0.05), "torax": Color(0.45, 0.16, 0.08)},
	"mosca_metalica": {"plan": "mosca", "cuerpo": Color(0.1, 0.65, 0.45), "metal": true, "ojos": Color(0.75, 0.12, 0.08),
		"ala": Color(0.85, 0.9, 1.0, 0.35)},
	"sirfido": {"plan": "mosca", "cuerpo": Color(1.0, 0.78, 0.15), "bandas": NEGRO, "torax": Color(0.25, 0.2, 0.1),
		"ojos": Color(0.5, 0.15, 0.08), "ala": Color(0.85, 0.9, 1.0, 0.3)},
	"taquinido": {"plan": "mosca", "cuerpo": Color(0.35, 0.35, 0.35), "torax": Color(0.5, 0.5, 0.48),
		"ojos": Color(0.7, 0.15, 0.1), "ala": Color(0.8, 0.82, 0.9, 0.4), "pelos": true},
	"zancudo": {"plan": "zancudo", "cuerpo": Color(0.45, 0.42, 0.38), "torax": Color(0.35, 0.32, 0.28),
		"ala": Color(0.85, 0.88, 0.95, 0.3)},
	"tipula": {"plan": "tipula", "cuerpo": Color(0.62, 0.48, 0.3), "torax": Color(0.5, 0.42, 0.32),
		"ala": Color(0.8, 0.75, 0.65, 0.35)},
	"libelula": {"plan": "libelula", "cuerpo": Color(0.15, 0.55, 0.85), "torax": Color(0.3, 0.7, 0.35),
		"ojos": Color(0.2, 0.45, 0.9), "ala": Color(0.85, 0.95, 1.0, 0.3)},
	"caballito_del_diablo": {"plan": "caballito", "cuerpo": Color(0.2, 0.75, 0.95), "bandas": NEGRO,
		"ojos": Color(0.2, 0.6, 0.95), "ala": Color(0.9, 0.95, 1.0, 0.3)},
	"mariposa_blanca": {"plan": "mariposa", "cuerpo": Color(0.3, 0.3, 0.28), "ala": Color(0.97, 0.97, 0.92),
		"borde": Color(0.15, 0.15, 0.15), "puntos": [Color(0.15, 0.15, 0.15)]},
	"mariposa_monarca": {"plan": "mariposa", "cuerpo": NEGRO, "ala": Color(0.98, 0.5, 0.05),
		"borde": NEGRO, "puntos": [BLANCO], "venas": NEGRO},
	"ninfalida": {"plan": "mariposa", "cuerpo": Color(0.3, 0.2, 0.12), "ala": Color(0.55, 0.32, 0.15),
		"borde": Color(0.95, 0.6, 0.2), "ocelos": true},
	"polilla_geometra": {"plan": "polilla", "cuerpo": Color(0.6, 0.55, 0.45), "ala": Color(0.78, 0.74, 0.62),
		"borde": Color(0.5, 0.45, 0.36)},
	"crisopa": {"plan": "crisopa", "cuerpo": Color(0.55, 0.85, 0.4), "ojos": Color(0.95, 0.75, 0.2),
		"ala": Color(0.8, 1.0, 0.85, 0.3)},
	"pececillo_plata": {"plan": "pececillo", "cuerpo": Color(0.75, 0.78, 0.82), "metal": true},
	"psocido": {"plan": "psocido", "cuerpo": Color(0.55, 0.42, 0.3), "cabeza": Color(0.65, 0.52, 0.38),
		"ala": Color(0.75, 0.68, 0.55, 0.55)},
	"tijereta": {"plan": "tijereta", "cuerpo": Color(0.45, 0.2, 0.1), "cabeza": Color(0.3, 0.12, 0.06),
		"patas": Color(0.75, 0.6, 0.35)},
}

## Aves: cuerpo, vientre, cabeza, ala, pico, patas y rasgos (pico/patas/cuello largos, cresta...).
const AVES := {
	"garza_blanca": {"cuerpo": BLANCO, "pico": Color(1.0, 0.8, 0.1), "patas": NEGRO, "pico_largo": 1.0,
		"patas_largas": 1.8, "cuello": 1.0},
	"coquito": {"cuerpo": Color(0.25, 0.2, 0.22), "ala": Color(0.3, 0.32, 0.25), "pico": Color(0.3, 0.25, 0.2),
		"patas": Color(0.75, 0.35, 0.3), "pico_largo": 1.1, "pico_curvo": true, "patas_largas": 1.2, "cara": Color(0.85, 0.45, 0.4)},
	"tingua_pico_rojo": {"cuerpo": Color(0.2, 0.2, 0.25), "pico": Color(0.9, 0.12, 0.1), "patas": Color(0.75, 0.8, 0.2),
		"escudo": Color(0.9, 0.12, 0.1), "punta_pico": Color(1.0, 0.85, 0.1), "patas_largas": 1.1, "cola_blanca": true},
	"tingua_bogotana": {"cuerpo": Color(0.45, 0.32, 0.2), "vientre": Color(0.55, 0.58, 0.62), "pico": Color(0.85, 0.15, 0.12),
		"patas": Color(0.8, 0.35, 0.25), "pico_largo": 0.8, "patas_largas": 1.1},
	"tingua_moteada": {"cuerpo": Color(0.25, 0.25, 0.28), "pico": Color(0.75, 0.8, 0.25), "patas": Color(0.6, 0.65, 0.3),
		"motas": BLANCO, "patas_largas": 1.0},
	"pato_canadiense": {"cuerpo": Color(0.55, 0.42, 0.3), "cabeza": Color(0.35, 0.4, 0.5), "ala": Color(0.35, 0.55, 0.8),
		"pico": Color(0.15, 0.15, 0.18), "patas": Color(0.95, 0.65, 0.2), "pato": true, "media_luna": BLANCO},
	"alcaravan": {"cuerpo": Color(0.55, 0.52, 0.48), "vientre": BLANCO, "pecho": NEGRO, "pico": Color(0.85, 0.2, 0.2),
		"patas": Color(0.85, 0.35, 0.4), "cresta": NEGRO, "patas_largas": 1.4},
	"playero_solitaria": {"cuerpo": Color(0.32, 0.3, 0.25), "vientre": BLANCO, "pico": NEGRO, "pico_largo": 0.7,
		"patas": Color(0.5, 0.6, 0.35), "patas_largas": 1.3, "motas": Color(0.85, 0.85, 0.8)},
	"mirla_patiamarilla": {"cuerpo": Color(0.18, 0.18, 0.2), "pico": Color(1.0, 0.55, 0.1), "patas": Color(1.0, 0.6, 0.1),
		"anillo": Color(1.0, 0.6, 0.1)},
	"copeton": {"cuerpo": Color(0.55, 0.42, 0.3), "vientre": Color(0.85, 0.82, 0.76), "cabeza": Color(0.55, 0.55, 0.55),
		"cuello_color": Color(0.75, 0.4, 0.2), "pico": Color(0.35, 0.3, 0.28), "patas": Color(0.6, 0.45, 0.35),
		"cresta": Color(0.45, 0.45, 0.45), "rayas": NEGRO},
	"monjita_bogotana": {"cuerpo": NEGRO, "cabeza": Color(1.0, 0.85, 0.1), "pico": NEGRO, "patas": NEGRO},
	"tordo_lanero": {"cuerpo": Color(0.12, 0.08, 0.2), "pico": NEGRO, "patas": NEGRO, "metal": true},
	"turpial_oriental": {"cuerpo": Color(1.0, 0.55, 0.08), "cabeza": NEGRO, "ala": NEGRO, "pico": Color(0.35, 0.38, 0.45),
		"patas": Color(0.35, 0.38, 0.45), "franja_ala": BLANCO},
	"capita_negra": {"cuerpo": Color(0.95, 0.85, 0.15), "cabeza": NEGRO, "ala": Color(0.2, 0.2, 0.18),
		"pico": Color(0.6, 0.55, 0.5), "patas": Color(0.45, 0.4, 0.35), "franja_ala": Color(0.95, 0.85, 0.15)},
	"espiguero_negriblanco": {"cuerpo": NEGRO, "vientre": BLANCO, "pico": Color(0.25, 0.25, 0.25), "patas": NEGRO,
		"franja_ala": BLANCO},
	"siriri_comun": {"cuerpo": Color(0.45, 0.5, 0.3), "vientre": Color(1.0, 0.88, 0.2), "cabeza": Color(0.55, 0.57, 0.6),
		"pico": NEGRO, "patas": NEGRO},
	"pibi_del_bosque": {"cuerpo": Color(0.42, 0.42, 0.36), "vientre": Color(0.75, 0.75, 0.68), "pico": NEGRO, "patas": NEGRO},
	"cucarachero_pantano": {"cuerpo": Color(0.55, 0.38, 0.22), "vientre": Color(0.65, 0.62, 0.58), "pico": NEGRO,
		"patas": Color(0.5, 0.4, 0.3), "cola_alta": true, "rayas": NEGRO, "pico_largo": 0.5},
	"colibri_chillon": {"cuerpo": Color(0.15, 0.62, 0.35), "ala": Color(0.25, 0.3, 0.28), "pico": NEGRO, "patas": NEGRO,
		"pico_largo": 1.2, "metal": true, "colibri": true, "mejilla": Color(0.45, 0.3, 0.85)},
}


static var _esfera: SphereMesh
static var _cilindro: CylinderMesh
static var _cono: CylinderMesh
static var _materiales := {}


## Modelo 3D de la especie, o null si no hay forma para ella (las plantas, por ahora).
static func crear(especie: Especie) -> Node3D:
	_preparar_mallas()
	var raiz := Node3D.new()
	raiz.name = especie.id.capitalize().replace(" ", "")
	if INSECTOS.has(especie.id):
		_insecto(raiz, INSECTOS[especie.id])
	elif AVES.has(especie.id):
		_ave(raiz, AVES[especie.id])
	else:
		match especie.id:
			"rana_sabanera": _rana(raiz)
			"chucha": _mamifero(raiz, Color(0.45, 0.45, 0.47), BLANCO, Color(1.0, 0.7, 0.75), NEGRO, true)
			"rata_parda": _mamifero(raiz, Color(0.45, 0.33, 0.24), Color(0.62, 0.52, 0.42), Color(0.95, 0.65, 0.65), Color(0.95, 0.65, 0.65), false)
			"capitan_sabana": _pez(raiz)
			"lombriz_roja": _lombriz(raiz)
			_:
				match especie.tipo:
					Especie.Tipo.INSECTO: _insecto(raiz, {"plan": "mosca", "cuerpo": Color(0.4, 0.35, 0.3), "ala": Color(0.85, 0.9, 1.0, 0.35)})
					Especie.Tipo.AVE: _ave(raiz, {"cuerpo": Color(0.5, 0.45, 0.4), "pico": NEGRO, "patas": NEGRO})
					_:
						raiz.free()
						return null
	raiz.set_script(ANIMACION)
	return raiz


# --- Insectos ---------------------------------------------------------------------------------

static func _insecto(raiz: Node3D, d: Dictionary) -> void:
	var plan: String = d.plan
	var metal: bool = d.get("metal", false)
	var cuerpo := _mat(d.cuerpo, metal)
	var torax := _mat(d.get("torax", d.cuerpo), metal)
	var cabeza := _mat(d.get("cabeza", d.get("torax", d.cuerpo)), metal)
	var patas := _mat(d.get("patas", NEGRO))
	var ala_color: Color = d.get("ala", Color(0.85, 0.9, 1.0, 0.35))
	var alto := 0.45   # altura del cuerpo sobre el suelo
	var largo_patas := 1.0
	var antenas := 0.55
	var ojo_tam := 0.16
	var cabeza_z := 0.62
	var alas := ""     # forma de las alas: "", "mosca", "abeja", "libelula", "mariposa", "techo", "plana"

	match plan:
		"escarabajo":
			alto = 0.4
			_esf(raiz, Vector3(0, alto, 0.42), Vector3(0.62, 0.36, 0.42), torax)              # pronoto
			_esf(raiz, Vector3(0, alto + 0.05, -0.22), Vector3(1.05, 0.72, 1.15), cuerpo)    # élitros
			_cil(raiz, Vector3(0, alto + 0.42, 0.3), Vector3(0, alto + 0.43, -0.78), 0.012, _mat(NEGRO))  # línea central
			if d.has("manchas"):
				var mancha := _mat(d.manchas)
				for p in [Vector3(0.22, 0.72, -0.05), Vector3(-0.22, 0.72, -0.05), Vector3(0.32, 0.6, -0.42),
						Vector3(-0.32, 0.6, -0.42), Vector3(0.14, 0.62, -0.62), Vector3(-0.14, 0.62, -0.62), Vector3(0, 0.76, 0.15)]:
					_esf(raiz, p + Vector3(0, alto - 0.4, 0), Vector3(0.15, 0.05, 0.15), mancha)
			cabeza_z = 0.66
			_esf(raiz, Vector3(0, alto - 0.02, cabeza_z), Vector3(0.42, 0.32, 0.3), cabeza)
			if d.has("manchas_cabeza"):
				for x in [0.2, -0.2]:
					_esf(raiz, Vector3(x, alto + 0.08, 0.52), Vector3(0.13, 0.1, 0.1), _mat(d.manchas_cabeza))
			largo_patas = 0.75
			antenas = 0.3
		"chinche":
			alto = 0.38
			_esf(raiz, Vector3(0, alto, 0.25), Vector3(0.75, 0.28, 0.45), torax)
			_esf(raiz, Vector3(0, alto, -0.25), Vector3(0.85, 0.26, 1.0), cuerpo)
			_cono_entre(raiz, Vector3(0, alto + 0.12, 0.1), Vector3(0, alto + 0.12, -0.4), 0.2, _mat(Color(d.cuerpo).darkened(0.25)))
			cabeza_z = 0.62
			_esf(raiz, Vector3(0, alto, cabeza_z), Vector3(0.3, 0.22, 0.3), cabeza)
			antenas = 0.9
		"abeja":
			alto = 0.6
			_esf(raiz, Vector3(0, alto, 0.15), Vector3(0.75, 0.7, 0.7), torax)
			_esf(raiz, Vector3(0, alto - 0.05, -0.5), Vector3(0.8, 0.75, 0.95), cuerpo)
			for z in [-0.3, -0.62]:
				_esf(raiz, Vector3(0, alto - 0.05, z), Vector3(0.82, 0.76, 0.16), _mat(d.bandas))
			cabeza_z = 0.6
			_esf(raiz, Vector3(0, alto, cabeza_z), Vector3(0.45, 0.42, 0.36), _mat(NEGRO))
			alas = "abeja"
		"avispa":
			alto = 0.6
			_esf(raiz, Vector3(0, alto, 0.15), Vector3(0.5, 0.48, 0.55), torax)
			_cil(raiz, Vector3(0, alto, -0.12), Vector3(0, alto - 0.02, -0.28), 0.06, torax)  # cintura
			_esf(raiz, Vector3(0, alto - 0.08, -0.72), Vector3(0.55, 0.5, 0.95), cuerpo)
			for z in [-0.5, -0.75, -0.98]:
				_esf(raiz, Vector3(0, alto - 0.08, z), Vector3(0.57, 0.52, 0.1), _mat(d.bandas))
			cabeza_z = 0.55
			_esf(raiz, Vector3(0, alto + 0.02, cabeza_z), Vector3(0.42, 0.4, 0.3), _mat(d.cuerpo))
			alas = "abeja"
			antenas = 0.65
		"hormiga":
			alto = 0.45
			_esf(raiz, Vector3(0, alto, 0.1), Vector3(0.32, 0.3, 0.6), torax)
			_esf(raiz, Vector3(0, alto - 0.02, -0.28), Vector3(0.14, 0.18, 0.14), torax)  # nodo
			_esf(raiz, Vector3(0, alto + 0.02, -0.68), Vector3(0.6, 0.55, 0.7), cuerpo)
			cabeza_z = 0.62
			_esf(raiz, Vector3(0, alto + 0.08, cabeza_z), Vector3(0.48, 0.42, 0.42), cuerpo)
			antenas = 0.7
		"mosca":
			alto = 0.55
			_esf(raiz, Vector3(0, alto + 0.05, 0.1), Vector3(0.62, 0.58, 0.62), torax)
			_esf(raiz, Vector3(0, alto - 0.02, -0.42), Vector3(0.6, 0.48, 0.7), cuerpo)
			if d.has("bandas"):
				for z in [-0.3, -0.55]:
					_esf(raiz, Vector3(0, alto - 0.02, z), Vector3(0.62, 0.5, 0.1), _mat(d.bandas))
			if d.get("pelos", false):
				for i in 10:
					var a := TAU * i / 10.0
					var base := Vector3(cos(a) * 0.25, alto + 0.12 + sin(a) * 0.2, -0.45 + sin(a * 2.0) * 0.1)
					_cil(raiz, base, base + Vector3(cos(a) * 0.12, 0.12, -0.05), 0.01, _mat(NEGRO))
			cabeza_z = 0.5
			_esf(raiz, Vector3(0, alto + 0.05, cabeza_z), Vector3(0.48, 0.42, 0.32), cabeza)
			ojo_tam = 0.24
			alas = "mosca"
			antenas = 0.15
		"zancudo", "tipula":
			var grande := plan == "tipula"
			alto = 0.95 if grande else 0.75
			_esf(raiz, Vector3(0, alto, 0.05), Vector3(0.3, 0.3, 0.38), torax)
			_esf(raiz, Vector3(0, alto - 0.05, -0.55), Vector3(0.16, 0.16, 0.85 if grande else 0.7), cuerpo)
			cabeza_z = 0.32
			_esf(raiz, Vector3(0, alto, cabeza_z), Vector3(0.2, 0.2, 0.2), cabeza)
			if not grande:   # probóscide
				_cil(raiz, Vector3(0, alto - 0.03, 0.4), Vector3(0, alto - 0.18, 0.75), 0.015, _mat(NEGRO))
			ojo_tam = 0.1
			largo_patas = 2.6 if grande else 1.9
			alas = "libelula" if grande else "mosca"
			antenas = 0.35
		"libelula", "caballito":
			var fina := plan == "caballito"
			alto = 0.55
			_esf(raiz, Vector3(0, alto, 0.15), Vector3(0.36, 0.38, 0.45), torax)
			var segmentos := 8
			for i in segmentos:
				var z := -0.12 - i * (0.24 if fina else 0.21)
				var mat := cuerpo
				if d.has("bandas") and i % 2 == 1:
					mat = _mat(d.bandas)
				var grosor := (0.1 if fina else 0.15) * (1.0 - i * 0.04)
				_esf(raiz, Vector3(0, alto - 0.02, z), Vector3(grosor, grosor, 0.26), mat)
			cabeza_z = 0.45
			_esf(raiz, Vector3(0, alto + 0.02, cabeza_z), Vector3(0.3, 0.26, 0.24), cabeza)
			ojo_tam = 0.22 if not fina else 0.15
			alas = "caballito" if fina else "libelula"
			antenas = 0.1
		"mariposa", "polilla":
			alto = 0.55
			_esf(raiz, Vector3(0, alto, 0.05), Vector3(0.24, 0.24, 0.4), torax)
			_esf(raiz, Vector3(0, alto - 0.03, -0.42), Vector3(0.2, 0.2, 0.62), cuerpo)
			cabeza_z = 0.35
			_esf(raiz, Vector3(0, alto + 0.02, cabeza_z), Vector3(0.24, 0.22, 0.22), cabeza)
			ojo_tam = 0.11
			alas = plan
			antenas = 0.8
		"crisopa":
			alto = 0.5
			_esf(raiz, Vector3(0, alto, 0.05), Vector3(0.24, 0.24, 0.4), torax)
			_esf(raiz, Vector3(0, alto - 0.03, -0.4), Vector3(0.18, 0.18, 0.65), cuerpo)
			cabeza_z = 0.32
			_esf(raiz, Vector3(0, alto, cabeza_z), Vector3(0.22, 0.2, 0.2), cabeza)
			ojo_tam = 0.12
			alas = "techo"
			antenas = 1.1
		"psocido":
			alto = 0.4
			_esf(raiz, Vector3(0, alto, 0.0), Vector3(0.4, 0.38, 0.5), torax)
			_esf(raiz, Vector3(0, alto - 0.02, -0.35), Vector3(0.42, 0.36, 0.5), cuerpo)
			cabeza_z = 0.4
			_esf(raiz, Vector3(0, alto + 0.08, cabeza_z), Vector3(0.48, 0.45, 0.42), cabeza)
			ojo_tam = 0.13
			alas = "techo"
			antenas = 0.8
		"pececillo":
			alto = 0.22
			for i in 7:
				var ancho := 0.5 * (1.0 - i * 0.11)
				_esf(raiz, Vector3(0, alto, 0.35 - i * 0.18), Vector3(ancho, 0.18, 0.24), cuerpo)
			for x in [-0.12, 0.0, 0.12]:   # tres "colitas"
				_cil(raiz, Vector3(x * 0.5, alto, -0.82), Vector3(x * 3.0, alto + 0.04, -1.45), 0.012, cuerpo)
			cabeza_z = 0.5
			_esf(raiz, Vector3(0, alto, cabeza_z), Vector3(0.3, 0.16, 0.2), cabeza)
			ojo_tam = 0.08
			largo_patas = 0.55
			antenas = 0.9
		"tijereta":
			alto = 0.3
			_esf(raiz, Vector3(0, alto, 0.2), Vector3(0.3, 0.2, 0.35), cabeza)
			_esf(raiz, Vector3(0, alto, -0.1), Vector3(0.36, 0.2, 0.35), _mat(Color(d.cuerpo).darkened(0.2)))  # élitros cortos
			for i in 4:
				_esf(raiz, Vector3(0, alto, -0.38 - i * 0.16), Vector3(0.36 - i * 0.03, 0.18, 0.2), cuerpo)
			for lado in [1.0, -1.0]:   # pinzas
				_cil(raiz, Vector3(0.06 * lado, alto, -0.95), Vector3(0.14 * lado, alto + 0.02, -1.25), 0.03, patas)
				_cil(raiz, Vector3(0.14 * lado, alto + 0.02, -1.25), Vector3(0.02 * lado, alto + 0.03, -1.42), 0.025, patas)
			cabeza_z = 0.45
			_esf(raiz, Vector3(0, alto, cabeza_z), Vector3(0.26, 0.18, 0.22), cabeza)
			ojo_tam = 0.08
			largo_patas = 0.6
			antenas = 0.6

	# Ojos (como los de la mariquita: grandes, brillantes y con reflejo)
	var color_ojo: Color = d.get("ojos", NEGRO)
	for lado in [1.0, -1.0]:
		var ojo := Vector3(0.17 * lado * (1.0 + ojo_tam), alto + 0.08, cabeza_z + 0.1)
		_esf(raiz, ojo, Vector3.ONE * ojo_tam * 1.4, _mat(color_ojo, false, 0.15))
		_esf(raiz, ojo + Vector3(0.03 * lado, 0.05, ojo_tam * 0.6), Vector3.ONE * ojo_tam * 0.45, _mat(BLANCO, false, 0.0, true))

	# Antenas
	if antenas > 0.0:
		for lado in [1.0, -1.0]:
			var base := Vector3(0.07 * lado, alto + 0.15, cabeza_z + 0.12)
			var codo := base + Vector3(0.12 * lado, antenas * 0.55, antenas * 0.35)
			var punta := codo + Vector3(0.1 * lado, antenas * 0.2, antenas * 0.5)
			_cil(raiz, base, codo, 0.018, patas)
			_cil(raiz, codo, punta, 0.016, patas)
			if plan == "mariposa":
				_esf(raiz, punta, Vector3.ONE * 0.06, patas)

	# Seis patas (tres por lado), con "rodilla" hacia arriba como en el modelo de Michelle
	for i in 3:
		var z := 0.18 - i * 0.2
		for lado in [1.0, -1.0]:
			var cadera := Vector3(0.12 * lado, alto - 0.08, z)
			var abrir := (0.32 + 0.12 * absf(i - 1.0)) * largo_patas
			var rodilla := cadera + Vector3(abrir * lado, alto * 0.35 + 0.08 * largo_patas, (i - 1) * 0.12 * largo_patas)
			var pie := Vector3(rodilla.x + 0.1 * lado * largo_patas, 0.0, rodilla.z + (i - 1) * 0.1 * largo_patas)
			_cil(raiz, cadera, rodilla, 0.035, patas)
			_cil(raiz, rodilla, pie, 0.03, patas)

	if d.get("sin_alas", false):
		# Ninfa / pupa con forma de adulto: solo "esbozos" de alas sobre el tórax
		if not alas.is_empty():
			for lado in [1.0, -1.0]:
				_esf(raiz, Vector3(0.14 * lado, alto + 0.2, -0.05), Vector3(0.16, 0.05, 0.35), _mat(Color(d.get("torax", d.cuerpo)).darkened(0.15)))
	else:
		_alas(raiz, alas, ala_color, d, alto)


static func _alas(raiz: Node3D, forma: String, color: Color, d: Dictionary, alto: float) -> void:
	if forma.is_empty():
		return
	var mat := _mat(color, false, 0.2)
	for lado in [1.0, -1.0]:
		var nombre := "AlaIzq" if lado > 0.0 else "AlaDer"
		match forma:
			"mosca", "abeja":
				var ala := _bisagra(raiz, nombre, Vector3(0.12 * lado, alto + 0.3, 0.05), 0.5, 30.0)
				var largo := 0.9 if forma == "mosca" else 0.75
				_esf(ala, Vector3(largo * 0.45 * lado, 0, -largo * 0.35), Vector3(largo * 0.55, 0.02, largo * 0.85), mat)
				ala.rotation = Vector3(0.15, 0.55 * lado, 0.15 * lado)
			"libelula", "caballito":
				var plegadas := forma == "caballito"
				for j in 2:   # dos pares
					var ala := _bisagra(raiz, nombre + str(j), Vector3(0.1 * lado, alto + 0.18, 0.22 - j * 0.18), 0.25, 20.0)
					_esf(ala, Vector3(0.75 * lado, 0, 0), Vector3(1.5, 0.02, 0.32), mat)
					_cil(ala, Vector3(0, 0.01, 0), Vector3(1.4 * lado, 0.01, 0), 0.01, _mat(Color(0.2, 0.2, 0.2, 0.6)))
					if plegadas:
						ala.rotation = Vector3(0, (1.35 + j * 0.1) * lado, 0.35 * lado)
					else:
						ala.rotation = Vector3(0, (-0.12 + j * 0.25) * lado, 0)
			"mariposa", "polilla":
				var ala := _bisagra(raiz, nombre, Vector3(0.1 * lado, alto + 0.08, 0.0), 0.7 if forma == "mariposa" else 0.25,
					3.0 if forma == "mariposa" else 4.0)
				var base_mat := _mat(color, false, 0.6)
				var borde_mat := _mat(d.get("borde", color.darkened(0.3)), false, 0.6)
				var polilla := forma == "polilla"
				# Ala anterior (grande) y posterior
				var anterior := Vector3(0.75 * lado, 0, 0.32 if not polilla else 0.1)
				var posterior := Vector3(0.55 * lado, 0, -0.42)
				_esf(ala, anterior, Vector3(1.55, 0.04, 1.0 if not polilla else 1.2), borde_mat)
				# (el color base es más grueso que el borde para que asome por encima y por debajo)
				_esf(ala, anterior + Vector3(-0.05 * lado, 0.0, -0.02), Vector3(1.32, 0.07, 0.82 if not polilla else 1.0), base_mat)
				if not polilla:
					_esf(ala, posterior, Vector3(1.0, 0.04, 0.95), borde_mat)
					_esf(ala, posterior + Vector3(-0.03 * lado, 0.0, 0.03), Vector3(0.82, 0.07, 0.78), base_mat)
				if d.has("venas"):
					var vena := _mat(d.venas)
					for k in 3:
						_cil(ala, Vector3(0.05 * lado, 0.04, 0.0), anterior + Vector3((0.55 - k * 0.2) * lado, 0.04, 0.35 - k * 0.25), 0.012, vena)
				for p in d.get("puntos", []):
					for k in 3:
						_esf(ala, anterior + Vector3((0.55 + k * 0.08) * lado, 0.0, 0.35 - k * 0.15), Vector3(0.09, 0.08, 0.09), _mat(p))
				if d.get("ocelos", false):
					_esf(ala, anterior + Vector3(0.3 * lado, 0.0, 0.1), Vector3(0.32, 0.08, 0.32), _mat(NEGRO))
					_esf(ala, anterior + Vector3(0.3 * lado, 0.0, 0.1), Vector3(0.2, 0.09, 0.2), _mat(Color(0.95, 0.65, 0.2)))
					_esf(ala, anterior + Vector3(0.3 * lado, 0.0, 0.1), Vector3(0.08, 0.1, 0.08), _mat(BLANCO))
				ala.rotation = Vector3(0, 0, (0.55 if not polilla else 0.08) * lado)
			"techo":   # alas en "tejadito" sobre el cuerpo (crisopa, psócido)
				var ala := _bisagra(raiz, nombre, Vector3(0.05 * lado, alto + 0.18, 0.12), 0.12, 6.0)
				_esf(ala, Vector3(0.2 * lado, 0, -0.55), Vector3(0.45, 0.02, 1.35), mat)
				for k in 4:
					_cil(ala, Vector3(0.02 * lado, 0.01, 0.05), Vector3((0.15 + k * 0.08) * lado, 0.01, -1.1 + k * 0.1), 0.006,
						_mat(Color(color.r * 0.6, color.g * 0.8, color.b * 0.6, 0.7)))
				ala.rotation = Vector3(0, 0, 0.7 * lado)


# --- Aves -------------------------------------------------------------------------------------

static func _ave(raiz: Node3D, d: Dictionary) -> void:
	var metal: bool = d.get("metal", false)
	var cuerpo := _mat(d.cuerpo, metal)
	var vientre := _mat(d.get("vientre", Color(d.cuerpo).lightened(0.15)), metal)
	var cabeza_mat := _mat(d.get("cabeza", d.cuerpo), metal)
	var ala_mat := _mat(d.get("ala", Color(d.cuerpo).darkened(0.12)), metal)
	var pico_mat := _mat(d.pico)
	var patas_mat := _mat(d.patas)
	var pato: bool = d.get("pato", false)
	var colibri: bool = d.get("colibri", false)
	var patas_largas: float = d.get("patas_largas", 0.7 if not pato else 0.35)
	var alto := 0.35 + 0.45 * patas_largas          # altura del vientre
	var cuello: float = d.get("cuello", 0.0)

	var centro := Vector3(0, alto + 0.45, 0)
	_esf(raiz, centro, Vector3(0.95, 0.85, 1.35) * (0.7 if colibri else 1.0), cuerpo)
	_esf(raiz, centro + Vector3(0, -0.12, 0.22), Vector3(0.82, 0.68, 0.9) * (0.7 if colibri else 1.0), vientre)
	if d.has("pecho"):
		_esf(raiz, centro + Vector3(0, 0.05, 0.45), Vector3(0.7, 0.32, 0.4), _mat(d.pecho))
	if d.has("motas"):
		for i in 10:
			var a := TAU * i / 10.0
			_esf(raiz, centro + Vector3(cos(a) * 0.46, sin(a * 3.0) * 0.12, sin(a) * 0.3 - 0.1), Vector3.ONE * 0.08, _mat(d.motas))
	if d.has("rayas"):
		for i in 4:
			_esf(raiz, centro + Vector3((i - 1.5) * 0.15, 0.38, -0.15), Vector3(0.05, 0.05, 0.6), _mat(d.rayas))

	# Cuello y cabeza
	var cabeza := centro + Vector3(0, 0.55, 0.55)
	if cuello > 0.0:
		cabeza = centro + Vector3(0, 0.55 + 1.1 * cuello, 0.75)
		var medio := centro + Vector3(0, 0.6 * cuello + 0.3, 0.95)
		_cil(raiz, centro + Vector3(0, 0.25, 0.5), medio, 0.13, cuerpo)
		_cil(raiz, medio, cabeza, 0.12, cuerpo)
	elif d.has("cuello_color"):
		_esf(raiz, centro + Vector3(0, 0.38, 0.5), Vector3(0.55, 0.3, 0.45), _mat(d.cuello_color))
	var tam_cabeza := 0.62 if not colibri else 0.45
	_esf(raiz, cabeza, Vector3.ONE * tam_cabeza, cabeza_mat)
	if d.has("cara"):
		_esf(raiz, cabeza + Vector3(0, 0, 0.12), Vector3(0.5, 0.4, 0.45), _mat(d.cara))
	if d.has("mejilla"):
		for lado in [1.0, -1.0]:
			_esf(raiz, cabeza + Vector3(0.2 * lado, -0.02, 0.05), Vector3(0.12, 0.2, 0.25), _mat(d.mejilla, true))
	if d.has("media_luna"):
		_esf(raiz, cabeza + Vector3(0, 0.02, 0.24), Vector3(0.62, 0.1, 0.18), _mat(d.media_luna))
	if d.has("anillo"):
		for lado in [1.0, -1.0]:
			_esf(raiz, cabeza + Vector3(0.24 * lado, 0.08, 0.12), Vector3.ONE * 0.16, _mat(d.anillo))
	if d.has("cresta"):
		for i in 3:
			_cono_entre(raiz, cabeza + Vector3(0, 0.25, -0.05 - i * 0.08), cabeza + Vector3(0, 0.55 - i * 0.08, -0.3 - i * 0.12),
				0.06, _mat(d.cresta))

	# Ojos de caricatura
	for lado in [1.0, -1.0]:
		var ojo := cabeza + Vector3(0.25 * lado, 0.08, 0.15) * (tam_cabeza / 0.62)
		_esf(raiz, ojo, Vector3.ONE * 0.17, _mat(BLANCO, false, 0.1))
		_esf(raiz, ojo + Vector3(0.03 * lado, 0.0, 0.06), Vector3.ONE * 0.11, _mat(NEGRO, false, 0.1))
		_esf(raiz, ojo + Vector3(0.03 * lado, 0.04, 0.11), Vector3.ONE * 0.035, _mat(BLANCO, false, 0.0, true))

	# Pico
	var pico_largo: float = d.get("pico_largo", 0.35 if not pato else 0.45)
	var base_pico := cabeza + Vector3(0, -0.04, tam_cabeza * 0.45)
	if d.has("escudo"):
		_esf(raiz, cabeza + Vector3(0, 0.12, tam_cabeza * 0.42), Vector3(0.14, 0.28, 0.12), _mat(d.escudo))
	if pato:
		_esf(raiz, base_pico + Vector3(0, -0.06, 0.2), Vector3(0.3, 0.1, 0.5), pico_mat)
	elif d.get("pico_curvo", false):
		var medio := base_pico + Vector3(0, -0.08, pico_largo * 0.55)
		_cil(raiz, base_pico, medio, 0.06, pico_mat)
		_cono_entre(raiz, medio, medio + Vector3(0, -0.35, pico_largo * 0.35), 0.06, pico_mat)
	else:
		var punta := base_pico + Vector3(0, -0.04, pico_largo + 0.1)
		_cono_entre(raiz, base_pico, punta, 0.1 if pico_largo < 0.6 else 0.07, pico_mat)
		if d.has("punta_pico"):
			_esf(raiz, punta.lerp(base_pico, 0.15), Vector3.ONE * 0.07, _mat(d.punta_pico))

	# Alas (pueden aletear) y cola
	for lado in [1.0, -1.0]:
		var nombre := "AlaIzq" if lado > 0.0 else "AlaDer"
		var ala := _bisagra(raiz, nombre, centro + Vector3(0.38 * lado, 0.22, 0.2), 0.35 if not colibri else 1.0,
			3.0 if not colibri else 30.0)
		_esf(ala, Vector3(0.04 * lado, -0.18, -0.35), Vector3(0.2, 0.45, 1.0) * (0.75 if colibri else 1.0), ala_mat)
		if d.has("franja_ala"):
			_esf(ala, Vector3(0.12 * lado, -0.1, -0.25), Vector3(0.1, 0.12, 0.6), _mat(d.franja_ala))
		ala.rotation = Vector3(0.1, 0, 0.12 * lado)
	var cola_mat := _mat(BLANCO) if d.get("cola_blanca", false) else ala_mat
	var cola_alta: bool = d.get("cola_alta", false)
	var cola := centro + Vector3(0, 0.05, -0.6)
	var punta_cola := cola + (Vector3(0, 0.6, -0.35) if cola_alta else Vector3(0, 0.15, -0.65))
	var pluma := _esf(raiz, cola.lerp(punta_cola, 0.5), Vector3.ONE, cola_mat)
	pluma.basis = Basis.looking_at(punta_cola - cola, Vector3.UP) * Basis.from_scale(Vector3(0.38, 0.1, 0.75))

	# Patas
	for lado in [1.0, -1.0]:
		var cadera := centro + Vector3(0.22 * lado, -0.35, 0.05)
		var pie := Vector3(0.25 * lado, 0.0, 0.1)
		if colibri:
			pie = cadera + Vector3(0, -0.15, 0.05)
		_cil(raiz, cadera, pie, 0.045 if not pato else 0.06, patas_mat)
		if pato:
			_esf(raiz, pie + Vector3(0, 0.02, 0.12), Vector3(0.28, 0.04, 0.32), patas_mat)
		else:
			for dedo in [-0.5, 0.0, 0.5]:
				_cil(raiz, pie, pie + Vector3(sin(dedo) * 0.18, 0.0, cos(dedo) * 0.18), 0.025, patas_mat)
	if colibri:
		raiz.set_meta("flota", 0.6)   # AnimacionModelo lo mantiene suspendido en el aire


# --- Otros animales ---------------------------------------------------------------------------

static func _rana(raiz: Node3D) -> void:
	var verde := _mat(Color(0.35, 0.72, 0.25))
	var franja := _mat(Color(0.55, 0.38, 0.18))
	var vientre := _mat(Color(0.92, 0.9, 0.75))
	_esf(raiz, Vector3(0, 0.45, -0.05), Vector3(1.1, 0.7, 1.3), verde)
	_esf(raiz, Vector3(0, 0.32, 0.2), Vector3(0.9, 0.45, 0.9), vientre)
	_esf(raiz, Vector3(0, 0.55, 0.45), Vector3(0.95, 0.55, 0.7), verde)   # cabeza
	for lado in [1.0, -1.0]:
		_esf(raiz, Vector3(0.5 * lado, 0.48, -0.05), Vector3(0.12, 0.2, 1.2), franja)
		var ojo := Vector3(0.3 * lado, 0.85, 0.5)
		_esf(raiz, ojo, Vector3.ONE * 0.32, verde)
		_esf(raiz, ojo + Vector3(0, 0.04, 0.1), Vector3.ONE * 0.24, _mat(Color(0.95, 0.75, 0.2), false, 0.1))
		_esf(raiz, ojo + Vector3(0, 0.04, 0.2), Vector3(0.16, 0.08, 0.06), _mat(NEGRO, false, 0.1))
		_esf(raiz, ojo + Vector3(0.04 * lado, 0.1, 0.22), Vector3.ONE * 0.05, _mat(BLANCO, false, 0.0, true))
		# Patas traseras plegadas y delanteras
		_esf(raiz, Vector3(0.55 * lado, 0.28, -0.45), Vector3(0.4, 0.35, 0.75), verde)
		_esf(raiz, Vector3(0.7 * lado, 0.08, -0.15), Vector3(0.3, 0.1, 0.55), verde)
		_cil(raiz, Vector3(0.35 * lado, 0.35, 0.5), Vector3(0.45 * lado, 0.0, 0.7), 0.07, verde)
		for dedo in [-0.5, 0.0, 0.5]:
			_esf(raiz, Vector3((0.45 + sin(dedo) * 0.12) * lado, 0.03, 0.7 + cos(dedo) * 0.12), Vector3.ONE * 0.08, verde)
	_esf(raiz, Vector3(0, 0.5, 0.82), Vector3(0.35, 0.05, 0.05), _mat(Color(0.2, 0.35, 0.15)))   # boca


static func _mamifero(raiz: Node3D, pelo: Color, cara: Color, nariz: Color, orejas: Color, chucha: bool) -> void:
	var cuerpo := _mat(pelo)
	_esf(raiz, Vector3(0, 0.55, -0.1), Vector3(0.95, 0.85, 1.5), cuerpo)
	var cabeza := Vector3(0, 0.75, 0.75)
	_esf(raiz, cabeza, Vector3(0.7, 0.62, 0.7), _mat(cara if chucha else pelo))
	_cono_entre(raiz, cabeza + Vector3(0, -0.05, 0.2), cabeza + Vector3(0, -0.12, 0.65), 0.22, _mat(cara))   # hocico
	_esf(raiz, cabeza + Vector3(0, -0.1, 0.66), Vector3.ONE * 0.12, _mat(nariz))
	for lado in [1.0, -1.0]:
		_esf(raiz, cabeza + Vector3(0.28 * lado, 0.32, -0.05), Vector3(0.3, 0.32, 0.08), _mat(orejas))
		var ojo := cabeza + Vector3(0.18 * lado, 0.1, 0.27)
		_esf(raiz, ojo, Vector3.ONE * 0.14, _mat(NEGRO, false, 0.1))
		_esf(raiz, ojo + Vector3(0.02 * lado, 0.03, 0.05), Vector3.ONE * 0.04, _mat(BLANCO, false, 0.0, true))
		for z in [0.4, -0.55]:
			_cil(raiz, Vector3(0.3 * lado, 0.35, z), Vector3(0.32 * lado, 0.0, z + 0.05), 0.09, cuerpo)
			_esf(raiz, Vector3(0.32 * lado, 0.03, z + 0.1), Vector3(0.16, 0.06, 0.2), _mat(nariz))
		# Bigotes
		for k in 2:
			_cil(raiz, cabeza + Vector3(0.1 * lado, -0.08, 0.55), cabeza + Vector3(0.45 * lado, -0.02 - k * 0.08, 0.55), 0.006, _mat(NEGRO))
	# Cola larga y desnuda
	var anterior := Vector3(0, 0.45, -0.85)
	for i in 6:
		var siguiente := anterior + Vector3(sin(i * 0.6) * 0.15, -0.04 if i < 3 else 0.06, -0.28)
		_cil(raiz, anterior, siguiente, 0.06 - i * 0.008, _mat(nariz if chucha else Color(0.85, 0.6, 0.6)))
		anterior = siguiente


static func _pez(raiz: Node3D) -> void:
	var cuerpo := _mat(Color(0.35, 0.33, 0.22))
	var vientre := _mat(Color(0.7, 0.66, 0.5))
	_esf(raiz, Vector3(0, 0.4, 0), Vector3(0.6, 0.5, 1.9), cuerpo)
	_esf(raiz, Vector3(0, 0.3, 0.1), Vector3(0.5, 0.3, 1.6), vientre)
	_esf(raiz, Vector3(0, 0.42, 0.85), Vector3(0.65, 0.42, 0.55), cuerpo)   # cabeza ancha (pez gato)
	_esf(raiz, Vector3(0, 0.45, -1.15), Vector3(0.06, 0.65, 0.5), cuerpo)    # aleta caudal
	_esf(raiz, Vector3(0, 0.68, -0.4), Vector3(0.05, 0.25, 0.5), cuerpo)     # aleta dorsal
	for lado in [1.0, -1.0]:
		var ojo := Vector3(0.22 * lado, 0.55, 1.0)
		_esf(raiz, ojo, Vector3.ONE * 0.12, _mat(BLANCO, false, 0.1))
		_esf(raiz, ojo + Vector3(0.02 * lado, 0, 0.04), Vector3.ONE * 0.08, _mat(NEGRO, false, 0.1))
		for k in 2:   # barbillas
			_cil(raiz, Vector3(0.15 * lado, 0.35 - k * 0.08, 1.1), Vector3(0.55 * lado, 0.2 - k * 0.1, 1.35), 0.015, cuerpo)
		_esf(raiz, Vector3(0.35 * lado, 0.22, 0.6), Vector3(0.35, 0.04, 0.2), cuerpo)   # aletas pectorales
	raiz.set_meta("flota", 0.25)


static func _lombriz(raiz: Node3D) -> void:
	var rosado := _mat(Color(0.85, 0.38, 0.4))
	var clitelo := _mat(Color(0.95, 0.55, 0.5))
	for i in 14:
		var z := 0.9 - i * 0.14
		var p := Vector3(sin(i * 0.5) * 0.25, 0.14 + (0.12 if i < 2 else 0.0), z)
		var mat := clitelo if i in [3, 4] else rosado
		_esf(raiz, p, Vector3.ONE * (0.24 - absf(i - 5) * 0.008), mat)
	for lado in [1.0, -1.0]:
		_esf(raiz, Vector3(0.06 * lado, 0.32, 0.95), Vector3.ONE * 0.06, _mat(NEGRO, false, 0.1))


# --- Piezas -----------------------------------------------------------------------------------

static func _preparar_mallas() -> void:
	if _esfera:
		return
	_esfera = SphereMesh.new()
	_esfera.radius = 0.5
	_esfera.height = 1.0
	_esfera.radial_segments = 16
	_esfera.rings = 8
	_cilindro = CylinderMesh.new()
	_cilindro.top_radius = 1.0
	_cilindro.bottom_radius = 1.0
	_cilindro.height = 1.0
	_cilindro.radial_segments = 8
	_cilindro.rings = 1
	_cono = CylinderMesh.new()
	_cono.top_radius = 0.0
	_cono.bottom_radius = 1.0
	_cono.height = 1.0
	_cono.radial_segments = 10
	_cono.rings = 1


## Material brillante tipo caricatura (se reutiliza por color).
static func _mat(color: Color, metal := false, rugosidad := 0.35, brilla := false) -> StandardMaterial3D:
	var clave := "%s|%s|%s|%s" % [color.to_html(), metal, rugosidad, brilla]
	if _materiales.has(clave):
		return _materiales[clave]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = rugosidad
	if metal:
		mat.metallic = 0.65
		mat.roughness = 0.25
	if brilla:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if color.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_materiales[clave] = mat
	return mat


## Elipsoide: esfera de diámetro 1 escalada a "tamano".
static func _esf(padre: Node3D, pos: Vector3, tamano: Vector3, mat: Material) -> MeshInstance3D:
	var pieza := MeshInstance3D.new()
	pieza.mesh = _esfera
	pieza.material_override = mat
	pieza.position = pos
	pieza.scale = tamano
	padre.add_child(pieza)
	return pieza


## Cilindro de "desde" a "hasta".
static func _cil(padre: Node3D, desde: Vector3, hasta: Vector3, radio: float, mat: Material) -> MeshInstance3D:
	return _entre(padre, _cilindro, desde, hasta, radio, mat)


## Cono con la base en "desde" y la punta en "hasta".
static func _cono_entre(padre: Node3D, desde: Vector3, hasta: Vector3, radio: float, mat: Material) -> MeshInstance3D:
	return _entre(padre, _cono, desde, hasta, radio, mat)


static func _entre(padre: Node3D, malla: Mesh, desde: Vector3, hasta: Vector3, radio: float, mat: Material) -> MeshInstance3D:
	var pieza := MeshInstance3D.new()
	pieza.mesh = malla
	pieza.material_override = mat
	var eje := hasta - desde
	var largo := maxf(eje.length(), 0.001)
	var arriba := eje / largo   # el cilindro de Godot va a lo largo de +Y
	var lateral := arriba.cross(Vector3.FORWARD if absf(arriba.dot(Vector3.FORWARD)) < 0.95 else Vector3.RIGHT).normalized()
	var frente := lateral.cross(arriba)
	pieza.transform = Transform3D(Basis(lateral * radio, arriba * largo, frente * radio), (desde + hasta) / 2.0)
	padre.add_child(pieza)
	return pieza


## Nodo del que cuelga un ala: AnimacionModelo lo hace aletear con esa amplitud (radianes) y rapidez.
static func _bisagra(padre: Node3D, nombre: String, pos: Vector3, amplitud: float, rapidez: float) -> Node3D:
	var bisagra := Node3D.new()
	bisagra.name = nombre
	bisagra.position = pos
	bisagra.set_meta("aleteo", amplitud)
	bisagra.set_meta("rapidez", rapidez)
	padre.add_child(bisagra)
	return bisagra


# --- Etapas del ciclo de vida ("evoluciones") ---------------------------------------------------

## Modelo de una fase del ciclo de vida: "Huevo", "Larva", "Pupa", "Ninfa" o "Adulto".
static func crear_etapa(especie: Especie, etapa: String) -> Node3D:
	var fase := etapa.to_lower()
	if fase.is_empty() or fase == "adulto" or not INSECTOS.has(especie.id):
		return crear(especie)
	_preparar_mallas()
	var d: Dictionary = INSECTOS[especie.id]
	var raiz := Node3D.new()
	raiz.name = "%s_%s" % [especie.id.capitalize().replace(" ", ""), etapa]
	match fase:
		"huevo": _huevos(raiz, especie.id, d)
		"larva": _larva(raiz, especie.id, d)
		"pupa": _pupa(raiz, especie.id, d)
		"ninfa": _insecto(raiz, _apagado(d, 0.35, especie.id in ["libelula", "caballito_del_diablo"]))
		_:
			raiz.free()
			return crear(especie)
	raiz.set_script(ANIMACION)
	return raiz


## Colores de adulto apagados (ninfas y pupas con forma de adulto) y sin alas.
static func _apagado(d: Dictionary, cuanto: float, acuatica := false) -> Dictionary:
	var copia := d.duplicate()
	var tono := Color(0.4, 0.36, 0.22) if acuatica else Color(0.55, 0.5, 0.4)
	for clave in ["cuerpo", "torax", "cabeza", "bandas"]:
		if copia.has(clave):
			copia[clave] = Color(copia[clave]).lerp(tono, cuanto + (0.35 if acuatica else 0.0))
	copia["sin_alas"] = true
	copia.erase("metal")
	return copia


static func _hoja(raiz: Node3D) -> void:
	_esf(raiz, Vector3(0, 0.03, 0), Vector3(2.0, 0.06, 1.2), _mat(Color(0.32, 0.6, 0.25)))
	_cil(raiz, Vector3(0, 0.07, -0.55), Vector3(0, 0.07, 0.55), 0.015, _mat(Color(0.5, 0.75, 0.4)))


static func _huevos(raiz: Node3D, id: String, d: Dictionary) -> void:
	var plan: String = d.plan
	if plan in ["libelula", "caballito"]:
		# En un tallo junto al agua
		_cil(raiz, Vector3(0, 0, 0), Vector3(0, 1.6, 0), 0.07, _mat(Color(0.35, 0.55, 0.25)))
		for i in 8:
			_esf(raiz, Vector3(0.08, 0.3 + i * 0.13, 0.02), Vector3(0.07, 0.1, 0.07), _mat(Color(0.95, 0.93, 0.75)))
		return
	_hoja(raiz)
	var color := Color(0.97, 0.95, 0.85)
	var cantidad := 9
	var forma := Vector3(0.14, 0.24, 0.14)   # óvalo de pie
	match plan:
		"escarabajo":
			color = Color(1.0, 0.85, 0.2) if id == "mariquita" else Color(1.0, 0.75, 0.25)
			cantidad = 14
		"mariposa", "polilla":
			color = Color(0.98, 0.95, 0.75) if id != "mariposa_blanca" else Color(1.0, 0.9, 0.4)
			cantidad = 3
			forma = Vector3(0.18, 0.3, 0.18)
		"chinche":
			color = Color(0.85, 0.95, 0.7)
			forma = Vector3(0.16, 0.2, 0.16)
		"zancudo":
			color = Color(0.15, 0.15, 0.15)   # balsa de huevos flotando
			cantidad = 20
			forma = Vector3(0.07, 0.2, 0.07)
		"crisopa":
			# Cada huevo en la punta de un hilo de seda
			for i in 5:
				var base := Vector3((i - 2) * 0.25, 0.06, 0.0)
				_cil(raiz, base, base + Vector3(0, 0.6, 0), 0.006, _mat(BLANCO))
				_esf(raiz, base + Vector3(0, 0.65, 0), Vector3(0.08, 0.13, 0.08), _mat(Color(0.75, 0.9, 0.6)))
			return
	var columnas := ceili(sqrt(cantidad))
	for i in cantidad:
		var x := (i % columnas - (columnas - 1) / 2.0) * forma.x * 1.25
		var z := (i / columnas - (columnas - 1) / 2.0) * forma.z * 1.25
		_esf(raiz, Vector3(x, 0.06 + forma.y / 2.0, z), forma, _mat(color))
		_esf(raiz, Vector3(x - 0.02, 0.06 + forma.y * 0.75, z + 0.03), forma * 0.25, _mat(BLANCO, false, 0.0, true))


static func _larva(raiz: Node3D, id: String, d: Dictionary) -> void:
	var plan: String = d.plan
	match plan:
		"mariposa", "polilla":
			var colores: Array = [Color(0.45, 0.75, 0.3)]
			var espinas := false
			match id:
				"mariposa_monarca":
					colores = [Color(1.0, 0.85, 0.15), NEGRO, BLANCO, NEGRO]
				"mariposa_blanca":
					colores = [Color(0.45, 0.72, 0.3), Color(0.5, 0.78, 0.32)]
				"ninfalida":
					colores = [Color(0.2, 0.15, 0.12), Color(0.25, 0.18, 0.12)]
					espinas = true
				"polilla_geometra":
					colores = [Color(0.55, 0.5, 0.3), Color(0.5, 0.45, 0.28)]
			var arqueada := id == "polilla_geometra"   # el "medidor" camina arqueado
			for i in 10:
				var z := 0.95 - i * 0.2
				var y := 0.2 + (sin(i / 9.0 * PI) * 0.45 if arqueada else 0.0)
				var p := Vector3(sin(i * 0.6) * 0.06, y, z)
				_esf(raiz, p, Vector3(0.36, 0.34, 0.26), _mat(colores[i % colores.size()]))
				if espinas:
					for lado in [1.0, -1.0]:
						_cono_entre(raiz, p + Vector3(0.12 * lado, 0.12, 0), p + Vector3(0.25 * lado, 0.32, 0), 0.03, _mat(Color(0.95, 0.6, 0.2)))
				if i % 3 == 1 and id == "mariposa_blanca":
					_esf(raiz, p + Vector3(0, 0.15, 0), Vector3(0.08, 0.04, 0.2), _mat(Color(1.0, 0.9, 0.3)))
				if i < 3 or i > 6:   # patitas
					for lado in [1.0, -1.0]:
						_cil(raiz, p + Vector3(0.1 * lado, -0.1, 0), Vector3(p.x + 0.14 * lado, 0.0, z), 0.03, _mat(Color(colores[0]).darkened(0.3)))
			if id == "mariposa_monarca":   # filamentos negros
				for z in [1.0, -0.85]:
					for lado in [1.0, -1.0]:
						_cil(raiz, Vector3(0.08 * lado, 0.32, z), Vector3(0.18 * lado, 0.7, z + 0.15 * signf(z)), 0.018, _mat(NEGRO))
			_cara_larva(raiz, Vector3(0, 0.22, 1.08), Color(colores[0]))
		"escarabajo":
			var cuerpo := Color(0.2, 0.2, 0.25) if id == "mariquita" else Color(0.95, 0.85, 0.4)
			var manchas := Color(1.0, 0.5, 0.1) if id == "mariquita" else NEGRO
			for i in 8:
				var ancho := 0.55 - absf(i - 2.5) * 0.05
				var p := Vector3(0, 0.25, 0.7 - i * 0.2)
				_esf(raiz, p, Vector3(ancho, 0.3, 0.26), _mat(cuerpo))
				if i in [2, 4]:
					for lado in [1.0, -1.0]:
						_esf(raiz, p + Vector3(0.15 * lado, 0.13, 0), Vector3.ONE * 0.11, _mat(manchas))
			for i in 3:
				for lado in [1.0, -1.0]:
					var cadera := Vector3(0.2 * lado, 0.2, 0.6 - i * 0.18)
					_cil(raiz, cadera, cadera + Vector3(0.25 * lado, -0.2, 0.05), 0.03, _mat(NEGRO))
			_cara_larva(raiz, Vector3(0, 0.3, 0.88), cuerpo)
		"abeja", "avispa", "hormiga", "mosca", "tipula":
			# Gusanito sin patas (blanco en abejas, avispas y moscas; grisáceo en la típula)
			var color := Color(0.97, 0.94, 0.85)
			if id == "sirfido":
				color = Color(0.7, 0.8, 0.55)
			elif plan == "tipula":
				color = Color(0.5, 0.45, 0.38)
			var curva := plan in ["abeja", "avispa", "hormiga"]
			for i in 9:
				var t := i / 8.0
				var p := Vector3(0, 0.3, 0.8 - i * 0.2)
				if curva:   # en forma de "C", como en su celda
					p = Vector3(0, 0.35 + sin(t * PI * 1.2) * 0.45, 0.6 - sin(t * PI * 0.9) * 1.1)
				var grosor := 0.42 - absf(t - 0.55) * 0.3
				_esf(raiz, p, Vector3(grosor, grosor, 0.28), _mat(color, false, 0.25))
			_cara_larva(raiz, Vector3(0, 0.4, 0.75) if curva else Vector3(0, 0.35, 0.88), color)
		"zancudo":
			# Larva acuática: tórax ancho, abdomen fino y sifón para respirar
			var oscuro := _mat(Color(0.3, 0.3, 0.28))
			_esf(raiz, Vector3(0, 0.3, 0.5), Vector3(0.45, 0.4, 0.45), oscuro)
			for i in 7:
				_esf(raiz, Vector3(0, 0.3, 0.2 - i * 0.18), Vector3(0.18, 0.18, 0.22), oscuro)
			_cil(raiz, Vector3(0, 0.3, -0.95), Vector3(0.1, 0.65, -1.15), 0.04, oscuro)
			for lado in [1.0, -1.0]:
				for k in 3:
					_cil(raiz, Vector3(0.18 * lado, 0.3, 0.5 - k * 0.1), Vector3(0.45 * lado, 0.4, 0.55 - k * 0.15), 0.008, oscuro)
			_cara_larva(raiz, Vector3(0, 0.32, 0.78), Color(0.3, 0.3, 0.28))
		"crisopa":
			# "León de áfidos": cuerpo moteado con mandíbulas curvas
			var crema := Color(0.85, 0.75, 0.55)
			for i in 6:
				_esf(raiz, Vector3(0, 0.25, 0.5 - i * 0.2), Vector3(0.5 - i * 0.05, 0.25, 0.26), _mat(crema if i % 2 == 0 else Color(0.7, 0.55, 0.35)))
			for lado in [1.0, -1.0]:
				_cil(raiz, Vector3(0.08 * lado, 0.27, 0.72), Vector3(0.22 * lado, 0.28, 1.0), 0.025, _mat(Color(0.55, 0.35, 0.2)))
				_cil(raiz, Vector3(0.22 * lado, 0.28, 1.0), Vector3(0.08 * lado, 0.28, 1.15), 0.02, _mat(Color(0.55, 0.35, 0.2)))
				for i in 3:
					var cadera := Vector3(0.18 * lado, 0.2, 0.45 - i * 0.15)
					_cil(raiz, cadera, cadera + Vector3(0.25 * lado, -0.2, 0.05), 0.025, _mat(Color(0.55, 0.45, 0.3)))
			_cara_larva(raiz, Vector3(0, 0.3, 0.68), crema)
		_:
			_insecto(raiz, _apagado(d, 0.5))


## Cabecita con ojos pequeños para las larvas.
static func _cara_larva(raiz: Node3D, pos: Vector3, color: Color) -> void:
	_esf(raiz, pos, Vector3(0.34, 0.32, 0.26), _mat(color.darkened(0.15)))
	for lado in [1.0, -1.0]:
		var ojo := pos + Vector3(0.09 * lado, 0.05, 0.12)
		_esf(raiz, ojo, Vector3.ONE * 0.08, _mat(NEGRO, false, 0.1))
		_esf(raiz, ojo + Vector3(0.01 * lado, 0.02, 0.03), Vector3.ONE * 0.025, _mat(BLANCO, false, 0.0, true))


static func _pupa(raiz: Node3D, id: String, d: Dictionary) -> void:
	var plan: String = d.plan
	match plan:
		"mariposa":
			# Crisálida colgando de una ramita
			_cil(raiz, Vector3(-0.8, 1.9, 0), Vector3(0.8, 1.9, 0), 0.06, _mat(Color(0.45, 0.32, 0.2)))
			_cil(raiz, Vector3(0, 1.88, 0), Vector3(0, 1.65, 0), 0.025, _mat(NEGRO))
			var color := Color(0.5, 0.38, 0.25)
			if id == "mariposa_monarca":
				color = Color(0.45, 0.78, 0.45)
			elif id == "mariposa_blanca":
				color = Color(0.6, 0.75, 0.4)
			var cuerpo := _mat(color, false, 0.2)
			_esf(raiz, Vector3(0, 1.2, 0), Vector3(0.55, 0.95, 0.5), cuerpo)
			_esf(raiz, Vector3(0, 0.65, 0), Vector3(0.3, 0.35, 0.3), cuerpo)
			if id == "mariposa_monarca":   # banda negra con puntos dorados
				_esf(raiz, Vector3(0, 1.45, 0), Vector3(0.57, 0.06, 0.52), _mat(NEGRO))
				for i in 6:
					var a := TAU * i / 6.0
					_esf(raiz, Vector3(cos(a) * 0.22, 1.5, sin(a) * 0.2), Vector3.ONE * 0.06, _mat(Color(1.0, 0.8, 0.2), true))
		"polilla":
			_hoja(raiz)
			_esf(raiz, Vector3(0, 0.3, 0), Vector3(0.45, 0.4, 1.0), _mat(Color(0.5, 0.32, 0.18), false, 0.2))
			for i in 4:
				_esf(raiz, Vector3(0, 0.3, 0.3 - i * 0.2), Vector3(0.47, 0.42, 0.04), _mat(Color(0.4, 0.25, 0.15)))
		"escarabajo":
			_hoja(raiz)
			var color := Color(1.0, 0.55, 0.15) if id == "mariquita" else Color(0.95, 0.85, 0.4)
			_esf(raiz, Vector3(0, 0.35, 0), Vector3(0.8, 0.55, 0.9), _mat(color, false, 0.25))
			for p in [Vector3(0.2, 0.6, 0.1), Vector3(-0.2, 0.6, 0.1), Vector3(0, 0.62, -0.2), Vector3(0.25, 0.5, -0.25), Vector3(-0.25, 0.5, -0.25)]:
				_esf(raiz, p, Vector3(0.12, 0.05, 0.12), _mat(NEGRO))
			_esf(raiz, Vector3(0, 0.22, -0.48), Vector3(0.4, 0.2, 0.3), _mat(Color(0.25, 0.25, 0.25)))
		"abeja", "avispa", "hormiga":
			# Pupa blanca con forma de adulto dentro de su celda
			var blanco := d.duplicate()
			for clave in ["cuerpo", "torax", "cabeza", "bandas"]:
				if blanco.has(clave):
					blanco[clave] = Color(0.96, 0.93, 0.85)
			blanco["sin_alas"] = true
			blanco["ojos"] = Color(0.75, 0.6, 0.6)
			_insecto(raiz, blanco)
		"mosca", "tipula":
			# Pupario: barrilito café
			_esf(raiz, Vector3(0, 0.32, 0), Vector3(0.6, 0.6, 1.3 if plan == "tipula" else 1.0), _mat(Color(0.5, 0.3, 0.15), false, 0.25))
			for i in 5:
				_esf(raiz, Vector3(0, 0.32, 0.4 - i * 0.2), Vector3(0.62, 0.62, 0.03), _mat(Color(0.4, 0.22, 0.1)))
		"zancudo":
			# Pupa en forma de "coma" con trompetas para respirar
			var oscuro := _mat(Color(0.3, 0.3, 0.32))
			_esf(raiz, Vector3(0, 0.55, 0.2), Vector3(0.75, 0.7, 0.7), oscuro)
			for i in 5:
				var t := i / 4.0
				_esf(raiz, Vector3(0, 0.45 - t * 0.3, -0.15 - t * 0.5), Vector3.ONE * (0.25 - t * 0.12), oscuro)
			for lado in [1.0, -1.0]:
				_cono_entre(raiz, Vector3(0.12 * lado, 0.8, 0.25), Vector3(0.2 * lado, 1.1, 0.3), 0.06, oscuro)
		"crisopa":
			_hoja(raiz)
			_esf(raiz, Vector3(0, 0.38, 0), Vector3.ONE * 0.65, _mat(Color(0.97, 0.97, 0.92), false, 0.6))
		_:
			_insecto(raiz, _apagado(d, 0.5))
