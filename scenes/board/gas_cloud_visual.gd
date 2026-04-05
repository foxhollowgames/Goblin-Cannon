extends Node2D
## GPU noise gas puff; parented to Board at local position. Frees with cloud expiry.

const GAS_SHADER: Shader = preload("res://scenes/board/gas_cloud.gdshader")

static var _white_tex: ImageTexture

static func _white_unit_texture() -> ImageTexture:
	if _white_tex == null:
		var img: Image = Image.create(8, 8, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		_white_tex = ImageTexture.create_from_image(img)
	return _white_tex

func setup(local_center: Vector2, radius_px: float, seed_key: int) -> void:
	position = local_center
	z_index = -3
	var sp: Sprite2D = Sprite2D.new()
	sp.centered = true
	sp.texture = _white_unit_texture()
	var d: float = radius_px * 2.0
	var tex_sz: float = 8.0
	sp.scale = Vector2(d / tex_sz, d / tex_sz)
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = GAS_SHADER
	mat.set_shader_parameter("noise_seed", float(seed_key % 10000))
	sp.material = mat
	sp.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(sp)
