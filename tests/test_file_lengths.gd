extends "res://tests/test_base.gd"

func _init() -> void:
	suite_name = "FileLengthLint"

const MAX_LINES: int = 500

const BASELINE_LIMITS: Dictionary = {
	"res://scenes/board/board.gd": 3237,
	"res://scenes/main/game_coordinator.gd": 1531,
	"res://scenes/board/peg.gd": 1180,
	"res://scenes/rewards/reward_draft_panel.gd": 886,
	"res://scenes/rewards/reward_handler.gd": 729,
	"res://resources/polyomino/polyomino_relic_database.gd": 654,
	"res://autoloads/constants.gd": 569,
	"res://scenes/ui/debug_full_store_modal.gd": 546,
}

func run() -> void:
	begin("all GDScript files <= 500 lines or within baseline limit")
	var directories: Array[String] = [
		"res://scenes",
		"res://autoloads",
		"res://resources",
		"res://simulation",
		"res://tests",
	]

	var gd_files: Array[String] = []
	for directory in directories:
		_collect_gd_files(directory, gd_files)

	gd_files.sort()
	for file_path in gd_files:
		_test_file_length(file_path)

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

func _test_file_length(path: String) -> void:
	var text: String = FileAccess.get_file_as_string(path)
	if text.ends_with("\r\n"):
		text = text.trim_suffix("\r\n")
	elif text.ends_with("\n"):
		text = text.trim_suffix("\n")

	var line_count: int = text.split("\n").size() if not text.is_empty() else 0
	var allowed_max_lines: int = BASELINE_LIMITS.get(path, MAX_LINES)

	assert_lte(line_count, allowed_max_lines, "%s line count (%d <= %d)" % [path, line_count, allowed_max_lines])
