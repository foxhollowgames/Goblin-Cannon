extends Control
class_name RelicLayoutPreview
## Visual preview control that renders polyomino relic shapes and machine composition.
## Shows multi-cell grid footprints, comic ink borders, and kinetic component glyphs.

const PolyominoRelicDatabase = preload("res://resources/polyomino/polyomino_relic_database.gd")
const PolyominoModuleData = preload("res://resources/polyomino/polyomino_module_data.gd")
const CellType = PolyominoModuleData.CellType

const DEFAULT_CELL_SIZE: float = 22.0
const DEFAULT_CELL_PAD: float = 1.5
const DEFAULT_PREVIEW_HEIGHT: float = 76.0
const DARK_INK_BORDER: Color = Color(0.08, 0.05, 0.12, 1.0)

var module_data: PolyominoModuleData = null
var relic_id: StringName = &""
var cell_size: float = DEFAULT_CELL_SIZE
var cell_pad: float = DEFAULT_CELL_PAD
var accent_color: Color = Color(0.9, 0.8, 0.4, 1.0)

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	custom_minimum_size = Vector2(180, DEFAULT_PREVIEW_HEIGHT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

func setup_for_relic(p_relic_id: StringName) -> bool:
	relic_id = p_relic_id
	if not PolyominoRelicDatabase.has_relic_definition(p_relic_id):
		module_data = null
		queue_redraw()
		return false

	module_data = PolyominoRelicDatabase.create_module_for_relic(p_relic_id)
	if module_data != null:
		accent_color = Constants.shop_rarity_accent_color(module_data.tier)
	queue_redraw()
	return true

func setup_for_module(data: PolyominoModuleData) -> void:
	module_data = data
	if module_data != null:
		relic_id = module_data.module_id
		accent_color = Constants.shop_rarity_accent_color(module_data.tier)
	queue_redraw()

func clear() -> void:
	module_data = null
	relic_id = &""
	queue_redraw()

func get_module_data() -> PolyominoModuleData:
	return module_data

func get_cell_count() -> int:
	return module_data.get_cell_count() if module_data != null else 0

func get_preview_bounds() -> Rect2:
	if module_data == null or module_data.cells.is_empty():
		return Rect2(Vector2.ZERO, size)

	var min_x: int = 9999
	var max_x: int = -9999
	var min_y: int = 9999
	var max_y: int = -9999
	for c in module_data.cells:
		min_x = mini(min_x, c.x)
		max_x = maxi(max_x, c.x)
		min_y = mini(min_y, c.y)
		max_y = maxi(max_y, c.y)

	var cols: int = max_x - min_x + 1
	var rows: int = max_y - min_y + 1
	var total_w: float = float(cols) * cell_size
	var total_h: float = float(rows) * cell_size
	var origin_x: float = (size.x - total_w) * 0.5
	var origin_y: float = (size.y - total_h) * 0.5
	return Rect2(origin_x, origin_y, total_w, total_h)

func _draw() -> void:
	if module_data == null or module_data.cells.is_empty():
		return

	var min_x: int = 9999
	var max_x: int = -9999
	var min_y: int = 9999
	var max_y: int = -9999
	for c in module_data.cells:
		min_x = mini(min_x, c.x)
		max_x = maxi(max_x, c.x)
		min_y = mini(min_y, c.y)
		max_y = maxi(max_y, c.y)

	var cols: int = max_x - min_x + 1
	var rows: int = max_y - min_y + 1
	var total_w: float = float(cols) * cell_size
	var total_h: float = float(rows) * cell_size
	var origin_x: float = (size.x - total_w) * 0.5 - float(min_x) * cell_size
	var origin_y: float = (size.y - total_h) * 0.5 - float(min_y) * cell_size

	# Draw connecting chassis struts between adjacent occupied cells
	for i in range(module_data.cells.size()):
		for j in range(i + 1, module_data.cells.size()):
			var c1: Vector2i = module_data.cells[i]
			var c2: Vector2i = module_data.cells[j]
			var dist: int = abs(c1.x - c2.x) + abs(c1.y - c2.y)
			if dist == 1:
				var p1 := Vector2(origin_x + (float(c1.x) + 0.5) * cell_size, origin_y + (float(c1.y) + 0.5) * cell_size)
				var p2 := Vector2(origin_x + (float(c2.x) + 0.5) * cell_size, origin_y + (float(c2.y) + 0.5) * cell_size)
				draw_line(p1, p2, DARK_INK_BORDER, cell_size * 0.6)
				draw_line(p1, p2, accent_color.darkened(0.5), cell_size * 0.45)

	# Draw individual occupied polyomino cells
	for c in module_data.cells:
		var cell_pos := Vector2(origin_x + float(c.x) * cell_size, origin_y + float(c.y) * cell_size)
		var rect := Rect2(cell_pos.x + cell_pad, cell_pos.y + cell_pad, cell_size - cell_pad * 2.0, cell_size - cell_pad * 2.0)

		# Dark comic ink background
		draw_rect(rect, DARK_INK_BORDER)
		# Tier accent fill
		draw_rect(rect.grow(-1.5), accent_color.darkened(0.65))
		# Inner highlight bevel
		draw_rect(rect.grow(-1.5), accent_color.lightened(0.2), false, 1.0)
		# Outer ink border outline
		draw_rect(rect, DARK_INK_BORDER, false, 2.0)

		# Render internal kinetic machinery glyph
		var c_type: int = module_data.get_cell_type_at(c)
		var c_dir: Vector2 = module_data.get_cell_direction_at(c)
		_draw_kinetic_glyph(rect.get_center(), c_type, c_dir, rect.size.x * 0.5)

func _draw_kinetic_glyph(center: Vector2, type: int, dir: Vector2, radius: float) -> void:
	var s: float = radius
	match type:
		CellType.BUMPER:
			# Circular bumper with high-contrast inner ring
			draw_circle(center, s * 0.65, DARK_INK_BORDER)
			draw_circle(center, s * 0.5, Color.WHITE)
			draw_circle(center, s * 0.25, accent_color.darkened(0.5))
		CellType.ACCELERATOR:
			# Directional wedge pointing along boost direction
			var dir_norm: Vector2 = dir.normalized() if dir.length_squared() > 0.001 else Vector2.DOWN
			var tip: Vector2 = center + dir_norm * (s * 0.7)
			var perp := Vector2(-dir_norm.y, dir_norm.x) * (s * 0.5)
			var base_p: Vector2 = center - dir_norm * (s * 0.4)
			var poly_ink := PackedVector2Array([tip + dir_norm * 1.5, base_p + perp * 1.25, base_p - perp * 1.25])
			var poly_white := PackedVector2Array([tip, base_p + perp, base_p - perp])
			draw_colored_polygon(poly_ink, DARK_INK_BORDER)
			draw_colored_polygon(poly_white, Color.WHITE)
		CellType.FUNNEL:
			# Converging guide rails pointing toward exit slot
			var dir_norm: Vector2 = dir.normalized() if dir.length_squared() > 0.001 else Vector2.DOWN
			var perp := Vector2(-dir_norm.y, dir_norm.x)
			var left_start: Vector2 = center - dir_norm * (s * 0.55) + perp * (s * 0.55)
			var left_end: Vector2 = center + dir_norm * (s * 0.45) + perp * (s * 0.15)
			var right_start: Vector2 = center - dir_norm * (s * 0.55) - perp * (s * 0.55)
			var right_end: Vector2 = center + dir_norm * (s * 0.45) - perp * (s * 0.15)
			draw_line(left_start, left_end, DARK_INK_BORDER, 3.5)
			draw_line(left_start, left_end, Color.WHITE, 2.0)
			draw_line(right_start, right_end, DARK_INK_BORDER, 3.5)
			draw_line(right_start, right_end, Color.WHITE, 2.0)
			draw_circle(center + dir_norm * (s * 0.45), s * 0.15, Color.WHITE)
		CellType.ROTARY_BOOSTER:
			# Circular arc spinner with rotational tick marks
			draw_arc(center, s * 0.55, 0.2, TAU * 0.85, 16, DARK_INK_BORDER, 3.5)
			draw_arc(center, s * 0.55, 0.2, TAU * 0.85, 16, Color.WHITE, 2.0)
			for i in range(3):
				var ang: float = 0.2 + float(i) * (TAU * 0.28)
				var p1: Vector2 = center + Vector2.from_angle(ang) * (s * 0.35)
				var p2: Vector2 = center + Vector2.from_angle(ang) * (s * 0.7)
				draw_line(p1, p2, Color.WHITE, 1.5)
			draw_circle(center, s * 0.2, Color.WHITE)
		CellType.MANA_SIPHON:
			# Swirling vortex concentric arc rings
			draw_arc(center, s * 0.6, 0.0, PI * 1.2, 12, accent_color.lightened(0.4), 2.0)
			draw_arc(center, s * 0.35, PI * 0.8, PI * 2.0, 10, Color.WHITE, 1.8)
			draw_circle(center, s * 0.18, Color.WHITE)
		CellType.DIRECTIONAL_DEFLECTOR:
			# Angled guide rails and directional pointer arrow
			var dir_norm: Vector2 = dir.normalized() if dir.length_squared() > 0.001 else Vector2(1, 1).normalized()
			var perp := Vector2(-dir_norm.y, dir_norm.x)
			var bar_p1: Vector2 = center - perp * (s * 0.5) - dir_norm * (s * 0.2)
			var bar_p2: Vector2 = center + perp * (s * 0.5) - dir_norm * (s * 0.2)
			draw_line(bar_p1, bar_p2, DARK_INK_BORDER, 4.0)
			draw_line(bar_p1, bar_p2, Color.WHITE, 2.2)
			draw_line(center, center + dir_norm * (s * 0.6), accent_color.lightened(0.4), 2.0)
		CellType.GUIDE_RAIL:
			# Parallel guide bars
			draw_line(center + Vector2(-s * 0.5, -s * 0.25), center + Vector2(s * 0.5, -s * 0.25), Color.WHITE, 1.8)
			draw_line(center + Vector2(-s * 0.5, s * 0.25), center + Vector2(s * 0.5, s * 0.25), Color.WHITE, 1.8)
		_:
			# Default indicator dot
			draw_circle(center, s * 0.2, accent_color.darkened(0.2))
