extends Node2D
## Projectile fired from a wall fortification toward the cannon.
## Uses a visible sprite so the player can track incoming shots.

signal hit_cannon(damage: int)

const PROJECTILE_SPRITE_SIZE: int = 24  # pixels; visible and trackable
const PULSE_SPEED: float = 8.0   # rad/s for subtle brightness pulse
const PULSE_AMOUNT: float = 0.15 # modulate between (1 - PULSE_AMOUNT) and 1.0

var _speed: float = 280.0
var _target: Vector2 = Vector2(160.0, 640.0)
var _damage: int = 3
var _sprite: Sprite2D
var _flight_time: float = 0.0
const HIT_DISTANCE: float = 20.0  # consider hit when within this many pixels of target

func _ready() -> void:
	if get_meta("speed", null) != null:
		_speed = get_meta("speed")
	if get_meta("target", null) != null:
		_target = get_meta("target")
	elif get_meta("target_y", null) != null:
		_target = Vector2(position.x, get_meta("target_y"))
	if get_meta("damage", null) != null:
		_damage = get_meta("damage")
	_create_projectile_sprite()

func _create_projectile_sprite() -> void:
	var size := PROJECTILE_SPRITE_SIZE
	var img := Image.create_from_data(size, size, false, Image.FORMAT_RGBA8, _make_projectile_pixel_data(size))
	var tex := ImageTexture.create_from_image(img)
	_sprite = Sprite2D.new()
	_sprite.texture = tex
	_sprite.centered = true
	_sprite.position = Vector2.ZERO
	add_child(_sprite)

func _make_projectile_pixel_data(size: int) -> PackedByteArray:
	var center := size / 2.0
	var inner_r := center - 3.0  # inner orange
	var outer_r := center - 0.5  # outer bright ring
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(size * size * 4)
	for j in size:
		for i in size:
			var dx := float(i) - center + 0.5
			var dy := float(j) - center + 0.5
			var d := sqrt(dx * dx + dy * dy)
			var idx := (j * size + i) * 4
			var r: int
			var g: int
			var b: int
			var a: int
			if d <= inner_r:
				r = 230
				g = 128
				b = 38
				a = 255
			elif d <= outer_r:
				r = 255
				g = 200
				b = 80
				a = 255
			else:
				r = 0
				g = 0
				b = 0
				a = 0
			bytes[idx] = r
			bytes[idx + 1] = g
			bytes[idx + 2] = b
			bytes[idx + 3] = a
	return bytes

func _process(delta: float) -> void:
	_flight_time += delta
	var to_target: Vector2 = _target - position
	var dist: float = to_target.length()
	if dist <= HIT_DISTANCE:
		hit_cannon.emit(_damage)
		queue_free()
		return
	var move: float = _speed * delta
	if move >= dist:
		position = _target
		hit_cannon.emit(_damage)
		queue_free()
		return
	position += to_target.normalized() * move
	rotation = to_target.angle()
	# Subtle brightness pulse so projectile is easier to track
	if _sprite:
		var pulse: float = 1.0 - PULSE_AMOUNT * 0.5 + PULSE_AMOUNT * 0.5 * sin(_flight_time * PULSE_SPEED)
		_sprite.modulate = Color(pulse, pulse, pulse, 1.0)
