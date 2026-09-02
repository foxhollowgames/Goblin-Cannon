extends RefCounted
class_name PolyominoFusionSystem
## Polyomino Relic Module Combining and Fusion System (TASK-018).

const JunkBoxItem = preload("res://resources/inventory/junk_box_item.gd")
const PolyominoModuleData = preload("res://resources/polyomino/polyomino_module_data.gd")

const RECIPE_BLUEPRINTS: Dictionary = {
	"item_bumper+item_accelerator": &"item_lightning_dynamo",
	"item_accelerator+item_bumper": &"item_lightning_dynamo",
	"item_funnel+item_booster": &"item_vortex_funnel",
	"item_booster+item_funnel": &"item_vortex_funnel"
}

static func _get_item_id(item: JunkBoxItem) -> StringName:
	if item == null:
		return &""
	if item.module_data != null and not item.module_data.module_id.is_empty():
		return item.module_data.module_id
	return item.instance_id

static func can_fuse(item_a: JunkBoxItem, item_b: JunkBoxItem) -> bool:
	if item_a == null or item_b == null or item_a == item_b:
		return false
	if item_a.item_type != JunkBoxItem.POLYOMINO_MODULE or item_b.item_type != JunkBoxItem.POLYOMINO_MODULE:
		return false
	if item_a.module_data == null or item_b.module_data == null:
		return false

	if item_a.module_data.tier == item_b.module_data.tier:
		return true

	var id_a: StringName = _get_item_id(item_a)
	var id_b: StringName = _get_item_id(item_b)
	var recipe_key: String = "%s+%s" % [id_a, id_b]
	return RECIPE_BLUEPRINTS.has(recipe_key)

static func fuse_modules(item_a: JunkBoxItem, item_b: JunkBoxItem) -> JunkBoxItem:
	if not can_fuse(item_a, item_b):
		return null

	var id_a: StringName = _get_item_id(item_a)
	var id_b: StringName = _get_item_id(item_b)
	var recipe_key: String = "%s+%s" % [id_a, id_b]
	var output_id: StringName = &""
	if RECIPE_BLUEPRINTS.has(recipe_key):
		output_id = RECIPE_BLUEPRINTS[recipe_key]
	else:
		output_id = StringName("%s_t%d" % [id_a, item_a.module_data.tier + 1])

	var fused_data := PolyominoModuleData.new()
	fused_data.module_id = output_id
	fused_data.tier = item_a.module_data.tier + 1

	fused_data.cells = item_a.module_data.cells.duplicate()
	for c in item_b.module_data.cells:
		if c not in fused_data.cells:
			fused_data.cells.append(c)

	for k in item_a.module_data.cell_types.keys():
		fused_data.cell_types[k] = item_a.module_data.cell_types[k]
	for k in item_b.module_data.cell_types.keys():
		if not fused_data.cell_types.has(k):
			fused_data.cell_types[k] = item_b.module_data.cell_types[k]

	var fused_item := JunkBoxItem.new(output_id, JunkBoxItem.POLYOMINO_MODULE)
	fused_item.display_name = "Fused Module Tier %d" % fused_data.tier
	fused_item.module_data = fused_data
	return fused_item
