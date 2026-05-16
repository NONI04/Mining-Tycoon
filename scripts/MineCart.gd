extends Node2D

# The single cart visits every level on the way down, collects ore from
# each chest, then ascends to the surface and deposits everything.

enum State { GOING_TO_LEVEL, COLLECTING, ASCENDING, UNLOADING }

var state: State = State.GOING_TO_LEVEL
var surface_y: float = 0.0
var levels_data: Array = []  # Array of {ore_name, y} — set before add_child

var _target_level: int = 0
var _collected: Array = []   # ore amount collected from each level
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
	_ore_rect.color = Color(0.85, 0.75, 0.30)  # gold tint when carrying
	_ore_rect.visible = false
	add_child(_ore_rect)

func _process(delta: float) -> void:
	var spd: float = GameManager.get_cart_speed()

	match state:
		State.GOING_TO_LEVEL:
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
				_update_ore_visual()

				if _target_level < levels_data.size() - 1:
					_target_level += 1
					state = State.GOING_TO_LEVEL
				else:
					state = State.ASCENDING

		State.ASCENDING:
			position.y = move_toward(position.y, surface_y, spd * delta)
			if abs(position.y - surface_y) < 1.0:
				position.y = surface_y
				_deposit_all()
				_unload_timer = 0.0
				state = State.UNLOADING

		State.UNLOADING:
			_unload_timer += delta
			if _unload_timer >= 0.6:
				_target_level = 0
				_collected.fill(0.0)
				_ore_rect.visible = false
				state = State.GOING_TO_LEVEL

func _deposit_all() -> void:
	for i in _collected.size():
		if _collected[i] > 0.0:
			GameManager.deposit_ore(levels_data[i].ore_name, _collected[i])

func _update_ore_visual() -> void:
	var total: float = 0.0
	for v in _collected:
		total += v
	_ore_rect.visible = total > 0.0
