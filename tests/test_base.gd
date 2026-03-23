extends RefCounted
## Lightweight assertion helpers for headless tests.
## Subclass, set suite_name, implement run(), call assert_* methods.

var suite_name: String = "UnnamedTest"
var passed: int = 0
var failed: int = 0
var errors: Array[String] = []
var _current_test: String = ""

func run() -> void:
	push_error("TestBase.run() not overridden — subclass must implement run()")

func begin(test_name: String) -> void:
	_current_test = test_name

func assert_eq(actual: Variant, expected: Variant, msg: String = "") -> void:
	var label: String = msg if not msg.is_empty() else _current_test
	if actual == expected:
		passed += 1
	else:
		failed += 1
		errors.append("%s: expected %s, got %s" % [label, str(expected), str(actual)])

func assert_neq(actual: Variant, not_expected: Variant, msg: String = "") -> void:
	var label: String = msg if not msg.is_empty() else _current_test
	if actual != not_expected:
		passed += 1
	else:
		failed += 1
		errors.append("%s: expected NOT %s, but got it" % [label, str(not_expected)])

func assert_true(condition: bool, msg: String = "") -> void:
	assert_eq(condition, true, msg if not msg.is_empty() else _current_test)

func assert_false(condition: bool, msg: String = "") -> void:
	assert_eq(condition, false, msg if not msg.is_empty() else _current_test)

func assert_gt(actual: Variant, threshold: Variant, msg: String = "") -> void:
	var label: String = msg if not msg.is_empty() else _current_test
	if actual > threshold:
		passed += 1
	else:
		failed += 1
		errors.append("%s: expected > %s, got %s" % [label, str(threshold), str(actual)])

func assert_gte(actual: Variant, threshold: Variant, msg: String = "") -> void:
	var label: String = msg if not msg.is_empty() else _current_test
	if actual >= threshold:
		passed += 1
	else:
		failed += 1
		errors.append("%s: expected >= %s, got %s" % [label, str(threshold), str(actual)])

func assert_lt(actual: Variant, threshold: Variant, msg: String = "") -> void:
	var label: String = msg if not msg.is_empty() else _current_test
	if actual < threshold:
		passed += 1
	else:
		failed += 1
		errors.append("%s: expected < %s, got %s" % [label, str(threshold), str(actual)])

func assert_lte(actual: Variant, threshold: Variant, msg: String = "") -> void:
	var label: String = msg if not msg.is_empty() else _current_test
	if actual <= threshold:
		passed += 1
	else:
		failed += 1
		errors.append("%s: expected <= %s, got %s" % [label, str(threshold), str(actual)])

func assert_in(item: Variant, collection: Array, msg: String = "") -> void:
	var label: String = msg if not msg.is_empty() else _current_test
	if item in collection:
		passed += 1
	else:
		failed += 1
		errors.append("%s: %s not found in collection" % [label, str(item)])

func assert_not_in(item: Variant, collection: Array, msg: String = "") -> void:
	var label: String = msg if not msg.is_empty() else _current_test
	if item not in collection:
		passed += 1
	else:
		failed += 1
		errors.append("%s: %s should not be in collection" % [label, str(item)])

func assert_empty(collection: Array, msg: String = "") -> void:
	var label: String = msg if not msg.is_empty() else _current_test
	if collection.is_empty():
		passed += 1
	else:
		failed += 1
		errors.append("%s: expected empty, got %d items" % [label, collection.size()])

func assert_not_empty(collection: Array, msg: String = "") -> void:
	var label: String = msg if not msg.is_empty() else _current_test
	if not collection.is_empty():
		passed += 1
	else:
		failed += 1
		errors.append("%s: expected non-empty array" % label)

func assert_approx(actual: float, expected: float, tolerance: float = 0.001, msg: String = "") -> void:
	var label: String = msg if not msg.is_empty() else _current_test
	if absf(actual - expected) <= tolerance:
		passed += 1
	else:
		failed += 1
		errors.append("%s: expected ~%s (±%s), got %s" % [label, str(expected), str(tolerance), str(actual)])
