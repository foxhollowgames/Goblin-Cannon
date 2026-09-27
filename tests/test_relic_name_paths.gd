extends "res://tests/test_base.gd"

const DB = preload("res://resources/polyomino/polyomino_relic_database.gd")
const Names = preload("res://resources/polyomino/relic_names.gd")
const Cards = preload("res://scenes/rewards/reward_card_catalog.gd")
const Fusion = preload("res://resources/polyomino/polyomino_fusion_system.gd")
const Item = preload("res://resources/inventory/junk_box_item.gd")

var reward_panel: Control
var shop_panel: Control

func _init() -> void:
    suite_name = "RelicNamePaths"

## Runs all tests in the test file.
func run() -> void:
    _test_factories()
    _test_fusion()
    _test_cards()

func _test_factories() -> void:
    begin("Card factories use canonical relic names")
    for id: StringName in DB.get_all_relic_ids():
        var expected: String = DB.get_relic_display_name(id)
        assert_eq(Cards.mk("Old title", "", id, 0).display_name, expected)
        assert_eq(Cards.mk_cross("Old title", "", id, []).display_name, expected)
        assert_eq(Cards.mk_boss("Old title", "", id).display_name, expected)
        assert_eq(Cards.mk("Custom Title", "", &"unknown", 0).display_name, "Custom Title")

func _test_fusion() -> void:
    begin("Fusion names survive save and load")
    var item1: Resource = DB.create_item_for_relic(&"bumper_vessel_twin")
    var item2: Resource = DB.create_item_for_relic(&"bumper_vessel_twin")
    var fused: Resource = Fusion.fuse_modules(item1, item2)
    assert_true(fused.display_name == "Fused Device" and fused.module_data.display_name == "Fused Device")
    assert_eq(fused.module_data.tier, 2)
    assert_eq(fused.module_data.module_id, &"bumper_vessel_twin_t2")
    
    fused.display_name = "Fused Module Tier 2"
    fused.module_data.display_name = "Fused Module Tier 2"
    var serialized_item: Dictionary = fused.serialize()
    var deserialized_item: Resource = Item.deserialize(serialized_item)
    assert_eq(deserialized_item.module_data.display_name, deserialized_item.display_name)
    assert_true(deserialized_item.display_name == "Fused Device" and deserialized_item.module_data.module_id == &"bumper_vessel_twin_t2")
    
    assert_eq(Names.resolve(&"unknown", "Fused Module Tier custom"), "Fused Module Tier custom")

func _test_cards() -> void:
    begin("Merchant and reward cards show canonical names")
    reward_panel = load("res://scenes/rewards/major_upgrade_draft_panel.tscn").instantiate() as Control
    shop_panel = load("res://scenes/rewards/reward_draft_panel.gd").new() as Control
    
    for id: StringName in DB.get_offerable_relic_ids():
        var expected: String = DB.get_relic_display_name(id)
        var pick: Resource = Cards.mk("Old title", "", id, 0)
        var reward_card: Control = reward_panel._make_card(pick, 0)
        assert_true(_has_label(reward_card, expected))
        reward_card.free()
        
        var option: Resource = load("res://resources/rewards/milestone_option.gd").new()
        option.relic_id = id
        option.rarity = DB.get_relic_tier(id)
        var shop_card: Control = shop_panel._make_relic_card(option, 0, 15)
        assert_true(_has_label(shop_card, expected))
        shop_card.free()
    
    reward_panel.free()
    shop_panel.free()

func _has_label(node: Node, expected: String) -> bool:
    if node is Label and node.text == expected:
        return true
    for child: Node in node.get_children():
        if _has_label(child, expected):
            return true
    return false

