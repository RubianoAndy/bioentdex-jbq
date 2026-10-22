extends Control
## Bioentdex: la base de datos del jugador. Pestaña "Especies" (insectos capturados con su foto,
## animales y plantas observados, y siluetas de lo que falta) y pestaña "Misiones" (sus respuestas).

const TAMANO_TARJETA := Vector2(212, 270)

@onready var cuadricula: GridContainer = $Margen/VBox/Pestanas/Especies/Cuadricula
@onready var lista_misiones: VBoxContainer = $Margen/VBox/Pestanas/Misiones/Lista
@onready var contador: Label = $Margen/VBox/Contador


func _ready() -> void:
	$Margen/VBox/Encabezado/BtnVolver.pressed.connect(_on_volver_pressed)
	var insectos := RegistroEspecies.especies.filter(func(e: Especie) -> bool: return e.es_capturable())
	var capturados := insectos.filter(func(e: Especie) -> bool: return RegistroEspecies.esta_capturada(e.id))
	var total_misiones := 0
	for zona in Expedicion.zonas:
		total_misiones += zona.misiones.size()
	contador.text = "Insectos capturados %d/%d  ·  Especies conocidas %d/%d  ·  Misiones %d/%d" % [
		capturados.size(), insectos.size(),
		RegistroEspecies.cantidad_descubiertas(), RegistroEspecies.especies.size(),
		RegistroEspecies.cantidad_misiones_resueltas(), total_misiones]

	for especie in RegistroEspecies.especies:
		cuadricula.add_child(_crear_tarjeta(especie))
	_llenar_misiones()


func _crear_tarjeta(especie: Especie) -> Button:
	var tarjeta := Button.new()
	tarjeta.custom_minimum_size = TAMANO_TARJETA
	tarjeta.icon = especie.obtener_imagen()
	tarjeta.expand_icon = true
	tarjeta.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tarjeta.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	tarjeta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tarjeta.add_theme_font_size_override("font_size", 19)
	var capturas := RegistroEspecies.capturas_de(especie.id)
	if not capturas.is_empty():
		tarjeta.text = "#%03d %s\nCapturado ×%d" % [especie.numero, especie.nombre_comun, capturas.size()]
		tarjeta.add_theme_color_override("font_color", Color(1, 0.86, 0.35))
	elif RegistroEspecies.esta_observada(especie.id):
		tarjeta.text = "#%03d %s\nObservado" % [especie.numero, especie.nombre_comun]
	else:
		tarjeta.text = "#%03d ???%s" % [especie.numero, "\nInsecto" if especie.es_capturable() else ""]
		tarjeta.disabled = true
		# La imagen se pinta de negro: queda solo la silueta
		tarjeta.add_theme_color_override("icon_disabled_color", Color.BLACK)
	tarjeta.pressed.connect(_mostrar_ficha.bind(especie))
	return tarjeta


func _mostrar_ficha(especie: Especie) -> void:
	var capturas := RegistroEspecies.capturas_de(especie.id)
	var foto := RegistroEspecies.cargar_foto(capturas[-1].foto) if not capturas.is_empty() else null
	FichaEspecie.mostrar(self, especie, "Tu foto" if foto else "", foto)


func _llenar_misiones() -> void:
	for zona in Expedicion.zonas:
		var titulo := Label.new()
		titulo.text = zona.nombre
		titulo.add_theme_font_size_override("font_size", 26)
		titulo.add_theme_color_override("font_color", Color(1, 0.84, 0.3))
		lista_misiones.add_child(titulo)
		for mision in zona.misiones:
			lista_misiones.add_child(_fila_mision(mision))


func _fila_mision(mision: Mision) -> Control:
	var registro := RegistroEspecies.registro_mision(mision.id)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	var texto := Label.new()
	texto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.add_theme_font_size_override("font_size", 20)
	if registro.is_empty():
		texto.text = "Pendiente · " + mision.enunciado
		texto.modulate.a = 0.6
	else:
		var estado := "Resuelta" if registro.correcta else "Sin resolver"
		texto.text = "%s · %s\nTu respuesta: %s (%s)" % [estado, mision.enunciado, registro.respuesta, registro.fecha.substr(0, 10)]
	if mision.especial and ResourceLoader.exists("res://ui/bandera.svg"):
		var bandera := TextureRect.new()
		bandera.texture = load("res://ui/bandera.svg")
		bandera.custom_minimum_size = Vector2(44, 44)
		bandera.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bandera.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		fila.add_child(bandera)
		texto.add_theme_color_override("font_color", Color(1, 0.86, 0.4))
	fila.add_child(texto)
	var foto := RegistroEspecies.cargar_foto(registro.get("foto", ""))
	if foto:
		var miniatura := TextureRect.new()
		miniatura.texture = foto
		miniatura.custom_minimum_size = Vector2(96, 96)
		miniatura.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		miniatura.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		fila.add_child(miniatura)
	return fila


func _on_volver_pressed() -> void:
	get_tree().change_scene_to_file(Perfil.volver_a)
