extends Node2D

enum State { DESCENDING, MINING }

var state: State = State.DESCENDING
var target_y: float = 0.0
var level_idx: int = 0

var _mine_timer: float = 0.0
var _body: ColorRect
var _hat: ColorRect
var _pickaxe_pivot: Node2D

const SWING_STRIKE: float = 0.18   # 오른→왼 빠르게
const SWING_RETURN: float = 0.38   # 왼→오른 천천히
const SWING_TOTAL:  float = SWING_STRIKE + SWING_RETURN

const ANGLE_RIGHT: float =  60.0   # 오른쪽 위 시작
const ANGLE_LEFT:  float = -60.0   # 왼쪽 위 끝 (타격)

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

	# 곡괭이 pivot (머리 위)
	_pickaxe_pivot = Node2D.new()
	_pickaxe_pivot.position = Vector2(2, -26)
	_pickaxe_pivot.rotation_degrees = ANGLE_RIGHT
	add_child(_pickaxe_pivot)

	# ⛏ 이모지 — pivot_offset으로 중심 기준 180° 회전해 위아래 보정
	var lbl := Label.new()
	lbl.text = "⛏"
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.position = Vector2(-8, -8)
	lbl.pivot_offset = Vector2(8, 8)
	lbl.scale = Vector2(-1, 1)
	_pickaxe_pivot.add_child(lbl)

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

	if cycle < SWING_STRIKE:
		# 빠르게 오른쪽→왼쪽 (타격)
		var p := cycle / SWING_STRIKE
		angle = lerpf(ANGLE_RIGHT, ANGLE_LEFT, ease(p, 2.0))
	else:
		# 천천히 왼쪽→오른쪽 (복귀)
		var p := (cycle - SWING_STRIKE) / SWING_RETURN
		angle = lerpf(ANGLE_LEFT, ANGLE_RIGHT, ease(p, 0.4))

	_pickaxe_pivot.rotation_degrees = angle

	# 스윙 방향으로 몸통 살짝 기울기
	var lean := (ANGLE_RIGHT - angle) / (ANGLE_RIGHT - ANGLE_LEFT)
	_body.position.x = -7.0 + (lean - 0.5) * 2.0
