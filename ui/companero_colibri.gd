extends PanelContainer
## Bocadillo del colibrí en las zonas interiores (en el mapa se usa BurbujaColibri).

@export var mostrar_retrato := true
@export var mostrar_boton_siguiente := true

var _zona_id := ""
var _tiene_contexto := false

@onready var retrato: TextureRect = $Margen/Columna/Contenido/Retrato
@onready var categoria: Label = $Margen/Columna/Categoria
@onready var texto: Label = $Margen/Columna/Contenido/Texto
@onready var boton_siguiente: Button = $Margen/Columna/BotonSiguiente


func _ready() -> void:
	retrato.visible = mostrar_retrato
	boton_siguiente.visible = mostrar_boton_siguiente
	boton_siguiente.pressed.connect(_mostrar_siguiente)
	if not mostrar_retrato:
		$Margen/Columna/Contenido.add_theme_constant_override("separation", 0)


func establecer_contexto(zona_id: String) -> void:
	if _tiene_contexto and zona_id == _zona_id:
		return
	_zona_id = zona_id
	_tiene_contexto = true
	_mostrar_siguiente()


func _mostrar_siguiente() -> void:
	var dialogo := DialogosColibri.siguiente(_zona_id)
	if dialogo.is_empty():
		categoria.text = "Colibrí"
		texto.text = "No pude cargar un dato para esta zona."
		boton_siguiente.disabled = true
		return

	categoria.text = "Colibrí · " + DialogosColibri.nombre_categoria(dialogo["categoria"])
	texto.text = dialogo["texto"]
	boton_siguiente.disabled = false
