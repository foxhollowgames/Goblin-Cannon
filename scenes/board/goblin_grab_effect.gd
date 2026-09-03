extends Node2D
## Visual effect for the Goblin Reset peg: a green goblin hand grips the ball and carries it upward.

#region Constants
const GOBLIN_HAND_TEXTURE: Texture2D = preload("res://assets/Kenney Game Assets All-in-1 3.4.0/2D assets/Monster Builder Pack/PNG/Default/arm_greenA.png")
#endregion

#region Variables
var _phase: float = 0.0
var _gripping: bool = true
#endregion

#region Engine Callbacks
func _ready() -> void:
	z_index = 200
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	_phase += delta * 6.0
	queue_redraw()

func _draw() -> void:
	var grip_squeeze: float = (0.85 + 0.15 * sin(_phase * 3.0)) if _gripping else 1.3
	if GOBLIN_HAND_TEXTURE:
		var w: float = 36.0 * grip_squeeze
		var h: float = 48.0
		var dest_rect := Rect2(-w * 0.5, -36.0, w, h)
		draw_texture_rect(GOBLIN_HAND_TEXTURE, dest_rect, false, Color(1.0, 1.0, 1.0, 0.95))
		return

	var hand_color := Color(0.35, 0.65, 0.2, 0.95)
	var dark_green := Color(0.2, 0.4, 0.12, 0.9)
	var claw_color := Color(0.55, 0.5, 0.25, 0.9)

	# Arm reaching down from above
	draw_line(Vector2(0, -55), Vector2(2, -12), dark_green, 7.0)
	draw_line(Vector2(-1, -55), Vector2(1, -12), hand_color, 5.0)

	# Wrist bump
	draw_circle(Vector2(0, -12), 6.0, hand_color)

	# Four fingers curling around from below
	var finger_angles: Array[float] = [-1.2, -0.4, 0.4, 1.2]
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
#endregion

#region Public Methods
## Releases the ball grip and initiates alpha fadeout before freeing the node.
func release_and_fade() -> void:
	_gripping = false
	var tween: Tween = create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	tween.tween_property(self, "modulate:a", 0.0, 0.35)
	tween.tween_callback(queue_free)
#endregion
