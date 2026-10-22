class_name Especie
extends Resource
## Ficha de una especie del humedal. Cada especie es un archivo .tres en res://especies/datos/
## (se crean desde el editor: clic derecho > Nuevo > Recurso > Especie).

enum Tipo { AVE, INSECTO, ANFIBIO, REPTIL, MAMIFERO, PEZ, PLANTA }
enum Estado { LC, NT, VU, EN, CR, DD }  # Categorías UICN

const NOMBRES_TIPO := {
	Tipo.AVE: "Ave",
	Tipo.INSECTO: "Insecto",
	Tipo.ANFIBIO: "Anfibio",
	Tipo.REPTIL: "Reptil",
	Tipo.MAMIFERO: "Mamífero",
	Tipo.PEZ: "Pez",
	Tipo.PLANTA: "Planta",
}

const NOMBRES_ESTADO := {
	Estado.LC: "Preocupación menor",
	Estado.NT: "Casi amenazada",
	Estado.VU: "Vulnerable",
	Estado.EN: "En peligro",
	Estado.CR: "En peligro crítico",
	Estado.DD: "Datos insuficientes",
}

@export var numero: int = 0              # orden en la Bioentdex (#001, #002...)
@export var id: String = ""              # identificador único, sin espacios (se usa al guardar)
@export var nombre_comun: String = ""
@export var nombre_cientifico: String = ""
@export var tipo: Tipo = Tipo.AVE
@export var estado_conservacion: Estado = Estado.LC
@export_multiline var descripcion: String = ""
@export var imagen: Texture2D
@export_multiline var consejo_macro: String = ""  # se muestra en la Guía Macrofotográfica


func nombre_tipo() -> String:
	return NOMBRES_TIPO[tipo]


func nombre_estado() -> String:
	return NOMBRES_ESTADO[estado_conservacion]
