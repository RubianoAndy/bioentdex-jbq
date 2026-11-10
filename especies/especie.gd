class_name Especie
extends Resource
## Ficha de una especie del humedal. Cada especie es un archivo .tres en res://especies/datos/
## (se crean desde el editor: clic derecho > Nuevo > Recurso > Especie).
##
## Imágenes (por convención, según el id):
##   - Animales del mapa (NPC):    res://animales/npc/<id>.svg (o .png)
##   - Insectos (dataset de RA):    res://dataset/insectos/<id>/  (todas las imágenes de la carpeta)

enum Tipo { AVE, INSECTO, ANFIBIO, REPTIL, MAMIFERO, PEZ, PLANTA, INVERTEBRADO }
enum Estado { LC, NT, VU, EN, CR, DD, NE }  # Categorías de conservación
enum Horario { SIEMPRE, DIA, NOCHE }
enum Movimiento { QUIETO, CAMINAR, NADAR, SALTAR, VOLAR }

const NOMBRES_TIPO := {
	Tipo.AVE: "Ave",
	Tipo.INSECTO: "Insecto",
	Tipo.ANFIBIO: "Anfibio",
	Tipo.REPTIL: "Reptil",
	Tipo.MAMIFERO: "Mamífero",
	Tipo.PEZ: "Pez",
	Tipo.PLANTA: "Planta",
	Tipo.INVERTEBRADO: "Invertebrado",
}

const NOMBRES_ESTADO := {
	Estado.LC: "Preocupación menor",
	Estado.NT: "Casi amenazada",
	Estado.VU: "Vulnerable",
	Estado.EN: "En peligro",
	Estado.CR: "En peligro crítico",
	Estado.DD: "Datos insuficientes",
	Estado.NE: "No evaluada",
}

@export var numero: int = 0              # orden en la Bioentdex (#001, #002...)
@export var id: String = ""              # identificador único, sin espacios (se usa al guardar)
@export var nombre_comun: String = ""
@export var nombre_cientifico: String = ""
@export var familia: String = ""
@export var orden: String = ""
@export var tipo: Tipo = Tipo.AVE
@export var estado_conservacion: Estado = Estado.NE
@export var fuente_estado_conservacion: String = ""
@export var alcance_estado_conservacion: String = ""
@export_multiline var descripcion: String = ""    # muy corta: una frase
@export_multiline var importancia: String = ""    # por qué es importante para el humedal
## Valores base del modelo educativo; no son mediciones de campo ni afirmaciones ecológicas.
## Probabilidad de anular un impacto QTE; solo configúrala con respaldo documentado para la especie.
@export_range(0.0, 0.5, 0.05) var defensa_morfologica_qte: float = 0.0
@export var adaptacion_defensiva_documentada: String = ""
## Incremento pequeño por categoría; LC, DD y NE permanecen neutrales.
@export_range(0.0, 0.02, 0.005) var incremento_educativo_conservacion: float = 0.01
## Fases que cuentan con respaldo en el contenido educativo de esta especie.
@export var etapas_ciclo_vida: PackedStringArray = []
@export_range(1, 10, 1) var registros_por_etapa: int = 3
@export var imagen: Texture2D                     # opcional: si está vacía se usa la de la convención
@export_multiline var consejo_macro: String = ""
## Página de su familia en la guía macrofotográfica (0 = no está en la guía)
@export var pagina_guia: int = 0
## Organismo Plus: no aparece en el mapa, se obtiene en la tienda con semillas
@export var plus: bool = false
@export var precio: int = 0

@export_group("Atributos ecológicos")
@export_range(0.0, 100.0, 0.1) var impacto_ecologico: float = 50.0
@export_range(0.0, 100.0, 0.1) var resistencia_habitat: float = 50.0
@export_range(0.0, 100.0, 0.1) var vitalidad_poblacional: float = 50.0

@export_group("En el mapa")
@export var horario: Horario = Horario.SIEMPRE
@export var movimiento: Movimiento = Movimiento.CAMINAR
## Tipos de suelo (ver PaletaMapa) donde puede aparecer suelto por el mapa
@export var suelos_habitat: PackedInt32Array = []
@export var tamano_en_mapa: float = 1.0


func nombre_tipo() -> String:
	return NOMBRES_TIPO[tipo]


func nombre_estado() -> String:
	return NOMBRES_ESTADO[estado_conservacion]


func factor_conservacion_pb() -> float:
	var peso := 0
	match estado_conservacion:
		Estado.NT: peso = 1
		Estado.VU: peso = 2
		Estado.EN: peso = 3
		Estado.CR: peso = 4
	return 1.0 + incremento_educativo_conservacion * peso


## Solo los insectos se capturan con la cámara; el resto de animales son NPC.
func es_capturable() -> bool:
	return tipo == Tipo.INSECTO


func es_animal() -> bool:
	return tipo != Tipo.PLANTA


func activa_ahora() -> bool:
	var hora: int = Time.get_datetime_dict_from_system().hour
	var de_dia := hora >= 6 and hora < 18
	match horario:
		Horario.DIA: return de_dia
		Horario.NOCHE: return not de_dia
	return true


## Imagen principal: la de la ficha, o la del mapa, o la primera del dataset.
func obtener_imagen() -> Texture2D:
	if imagen:
		return imagen
	var npc := imagen_mapa()
	if npc:
		return npc
	var dataset := imagenes_dataset()
	return dataset[0] if not dataset.is_empty() else null


func imagen_mapa() -> Texture2D:
	for extension in ["svg", "png", "webp"]:
		var ruta := "res://animales/npc/%s.%s" % [id, extension]
		if ResourceLoader.exists(ruta):
			return load(ruta)
	if es_capturable():
		var dataset := imagenes_dataset()
		return dataset[0] if not dataset.is_empty() else null
	return null


## Fotografías reales del humedal (res://dataset/fotos_app/<id>/). Se generan desde
## dataset/insectos reales con dataset/herramientas/generar_fotos_app.py.
func fotos_reales() -> Array[Texture2D]:
	var fotos: Array[Texture2D] = []
	var carpeta := "res://dataset/fotos_app/%s/" % id
	for archivo in ResourceLoader.list_directory(carpeta):
		if archivo.get_extension().to_lower() in ["jpg", "jpeg", "png", "webp"]:
			var textura := load(carpeta + archivo) as Texture2D
			if textura:
				fotos.append(textura)
	return fotos


## Imágenes del dataset de realidad aumentada (res://dataset/insectos/<id>/).
func imagenes_dataset() -> Array[Texture2D]:
	var imagenes: Array[Texture2D] = []
	var carpeta := "res://dataset/insectos/%s/" % id
	for archivo in ResourceLoader.list_directory(carpeta):
		if archivo.get_extension().to_lower() in ["svg", "png", "jpg", "jpeg", "webp"]:
			var textura := load(carpeta + archivo) as Texture2D
			if textura:
				imagenes.append(textura)
	return imagenes
