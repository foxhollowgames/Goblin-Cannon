extends "res://tests/test_base.gd"
## Ensures core .gd files parse and load. Catches parser errors (e.g. Object.get() with 2 args).

func _init() -> void:
	suite_name = "ScriptParseSmoke"

func run() -> void:
	test_critical_scripts_load()
	test_all_scenes_tree_gd_loads()
	test_all_resources_tree_gd_loads()

func test_critical_scripts_load() -> void:
	begin("critical scripts load (parser + compile)")
	for path in _critical_script_paths():
		var script: GDScript = load(path) as GDScript
		assert_true(script != null, "load %s" % path)

func test_all_scenes_tree_gd_loads() -> void:
	begin("every .gd under res://scenes parses")
	var paths: Array[String] = []
	_collect_gd_files("res://scenes", paths)
	paths.sort()
	for path in paths:
		var script: GDScript = load(path) as GDScript
		assert_true(script != null, "load %s" % path)

func test_all_resources_tree_gd_loads() -> void:
	begin("every .gd under res://resources parses")
	var paths: Array[String] = []
	_collect_gd_files("res://resources", paths)
	paths.sort()
	for path in paths:
		var script: GDScript = load(path) as GDScript
		assert_true(script != null, "load %s" % path)

func _critical_script_paths() -> Array[String]:
	return [
		"res://resources/polyomino/polyomino_module_data.gd",
		"res://scenes/board/machinery/polyomino_machinery_component.gd",
		"res://scenes/board/board.gd",
		"res://scenes/board/peg.gd",
		"res://scenes/main/game_coordinator.gd",
		"res://scenes/main/combat_manager.gd",
		"res://scenes/rewards/reward_handler.gd",
	]

func _collect_gd_files(dir_path: String, out: Array[String]) -> void:
	var d: DirAccess = DirAccess.open(dir_path)
	if d == null:
		return
	d.list_dir_begin()
	var entry: String = d.get_next()
	while entry != "":
		if entry.begins_with("."):
			entry = d.get_next()
			continue
		var full: String = dir_path.path_join(entry)
		if d.current_is_dir():
			_collect_gd_files(full, out)
		elif entry.ends_with(".gd"):
			out.append(full)
		entry = d.get_next()
