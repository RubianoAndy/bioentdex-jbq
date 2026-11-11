extends Control
## Acceso local del docente y exportación manual de contadores pedagógicos agregados.

const DORADO := Color(1.0, 0.82, 0.32)

var _columna: VBoxContainer
var _mensaje: Label


func _ready() -> void:
	var fondo := ColorRect.new()
	fondo.color = Color(0.025, 0.09, 0.07)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	var margen := MarginContainer.new()
	margen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margen.add_theme_constant_override("margin_left", 26)
	margen.add_theme_constant_override("margin_top", 28)
	margen.add_theme_constant_override("margin_right", 26)
	margen.add_theme_constant_override("margin_bottom", 28)
	add_child(margen)
	_columna = VBoxContainer.new()
	_columna.add_theme_constant_override("separation", 14)
	margen.add_child(_columna)
	_mostrar_acceso()


func _exit_tree() -> void:
	AnaliticaPedagogica.cerrar_sesion_docente()


func _mostrar_acceso() -> void:
	for hijo in _columna.get_children():
		hijo.queue_free()
	_agregar_titulo("Analítica pedagógica local")
	_agregar_texto(Privacidad.aviso_analitica())
	_agregar_texto(Privacidad.limite_pin())
	if AnaliticaPedagogica.pin_configurado():
		_formulario_pin()
	else:
		_formulario_configuracion()
	_mensaje = _agregar_texto("", Color.WHITE)
	_agregar_boton("Volver", _volver)


func _formulario_configuracion() -> void:
	_agregar_texto("Primera configuración: el docente debe crear su propio PIN local de al menos 6 dígitos. No existe un PIN predeterminado.")
	var pin := _entrada("Crear PIN docente", true)
	var confirmar := _entrada("Confirmar PIN", true)
	var configurar := Button.new()
	configurar.text = "Guardar PIN docente en este dispositivo"
	configurar.custom_minimum_size.y = 64
	configurar.pressed.connect(func() -> void:
		if pin.text != confirmar.text:
			_mostrar_mensaje("Los PIN no coinciden.")
			return
		var pin_nuevo := pin.text
		if not AnaliticaPedagogica.configurar_pin(pin_nuevo):
			_mostrar_mensaje(AnaliticaPedagogica.mensaje_pin())
			return
		if AnaliticaPedagogica.autenticar(pin_nuevo):
			pin.clear()
			confirmar.clear()
			_mostrar_resumen()
		else:
			pin.clear()
			confirmar.clear()
			var error := AnaliticaPedagogica.mensaje_pin()
			_mostrar_acceso()
			_mostrar_mensaje(error))
	_columna.add_child(configurar)


func _formulario_pin() -> void:
	_agregar_texto("Ingresa el PIN configurado por el docente en este dispositivo.")
	var pin := _entrada("PIN docente", true)
	var ingresar := Button.new()
	ingresar.text = "Ingresar"
	ingresar.custom_minimum_size.y = 64
	ingresar.pressed.connect(func() -> void:
		if AnaliticaPedagogica.autenticar(pin.text):
			pin.clear()
			_mostrar_resumen()
		else:
			pin.clear()
			var espera := AnaliticaPedagogica.segundos_bloqueo()
			_mostrar_mensaje(AnaliticaPedagogica.mensaje_pin() if espera == 0 else "Demasiados intentos. Espera %d segundos." % espera))
	_columna.add_child(ingresar)


func _mostrar_resumen() -> void:
	for hijo in _columna.get_children():
		hijo.queue_free()
	_agregar_titulo("Resumen de esta instalación")
	_agregar_texto(Privacidad.aviso_analitica())
	_agregar_texto(AnaliticaPedagogica.resumen_legible())
	_mensaje = _agregar_texto("", Color.WHITE)
	_agregar_boton("Exportar JSON local", func() -> void:
		var resultado := AnaliticaPedagogica.exportar_json_docente()
		_mostrar_mensaje(resultado))
	_agregar_boton("Cerrar sesión docente", func() -> void:
		AnaliticaPedagogica.cerrar_sesion_docente()
		_mostrar_acceso())
	_agregar_boton("Volver", _volver)


func _entrada(ayuda: String, oculta: bool) -> LineEdit:
	var entrada := LineEdit.new()
	entrada.placeholder_text = ayuda
	entrada.secret = oculta
	entrada.custom_minimum_size.y = 56
	entrada.max_length = 32
	_columna.add_child(entrada)
	return entrada


func _agregar_titulo(texto: String) -> void:
	var etiqueta := _agregar_texto(texto, DORADO)
	etiqueta.add_theme_font_size_override("font_size", 32)
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _agregar_texto(texto: String, color: Color = Color.WHITE) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etiqueta.add_theme_font_size_override("font_size", 20)
	etiqueta.add_theme_color_override("font_color", color)
	_columna.add_child(etiqueta)
	return etiqueta


func _agregar_boton(texto: String, accion: Callable) -> void:
	var boton := Button.new()
	boton.text = texto
	boton.custom_minimum_size.y = 62
	boton.pressed.connect(accion)
	_columna.add_child(boton)


func _mostrar_mensaje(texto: String) -> void:
	if is_instance_valid(_mensaje):
		_mensaje.text = texto


func _volver() -> void:
	AnaliticaPedagogica.cerrar_sesion_docente()
	get_tree().change_scene_to_file(Perfil.volver_a)
