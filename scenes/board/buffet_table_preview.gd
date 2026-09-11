extends Node2D
## Preview VFX before a buffet table peg spawns with animated steam puff VFX.

const FOOD_TEXTURE: Texture2D = preload("res://assets/Kenney Game Assets All-in-1 3.4.0/2D assets/Pixel Platformer Food Expansion/Tiles/tile_0070.png")
const STEAM_VFX_TEXTURE: Texture2D = preload("res://assets/VFX/Essentials VFX Spritesheets/Smoke_Cloud_Burst_v1_A_spritesheet.png")

var _phase: float = 0.0

func _ready() -> void:
	z_index = 50
	set_process(true)

func _process(delta: float) -> void:
	_phase += delta * 4.0
	queue_redraw()

func _draw() -> void:
	var pulse: float = 0.88 + 0.12 * sin(_phase * 2.2)
	var cloth := Color(0.82, 0.72, 0.55, 0.92 * pulse)

	# Steam puff spritesheet
	if STEAM_VFX_TEXTURE:
		var frame_idx: int = int(_phase * 5.0) % 16
		var col: int = frame_idx % 4
		var row: int = frame_idx / 4
		var src_rect := Rect2(col * 512, row * 512, 512, 512)
		var steam_rect := Rect2(-24.0, -32.0, 48.0, 48.0)
		draw_texture_rect_region(STEAM_VFX_TEXTURE, steam_rect, src_rect, Color(0.9, 0.95, 1.0, 0.45 * pulse))
	else:
		var steam := Color(0.85, 0.9, 0.95, 0.35 * pulse)
		for i in range(4):
			var ox: float = (float(i) - 1.5) * 14.0
			draw_arc(Vector2(ox, 8.0), 10.0 + float(i) * 2.0, PI * 1.1, PI * 1.9, 10, steam, 2.0)

	# Table surface
	var tw: float = 52.0
	var th: float = 14.0
	draw_rect(Rect2(-tw * 0.5, -th * 0.5, tw, th), cloth)
	draw_rect(Rect2(-tw * 0.5, -th * 0.5, tw, 3.0), cloth.darkened(0.12))

	# Dedicated food sprite assets
	if FOOD_TEXTURE:
		var food_rect := Rect2(-10.0, -14.0, 20.0, 20.0)
		draw_texture_rect(FOOD_TEXTURE, food_rect, false, Color(1, 1, 1, 0.95 * pulse))
	else:
		draw_arc(Vector2.ZERO, 11.0, PI, TAU, 16, Color(0.75, 0.78, 0.82, 0.55 * pulse), 2.0)
