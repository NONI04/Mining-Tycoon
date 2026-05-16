extends Node2D

const SURFACE_Y: float = 80.0
const MINER_X: float = 358.0
const CART_X: float = 402.0
const SHAFT_CENTER_X: float = 380.0
const MINE_WIDTH: float = 760.0
const MINE_TOTAL_HEIGHT: float = 1560.0
const LEVEL_SPACING: float = 65.0

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
var _hire_btn: Button
var _upgrade_btns: Dictionary = {}
var _chest_labels: Array = []
var _camera: Camera2D
var _cart_node: Node2D

func _ready() -> void:
	_build_mine()
	_build_ui()
	GameManager.money_changed.connect(_on_money_changed)
	GameManager.chest_changed.connect(_on_chest_changed)
	GameManager.ui_refresh_needed.connect(_refresh_ui)
	_refresh_ui()

func _process(delta: float) -> void:
	if _cart_node == null or _camera == null:
		return
	var target_y: float = clamp(_cart_node.position.y, 360.0, MINE_TOTAL_HEIGHT - 360.0)
	_camera.position.y = lerp(_camera.position.y, target_y, 4.0 * delta)

# ── Mine visual ────────────────────────────────────────────────

func _build_mine() -> void:
	var bg := ColorRect.new()
	bg.size = Vector2(MINE_WIDTH, MINE_TOTAL_HEIGHT)
	bg.color = Color(0.08, 0.05, 0.03)
	add_child(bg)

	# Surface platform
	_add_rect(Vector2(SHAFT_CENTER_X - 100.0, SURFACE_Y - 12.0),
			Vector2(200.0, 12.0), Color(0.50, 0.45, 0.35))
	_add_label("지상", Vector2(SHAFT_CENTER_X + 108.0, SURFACE_Y - 16.0), Color.WHITE)

	# Shaft walls (full depth)
	var shaft_height: float = MINE_TOTAL_HEIGHT - SURFACE_Y
	_add_rect(Vector2(SHAFT_CENTER_X - 44.0, SURFACE_Y), Vector2(6.0, shaft_height), Color(0.35, 0.28, 0.18))
	_add_rect(Vector2(SHAFT_CENTER_X + 38.0, SURFACE_Y), Vector2(6.0, shaft_height), Color(0.35, 0.28, 0.18))

	# Level platforms, chests, labels
	for i in LEVELS.size():
		var lvl: Dictionary = LEVELS[i]

		_add_rect(Vector2(SHAFT_CENTER_X - 180.0, lvl.y), Vector2(360.0, 8.0), lvl.color)

		var lbl_text: String = "%s  %s  ($%.0f)" % [lvl.name, lvl.ore_name, lvl.value]
		_add_label(lbl_text, Vector2(SHAFT_CENTER_X + 108.0, lvl.y - 4.0), Color.WHITE)

		# Chest box
		var cx: float = SHAFT_CENTER_X - 165.0
		var cy: float = lvl.y - 28.0
		_add_rect(Vector2(cx, cy), Vector2(30.0, 26.0), Color(0.40, 0.25, 0.10))
		_add_rect(Vector2(cx + 2.0, cy + 2.0), Vector2(26.0, 10.0), Color(0.55, 0.35, 0.15))

		# Ore count label
		var count_lbl := Label.new()
		count_lbl.text = "0"
		count_lbl.position = Vector2(cx, cy - 20.0)
		count_lbl.modulate = lvl.color * 1.6
		add_child(count_lbl)
		_chest_labels.append(count_lbl)

	# Camera
	_camera = Camera2D.new()
	_camera.position = Vector2(640.0, 360.0)
	add_child(_camera)
	_camera.make_current()

	# Single cart
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
	add_child(r)

func _add_label(text: String, pos: Vector2, color: Color) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.position = pos
	lbl.modulate = color
	add_child(lbl)

# ── UI panel ───────────────────────────────────────────────────

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

	_hire_btn = Button.new()
	_hire_btn.pressed.connect(_on_hire_pressed)
	vbox.add_child(_hire_btn)

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

# ── Hiring ─────────────────────────────────────────────────────

func _on_hire_pressed() -> void:
	if not GameManager.hire():
		return

	var idx: int = GameManager.total_miners - 1
	var lvl: Dictionary = LEVELS[idx]

	var miner := Node2D.new()
	miner.set_script(load("res://scripts/Miner.gd"))
	miner.position = Vector2(MINER_X, SURFACE_Y)
	miner.target_y = lvl.y
	miner.level_idx = idx
	add_child(miner)

# ── Callbacks ──────────────────────────────────────────────────

func _on_upgrade_pressed(id: String) -> void:
	GameManager.purchase_upgrade(id)

func _on_money_changed(amount: float) -> void:
	_money_label.text = "💰 $%.1f" % amount
	_hire_btn.disabled = not GameManager.can_hire()
	_refresh_upgrade_btns()

func _on_chest_changed(level_idx: int, amount: float) -> void:
	if level_idx < _chest_labels.size():
		_chest_labels[level_idx].text = "%.0f" % amount

func _refresh_ui() -> void:
	_money_label.text = "💰 $%.1f" % GameManager.money
	_miners_label.text = "👷 광부: %d / %d명" % [GameManager.total_miners, GameManager.MAX_MINERS]

	var next: int = GameManager.total_miners
	if next < LEVELS.size():
		var ore: String = LEVELS[next].ore_name
		_hire_btn.text = "광부 고용 → %d층 (%s)\n$%.0f" % [next + 1, ore, GameManager.get_hire_cost()]
	else:
		_hire_btn.text = "최대 광부 수 도달"

	_hire_btn.disabled = not GameManager.can_hire()
	_refresh_upgrade_btns()

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
