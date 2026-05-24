extends Node2D

var level_idx: int = 0
var levels_data: Array = []

var _mine_timer: float = 0.0
var _current_ore_idx: int = 0
var _body: ColorRect
var _hat: ColorRect
var _pickaxe_pivot: Node2D

# 스윙 비율: 전체 채굴 주기 중 오른→왼 비율 (나머지는 왼→오른)
const STRIKE_FRAC: float = 0.68

const ANGLE_RIGHT: float = -60.0
const ANGLE_LEFT:  float =  60.0

func _ready() -> void:
	# 몸통
	_body = ColorRect.new()
	_body.size = Vector2(14, 22)
	_body.position = Vector2(-7, -22)
	_body.color = Color(0.85, 0.65, 0.45)
	add_child(_body)

	# 안전모
	_hat = ColorRect.new()
	_hat.size = Vector2(16, 7)
	_hat.position = Vector2(-8, -29)
	_hat.color = Color(1.0, 0.85, 0.0)
	add_child(_hat)

	# 곡괭이 pivot — 손 위치(어깨 높이)
	# 이모지를 피벗 위쪽에 배치해 금속 머리가 위에서 호를 그리게 함
	_pickaxe_pivot = Node2D.new()
	_pickaxe_pivot.position = Vector2(0, -16)
	_pickaxe_pivot.rotation_degrees = ANGLE_RIGHT
	add_child(_pickaxe_pivot)

	var lbl := Label.new()
	lbl.text = "⛏"
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.position = Vector2(-8, -22)  # 피벗 위쪽에 배치
	lbl.pivot_offset = Vector2(8, 8)
	lbl.scale = Vector2(-1, 1)
	_pickaxe_pivot.add_child(lbl)
	_current_ore_idx = _pick_ore_index()

func _process(delta: float) -> void:
	var duration: float = GameManager.get_mine_duration(levels_data[_current_ore_idx].value)
	_mine_timer += delta
	_animate_pickaxe(_mine_timer, duration)
	if _mine_timer >= duration:
		_mine_timer -= duration
		GameManager.add_to_chest(level_idx, _current_ore_idx, GameManager.get_ore_per_load())
		_show_ore_popup(_current_ore_idx)
		_current_ore_idx = _pick_ore_index()

func _show_ore_popup(ore_idx: int) -> void:
	var lbl := Label.new()
	lbl.text = levels_data[ore_idx].icon + " " + levels_data[ore_idx].ore_name
	lbl.modulate = levels_data[ore_idx].color * 2.0
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.position = Vector2(-18, -46)
	add_child(lbl)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(lbl, "position:y", lbl.position.y - 30.0, 1.0)
	tween.tween_property(lbl, "modulate:a", 0.0, 1.0)
	tween.finished.connect(lbl.queue_free)

func _pick_ore_index() -> int:
	var total_weight: float = 0.0
	for i in range(level_idx + 1):
		total_weight += levels_data[i].value
	var r: float = randf() * total_weight
	var cumulative: float = 0.0
	for i in range(level_idx + 1):
		cumulative += levels_data[i].value
		if r <= cumulative:
			return i
	return level_idx

func _animate_pickaxe(t: float, duration: float) -> void:
	var cycle: float = fmod(t, duration)
	var strike_end: float = duration * STRIKE_FRAC
	var angle: float

	if cycle < strike_end:
		var p := cycle / strike_end
		angle = lerpf(ANGLE_RIGHT, ANGLE_LEFT, ease(p, 2.0))
	else:
		var p := (cycle - strike_end) / (duration - strike_end)
		angle = lerpf(ANGLE_LEFT, ANGLE_RIGHT, ease(p, 0.4))

	_pickaxe_pivot.rotation_degrees = angle

	# 스윙 방향으로 몸통 살짝 기울기
	var lean := (ANGLE_RIGHT - angle) / (ANGLE_RIGHT - ANGLE_LEFT)
	_body.position.x = -7.0 + (lean - 0.5) * 2.0
