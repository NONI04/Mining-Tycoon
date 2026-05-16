extends Node

signal money_changed(new_amount: float)
signal depth_changed(new_depth: int)
signal upgrade_purchased(upgrade_id: String)

var money: float = 0.0
var depth: int = 1
var ore_per_click: float = 1.0
var auto_mine_rate: float = 0.0

var upgrades: Dictionary = {
	"pickaxe": {
		"name": "Better Pickaxe",
		"description": "Doubles mining power per click",
		"base_cost": 50.0,
		"cost_multiplier": 2.0,
		"level": 0,
		"max_level": 10,
		"effect": "ore_per_click"
	},
	"auto_miner": {
		"name": "Auto Miner",
		"description": "Automatically mines every second",
		"base_cost": 100.0,
		"cost_multiplier": 2.5,
		"level": 0,
		"max_level": 5,
		"effect": "auto_mine"
	},
	"depth_drill": {
		"name": "Depth Drill",
		"description": "Go deeper for rarer ore",
		"base_cost": 500.0,
		"cost_multiplier": 3.0,
		"level": 0,
		"max_level": 10,
		"effect": "depth"
	}
}

var ore_types: Array = [
	{"name": "Stone",   "value": 1,   "min_depth": 1,  "color": Color(0.55, 0.55, 0.55)},
	{"name": "Coal",    "value": 3,   "min_depth": 2,  "color": Color(0.22, 0.22, 0.22)},
	{"name": "Iron",    "value": 10,  "min_depth": 3,  "color": Color(0.80, 0.55, 0.35)},
	{"name": "Gold",    "value": 50,  "min_depth": 5,  "color": Color(1.00, 0.82, 0.00)},
	{"name": "Diamond", "value": 200, "min_depth": 8,  "color": Color(0.55, 0.92, 1.00)},
]

var _auto_mine_timer: float = 0.0

func _process(delta: float) -> void:
	if auto_mine_rate <= 0.0:
		return
	_auto_mine_timer += delta
	if _auto_mine_timer >= 1.0:
		_auto_mine_timer = 0.0
		add_money(auto_mine_rate * _get_best_ore_value())

func mine() -> float:
	var value = ore_per_click * _get_best_ore_value()
	add_money(value)
	return value

func add_money(amount: float) -> void:
	money += amount
	money_changed.emit(money)

func _get_best_ore_value() -> float:
	var available = ore_types.filter(func(o): return o.min_depth <= depth)
	if available.is_empty():
		return 1.0
	return float(available.back().value)

func get_upgrade_cost(upgrade_id: String) -> float:
	var upg = upgrades[upgrade_id]
	return upg.base_cost * pow(upg.cost_multiplier, upg.level)

func can_afford(upgrade_id: String) -> bool:
	var upg = upgrades[upgrade_id]
	return money >= get_upgrade_cost(upgrade_id) and upg.level < upg.max_level

func purchase_upgrade(upgrade_id: String) -> bool:
	if not can_afford(upgrade_id):
		return false
	var upg = upgrades[upgrade_id]
	money -= get_upgrade_cost(upgrade_id)
	upg.level += 1
	match upg.effect:
		"ore_per_click":
			ore_per_click *= 2.0
		"auto_mine":
			auto_mine_rate += 1.0
		"depth":
			depth += 1
			depth_changed.emit(depth)
	money_changed.emit(money)
	upgrade_purchased.emit(upgrade_id)
	return true
