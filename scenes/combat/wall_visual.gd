extends Node2D
## Graphical wall at the top of the battlefield. Draws stone/brick style wall using asset pack tile textures.
## Supports explosion (debris) and rebuild (slide-in) animations for wall break transitions.

#region Constants
const WALL_HEIGHT: float = 100.0
const WALL_WIDTH: float = 60.0
const BRICK_ROWS: int = 5
const BRICK_COLS: int = 3
const DEBRIS_COUNT: int = 24
const DEBRIS_GRAVITY: float = 580.0
const EXPLOSION_DURATION: float = 1.8

const CASTLE_WALL_TEXTURE: Texture2D = preload("res://assets/Kenney Game Assets All-in-1 3.4.0/2D assets/Background Elements Redux/PNG/Retina/castleWall.png")
const WALL_TILE_TEXTURE: Texture2D = preload("res://assets/Kenney Game Assets All-in-1 3.4.0/2D assets/Platformer Pack Medieval/PNG/medievalTile_015.png")
const WALL_CAP_TEXTURE: Texture2D = preload("res://assets/Kenney Game Assets All-in-1 3.4.0/2D assets/Platformer Assets Tile Extensions/PNG Castle/castleHalfMid.png")
#endregion

#region Variables
var _show_wall: bool = true
var _exploding: bool = false
var _explosion_timer: float = 0.0
var _debris: Array[Dictionary] = []  # { pos: Vector2, vel: Vector2, rot_speed: float, angle: float, size: Vector2, shade: float, alpha: float }
var _rebuild_offset_y: float = 0.0
var _flash_alpha: float = 0.0
var _rumble_offset: Vector2 = Vector2.ZERO
var _rumble_tween: Tween = null
#endregion

#region Public Methods
## Triggers hit flash and rumble reaction when struck by a cannonball.
func trigger_hit_reaction() -> void:
	_flash_alpha = 1.0
	if _rumble_tween and _rumble_tween.is_valid():
		_rumble_tween.kill()
	_rumble_tween = create_tween()
	_rumble_tween.tween_property(self, "_rumble_offset", Vector2(4.0, -2.0), 0.04)
	_rumble_tween.tween_property(self, "_rumble_offset", Vector2(-3.0, 1.5), 0.04)
	_rumble_tween.tween_property(self, "_rumble_offset", Vector2(2.0, -1.0), 0.04)
	_rumble_tween.tween_property(self, "_rumble_offset", Vector2.ZERO, 0.04)
	queue_redraw()

## Triggers debris explosion animation sequence upon wall destruction.
func play_explosion() -> void:
	_show_wall = false
	_exploding = true
	_explosion_timer = 0.0
	_flash_alpha = 1.0
	_debris.clear()
	var half_w: float = WALL_WIDTH * 0.5
	var half_h: float = WALL_HEIGHT * 0.5
	var brick_w: float = WALL_WIDTH / float(BRICK_COLS)
	var brick_h: float = WALL_HEIGHT / float(BRICK_ROWS)
	for i in DEBRIS_COUNT:
		var col: int = i % BRICK_COLS
		var row: int = (i / BRICK_COLS) % BRICK_ROWS
		var offset_x: float = (row % 2) * (brick_w * 0.5)
		_debris.append({
			"pos": Vector2(-half_w + col * brick_w + offset_x + brick_w * 0.5, -half_h + row * brick_h + brick_h * 0.5),
			"vel": Vector2(randf_range(-160, 80), randf_range(-380, -90)),
			"rot_speed": randf_range(-6.0, 6.0),
			"angle": 0.0,
			"size": Vector2(brick_w - 2, brick_h - 2),
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
	_rebuild_offset_y = -WALL_HEIGHT - 30.0
	var tween: Tween = create_tween()
	tween.tween_property(self, "_rebuild_offset_y", 0.0, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
	queue_redraw()
#endregion

#region Engine Callbacks
func _process(delta: float) -> void:
	if _flash_alpha > 0.0:
		_flash_alpha = maxf(0.0, _flash_alpha - delta * 3.5)
		queue_redraw()
	if _rumble_offset != Vector2.ZERO:
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
	var center_offset: Vector2 = _rumble_offset + Vector2(0.0, _rebuild_offset_y)
	var half_w: float = WALL_WIDTH * 0.5
	var half_h: float = WALL_HEIGHT * 0.5
	var wall_rect := Rect2(-half_w + center_offset.x, -half_h + center_offset.y, WALL_WIDTH, WALL_HEIGHT)

	if _exploding:
		for piece in _debris:
			if piece.alpha <= 0.0:
				continue
			var sz: Vector2 = piece.size
			var half: Vector2 = sz * 0.5
			draw_set_transform(piece.pos + center_offset, piece.angle)
			if WALL_TILE_TEXTURE:
				draw_texture_rect(WALL_TILE_TEXTURE, Rect2(-half, sz), false, Color(1, 1, 1, piece.alpha))
			else:
				var color := Color(piece.shade, piece.shade * 0.95, piece.shade * 0.9, piece.alpha)
				draw_rect(Rect2(-half, sz), color)
		draw_set_transform(Vector2.ZERO, 0.0)
		return

	if not _show_wall:
		return

	if CASTLE_WALL_TEXTURE:
		draw_texture_rect(CASTLE_WALL_TEXTURE, wall_rect, false)
	elif WALL_TILE_TEXTURE:
		draw_texture_rect(WALL_TILE_TEXTURE, wall_rect, false)
	else:
		draw_rect(wall_rect, Color(0.28, 0.25, 0.22, 1.0))

	# Wall cap battlement
	if WALL_CAP_TEXTURE:
		var cap_w: float = 24.0
		var cap_h: float = 12.0
		draw_texture_rect(WALL_CAP_TEXTURE, Rect2(-half_w + center_offset.x, -half_h - cap_h * 0.5 + center_offset.y, cap_w, cap_h), false)
		draw_texture_rect(WALL_CAP_TEXTURE, Rect2(half_w - cap_w + center_offset.x, -half_h - cap_h * 0.5 + center_offset.y, cap_w, cap_h), false)

	# Hit flash overlay
	if _flash_alpha > 0.0:
		var fl: Color = Constants.gameplay_wall_flash()
		var flash_rect := Rect2(wall_rect.position - Vector2(4, 4), wall_rect.size + Vector2(8, 8))
		draw_rect(flash_rect, Color(fl.r, fl.g, fl.b, _flash_alpha * 0.85))
#endregion


