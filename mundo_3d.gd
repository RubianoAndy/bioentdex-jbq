extends Node3D

@export var textura_mapa: Texture2D
@export var repeticiones := 3.0
@export var velocidad_caminata := 6.0      # velocidad con las flechas del teclado
@export var sensibilidad_arrastre := 0.05  # cuánto avanza por cada píxel que arrastras
@export_range(0.0, 0.9) var recorte_superior := 0.4   # fracción de arriba que se descarta (el cielo)

@onready var suelo: MeshInstance3D = $Suelo
var mat := StandardMaterial3D.new()
var tamano_suelo := 80.0   # el mismo Size que le pusiste al PlaneMesh

func _ready() -> void:
	mat.albedo_texture = _tile_sin_costuras(textura_mapa)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	mat.uv1_scale = Vector3(repeticiones, repeticiones, 1)
	suelo.material_override = mat

# Esta función es la que "mueve al personaje" por el mapa.
# x = derecha, y = hacia abajo en pantalla (caminar hacia adelante es y negativo)
func caminar(movimiento: Vector2) -> void:
	var k := repeticiones / tamano_suelo
	mat.uv1_offset.x += movimiento.x * k
	mat.uv1_offset.y += movimiento.y * k

func _process(delta: float) -> void:
	# Flechas del teclado, para probar en el computador
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if dir != Vector2.ZERO:
		caminar(dir * velocidad_caminata * delta)

func _input(event: InputEvent) -> void:
	# Arrastrar el dedo (o el mouse) en la dirección en la que quieres caminar
	if event is InputEventScreenDrag:
		caminar(event.relative * sensibilidad_arrastre)

func _tile_sin_costuras(tex: Texture2D) -> ImageTexture:
	var img := tex.get_image()
	if img.is_compressed():
		img.decompress()
	var w := img.get_width()
	var h := img.get_height()
	var fx := img.duplicate() as Image
	fx.flip_x()
	var fy := img.duplicate() as Image
	fy.flip_y()
	var fxy := fx.duplicate() as Image
	fxy.flip_y()
	var out := Image.create(w * 2, h * 2, false, img.get_format())
	var r := Rect2i(0, 0, w, h)
	out.blit_rect(img, r, Vector2i(0, 0))
	out.blit_rect(fx, r, Vector2i(w, 0))
	out.blit_rect(fy, r, Vector2i(0, h))
	out.blit_rect(fxy, r, Vector2i(w, h))
	out.generate_mipmaps()
	return ImageTexture.create_from_image(out)
