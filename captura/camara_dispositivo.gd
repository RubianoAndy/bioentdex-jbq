class_name CamaraDispositivo
extends Node
## Muestra la cámara trasera del teléfono en un TextureRect, si está disponible.
## Si no hay cámara (por ejemplo en el PC) o niegan el permiso, devuelve false y la vista usa
## un fondo simulado. En Android hay que activar el permiso "Camera" en el preset de exportación.

const SHADER_YCBCR := """
shader_type canvas_item;
uniform sampler2D textura_y;
uniform sampler2D textura_cbcr;
void fragment() {
	float y = texture(textura_y, UV).r;
	vec2 cbcr = texture(textura_cbcr, UV).rg - vec2(0.5);
	COLOR = vec4(y + 1.402 * cbcr.y, y - 0.344 * cbcr.x - 0.714 * cbcr.y, y + 1.772 * cbcr.x, 1.0);
}
"""

var _feed: CameraFeed
var _destino: TextureRect
var _tipo := -1   # formato que se está mostrando (CameraFeed.FEED_*), -1 = aún no llega imagen


func iniciar(destino: TextureRect) -> bool:
	if OS.get_name() == "Android" and not OS.get_granted_permissions().has("android.permission.CAMERA"):
		# Se pide el permiso y se espera la respuesta: así la cámara funciona desde la primera vez
		OS.request_permission("CAMERA")
		var respuesta: Array = await get_tree().on_request_permissions_result
		if not respuesta[1] and not OS.get_granted_permissions().has("android.permission.CAMERA"):
			return false
	CameraServer.monitoring_feeds = true
	for intento in 30:   # la lista de cámaras tarda unos instantes en llegar
		if CameraServer.get_feed_count() > 0:
			break
		await get_tree().process_frame
	if CameraServer.get_feed_count() == 0:
		return false

	_feed = CameraServer.get_feed(0)
	for i in CameraServer.get_feed_count():
		if CameraServer.get_feed(i).get_position() == CameraFeed.FEED_BACK:
			_feed = CameraServer.get_feed(i)
	if not _feed.get_formats().is_empty():
		_feed.set_format(0, {})
	_destino = destino
	_feed.frame_changed.connect(_on_cuadro)
	_feed.feed_is_active = true
	# Ojo: antes del primer cuadro get_datatype() dice FEED_RGB aunque la cámara mande YCbCr
	# (en Android casi siempre). Por eso se espera a que llegue un cuadro de verdad.
	for intento in 180:
		if _tipo != -1:
			return true
		await get_tree().process_frame
	detener()
	return false


## Cada cuadro nuevo: si cambió el formato, se ajusta la textura (y el shader para YCbCr).
func _on_cuadro() -> void:
	var tipo := _feed.get_datatype()
	if tipo == _tipo:
		return
	_tipo = tipo
	match tipo:
		CameraFeed.FEED_RGB:
			_destino.material = null
			_destino.texture = _textura(CameraServer.FEED_RGBA_IMAGE)
		CameraFeed.FEED_YCBCR_SEP:
			var mat := ShaderMaterial.new()
			mat.shader = Shader.new()
			mat.shader.code = SHADER_YCBCR
			mat.set_shader_parameter("textura_y", _textura(CameraServer.FEED_Y_IMAGE))
			mat.set_shader_parameter("textura_cbcr", _textura(CameraServer.FEED_CBCR_IMAGE))
			_destino.texture = _textura(CameraServer.FEED_Y_IMAGE)
			_destino.material = mat


func detener() -> void:
	if _feed:
		if _feed.frame_changed.is_connected(_on_cuadro):
			_feed.frame_changed.disconnect(_on_cuadro)
		_feed.feed_is_active = false


func _exit_tree() -> void:
	detener()


func _textura(cual: CameraServer.FeedImage) -> CameraTexture:
	var textura := CameraTexture.new()
	textura.camera_feed_id = _feed.get_id()
	textura.which_feed = cual
	return textura
