class_name CamaraDispositivo
extends Node
## Muestra la cámara trasera del teléfono en un TextureRect, si está disponible.
## Si no hay cámara (por ejemplo en el PC) o falta el permiso, devuelve false y la vista usa
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


func iniciar(destino: TextureRect) -> bool:
	if OS.get_name() == "Android" and not OS.get_granted_permissions().has("android.permission.CAMERA"):
		OS.request_permission("CAMERA")   # la próxima vez que se abra ya habrá permiso
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
	_feed.feed_is_active = true
	for intento in 60:   # esperar el primer cuadro para saber el formato
		if _feed.get_datatype() != CameraFeed.FEED_NOIMAGE:
			break
		await get_tree().process_frame

	match _feed.get_datatype():
		CameraFeed.FEED_RGB:
			destino.texture = _textura(CameraServer.FEED_RGBA_IMAGE)
		CameraFeed.FEED_YCBCR_SEP:
			var mat := ShaderMaterial.new()
			mat.shader = Shader.new()
			mat.shader.code = SHADER_YCBCR
			mat.set_shader_parameter("textura_y", _textura(CameraServer.FEED_Y_IMAGE))
			mat.set_shader_parameter("textura_cbcr", _textura(CameraServer.FEED_CBCR_IMAGE))
			destino.texture = _textura(CameraServer.FEED_Y_IMAGE)
			destino.material = mat
		_:
			detener()
			return false
	return true


func detener() -> void:
	if _feed:
		_feed.feed_is_active = false


func _exit_tree() -> void:
	detener()


func _textura(cual: CameraServer.FeedImage) -> CameraTexture:
	var textura := CameraTexture.new()
	textura.camera_feed_id = _feed.get_id()
	textura.which_feed = cual
	return textura
