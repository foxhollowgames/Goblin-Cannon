extends Node2D
## Visual effect for the Goblin Reset peg: a green goblin hand grips the ball and carries it upward.

var _phase: float = 0.0
var _gripping: bool = true

func _ready() -> void:
	z_index = 200
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	_phase += delta * 6.0
	queue_redraw()

func release_and_fade() -> void:
	_gripping = false
	var tween := create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	tween.tween_property(self, "modulate:a", 0.0, 0.35)
	tween.tween_callback(queue_free)

func _draw() -> void:
	var hand_color := Color(0.35, 0.65, 0.2, 0.95)
	var dark_green := Color(0.2, 0.4, 0.12, 0.9)
	var claw_color := Color(0.55, 0.5, 0.25, 0.9)
	var grip_squeeze: float = (0.85 + 0.15 * sin(_phase * 3.0)) if _gripping else 1.3

	# Arm reaching down from above
	draw_line(Vector2(0, -55), Vector2(2, -12), dark_green, 7.0)
	draw_line(Vector2(-1, -55), Vector2(1, -12), hand_color, 5.0)

	# Wrist bump
	draw_circle(Vector2(0, -12), 6.0, hand_color)

	# Four fingers curling around from below
	var finger_angles: Array = [-1.2, -0.4, 0.4, 1.2]
	for angle in finger_angles:
		var base := Vector2(cos(angle) * 5.0, 2.0)
		var mid := base + Vector2(cos(angle) * 7.0 * grip_squeeze, 6.0 * grip_squeeze)
		var tip := mid + Vector2(cos(angle) * 4.0 * grip_squeeze, 3.0 * grip_squeeze)
		draw_line(base, mid, hand_color, 3.5)
		draw_line(mid, tip, hand_color, 2.5)
		draw_circle(tip, 2.0, claw_color)

	# Warts
	draw_circle(Vector2(-4, -8), 2.0, dark_green)
	draw_circle(Vector2(3, -15), 1.5, dark_green)
