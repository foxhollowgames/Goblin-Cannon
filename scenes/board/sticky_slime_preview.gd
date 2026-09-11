extends Node2D
## Warning VFX above pegs before slime coating with splat and bubble sprites.

const SPLAT_TEXTURE: Texture2D = preload("res://assets/Kenney Game Assets All-in-1 3.4.0/2D assets/Splat Pack/PNG/Default (256px)/splat20.png")
const BUBBLES_VFX_TEXTURE: Texture2D = preload("res://assets/VFX/Essentials VFX Spritesheets/Bubbles_V1_spritesheet.png")

var _phase: float = 0.0

func _ready() -> void:
	z_index = 45
	set_process(true)

func _process(delta: float) -> void:
	_phase += delta * 4.0
	queue_redraw()

func _draw() -> void:
	var pulse: float = 0.82 + 0.18 * sin(_phase * 2.0)
	
	# Splat texture base
	if SPLAT_TEXTURE:
		var s_rect := Rect2(-20.0, -20.0, 40.0, 40.0)
		draw_texture_rect(SPLAT_TEXTURE, s_rect, false, Color(0.3, 0.9, 0.45, 0.45 * pulse))
	else:
		var glow := Color(0.25, 0.85, 0.45, 0.25 * pulse)
		draw_arc(Vector2.ZERO, 18.0, 0.0, TAU, 24, glow, 3.0)

	# Bubbles spritesheet
	if BUBBLES_VFX_TEXTURE:
		var frame_idx: int = int(_phase * 6.0) % 16
		var col: int = frame_idx % 4
		var row: int = frame_idx / 4
		var src_rect := Rect2(col * 512, row * 512, 512, 512)
		var b_rect := Rect2(-18.0, -28.0, 36.0, 36.0)
		draw_texture_rect_region(BUBBLES_VFX_TEXTURE, b_rect, src_rect, Color(0.4, 1.0, 0.6, 0.65 * pulse))
	else:
		var drop := Color(0.4, 0.95, 0.55, 0.55 * pulse)
		for i in range(3):
			var dy: float = -8.0 - float(i) * 9.0 + fposmod(_phase * 22.0 + float(i) * 4.0, 10.0)
			draw_circle(Vector2(sin(_phase + float(i)) * 6.0, dy), 3.0 + float(i) * 0.4, drop)
