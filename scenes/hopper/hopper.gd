extends Node2D
## Hopper (§6.1). FIFO ball queue; owns ball_id. add_balls, release_next_ball, get_visible_count.

signal ball_requested(count: int)  # optional

var _queue: Array = []  # { ball_id, def }; Ball nodes created on release
var _next_ball_id: int = 0
var _ball_scene: PackedScene

func _ready() -> void:
	_ball_scene = load("res://scenes/balls/ball.tscn") as PackedScene

func add_balls(count: int) -> void:
	for i in count:
		_add_single_ball(null)

func _add_single_ball(_ball_def: Resource) -> void:
	_next_ball_id += 1
	_queue.append({"ball_id": _next_ball_id, "def": _ball_def})

func release_next_ball() -> Node:
	if _queue.is_empty() or not _ball_scene:
		return null
	var front: Dictionary = _queue.pop_front()
	var ball: Node = _ball_scene.instantiate()
	if ball.has_method("set_ball_id"):
		ball.set_ball_id(front.ball_id)
	if ball.has_method("set_definition") and front.get("def"):
		ball.set_definition(front.def)
	return ball

func get_visible_count() -> int:
	return mini(_queue.size(), 100)

func _remove_from_front() -> Node:
	return release_next_ball()
