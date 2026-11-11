extends Node
## Autoload central para buses, musica, ambiente y efectos.

const BUS_MASTER := "Master"
const BUS_MUSICA := "BGM"
const BUS_AMBIENTE := "AMB"
const BUS_SFX := "SFX"
const CAPACIDAD_SFX := 8
const CLAVES_AMBIENTE := [
	"humedal_aves",
	"humedal_insectos",
	"humedal_viento",
	"humedal_agua",
]

var catalogo_audio: Dictionary = {
	"musica_principal": "res://audio/musica/principal.ogg",
	"humedal_aves": "res://audio/ambiente/aves.ogg",
	"humedal_insectos": "res://audio/ambiente/insectos.ogg",
	"humedal_viento": "res://audio/ambiente/viento.ogg",
	"humedal_agua": "res://audio/ambiente/agua.ogg",
	"ui_click": "res://audio/sfx/ui/click.ogg",
	"camara_obturador": "res://audio/sfx/camara/obturador.ogg",
	"especie_registrada": "res://audio/sfx/logros/especie_registrada.ogg",
	"logro_desbloqueado": "res://audio/sfx/logros/desbloqueado.ogg",
	"aviso_colibri": "res://audio/sfx/colibri/aviso.ogg",
}

var _reproductor_musica: AudioStreamPlayer
var _reproductores_ambiente: Dictionary = {}
var _reproductores_sfx: Array[AudioStreamPlayer] = []
var _streams: Dictionary = {}
var _avisos_emitidos: Dictionary = {}
var _indice_sfx := 0
var _pista_actual := ""


func _ready() -> void:
	_asegurar_buses()
	_crear_reproductores()
	_conectar_senales_de_juego()


func reproducir_musica(pista: String) -> bool:
	var stream := _obtener_stream(pista)
	if stream == null:
		return false
	if _pista_actual == pista and _reproductor_musica.playing:
		return true
	_reproductor_musica.stop()
	_reproductor_musica.stream = stream
	_reproductor_musica.play()
	_pista_actual = pista
	return true


func detener_musica() -> void:
	_reproductor_musica.stop()
	_pista_actual = ""


func reproducir_ambiente(sonido_humedal: String) -> bool:
	var stream := _obtener_stream(sonido_humedal)
	if stream == null:
		return false
	var reproductor: AudioStreamPlayer
	if _reproductores_ambiente.has(sonido_humedal):
		reproductor = _reproductores_ambiente[sonido_humedal]
	else:
		reproductor = _crear_reproductor(BUS_AMBIENTE, "Ambiente_" + sonido_humedal)
		reproductor.finished.connect(_repetir_ambiente.bind(sonido_humedal))
		_reproductores_ambiente[sonido_humedal] = reproductor
	if reproductor.playing and reproductor.stream == stream:
		return true
	reproductor.stream = stream
	reproductor.play()
	return true


func detener_ambiente(sonido_humedal: String) -> void:
	if _reproductores_ambiente.has(sonido_humedal):
		(_reproductores_ambiente[sonido_humedal] as AudioStreamPlayer).stop()


func reproducir_paisaje_humedal() -> void:
	for clave in CLAVES_AMBIENTE:
		reproducir_ambiente(clave)


func detener_paisaje_humedal() -> void:
	for clave in CLAVES_AMBIENTE:
		detener_ambiente(clave)


func reproducir_sfx(efecto: String) -> bool:
	var stream := _obtener_stream(efecto)
	if stream == null:
		return false
	var reproductor := _reproductores_sfx[_indice_sfx]
	_indice_sfx = (_indice_sfx + 1) % _reproductores_sfx.size()
	reproductor.stop()
	reproductor.stream = stream
	reproductor.play()
	return true


func set_volumen_canal(canal: String, volumen: float) -> bool:
	var indice := AudioServer.get_bus_index(_normalizar_canal(canal))
	if indice < 0:
		push_warning("AudioManager: canal de audio desconocido '%s'." % canal)
		return false
	var nivel := clampf(volumen, 0.0, 1.0)
	AudioServer.set_bus_volume_db(indice, -80.0 if nivel == 0.0 else linear_to_db(nivel))
	return true


func get_volumen_canal(canal: String) -> float:
	var indice := AudioServer.get_bus_index(_normalizar_canal(canal))
	if indice < 0:
		push_warning("AudioManager: canal de audio desconocido '%s'." % canal)
		return -1.0
	return db_to_linear(AudioServer.get_bus_volume_db(indice))


func silenciar_canal(canal: String, silenciado: bool = true) -> bool:
	var indice := AudioServer.get_bus_index(_normalizar_canal(canal))
	if indice < 0:
		push_warning("AudioManager: canal de audio desconocido '%s'." % canal)
		return false
	AudioServer.set_bus_mute(indice, silenciado)
	return true


func esta_silenciado(canal: String) -> bool:
	var indice := AudioServer.get_bus_index(_normalizar_canal(canal))
	if indice < 0:
		push_warning("AudioManager: canal de audio desconocido '%s'." % canal)
		return false
	return AudioServer.is_bus_mute(indice)


func configurar_ruta(clave: String, ruta: String) -> bool:
	if clave.is_empty() or not ruta.begins_with("res://audio/") or ruta.contains(".."):
		push_warning("AudioManager: la ruta de '%s' debe estar dentro de res://audio/." % clave)
		return false
	catalogo_audio[clave] = ruta
	_streams.erase(clave)
	_avisos_emitidos.erase("recurso_" + clave)
	return true


func conectar_botones(nodo: Node) -> void:
	if nodo is BaseButton:
		var clic := Callable(self, "reproducir_sfx").bind("ui_click")
		if not (nodo as BaseButton).pressed.is_connected(clic):
			(nodo as BaseButton).pressed.connect(clic)
	for hijo in nodo.get_children():
		conectar_botones(hijo)


func _asegurar_buses() -> void:
	if AudioServer.get_bus_index(BUS_MASTER) < 0:
		push_error("AudioManager: AudioServer no contiene el bus Master.")
		return
	_asegurar_bus(BUS_MUSICA)
	_asegurar_bus(BUS_AMBIENTE)
	_asegurar_bus(BUS_SFX)


func _asegurar_bus(nombre: String) -> void:
	var indice := AudioServer.get_bus_index(nombre)
	if indice < 0:
		AudioServer.add_bus(-1)
		indice = AudioServer.bus_count - 1
		AudioServer.set_bus_name(indice, nombre)
	AudioServer.set_bus_send(indice, BUS_MASTER)


func _crear_reproductores() -> void:
	_reproductor_musica = _crear_reproductor(BUS_MUSICA, "Musica")
	for indice in CAPACIDAD_SFX:
		_reproductores_sfx.append(_crear_reproductor(BUS_SFX, "SFX_%d" % indice))


func _crear_reproductor(canal: String, nombre: String) -> AudioStreamPlayer:
	var reproductor := AudioStreamPlayer.new()
	reproductor.name = nombre
	reproductor.bus = canal
	reproductor.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(reproductor)
	return reproductor


func _obtener_stream(clave: String) -> AudioStream:
	if _streams.has(clave):
		return _streams[clave] as AudioStream
	if not catalogo_audio.has(clave):
		_avisar_una_vez("clave_" + clave, "AudioManager: no hay una ruta configurada para '%s'." % clave)
		return null
	var ruta: Variant = catalogo_audio[clave]
	if typeof(ruta) != TYPE_STRING or String(ruta).is_empty():
		_avisar_una_vez("ruta_" + clave, "AudioManager: la ruta de audio para '%s' esta vacia." % clave)
		return null
	if not ResourceLoader.exists(ruta):
		_avisar_una_vez("recurso_" + clave,
			"AudioManager: falta el audio '%s' en %s; agrega el archivo o configura otra ruta." % [clave, ruta])
		return null
	var recurso: Resource = ResourceLoader.load(ruta)
	if not recurso is AudioStream:
		_avisar_una_vez("tipo_" + clave,
			"AudioManager: el recurso de '%s' no es un AudioStream valido (%s)." % [clave, ruta])
		return null
	var stream := recurso as AudioStream
	_streams[clave] = stream
	return stream


func _repetir_ambiente(clave: String) -> void:
	if _reproductores_ambiente.has(clave):
		var reproductor := _reproductores_ambiente[clave] as AudioStreamPlayer
		if is_instance_valid(reproductor) and reproductor.stream != null:
			reproductor.play()


func _normalizar_canal(canal: String) -> String:
	match canal.to_lower():
		"master":
			return BUS_MASTER
		"bgm", "musica":
			return BUS_MUSICA
		"amb", "ambiente":
			return BUS_AMBIENTE
		"sfx":
			return BUS_SFX
		_:
			return canal


func _conectar_senales_de_juego() -> void:
	var registro := get_node_or_null("/root/RegistroEspecies")
	if registro and registro.has_signal("especie_descubierta"):
		var callback := Callable(self, "_al_descubrir_especie")
		if not registro.is_connected("especie_descubierta", callback):
			registro.connect("especie_descubierta", callback)
	var recompensas := get_node_or_null("/root/Recompensas")
	if recompensas and recompensas.has_signal("subio_nivel"):
		var callback := Callable(self, "_al_desbloquear_logro")
		if not recompensas.is_connected("subio_nivel", callback):
			recompensas.connect("subio_nivel", callback)


func _al_descubrir_especie(_especie: Especie) -> void:
	reproducir_sfx("especie_registrada")


func _al_desbloquear_logro(_nivel: int) -> void:
	reproducir_sfx("logro_desbloqueado")


func _avisar_una_vez(id: String, mensaje: String) -> void:
	if _avisos_emitidos.has(id):
		return
	_avisos_emitidos[id] = true
	push_warning(mensaje)
