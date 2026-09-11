extends Node2D
## Warning rings and animated vortex before the black hole event activates.

const VORTEX_VFX_TEXTURE: Texture2D = preload("res://assets/VFX/Essentials VFX Spritesheets/Tornado_spritesheet.png")

var _phase: float = 0.0

func _ready() -> void:
	z_index = 50
	set_process(true)

func _process(delta: float) -> void:
	_phase += delta * 4.5
	queue_redraw()

func _draw() -> void:
	var pulse: float = 0.75 + 0.25 * sin(_phase * 2.0)

	# Animated vortex swirl spritesheet
	if VORTEX_VFX_TEXTURE:
		var frame_idx: int = int(_phase * 6.0) % 16
		var col: int = frame_idx % 4
		var row: int = frame_idx / 4
		var src_rect := Rect2(col * 512, row * 512, 512, 512)
		var v_rect := Rect2(-54.0, -54.0, 108.0, 108.0)
		draw_texture_rect_region(VORTEX_VFX_TEXTURE, v_rect, src_rect, Color(0.45, 0.2, 0.75, 0.65 * pulse))

	var t: float = float(Time.get_ticks_msec()) * 0.0025
	for i in range(3):
		var r: float = 30.0 + float(i) * 16.0
		var a0: float = t + float(i) * TAU / 3.0
		var a1: float = a0 + TAU * 0.42
		var col := Color(0.25, 0.12, 0.45, (0.5 - float(i) * 0.08) * pulse)
		draw_arc(Vector2.ZERO, r, a0, a1, 24, col, 3.0)
	draw_circle(Vector2.ZERO, 14.0, Color(0.02, 0.02, 0.06, 0.92 * pulse))
	draw_arc(Vector2.ZERO, 16.0, 0.0, TAU, 32, Color(0.4, 0.2, 0.7, 0.55 * pulse), 2.0)
