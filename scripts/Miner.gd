extends Node2D

enum State { DESCENDING, MINING }

var state: State = State.DESCENDING
var target_y: float = 0.0
var level_idx: int = 0

var _mine_timer: float = 0.0
var _body: ColorRect
var _hat: ColorRect
var _pickaxe_pivot: Node2D

const SWING_DOWN_DURATION: float = 0.18  # 빠른 내리기
const SWING_UP_DURATION:   float = 0.38  # 느린 올리기
const SWING_TOTAL:         float = SWING_DOWN_DURATION + SWING_UP_DURATION

const ANGLE_RAISED: float = -130.0  # 머리 위로 들어올린 각도
const ANGLE_HIT:    float =   20.0  # 아래로 내리찍는 각도

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

	# 곡괭이 pivot (머리 위 — 위에서 내려치는 모션)
	_pickaxe_pivot = Node2D.new()
	_pickaxe_pivot.position = Vector2(2, -26)
	_pickaxe_pivot.rotation_degrees = ANGLE_RAISED
	add_child(_pickaxe_pivot)

	# 곡괭이 이모지 (⛏ 아이콘)
	var pickaxe_lbl := Label.new()
	pickaxe_lbl.text = "⛏"
	pickaxe_lbl.add_theme_font_size_override("font_size", 16)
	pickaxe_lbl.position = Vector2(-8, -8)
	_pickaxe_pivot.add_child(pickaxe_lbl)

func _process(delta: float) -> void:
	match state:
		State.DESCENDING:
			position.y = move_toward(position.y, target_y, 90.0 * delta)
			if abs(position.y - target_y) < 1.0:
				position.y = target_y
				state = State.MINING

		State.MINING:
			_mine_timer += delta
			_animate_pickaxe(_mine_timer)

			if _mine_timer >= GameManager.get_mine_duration():
				_mine_timer = 0.0
				GameManager.add_to_chest(level_idx, GameManager.get_ore_per_load())

func _animate_pickaxe(t: float) -> void:
	var cycle: float = fmod(t, SWING_TOTAL)
	var angle: float

	if cycle < SWING_DOWN_DURATION:
		# 빠르게 내리찍기
		var p: float = cycle / SWING_DOWN_DURATION
		angle = lerpf(ANGLE_RAISED, ANGLE_HIT, ease(p, 2.0))
	else:
		# 천천히 들어올리기
		var p: float = (cycle - SWING_DOWN_DURATION) / SWING_UP_DURATION
		angle = lerpf(ANGLE_HIT, ANGLE_RAISED, ease(p, 0.4))

	_pickaxe_pivot.rotation_degrees = angle

	# 내리찍는 순간 살짝 앞으로 기울기
	var lean: float = (angle - ANGLE_RAISED) / (ANGLE_HIT - ANGLE_RAISED)
	_body.position.x = -7.0 + lean * 3.0
