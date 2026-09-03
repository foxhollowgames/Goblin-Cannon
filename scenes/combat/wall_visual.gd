extends Node2D
## Graphical wall at the top of the battlefield. Draws stone/brick style wall using asset pack tile textures.
## Supports explosion (debris) and rebuild (slide-in) animations for wall break transitions.

#region Constants
const WALL_HEIGHT: float = 72.0
const WALL_WIDTH: float = 320.0
const BRICK_ROWS: int = 4
const BRICK_COLS: int = 12
const DEBRIS_COUNT: int = 28
const DEBRIS_GRAVITY: float = 580.0
const EXPLOSION_DURATION: float = 1.8

const WALL_TILE_PATH: String = "res://assets/Kenney Game Assets All-in-1 3.4.0/2D assets/Platformer Pack Medieval/PNG/medievalTile_015.png"
const WALL_CAP_PATH: String = "res://assets/Kenney Game Assets All-in-1 3.4.0/2D assets/Platformer Assets Tile Extensions/PNG Castle/castleHalfMid.png"

static var WALL_TILE_TEXTURE: Texture2D = (load(WALL_TILE_PATH) as Texture2D) if ResourceLoader.exists(WALL_TILE_PATH) else null
static var WALL_CAP_TEXTURE: Texture2D = (load(WALL_CAP_PATH) as Texture2D) if ResourceLoader.exists(WALL_CAP_PATH) else null
#endregion

#region Variables
var _show_wall: bool = true
var _exploding: bool = false
var _explosion_timer: float = 0.0
var _debris: Array[Dictionary] = []  # { pos: Vector2, vel: Vector2, rot_speed: float, angle: float, size: Vector2, shade: float, alpha: float }
var _rebuild_offset_y: float = 0.0
var _flash_alpha: float = 0.0
#endregion

#region Public Methods
## Triggers debris explosion animation sequence upon wall destruction.
func play_explosion() -> void:
	_show_wall = false
	_exploding = true
	_explosion_timer = 0.0
	_flash_alpha = 1.0
	_debris.clear()
	for i in DEBRIS_COUNT:
		var col: int = i % BRICK_COLS
		var row: int = (i / BRICK_COLS) % BRICK_ROWS
		var brick_w: float = WALL_WIDTH / float(BRICK_COLS)
		var brick_h: float = WALL_HEIGHT / float(BRICK_ROWS)
		var offset_x: float = (row % 2) * (brick_w * 0.5)
		_debris.append({
			"pos": Vector2(col * brick_w + offset_x + brick_w * 0.5, row * brick_h + brick_h * 0.5),
			"vel": Vector2(randf_range(-180, 180), randf_range(-450, -120)),
			"rot_speed": randf_range(-6.0, 6.0),
			"angle": 0.0,
			"size": Vector2(brick_w - 4, brick_h - 4),
			"shade": 0.28 + (row + col) % 3 * 0.025 if (row + col) % 2 == 0 else 0.32 + (row * 2 + col) % 3 * 0.02,
			"alpha": 1.0,
		})
	queue_redraw()

## Plays slide-in rebuild animation sequence when next wall enters.
func play_rebuild() -> void:
	_exploding = false
	_debris.clear()
	_explosion_timer = 0.0
	_show_wall = true
	_rebuild_offset_y = -WALL_HEIGHT - 20.0
	var tween: Tween = create_tween()
	tween.tween_property(self, "_rebuild_offset_y", 0.0, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
	queue_redraw()
#endregion

#region Engine Callbacks
func _process(delta: float) -> void:
	if _flash_alpha > 0.0:
		_flash_alpha = maxf(0.0, _flash_alpha - delta * 3.0)
		queue_redraw()
	if not _exploding:
		if _rebuild_offset_y != 0.0:
			queue_redraw()
		return
	_explosion_timer += delta
	for piece in _debris:
		piece.vel.y += DEBRIS_GRAVITY * delta
		piece.pos += piece.vel * delta
		piece.angle += piece.rot_speed * delta
		piece.alpha = clampf(1.0 - _explosion_timer / EXPLOSION_DURATION, 0.0, 1.0)
	queue_redraw()
	if _explosion_timer >= EXPLOSION_DURATION:
		_exploding = false
		_debris.clear()

func _draw() -> void:
	if _flash_alpha > 0.0:
		var fl: Color = Constants.gameplay_wall_flash()
		draw_rect(Rect2(-20, -20, WALL_WIDTH + 40, WALL_HEIGHT + 40), Color(fl.r, fl.g, fl.b, _flash_alpha))

	if _exploding:
		for piece in _debris:
			if piece.alpha <= 0.0:
				continue
			var sz: Vector2 = piece.size
			var half: Vector2 = sz * 0.5
			draw_set_transform(piece.pos, piece.angle)
			if WALL_TILE_TEXTURE:
				draw_texture_rect(WALL_TILE_TEXTURE, Rect2(-half, sz), false, Color(1, 1, 1, piece.alpha))
			else:
				var color := Color(piece.shade, piece.shade * 0.95, piece.shade * 0.9, piece.alpha)
				draw_rect(Rect2(-half, sz), color)
		draw_set_transform(Vector2.ZERO, 0.0)
		return

	if not _show_wall:
		return

	var offset := Vector2(0, _rebuild_offset_y)
	var base_rect := Rect2(offset, Vector2(WALL_WIDTH, WALL_HEIGHT))
	draw_rect(base_rect, Color(0.25, 0.22, 0.2, 1))
	draw_rect(base_rect, Color(0.35, 0.32, 0.28, 1), false, 3.0)
	var brick_w: float = WALL_WIDTH / float(BRICK_COLS)
	var brick_h: float = WALL_HEIGHT / float(BRICK_ROWS)
	for row in range(BRICK_ROWS):
		for col in range(BRICK_COLS):
			var offset_x: float = (row % 2) * (brick_w * 0.5)
			var x: float = col * brick_w + offset_x
			var y: float = row * brick_h
			var brick := Rect2(x + 2 + offset.x, y + 2 + offset.y, brick_w - 4, brick_h - 4)
			if WALL_TILE_TEXTURE:
				var shade: float = 0.85 + (row + col) % 3 * 0.05
				draw_texture_rect(WALL_TILE_TEXTURE, brick, false, Color(shade, shade, shade, 1.0))
			else:
				var shade: float = 0.28 + (row + col) % 3 * 0.025 if (row + col) % 2 == 0 else 0.32 + (row * 2 + col) % 3 * 0.02
				draw_rect(brick, Color(shade, shade * 0.95, shade * 0.9, 1))
	for i in range(0, int(WALL_WIDTH), 24):
		var cap := Rect2(i + offset.x, offset.y, 20, 8)
		if WALL_CAP_TEXTURE:
			draw_texture_rect(WALL_CAP_TEXTURE, cap, false)
		else:
			draw_rect(cap, Color(0.3, 0.27, 0.24, 1))
			draw_rect(cap, Color(0.4, 0.36, 0.32, 1), false, 1.0)
#endregion
