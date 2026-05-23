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

const MAX_MINERS: int = 20
const HIRE_BASE_COST: float = 50.0

const UPGRADES: Dictionary = {
	"mining_speed": {
		"name": "강한 곡괭이",
		"desc": "채굴 속도 +50%",
		"base_cost": 120.0,
		"mult": 2.2,
		"max": 5
	},
	"cart_speed": {
		"name": "미끄러운 레일",
		"desc": "수레 속도 +50%",
		"base_cost": 180.0,
		"mult": 2.2,
		"max": 5
	},
	"cart_capacity": {
		"name": "큰 수레",
		"desc": "적재량 2배",
		"base_cost": 250.0,
		"mult": 2.5,
		"max": 5
	},
}

func _ready() -> void:
	chest_ore.resize(MAX_MINERS)
	for i in chest_ore.size():
		chest_ore[i] = {}

func get_hire_cost() -> float:
	return HIRE_BASE_COST * pow(1.8, total_miners)

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

func get_mine_duration() -> float:
	return 4.0 / (1.0 + mining_speed_level * 0.5)

func get_cart_speed() -> float:
	return 120.0 * (1.0 + cart_speed_level * 0.5)

func get_ore_per_load() -> float:
	return pow(2.0, cart_capacity_level)

func add_to_chest(level_idx: int, ore_type_idx: int) -> void:
	chest_ore[level_idx][ore_type_idx] = chest_ore[level_idx].get(ore_type_idx, 0) + 1
	var total: int = 0
	for v in chest_ore[level_idx].values():
		total += v
	chest_changed.emit(level_idx, float(total))

func collect_chest(level_idx: int) -> Dictionary:
	var result: Dictionary = chest_ore[level_idx].duplicate()
	chest_ore[level_idx].clear()
	chest_changed.emit(level_idx, 0.0)
	return result

func add_surface_ore(ore_type_idx: int, amount: float) -> void:
	surface_ore[ore_type_idx] = surface_ore.get(ore_type_idx, 0.0) + amount
	surface_ore_changed.emit()

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
	for i in chest_ore.size():
		chest_ore[i].clear()
		chest_changed.emit(i, 0.0)
	surface_ore.clear()
	surface_ore_changed.emit()
	money_changed.emit(money)
	ui_refresh_needed.emit()
