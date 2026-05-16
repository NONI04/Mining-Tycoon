extends Node2D

var money_label: Label
var depth_label: Label
var opc_label: Label
var auto_label: Label
var feedback_label: Label
var upgrade_buttons: Dictionary = {}

func _ready() -> void:
	_build_ui()
	GameManager.money_changed.connect(_on_money_changed)
	GameManager.depth_changed.connect(_on_depth_changed)
	GameManager.upgrade_purchased.connect(_on_upgrade_purchased)
	_refresh_upgrades()

func _build_ui() -> void:
	# Dark mine background
	var bg = ColorRect.new()
	bg.size = Vector2(1280, 720)
	bg.color = Color(0.09, 0.06, 0.03)
	add_child(bg)

	# ── Left panel: Stats ──────────────────────────────────────
	var stats_bg = PanelContainer.new()
	stats_bg.position = Vector2(20, 20)
	stats_bg.size = Vector2(260, 180)
	add_child(stats_bg)

	var stats = VBoxContainer.new()
	stats_bg.add_child(stats)

	var title = Label.new()
	title.text = "⛏  Mining Tycoon"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_child(title)

	stats.add_child(HSeparator.new())

	money_label = _make_label("💰 Money: $0")
	stats.add_child(money_label)

	depth_label = _make_label("📍 Depth: 1 m")
	stats.add_child(depth_label)

	opc_label = _make_label("🪨 Per click: x1")
	stats.add_child(opc_label)

	auto_label = _make_label("🤖 Auto: 0 /s")
	stats.add_child(auto_label)

	# ── Center: Mine button ────────────────────────────────────
	var mine_btn = Button.new()
	mine_btn.text = "⛏\nMINE!"
	mine_btn.position = Vector2(490, 220)
	mine_btn.size = Vector2(300, 220)
	mine_btn.pressed.connect(_on_mine_pressed)
	add_child(mine_btn)

	feedback_label = Label.new()
	feedback_label.position = Vector2(490, 460)
	feedback_label.size = Vector2(300, 40)
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(feedback_label)

	# ── Right panel: Upgrades ──────────────────────────────────
	var upg_bg = PanelContainer.new()
	upg_bg.position = Vector2(1000, 20)
	upg_bg.size = Vector2(260, 400)
	add_child(upg_bg)

	var upg_box = VBoxContainer.new()
	upg_bg.add_child(upg_box)

	var upg_title = Label.new()
	upg_title.text = "🏪 Upgrades"
	upg_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	upg_box.add_child(upg_title)

	upg_box.add_child(HSeparator.new())

	for id in GameManager.upgrades:
		var btn = Button.new()
		btn.pressed.connect(_on_upgrade_pressed.bind(id))
		upg_box.add_child(btn)
		upgrade_buttons[id] = btn

func _make_label(text: String) -> Label:
	var lbl = Label.new()
	lbl.text = text
	return lbl

# ── Event handlers ─────────────────────────────────────────────

func _on_mine_pressed() -> void:
	var earned = GameManager.mine()
	feedback_label.text = "+$%.1f" % earned
	get_tree().create_timer(0.6).timeout.connect(func(): feedback_label.text = "")

func _on_upgrade_pressed(id: String) -> void:
	if GameManager.purchase_upgrade(id):
		_refresh_upgrades()

func _on_money_changed(amount: float) -> void:
	money_label.text = "💰 Money: $%.1f" % amount
	_refresh_upgrade_buttons()

func _on_depth_changed(new_depth: int) -> void:
	depth_label.text = "📍 Depth: %d m" % new_depth

func _on_upgrade_purchased(_id: String) -> void:
	opc_label.text = "🪨 Per click: x%.1f" % GameManager.ore_per_click
	auto_label.text = "🤖 Auto: %.1f /s" % GameManager.auto_mine_rate
	_refresh_upgrades()

# ── UI helpers ─────────────────────────────────────────────────

func _upgrade_text(id: String) -> String:
	var upg = GameManager.upgrades[id]
	var cost = GameManager.get_upgrade_cost(id)
	if upg.level >= upg.max_level:
		return "%s\nMAX LEVEL" % upg.name
	return "%s  Lv.%d/%d\n$%.0f  — %s" % [
		upg.name, upg.level, upg.max_level, cost, upg.description
	]

func _refresh_upgrades() -> void:
	for id in upgrade_buttons:
		upgrade_buttons[id].text = _upgrade_text(id)
	_refresh_upgrade_buttons()

func _refresh_upgrade_buttons() -> void:
	for id in upgrade_buttons:
		var upg = GameManager.upgrades[id]
		upgrade_buttons[id].disabled = not GameManager.can_afford(id) or upg.level >= upg.max_level
