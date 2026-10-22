extends Control
## Bioentdex: catálogo de especies. Las no descubiertas se ven como silueta con "???".

const TAMANO_TARJETA := Vector2(208, 260)

@onready var cuadricula: GridContainer = $Margen/VBox/Scroll/Cuadricula
@onready var contador: Label = $Margen/VBox/Encabezado/Contador
@onready var detalle: PanelContainer = $Detalle
@onready var detalle_imagen: TextureRect = $Detalle/Margen/VBox/Imagen
@onready var detalle_nombre: Label = $Detalle/Margen/VBox/Nombre
@onready var detalle_cientifico: Label = $Detalle/Margen/VBox/Cientifico
@onready var detalle_datos: Label = $Detalle/Margen/VBox/Datos
@onready var detalle_descripcion: Label = $Detalle/Margen/VBox/Scroll/Descripcion


func _ready() -> void:
	$Margen/VBox/Encabezado/BtnVolver.pressed.connect(_on_volver_pressed)
	$Detalle/Margen/VBox/BtnCerrar.pressed.connect(detalle.hide)
	for especie in RegistroEspecies.especies:
		cuadricula.add_child(_crear_tarjeta(especie))
	contador.text = "%d / %d" % [RegistroEspecies.cantidad_descubiertas(), RegistroEspecies.especies.size()]


func _crear_tarjeta(especie: Especie) -> Button:
	var tarjeta := Button.new()
	tarjeta.custom_minimum_size = TAMANO_TARJETA
	tarjeta.icon = especie.imagen
	tarjeta.expand_icon = true
	tarjeta.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tarjeta.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	tarjeta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if RegistroEspecies.esta_descubierta(especie.id):
		tarjeta.text = "#%03d\n%s" % [especie.numero, especie.nombre_comun]
		tarjeta.pressed.connect(_mostrar_detalle.bind(especie))
	else:
		tarjeta.text = "#%03d\n???" % especie.numero
		tarjeta.disabled = true
		# La imagen se pinta de negro: queda solo la silueta
		tarjeta.add_theme_color_override("icon_disabled_color", Color.BLACK)
	return tarjeta


func _mostrar_detalle(especie: Especie) -> void:
	detalle_imagen.texture = especie.imagen
	detalle_nombre.text = especie.nombre_comun
	detalle_cientifico.text = especie.nombre_cientifico
	detalle_datos.text = "%s · %s" % [especie.nombre_tipo(), especie.nombre_estado()]
	detalle_descripcion.text = especie.descripcion
	detalle.show()


func _on_volver_pressed() -> void:
	get_tree().change_scene_to_file("res://MenuPrincipal.tscn")
