extends Node2D

enum State { DESCENDING, MINING }

var state: State = State.DESCENDING
var target_y: float = 0.0
var level_idx: int = 0

var _mine_timer: float = 0.0
var _body: ColorRect
var _hat: ColorRect

func _ready() -> void:
	_body = ColorRect.new()
	_body.size = Vector2(14, 22)
	_body.position = Vector2(-7, -22)
	_body.color = Color(0.85, 0.65, 0.45)
	add_child(_body)

	_hat = ColorRect.new()
	_hat.size = Vector2(16, 7)
	_hat.position = Vector2(-8, -29)
	_hat.color = Color(1.0, 0.85, 0.0)
	add_child(_hat)

func _process(delta: float) -> void:
	match state:
		State.DESCENDING:
			position.y = move_toward(position.y, target_y, 90.0 * delta)
			if abs(position.y - target_y) < 1.0:
				position.y = target_y
				state = State.MINING

		State.MINING:
			_mine_timer += delta
			_body.position.x = -7.0 + sin(_mine_timer * 14.0) * 2.5
			if _mine_timer >= GameManager.get_mine_duration():
				_mine_timer = 0.0
				_body.position.x = -7.0
				GameManager.add_to_chest(level_idx, GameManager.get_ore_per_load())
