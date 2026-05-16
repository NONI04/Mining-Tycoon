extends Node2D

enum State { GOING_TO_LEVEL, COLLECTING, ASCENDING, UNLOADING }

var state: State = State.GOING_TO_LEVEL
var surface_y: float = 0.0
var levels_data: Array = []

var _target_level: int = 0
var _collected: Array = []
var _collect_timer: float = 0.0
var _unload_timer: float = 0.0

var _body: ColorRect
var _ore_rect: ColorRect

func _ready() -> void:
	_collected.resize(levels_data.size())
	_collected.fill(0.0)

	_body = ColorRect.new()
	_body.size = Vector2(28, 16)
	_body.position = Vector2(-14, -16)
	_body.color = Color(0.45, 0.30, 0.15)
	add_child(_body)

	_ore_rect = ColorRect.new()
	_ore_rect.size = Vector2(22, 8)
	_ore_rect.position = Vector2(-11, -14)
	_ore_rect.color = Color(0.85, 0.75, 0.30)
	_ore_rect.visible = false
	add_child(_ore_rect)

func _process(delta: float) -> void:
	var spd: float = GameManager.get_cart_speed()
	var active: int = GameManager.total_miners

	match state:
		State.GOING_TO_LEVEL:
			if active == 0 or _target_level >= active:
				state = State.ASCENDING
				return
			var ty: float = levels_data[_target_level].y
			position.y = move_toward(position.y, ty, spd * delta)
			if abs(position.y - ty) < 1.0:
				position.y = ty
				_collect_timer = 0.0
				state = State.COLLECTING

		State.COLLECTING:
			_collect_timer += delta
			if _collect_timer >= 0.25:
				var amount: float = GameManager.collect_chest(_target_level)
				_collected[_target_level] += amount
				_ore_rect.visible = _has_ore()

				if _target_level < active - 1:
					_target_level += 1
					state = State.GOING_TO_LEVEL
				else:
					state = State.ASCENDING

		State.ASCENDING:
			position.y = move_toward(position.y, surface_y, spd * delta)
			if abs(position.y - surface_y) < 1.0:
				position.y = surface_y
				_deposit_all()
				_ore_rect.visible = false
				_unload_timer = 0.0
				state = State.UNLOADING

		State.UNLOADING:
			_unload_timer += delta
			if _unload_timer >= 0.6:
				_target_level = 0
				_collected.fill(0.0)
				state = State.GOING_TO_LEVEL

func _deposit_all() -> void:
	var total_value: float = 0.0
	for i in _collected.size():
		if _collected[i] > 0.0:
			total_value += levels_data[i].value * _collected[i]
	if total_value > 0.0:
		GameManager.deposit_value(total_value)

func _has_ore() -> bool:
	for v in _collected:
		if v > 0.0:
			return true
	return false
