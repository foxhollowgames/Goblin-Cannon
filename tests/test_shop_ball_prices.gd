extends "res://tests/test_base.gd"

func _init() -> void:
	suite_name = "ShopBallPrices"

func run() -> void:
	test_shop_price_for_ball_rarity_uses_surcharge()
	test_stat_shop_prices_unaffected_by_ball_surcharge()

func test_shop_price_for_ball_rarity_uses_surcharge() -> void:
	begin("shop_price_for_ball_rarity equals tier base + SHOP_BALL_PURCHASE_SURCHARGE_COINS")
	var s: int = Constants.SHOP_BALL_PURCHASE_SURCHARGE_COINS
	assert_eq(Constants.shop_price_for_ball_rarity(Constants.RARITY_COMMON), Constants.SHOP_PRICE_COMMON + s)
	assert_eq(Constants.shop_price_for_ball_rarity(Constants.RARITY_UNCOMMON), Constants.SHOP_PRICE_UNCOMMON + s)
	assert_eq(Constants.shop_price_for_ball_rarity(Constants.RARITY_RARE), Constants.SHOP_PRICE_RARE + s)
	assert_eq(Constants.shop_price_for_ball_rarity(Constants.RARITY_EPIC), Constants.SHOP_PRICE_EPIC + s)
	assert_eq(Constants.shop_price_for_ball_rarity(Constants.RARITY_LEGENDARY), Constants.SHOP_PRICE_EPIC + s)

func test_stat_shop_prices_unaffected_by_ball_surcharge() -> void:
	begin("shop_price_for_stat_rarity tier 0..2 uses SHOP_PRICE_* without ball surcharge")
	assert_eq(Constants.shop_price_for_stat_rarity(0), Constants.SHOP_PRICE_COMMON)
	assert_eq(Constants.shop_price_for_stat_rarity(1), Constants.SHOP_PRICE_UNCOMMON)
	assert_eq(Constants.shop_price_for_stat_rarity(2), Constants.SHOP_PRICE_RARE)
