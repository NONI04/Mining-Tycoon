extends Node2D

enum State { DESCENDING, WAITING, ASCENDING, UNLOADING }

var state: State = State.DESCENDING
var surface_y: float = 0.0
var level_y: float = 0.0
var ore_name: String = ""
var linked_miner: Node2D = null

var _ore_carried: float = 0.0
var _unload_timer: float = 0.0
var _body: ColorRect
var _ore_rect: ColorRect

func _ready() -> void:
	_body = ColorRect.new()
	_body.size = Vector2(28, 16)
	_body.position = Vector2(-14, -16)
	_body.color = Color(0.45, 0.30, 0.15)
	add_child(_body)

	_ore_rect = ColorRect.new()
	_ore_rect.size = Vector2(22, 8)
	_ore_rect.position = Vector2(-11, -14)
	_ore_rect.visible = false
	add_child(_ore_rect)

	match ore_name:
		"Stone": _ore_rect.color = Color(0.55, 0.55, 0.55)
		"Coal":  _ore_rect.color = Color(0.22, 0.22, 0.22)
		"Iron":  _ore_rect.color = Color(0.75, 0.50, 0.30)

func _process(delta: float) -> void:
	var spd: float = GameManager.get_cart_speed()
	match state:
		State.DESCENDING:
			position.y = move_toward(position.y, level_y, spd * delta)
			if abs(position.y - level_y) < 1.0:
				position.y = level_y
				state = State.WAITING

		State.WAITING:
			if linked_miner != null and linked_miner.ore_pile > 0.0:
				_ore_carried = linked_miner.ore_pile
				linked_miner.ore_pile = 0.0
				_ore_rect.visible = true
				state = State.ASCENDING

		State.ASCENDING:
			position.y = move_toward(position.y, surface_y, spd * delta)
			if abs(position.y - surface_y) < 1.0:
				position.y = surface_y
				GameManager.deposit_ore(ore_name, _ore_carried)
				_ore_carried = 0.0
				_ore_rect.visible = false
				_unload_timer = 0.0
				state = State.UNLOADING

		State.UNLOADING:
			_unload_timer += delta
			if _unload_timer >= 0.5:
				state = State.DESCENDING
