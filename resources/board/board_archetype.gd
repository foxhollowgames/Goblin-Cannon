@tool
extends Resource
class_name BoardArchetype
## §7: archetype enum, peg_layout (Array or PackedScene).

enum Archetype { BALANCED, TECH, MAGIC }

@export var archetype: Archetype = Archetype.BALANCED
@export var peg_layout: Array = []  # or PackedScene for full layout scene
