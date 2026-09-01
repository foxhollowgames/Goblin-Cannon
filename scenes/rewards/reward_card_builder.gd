class_name RewardCardBuilder
extends RefCounted
## Static helper class for constructing and styling shop card UI components in RewardDraftPanel.

# Constants for rarity levels
const RARITY_COMMON = 0
const RARITY_UNCOMMON = 1
const RARITY_RARE = 2
const RARITY_EPIC = 3
const RARITY_LEGENDARY = 4

# ## Build a shop card with the given offer index and pick resource.
static func build_shop_card(offer_index: int, pick: Resource) -> PanelContainer:
	var card = PanelContainer.new()
	card.name = "ShopCard_" + str(offer_index)
	
	# Add card content here (e.g., icons, labels, etc.)
	# Example: var icon = Sprite.new(); card.add_child(icon); icon.texture = pick.icon
	
	return card

# ## Apply styling based on the rarity level to the given card.
static func apply_rarity_style(card: PanelContainer, rarity: int) -> void:
	var color = Color(1, 1, 1)
	
	match rarity:
		RARITY_COMMON:
			color = Color(0.8, 0.8, 0.8)
		RARITY_UNCOMMON:
			color = Color(0.4, 0.7, 0.2)
		RARITY_RARE:
			color = Color(0.3, 0.5, 1.0)
		RARITY_EPIC:
			color = Color(1.0, 0.4, 0.8)
		RARITY_LEGENDARY:
			color = Color(1.0, 0.9, 0.2)
	
	card.modulate = color

# ## Create a rarity marker based on the given rarity level.
static func create_rarity_marker(rarity: int) -> Control:
	var marker_script: Script = load("res://scenes/rewards/rarity_shape_marker.gd") as Script
	var marker: Control = marker_script.new() as Control
	if "rarity" in marker:
		marker.set("rarity", rarity)
	return marker
