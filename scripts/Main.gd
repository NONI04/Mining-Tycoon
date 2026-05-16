extends Node2D

const SURFACE_Y: float = 90.0
const MINER_X: float = 358.0
const CART_X: float = 402.0
const SHAFT_CENTER_X: float = 380.0
const MINE_WIDTH: float = 760.0

const LEVELS: Array = [
	{"name": "1층 - 돌",     "ore_name": "Stone", "y": 260.0, "color": Color(0.55, 0.55, 0.55)},
	{"name": "2층 - 석탄",   "ore_name": "Coal",  "y": 400.0, "color": Color(0.22, 0.22, 0.22)},
	{"name": "3층 - 철광석", "ore_name": "Iron",  "y": 540.0, "color": Color(0.75, 0.50, 0.30)},
]

var _money_label: Label
var _miners_label: Label
var _hire_btn: Button
var _upgrade_btns: Dictionary = {}
var _chest_labels: Array = []  # ore-count label per level

func _ready() -> void:
	_build_mine()
	_build_ui()
	GameManager.money_changed.connect(_on_money_changed)
	GameManager.chest_changed.connect(_on_chest_changed)
	GameManager.ui_refresh_needed.connect(_refresh_ui)
	_refresh_ui()

# ── Mine visual ────────────────────────────────────────────────

func _build_mine() -> void:
	# Background
	var bg = ColorRect.new()
	bg.size = Vector2(MINE_WIDTH, 720.0)
	bg.color = Color(0.08, 0.05, 0.03)
	add_child(bg)

	# Surface platform
	_add_rect(Vector2(SHAFT_CENTER_X - 100.0, SURFACE_Y - 12.0),
			Vector2(200.0, 12.0), Color(0.50, 0.45, 0.35))
	_add_label("지상", Vector2(SHAFT_CENTER_X + 108.0, SURFACE_Y - 16.0), Color.WHITE)

	# Shaft walls
	_add_rect(Vector2(SHAFT_CENTER_X - 44.0, SURFACE_Y), Vector2(6.0, 620.0), Color(0.35, 0.28, 0.18))
	_add_rect(Vector2(SHAFT_CENTER_X + 38.0, SURFACE_Y), Vector2(6.0, 620.0), Color(0.35, 0.28, 0.18))

	# Level platforms, chests, and chest labels
	for i in LEVELS.size():
		var lvl: Dictionary = LEVELS[i]

		# Platform
		_add_rect(Vector2(SHAFT_CENTER_X - 180.0, lvl.y),
				Vector2(360.0, 10.0), lvl.color)
		_add_label(lvl.name, Vector2(SHAFT_CENTER_X + 108.0, lvl.y - 4.0), Color.WHITE)

		# Chest box (left side of shaft)
		var chest_pos := Vector2(SHAFT_CENTER_X - 165.0, lvl.y - 28.0)
		_add_rect(chest_pos, Vector2(30.0, 26.0), Color(0.40, 0.25, 0.10))
		_add_rect(chest_pos + Vector2(2.0, 2.0), Vector2(26.0, 10.0), Color(0.55, 0.35, 0.15))

		# Ore count label above the chest
		var count_lbl := Label.new()
		count_lbl.text = "0"
		count_lbl.position = Vector2(chest_pos.x, chest_pos.y - 22.0)
		count_lbl.modulate = lvl.color * 1.6
		add_child(count_lbl)
		_chest_labels.append(count_lbl)

	# Single cart (created once, cycles through all levels)
	var cart := Node2D.new()
	cart.set_script(load("res://scripts/MineCart.gd"))
	cart.position = Vector2(CART_X, SURFACE_Y)
	cart.surface_y = SURFACE_Y
	cart.levels_data = LEVELS
	add_child(cart)

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
	var lvl: Dictionary = LEVELS[idx % LEVELS.size()]

	var miner := Node2D.new()
	miner.set_script(load("res://scripts/Miner.gd"))
	miner.position = Vector2(MINER_X, SURFACE_Y)
	miner.target_y = lvl.y
	miner.level_idx = idx % LEVELS.size()
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
	_miners_label.text = "👷 광부: %d명 / %d명" % [GameManager.total_miners, GameManager.MAX_MINERS]
	_hire_btn.text = "광부 고용  $%.0f" % GameManager.get_hire_cost()
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
