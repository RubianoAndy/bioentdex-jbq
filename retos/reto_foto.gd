class_name RetoFoto
extends Control
## Ventana del reto de foto del mapa: explica el reto, abre la cámara del teléfono y guarda la foto
## en la base de datos de la Bioentdex (RegistroEspecies.registrar_mision).

signal terminado(cumplido: bool)

const CAPTURA := preload("res://captura/CapturaAR.tscn")
const AZUL := Color(0.45, 0.78, 1.0)

var mision: Mision
var zona_id := ""
var tipo_fondo := "pradera"

var _panel: PanelContainer
var _caja: VBoxContainer


static func mostrar(padre: Node, nueva_mision: Mision, nueva_zona_id: String, fondo: String) -> RetoFoto:
	var reto := RetoFoto.new()
	reto.mision = nueva_mision
	reto.zona_id = nueva_zona_id
	reto.tipo_fondo = fondo
	padre.add_child(reto)
	return reto


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var sombra := ColorRect.new()
	sombra.color = Color(0, 0, 0, 0.55)
	sombra.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(sombra)

	_panel = PanelContainer.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_left = 24
	_panel.offset_right = -24
	_panel.offset_bottom = -40
	_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(_panel)
	var margen := MarginContainer.new()
	for lado in ["left", "right", "top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 24)
	_panel.add_child(margen)
	_caja = VBoxContainer.new()
	_caja.add_theme_constant_override("separation", 18)
	margen.add_child(_caja)
	_mostrar_inicio()


func _mostrar_inicio() -> void:
	_limpiar()
	_caja.add_child(_etiqueta("Reto de foto", 26, AZUL))
	_caja.add_child(_etiqueta(mision.enunciado, 30, Color.WHITE))
	if RegistroEspecies.mision_resuelta(mision.id):
		_caja.add_child(_etiqueta("Ya cumpliste este reto, pero puedes tomar otra foto: también se guarda.", 22, Color(1, 1, 1, 0.7)))
	_caja.add_child(_boton("Abrir cámara", _abrir_camara))
	_caja.add_child(_boton("Ahora no", _terminar.bind(false)))


func _abrir_camara() -> void:
	_panel.hide()
	var camara := CAPTURA.instantiate()
	camara.tipo_fondo = tipo_fondo
	camara.texto_mision = mision.enunciado
	camara.zona_id = zona_id
	camara.foto_tomada.connect(_on_foto_tomada)
	camara.terminada.connect(func(capturado: bool) -> void:
		if not capturado:
			_panel.show())   # salió sin tomar la foto
	add_child(camara)


func _on_foto_tomada(foto: Image) -> void:
	RegistroEspecies.registrar_mision(mision, zona_id, "foto", true, foto)
	_panel.show()
	_limpiar()
	_caja.add_child(_etiqueta("¡Foto guardada en tu Bioentdex!", 30, AZUL))
	var miniatura := TextureRect.new()
	miniatura.texture = ImageTexture.create_from_image(foto)
	miniatura.custom_minimum_size = Vector2(0, 320)
	miniatura.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	miniatura.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_caja.add_child(miniatura)
	if not mision.explicacion.is_empty():
		_caja.add_child(_etiqueta(mision.explicacion, 24, Color.WHITE))
	_caja.add_child(_boton("Listo", _terminar.bind(true)))


func _terminar(cumplido: bool) -> void:
	terminado.emit(cumplido)
	queue_free()


func _limpiar() -> void:
	for hijo in _caja.get_children():
		hijo.queue_free()


func _boton(texto: String, accion: Callable) -> Button:
	var boton := Button.new()
	boton.text = texto
	boton.custom_minimum_size = Vector2(0, 72)
	boton.add_theme_font_size_override("font_size", 26)
	boton.pressed.connect(accion)
	return boton


func _etiqueta(texto: String, tamano: int, color: Color) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etiqueta.add_theme_font_size_override("font_size", tamano)
	etiqueta.add_theme_color_override("font_color", color)
	return etiqueta
