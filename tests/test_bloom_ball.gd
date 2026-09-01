extends "res://tests/test_base.gd"

func _init() -> void:
	suite_name = "BloomBall"

func run() -> void:
	test_bloom_peg_hit_block_uses_ball_position_for_spawn()
	test_bloom_spawn_helper_documents_ball_position()
	test_bloom_does_not_share_binary_split_codepath()
	test_bloom_spawn_marks_temporary_for_lifecycle()

func test_bloom_peg_hit_block_uses_ball_position_for_spawn() -> void:
	begin("Bloom peg-hit handler passes Bloom ball global_position to spawn")
	var board_script: GDScript = load("res://scenes/board/board.gd") as GDScript
	var src: String = board_script.source_code
	var idx: int = src.find("ability_key == \"Bloom\"")
	assert_gt(idx, -1, "Bloom branch present")
	var slice: String = src.substr(idx, mini(420, src.length() - idx))
	assert_true(slice.contains("_spawn_random_ball_from_bloom_at(b.global_position"), "spawn at ball, not peg")

func test_bloom_spawn_helper_documents_ball_position() -> void:
	begin("_spawn_random_ball_from_bloom_at doc mentions Bloom ball center")
	var board_script: GDScript = load("res://scenes/board/board.gd") as GDScript
	var src: String = board_script.source_code
	assert_true(src.contains("Bloom ball") and src.contains("_spawn_random_ball_from_bloom_at"), "helper documented")

func test_bloom_does_not_share_binary_split_codepath() -> void:
	begin("Bloom is separate from Binary ball–ball split")
	var board_script: GDScript = load("res://scenes/board/board.gd") as GDScript
	var src: String = board_script.source_code
	assert_true(src.contains("_process_binary_ball_on_ball_splits"), "Binary split path exists")
	var bloom_i: int = src.find("ability_key == \"Bloom\"")
	var bin_i: int = src.find("_try_binary_split_victim_from_collision")
	assert_gt(abs(bloom_i - bin_i), 50, "Bloom and Binary split are distinct regions")

func test_bloom_spawn_marks_temporary_for_lifecycle() -> void:
	begin("Bloom spawn marks ball so hopper path can exclude it")
	var board_script: GDScript = load("res://scenes/board/board.gd") as GDScript
	var src: String = board_script.source_code
	assert_true(src.contains("mark_as_bloom_spawn"), "spawn marks bloom balls")
	var gc_script: GDScript = load("res://scenes/main/game_ball_manager.gd") as GDScript
	var gcs: String = gc_script.source_code
	assert_true(gcs.contains("is_bloom_spawn"), "ball manager checks bloom spawn before hopper return")
