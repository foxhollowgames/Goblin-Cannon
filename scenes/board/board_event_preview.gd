extends Node2D
## Money bag + aura/sparkle VFX preview before a milestone merchant event peg spawns.

const ITEM_TEXTURE: Texture2D = preload("res://assets/Kenney Game Assets All-in-1 3.4.0/2D assets/Generic Items/PNG/White/genericItem_white_138.png")
const AURA_VFX_TEXTURE: Texture2D = preload("res://assets/VFX/Essentials VFX Spritesheets/Aura_V1_spritesheet.png")

var _phase: float = 0.0

func _ready() -> void:
	z_index = 50
	set_process(true)

func _process(delta: float) -> void:
	_phase += delta * 4.0
	queue_redraw()

func _draw() -> void:
	var t: float = float(Time.get_ticks_msec()) * 0.003
	var pulse: float = 0.85 + 0.15 * sin(_phase * 2.0)
	
	# Animated aura spritesheet
	if AURA_VFX_TEXTURE:
		var frame_idx: int = int(_phase * 6.0) % 16
		var col: int = frame_idx % 4
		var row: int = frame_idx / 4
		var src_rect := Rect2(col * 512, row * 512, 512, 512)
		var aura_rect := Rect2(-36.0, -36.0, 72.0, 72.0)
		draw_texture_rect_region(AURA_VFX_TEXTURE, aura_rect, src_rect, Color(0.95, 0.82, 0.25, 0.65 * pulse))
	else:
		var r0: float = 28.0
		for i in range(5):
			var a0: float = t + float(i) * TAU / 5.0
			var a1: float = a0 + TAU * 0.35
			var col := Color(0.55, 0.35, 0.95, 0.45 - float(i) * 0.06)
			draw_arc(Vector2.ZERO, r0 + float(i) * 5.0, a0, a1, 16, col, 3.0 - float(i) * 0.35)

	# Dedicated item sprite with gold shimmer
	var gold := Color(1.0, 0.85, 0.2, pulse)
	var bag_size: Vector2 = Vector2(28.0, 28.0)
	var bag_rect := Rect2(-bag_size * 0.5, bag_size)
	if ITEM_TEXTURE:
		draw_texture_rect(ITEM_TEXTURE, bag_rect, false, gold)
	else:
		draw_rect(Rect2(-11.0, -9.0, 22.0, 19.5), gold)
		draw_circle(Vector2(0, -17.0), 4.0, gold.lightened(0.1))
