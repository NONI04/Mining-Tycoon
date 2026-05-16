extends Node2D

const SURFACE_Y: float = 80.0
const MINER_X: float = 358.0
const CART_X: float = 402.0
const SHAFT_CENTER_X: float = 380.0
const MINE_WIDTH: float = 760.0
const MINE_TOTAL_HEIGHT: float = 1560.0
const SCROLL_SPEED: float = 60.0

# 오른쪽 바깥 버튼 (정사각형)
const BTN_X: float = 610.0
const BTN_W: float = 30.0
const BTN_H: float = 30.0

const C_UNLOCKED  := Color(0.12, 0.28, 0.12)
const C_AVAILABLE := Color(0.15, 0.48, 0.15)
const C_TOO_POOR  := Color(0.32, 0.18, 0.08)
const C_LOCKED    := Color(0.16, 0.16, 0.16)

const LEVELS: Array = [
	{"name": "1층",  "ore_name": "돌",        "y": 190.0,  "color": Color(0.55, 0.55, 0.55), "value": 5.0},
	{"name": "2층",  "ore_name": "석탄",      "y": 255.0,  "color": Color(0.22, 0.22, 0.22), "value": 12.0},
	{"name": "3층",  "ore_name": "구리",      "y": 320.0,  "color": Color(0.80, 0.45, 0.20), "value": 25.0},
	{"name": "4층",  "ore_name": "주석",      "y": 385.0,  "color": Color(0.70, 0.72, 0.73), "value": 45.0},
	{"name": "5층",  "ore_name": "철",        "y": 450.0,  "color": Color(0.72, 0.50, 0.38), "value": 80.0},
	{"name": "6층",  "ore_name": "납",        "y": 515.0,  "color": Color(0.40, 0.42, 0.48), "value": 130.0},
	{"name": "7층",  "ore_name": "아연",      "y": 580.0,  "color": Color(0.75, 0.80, 0.78), "value": 200.0},
	{"name": "8층",  "ore_name": "크롬",      "y": 645.0,  "color": Color(0.82, 0.86, 0.86), "value": 320.0},
	{"name": "9층",  "ore_name": "니켈",      "y": 710.0,  "color": Color(0.68, 0.80, 0.65), "value": 500.0},
	{"name": "10층", "ore_name": "은",        "y": 775.0,  "color": Color(0.90, 0.92, 0.95), "value": 800.0},
	{"name": "11층", "ore_name": "망간",      "y": 840.0,  "color": Color(0.78, 0.40, 0.58), "value": 1200.0},
	{"name": "12층", "ore_name": "코발트",    "y": 905.0,  "color": Color(0.20, 0.40, 0.85), "value": 1900.0},
	{"name": "13층", "ore_name": "텅스텐",    "y": 970.0,  "color": Color(0.38, 0.40, 0.48), "value": 3000.0},
	{"name": "14층", "ore_name": "티타늄",    "y": 1035.0, "color": Color(0.60, 0.72, 0.85), "value": 5000.0},
	{"name": "15층", "ore_name": "금",        "y": 1100.0, "color": Color(1.00, 0.82, 0.00), "value": 8000.0},
	{"name": "16층", "ore_name": "백금",      "y": 1165.0, "color": Color(0.92, 0.95, 1.00), "value": 13000.0},
	{"name": "17층", "ore_name": "루비",      "y": 1230.0, "color": Color(0.90, 0.10, 0.18), "value": 20000.0},
	{"name": "18층", "ore_name": "에메랄드",  "y": 1295.0, "color": Color(0.08, 0.80, 0.30), "value": 30000.0},
	{"name": "19층", "ore_name": "사파이어",  "y": 1360.0, "color": Color(0.10, 0.35, 0.92), "value": 50000.0},
	{"name": "20층", "ore_name": "다이아몬드","y": 1425.0, "color": Color(0.70, 0.95, 1.00), "value": 80000.0},
]

var _money_label: Label
var _miners_label: Label
var _upgrade_btns: Dictionary = {}
var _chest_labels: Array = []
var _camera: Camera2D
var _cart_node: Node2D

# 세계 공간 커스텀 버튼
var _btn_bgs:   Array = []   # ColorRect
var _btn_lbls:  Array = []   # Label (아이콘 전용)
var _btn_rects: Array = []   # Rect2 (클릭 감지용)

func _ready() -> void:
	_setup_fonts()
	_build_mine()
	_build_ui()
	GameManager.money_changed.connect(_on_money_changed)
	GameManager.chest_changed.connect(_on_chest_changed)
	GameManager.ui_refresh_needed.connect(_refresh_ui)
	_refresh_ui()

func _setup_fonts() -> void:
	var kr_font: FontFile = load("res://fonts/NotoSansKR.ttf")
	var sym_font: FontFile = load("res://fonts/NotoSansSymbols2.ttf")
	kr_font.fallbacks = [sym_font]
	var theme := Theme.new()
	theme.default_font = kr_font
	theme.default_font_size = 14
	get_tree().root.theme = theme

# ── 입력 ───────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	match event.button_index:
		MOUSE_BUTTON_WHEEL_DOWN:
			_camera.position.y = clamp(
				_camera.position.y + SCROLL_SPEED, 360.0, MINE_TOTAL_HEIGHT - 360.0)
		MOUSE_BUTTON_WHEEL_UP:
			_camera.position.y = clamp(
				_camera.position.y - SCROLL_SPEED, 360.0, MINE_TOTAL_HEIGHT - 360.0)
		MOUSE_BUTTON_LEFT:
			if event.pressed:
				_check_btn_click(event.position)

func _check_btn_click(screen_pos: Vector2) -> void:
	var world_pos := get_viewport().canvas_transform.affine_inverse() * screen_pos
	for i in _btn_rects.size():
		if _btn_rects[i].has_point(world_pos):
			_try_unlock(i)
			return

func _try_unlock(i: int) -> void:
	if i != GameManager.total_miners:
		return
	if not GameManager.hire():
		return
	var lvl: Dictionary = LEVELS[i]
	var miner := Node2D.new()
	miner.set_script(load("res://scripts/Miner.gd"))
	miner.position = Vector2(MINER_X, SURFACE_Y)
	miner.target_y = lvl.y
	miner.level_idx = i
	add_child(miner)
	_refresh_level_btns()

# ── 광산 시각 요소 ─────────────────────────────────────────────

func _build_mine() -> void:
	var bg := ColorRect.new()
	bg.size = Vector2(MINE_WIDTH, MINE_TOTAL_HEIGHT)
	bg.color = Color(0.08, 0.05, 0.03)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_add_rect(Vector2(SHAFT_CENTER_X - 100.0, SURFACE_Y - 12.0),
			Vector2(200.0, 12.0), Color(0.50, 0.45, 0.35))
	_add_label("지상", Vector2(SHAFT_CENTER_X + 108.0, SURFACE_Y - 16.0), Color.WHITE)

	var shaft_h: float = MINE_TOTAL_HEIGHT - SURFACE_Y
	_add_rect(Vector2(SHAFT_CENTER_X - 44.0, SURFACE_Y), Vector2(6.0, shaft_h), Color(0.35, 0.28, 0.18))
	_add_rect(Vector2(SHAFT_CENTER_X + 38.0, SURFACE_Y), Vector2(6.0, shaft_h), Color(0.35, 0.28, 0.18))

	for i in LEVELS.size():
		var lvl: Dictionary = LEVELS[i]
		var ly: float = lvl.y

		# 플랫폼
		_add_rect(Vector2(SHAFT_CENTER_X - 140.0, ly), Vector2(280.0, 8.0), lvl.color)

		# 광물 정보 라벨 — 왼쪽 바깥
		var info := "%s %s\n$%.0f" % [lvl.name, lvl.ore_name, lvl.value]
		_add_label(info, Vector2(5.0, ly - 26.0), lvl.color * 1.5)

		# 상자 — 플랫폼 위 (광부와 같은 높이)
		var cx: float = SHAFT_CENTER_X - 128.0
		var cy: float = ly - 26.0
		_add_rect(Vector2(cx, cy), Vector2(26.0, 26.0), Color(0.40, 0.25, 0.10))
		_add_rect(Vector2(cx + 2.0, cy + 2.0), Vector2(22.0, 9.0), Color(0.55, 0.35, 0.15))

		# 상자 수량 라벨
		var clbl := Label.new()
		clbl.text = "0"
		clbl.position = Vector2(cx + 2.0, cy + 10.0)
		clbl.modulate = lvl.color * 1.8
		clbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(clbl)
		_chest_labels.append(clbl)

		# 버튼 — 오른쪽 바깥 (텍스트 없음, 색상으로만 상태 표시)
		var br := Rect2(Vector2(BTN_X, ly - BTN_H * 0.5), Vector2(BTN_W, BTN_H))
		_btn_rects.append(br)

		var btn_bg := ColorRect.new()
		btn_bg.position = br.position
		btn_bg.size = br.size
		btn_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(btn_bg)
		_btn_bgs.append(btn_bg)

		var btn_lbl := Label.new()
		btn_lbl.position = br.position
		btn_lbl.size = br.size
		btn_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		btn_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(btn_lbl)
		_btn_lbls.append(btn_lbl)

	# 카메라
	_camera = Camera2D.new()
	_camera.position = Vector2(640.0, 360.0)
	add_child(_camera)
	_camera.make_current()

	# 수레 (1개)
	var cart := Node2D.new()
	cart.set_script(load("res://scripts/MineCart.gd"))
	cart.position = Vector2(CART_X, SURFACE_Y)
	cart.surface_y = SURFACE_Y
	cart.levels_data = LEVELS
	add_child(cart)
	_cart_node = cart

func _add_rect(pos: Vector2, size: Vector2, color: Color) -> void:
	var r := ColorRect.new()
	r.position = pos
	r.size = size
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)

func _add_label(text: String, pos: Vector2, color: Color) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.position = pos
	lbl.modulate = color
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lbl)

# ── UI 패널 ────────────────────────────────────────────────────

func _build_ui() -> void:
	var ui := CanvasLayer.new()
	add_child(ui)

	var panel := ColorRect.new()
	panel.position = Vector2(780.0, 0.0)
	panel.size = Vector2(500.0, 720.0)
	panel.color = Color(0.12, 0.10, 0.08)
	ui.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.position = Vector2(800.0, 20.0)
	vbox.size = Vector2(460.0, 680.0)
	ui.add_child(vbox)

	var title := Label.new()
	title.text = "⛏  Mining Tycoon"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	vbox.add_child(HSeparator.new())

	_money_label = Label.new()
	vbox.add_child(_money_label)

	_miners_label = Label.new()
	vbox.add_child(_miners_label)

	vbox.add_child(HSeparator.new())

	var upg_title := Label.new()
	upg_title.text = "업그레이드"
	upg_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(upg_title)

	for id in GameManager.UPGRADES:
		var btn := Button.new()
		btn.pressed.connect(_on_upgrade_pressed.bind(id))
		vbox.add_child(btn)
		_upgrade_btns[id] = btn

# ── 콜백 ───────────────────────────────────────────────────────

func _on_upgrade_pressed(id: String) -> void:
	GameManager.purchase_upgrade(id)

func _on_money_changed(amount: float) -> void:
	_money_label.text = "$ %.1f" % amount
	_refresh_upgrade_btns()
	_refresh_level_btns()

func _on_chest_changed(level_idx: int, amount: float) -> void:
	if level_idx < _chest_labels.size():
		_chest_labels[level_idx].text = "%.0f" % amount

func _refresh_ui() -> void:
	_money_label.text = "$ %.1f" % GameManager.money
	_miners_label.text = "광부: %d / %d명" % [GameManager.total_miners, GameManager.MAX_MINERS]
	_refresh_upgrade_btns()
	_refresh_level_btns()

func _refresh_level_btns() -> void:
	var unlocked: int = GameManager.total_miners
	for i in _btn_bgs.size():
		var bg: ColorRect = _btn_bgs[i]
		var lbl: Label    = _btn_lbls[i]
		if i < unlocked:
			bg.color = C_UNLOCKED
			lbl.text = "⛏"
		elif i == unlocked:
			bg.color = C_AVAILABLE if GameManager.can_hire() else C_TOO_POOR
			lbl.text = "+"
		else:
			bg.color = C_LOCKED
			lbl.text = "×"

func _refresh_upgrade_btns() -> void:
	for id in _upgrade_btns:
		var upg: Dictionary = GameManager.UPGRADES[id]
		var lvl: int = GameManager.get(id + "_level")
		var btn: Button = _upgrade_btns[id]
		if lvl >= upg.max:
			btn.text = "%s  [MAX]" % upg.name
			btn.disabled = true
		else:
			btn.text = "%s  Lv.%d  $%.0f\n%s" % [upg.name, lvl, GameManager.upgrade_cost(id), upg.desc]
			btn.disabled = not GameManager.can_upgrade(id)
