extends Node

signal money_changed(amount: float)
signal chest_changed(level_idx: int, amount: float)
signal ui_refresh_needed()
signal surface_ore_changed()

const START_MONEY: float = 50.0
var money: float = START_MONEY
var total_miners: int = 0
var chest_ore: Array = []
var surface_ore: Dictionary = {}

var mining_speed_level: int = 0
var cart_speed_level: int = 0
var cart_capacity_level: int = 0
var extra_miners_level: int = 0

const LUCKY_MULTS: Array = [1.0, 2.0, 3.0, 5.0]

const MAX_MINERS: int = 20
const HIRE_COSTS: Array = [
	50.0, 75.0, 225.0, 510.0, 1000.0, 1850.0, 3150.0, 5600.0, 9500.0, 15000.0,
	26000.0, 43000.0, 72000.0, 118000.0, 185000.0, 290000.0, 460000.0, 715000.0, 1100000.0, 1750000.0
]

const UPGRADES: Dictionary = {
	"mining_speed": {
		"name": "강한 곡괭이",
		"desc": "채굴 속도 +50%",
		"base_cost": 800.0,
		"mult": 4.0,
		"max": 5
	},
	"cart_speed": {
		"name": "미끄러운 레일",
		"desc": "수레 속도 +50%",
		"base_cost": 1200.0,
		"mult": 4.0,
		"max": 5
	},
	"cart_capacity": {
		"name": "행운",
		"desc": "",
		"prices": [10000000.0, 30000000.0, 100000000.0],
		"max": 3
	},
	"extra_miners": {
		"name": "광부 추가",
		"desc": "",
		"base_cost": 195313.0,
		"mult": 4.0,
		"max": 5
	},
}

func _ready() -> void:
	chest_ore.resize(MAX_MINERS)
	for i in chest_ore.size():
		chest_ore[i] = {}

func get_hire_cost() -> float:
	if total_miners >= HIRE_COSTS.size():
		return INF
	return HIRE_COSTS[total_miners]

func can_hire() -> bool:
	return money >= get_hire_cost() and total_miners < MAX_MINERS

func hire() -> bool:
	if not can_hire():
		return false
	money -= get_hire_cost()
	total_miners += 1
	money_changed.emit(money)
	ui_refresh_needed.emit()
	return true

func get_mine_duration(ore_value: float) -> float:
	# 2.0s at value=5 (돌), 6.0s at value=80000 (다이아), ~3x ratio
	var base: float = 1.335 + log(ore_value) * 0.413
	return base / (1.0 + mining_speed_level * 0.5)

func get_cart_speed() -> float:
	return 120.0 * (1.0 + cart_speed_level * 0.5)

func get_miners_per_floor() -> int:
	return 1 + extra_miners_level

func get_ore_per_load() -> float:
	return LUCKY_MULTS[cart_capacity_level]

func add_to_chest(level_idx: int, ore_type_idx: int, amount: float = 1.0) -> void:
	chest_ore[level_idx][ore_type_idx] = chest_ore[level_idx].get(ore_type_idx, 0.0) + amount
	var total: float = 0.0
	for v in chest_ore[level_idx].values():
		total += v
	chest_changed.emit(level_idx, total)

func collect_chest(level_idx: int) -> Dictionary:
	var result: Dictionary = chest_ore[level_idx].duplicate()
	chest_ore[level_idx].clear()
	chest_changed.emit(level_idx, 0.0)
	return result

func add_surface_ore(ore_type_idx: int, amount: float) -> void:
	surface_ore[ore_type_idx] = surface_ore.get(ore_type_idx, 0.0) + amount
	surface_ore_changed.emit()

func sell_one_ore(ore_type_idx: int, levels_data: Array) -> void:
	if not surface_ore.has(ore_type_idx) or surface_ore[ore_type_idx] <= 0.0:
		return
	var value: float = levels_data[ore_type_idx].value
	surface_ore[ore_type_idx] -= 1.0
	if surface_ore[ore_type_idx] <= 0.0:
		surface_ore.erase(ore_type_idx)
	surface_ore_changed.emit()
	deposit_value(value)

func sell_all_of_ore(ore_type_idx: int, levels_data: Array) -> void:
	if not surface_ore.has(ore_type_idx):
		return
	var value: float = surface_ore[ore_type_idx] * levels_data[ore_type_idx].value
	surface_ore.erase(ore_type_idx)
	surface_ore_changed.emit()
	if value > 0.0:
		deposit_value(value)

func sell_all_surface_ore(levels_data: Array) -> void:
	var total: float = 0.0
	for ore_idx in surface_ore:
		total += surface_ore[ore_idx] * levels_data[ore_idx].value
	surface_ore.clear()
	surface_ore_changed.emit()
	if total > 0.0:
		deposit_value(total)

func deposit_value(value: float) -> void:
	money += value
	money_changed.emit(money)

func upgrade_cost(id: String) -> float:
	var lvl: int = get(id + "_level")
	if UPGRADES[id].has("prices"):
		return UPGRADES[id].prices[lvl]
	return UPGRADES[id].base_cost * pow(UPGRADES[id].mult, lvl)

func can_upgrade(id: String) -> bool:
	var lvl: int = get(id + "_level")
	return money >= upgrade_cost(id) and lvl < UPGRADES[id].max

func purchase_upgrade(id: String) -> bool:
	if not can_upgrade(id):
		return false
	money -= upgrade_cost(id)
	set(id + "_level", get(id + "_level") + 1)
	money_changed.emit(money)
	ui_refresh_needed.emit()
	return true

func reset() -> void:
	money = START_MONEY
	total_miners = 0
	mining_speed_level = 0
	cart_speed_level = 0
	cart_capacity_level = 0
	extra_miners_level = 0
	for i in chest_ore.size():
		chest_ore[i].clear()
		chest_changed.emit(i, 0.0)
	surface_ore.clear()
	surface_ore_changed.emit()
	money_changed.emit(money)
	ui_refresh_needed.emit()
