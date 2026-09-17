extends SceneTree
## Renders representative live relics and their shop previews for visual review.

func _initialize() -> void:
	call_deferred("_render")

func _render() -> void:
	root.size = Vector2i(1200, 850)
	root.content_scale_size = Vector2i(1200, 850)
	var database = load("res://resources/polyomino/polyomino_relic_database.gd")
	var module_script = load("res://scenes/board/machinery/polyomino_module_node.gd")
	var preview_script = load("res://scenes/rewards/relic_layout_preview.gd")
	var background := ColorRect.new()
	background.color = Color(0.055, 0.07, 0.10)
	background.size = Vector2(1200, 850)
	root.add_child(background)
	var ids: Array[StringName] = [&"word_bank_gob", &"wire_gate_cup", &"funneled_spinner_chute", &"bumper_vessel_twin", &"track_u_turn", &"corner_slingshot", &"golem_effigy"]
	for index: int in range(ids.size()):
		var origin := Vector2(35 + (index % 4) * 300, 55 + (index / 4) * 390)
		var label := Label.new()
		label.text = String(ids[index]).replace("_", " ")
		label.position = origin
		root.add_child(label)
		var module: Node2D = module_script.new()
		module.position = origin + Vector2(50, 75)
		module.setup_module(database.create_item_for_relic(ids[index]), Vector2i.ZERO)
		root.add_child(module)
		var preview: Control = preview_script.new()
		preview.position = origin + Vector2(0, 250)
		preview.size = Vector2(240, 100)
		preview.setup_for_relic(ids[index])
		root.add_child(preview)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/knowledge/relic-flow-preview.png")
	quit()
