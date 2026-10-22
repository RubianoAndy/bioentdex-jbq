class_name Zona
extends Resource
## Una zona del humedal (acuática, vegetal...). Cada zona es un .tres en res://zonas/datos/.

@export var id: String = ""
@export var nombre: String = ""
@export_multiline var descripcion: String = ""
@export var color: Color = Color.WHITE
## Centro de la zona en el mapa: x = este/oeste, y = norte(-)/sur(+). El mapa mide 24 x 43.
@export var posicion: Vector2 = Vector2.ZERO
@export var radio: float = 2.5
@export var especies: Array[Especie] = []
