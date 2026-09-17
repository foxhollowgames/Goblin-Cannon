extends RefCounted
## Keeps one device in control of a captured ball until it releases that ball.

const OWNER_KEY: StringName = &"relic_flow_owner"

static func available(ball: Node, device: Node) -> bool:
	if not ball.has_meta(OWNER_KEY): return true
	var owner: Variant = ball.get_meta(OWNER_KEY)
	return owner == null or not is_instance_valid(owner.get_ref()) or owner.get_ref() == device

static func claim(ball: Node, device: Node) -> bool:
	if not available(ball, device): return false
	ball.set_meta(OWNER_KEY, weakref(device))
	return true

static func release(ball: Node, device: Node) -> void:
	if is_instance_valid(ball) and ball.has_meta(OWNER_KEY) and available(ball, device):
		ball.remove_meta(OWNER_KEY)
