extends Node2D
## One-shot VFX when milestone merchant peg activates: gold coins and sparkle bursts.

const COIN_TEXTURE: Texture2D = preload("res://assets/Kenney Game Assets All-in-1 3.4.0/2D assets/Jumper Pack/PNG/HUD/coin_gold.png")
const COINS_VFX_TEXTURE: Texture2D = preload("res://assets/VFX/Essentials VFX Spritesheets/Coins_V1_A_spritesheet.png")

const COIN_COUNT: int = 14
const DURATION_SEC: float = 0.65

var _coins: Array[Dictionary] = []
var _elapsed: float = 0.0

## Configures burst at given position.
func setup(pos: Vector2) -> void:
	position = pos
	for i in COIN_COUNT:
		var angle: float = randf_range(-PI * 0.95, -PI * 0.05)
		var speed: float = randf_range(90.0, 220.0)
		_coins.append({
			"pos": Vector2.ZERO,
			"vel": Vector2.from_angle(angle) * speed,
			"rot": randf_range(0.0, TAU),
			"rot_speed": randf_range(-10.0, 10.0),
			"size": randf_range(12.0, 18.0),
		})

func _ready() -> void:
	z_index = 105
	var tween: Tween = create_tween()
	tween.tween_callback(queue_free).set_delay(DURATION_SEC)

func _process(delta: float) -> void:
	_elapsed += delta
	for c in _coins:
		c.pos += c.vel * delta
		c.vel.y += 420.0 * delta
		c.rot += c.rot_speed * delta
	queue_redraw()

func _draw() -> void:
	var t: float = clampf(_elapsed / DURATION_SEC, 0.0, 1.0)
	var alpha: float = clampf(1.0 - t, 0.0, 1.0)
	if COINS_VFX_TEXTURE:
		var frame_idx: int = int(t * 15.0) % 16
		var col: int = frame_idx % 4
		var row: int = frame_idx / 4
		var src_rect := Rect2(col * 512, row * 512, 512, 512)
		var dest_rect := Rect2(-32.0, -32.0, 64.0, 64.0)
		draw_texture_rect_region(COINS_VFX_TEXTURE, dest_rect, src_rect, Color(1, 1, 1, alpha * 0.9))
	for c in _coins:
		var sz: float = float(c.size)
		var rect := Rect2(c.pos - Vector2(sz, sz) * 0.5, Vector2(sz, sz))
		if COIN_TEXTURE:
			draw_texture_rect(COIN_TEXTURE, rect, false, Color(1, 1, 1, alpha))
		else:
			draw_circle(c.pos, sz * 0.5, Color(1.0, 0.84, 0.0, alpha))
