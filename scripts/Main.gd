extends Node2D

const SURFACE_Y: float = 80.0
const MINER_X: float = 155.0
const CART_X: float = 495.0
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
var _upgrade_btns: Dictionary = {}
var _chest_labels: Array = []
var _camera: Camera2D
var _cart_node: Node2D
var _miners: Array = []
var _surface_table: VBoxContainer
var _floor_containers: Array = []
var _hold_ore_idx: int = -1
var _hold_timer: float = 0.0
var _prev_extra_miners_level: int = 0

# 세계 공간 커스텀 버튼
var _btn_bgs:        Array = []   # ColorRect
var _btn_lbls:       Array = []   # Label (아이콘 전용)
var _btn_rects:      Array = []   # Rect2 (클릭 감지용)
var _btn_price_lbls: Array = []   # Label (고용 비용)

func _process(delta: float) -> void:
	var i: int = GameManager.total_miners
	if i < _btn_rects.size():
		var world_pos := get_viewport().canvas_transform.affine_inverse() * get_viewport().get_mouse_position()
		var hovering: bool = _btn_rects[i].has_point(world_pos)
		var base: Color = C_AVAILABLE if GameManager.can_hire() else C_TOO_POOR
		_btn_bgs[i].color = base.darkened(0.4) if hovering else base

	if _hold_ore_idx >= 0:
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_hold_ore_idx = -1
		else:
			_hold_timer -= delta
			if _hold_timer <= 0.0:
				_hold_timer += 0.08
				GameManager.sell_one_ore(_hold_ore_idx, LEVELS)

func _ready() -> void:
	_setup_fonts()
	_build_mine()
	_build_ui()
	GameManager.money_changed.connect(_on_money_changed)
	GameManager.chest_changed.connect(_on_chest_changed)
	GameManager.ui_refresh_needed.connect(_refresh_ui)
	GameManager.surface_ore_changed.connect(_refresh_surface_table)
	_refresh_ui()
	_refresh_surface_table()

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
			if get_viewport().get_mouse_position().x < 760.0:
				_camera.position.y = clamp(
					_camera.position.y + SCROLL_SPEED, 360.0, MINE_TOTAL_HEIGHT - 360.0)
		MOUSE_BUTTON_WHEEL_UP:
			if get_viewport().get_mouse_position().x < 760.0:
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

func _spawn_miner(floor_idx: int, slot: int) -> Node2D:
	var lvl: Dictionary = LEVELS[floor_idx]
	var miner := Node2D.new()
	miner.set_script(load("res://scripts/Miner.gd"))
	miner.position = Vector2(MINER_X + slot * 46, lvl.y)
	miner.level_idx = floor_idx
	miner.levels_data = LEVELS
	add_child(miner)
	return miner

func _try_unlock(i: int) -> void:
	if i != GameManager.total_miners:
		return
	if not GameManager.hire():
		return
	var floor_miners: Array = []
	for slot in GameManager.get_miners_per_floor():
		floor_miners.append(_spawn_miner(i, slot))
	_miners.append(floor_miners)
	_refresh_level_btns()

# ── 광산 시각 요소 ─────────────────────────────────────────────

func _build_mine() -> void:
	var bg := ColorRect.new()
	bg.size = Vector2(MINE_WIDTH, MINE_TOTAL_HEIGHT)
	bg.color = Color(0.08, 0.05, 0.03)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var surface_right: float = BTN_X + BTN_W
	var surface_half: float = surface_right - SHAFT_CENTER_X
	_add_rect(Vector2(SHAFT_CENTER_X - surface_half, SURFACE_Y - 12.0),
			Vector2(surface_half * 2.0, 12.0), Color(0.50, 0.45, 0.35))
	_add_label("지상", Vector2(surface_right + 4.0, SURFACE_Y - 16.0), Color.WHITE)

	var shaft_h: float = MINE_TOTAL_HEIGHT - SURFACE_Y

	for i in LEVELS.size():
		var lvl: Dictionary = LEVELS[i]
		var ly: float = lvl.y

		var floor_node := Node2D.new()
		add_child(floor_node)
		_floor_containers.append(floor_node)

		# 플랫폼
		var platform := ColorRect.new()
		platform.position = Vector2(135.0, ly)
		platform.size = Vector2(385.0, 8.0)
		platform.color = lvl.color
		platform.mouse_filter = Control.MOUSE_FILTER_IGNORE
		floor_node.add_child(platform)

		# 광물 정보 라벨 — 왼쪽 바깥
		var info_lbl := Label.new()
		info_lbl.text = "%s %s\n$%.0f" % [lvl.name, lvl.ore_name, lvl.value]
		info_lbl.position = Vector2(5.0, ly - 26.0)
		info_lbl.modulate = lvl.color * 1.5
		info_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		floor_node.add_child(info_lbl)

		# 상자
		var cx: float = 442.0
		var cy: float = ly - 26.0
		var chest_outer := ColorRect.new()
		chest_outer.position = Vector2(cx, cy)
		chest_outer.size = Vector2(26.0, 26.0)
		chest_outer.color = Color(0.40, 0.25, 0.10)
		chest_outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		floor_node.add_child(chest_outer)
		var chest_inner := ColorRect.new()
		chest_inner.position = Vector2(cx + 2.0, cy + 2.0)
		chest_inner.size = Vector2(22.0, 9.0)
		chest_inner.color = Color(0.55, 0.35, 0.15)
		chest_inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		floor_node.add_child(chest_inner)

		var clbl := Label.new()
		clbl.text = "0"
		clbl.position = Vector2(cx + 2.0, cy + 10.0)
		clbl.modulate = lvl.color * 1.8
		clbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		floor_node.add_child(clbl)
		_chest_labels.append(clbl)

		# 해금 버튼
		var br := Rect2(Vector2(BTN_X, ly - BTN_H * 0.5), Vector2(BTN_W, BTN_H))
		_btn_rects.append(br)

		var btn_bg := ColorRect.new()
		btn_bg.position = br.position
		btn_bg.size = br.size
		btn_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		floor_node.add_child(btn_bg)
		_btn_bgs.append(btn_bg)

		var btn_lbl := Label.new()
		btn_lbl.position = br.position
		btn_lbl.size = br.size
		btn_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		btn_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		floor_node.add_child(btn_lbl)
		_btn_lbls.append(btn_lbl)

		var price_lbl := Label.new()
		price_lbl.position = Vector2(BTN_X + BTN_W + 4.0, ly - BTN_H * 0.5)
		price_lbl.size = Vector2(110.0, BTN_H)
		price_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		price_lbl.modulate = Color(1.0, 0.9, 0.3)
		price_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		price_lbl.visible = false
		floor_node.add_child(price_lbl)
		_btn_price_lbls.append(price_lbl)

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

	var dev_row := HBoxContainer.new()
	dev_row.position = Vector2(8.0, 8.0)
	ui.add_child(dev_row)

	var test_btn := Button.new()
	test_btn.text = "테스트"
	test_btn.add_theme_font_size_override("font_size", 11)
	test_btn.pressed.connect(_on_test_money_pressed)
	dev_row.add_child(test_btn)

	var reset_btn := Button.new()
	reset_btn.text = "리셋"
	reset_btn.add_theme_font_size_override("font_size", 11)
	reset_btn.pressed.connect(_on_reset_pressed)
	dev_row.add_child(reset_btn)

	var panel := ColorRect.new()
	panel.position = Vector2(760.0, 0.0)
	panel.size = Vector2(520.0, 720.0)
	panel.color = Color(0.12, 0.10, 0.08)
	ui.add_child(panel)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(760.0, 0.0)
	scroll.size = Vector2(520.0, 720.0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	ui.add_child(scroll)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "⛏  Mining Tycoon"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	vbox.add_child(HSeparator.new())

	_money_label = Label.new()
	vbox.add_child(_money_label)

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

	vbox.add_child(HSeparator.new())

	var storage_title := Label.new()
	storage_title.text = "지상 창고"
	storage_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(storage_title)

	var table_header := HBoxContainer.new()
	var th1 := Label.new()
	th1.text = "광물"
	th1.custom_minimum_size.x = 90
	var th2 := Label.new()
	th2.text = "개수"
	th2.custom_minimum_size.x = 70
	var th3 := Label.new()
	th3.text = "가격"
	th3.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	th3.custom_minimum_size.x = 80
	table_header.add_child(th1)
	table_header.add_child(th2)
	table_header.add_child(th3)
	vbox.add_child(table_header)
	vbox.add_child(HSeparator.new())

	_surface_table = VBoxContainer.new()
	vbox.add_child(_surface_table)

# ── 콜백 ───────────────────────────────────────────────────────

func _on_upgrade_pressed(id: String) -> void:
	GameManager.purchase_upgrade(id)

func _on_test_money_pressed() -> void:
	GameManager.deposit_value(100_000_000.0)

func _on_reset_pressed() -> void:
	for floor_miners in _miners:
		for miner in floor_miners:
			miner.queue_free()
	_miners.clear()
	_prev_extra_miners_level = 0
	_cart_node.reset()
	GameManager.reset()

func _on_money_changed(amount: float) -> void:
	_money_label.text = "💰 $" + _comma(amount)
	_refresh_upgrade_btns()
	_refresh_level_btns()

func _on_chest_changed(level_idx: int, amount: float) -> void:
	if level_idx < _chest_labels.size():
		_chest_labels[level_idx].text = "%.0f" % amount

func _refresh_ui() -> void:
	_money_label.text = "💰 $" + _comma(GameManager.money)
	_refresh_upgrade_btns()
	_refresh_level_btns()
	_refresh_surface_table()
	_refresh_floor_visibility()
	var new_level: int = GameManager.extra_miners_level
	if new_level > _prev_extra_miners_level:
		for floor_idx in _miners.size():
			for slot in range(_prev_extra_miners_level + 1, new_level + 1):
				_miners[floor_idx].append(_spawn_miner(floor_idx, slot))
		_prev_extra_miners_level = new_level

func _refresh_level_btns() -> void:
	var unlocked: int = GameManager.total_miners
	for i in _btn_bgs.size():
		var bg: ColorRect  = _btn_bgs[i]
		var lbl: Label     = _btn_lbls[i]
		var plbl: Label    = _btn_price_lbls[i]
		if i < unlocked:
			bg.color = C_UNLOCKED
			lbl.text = "⛏"
			plbl.visible = false
		elif i == unlocked:
			bg.color = C_AVAILABLE if GameManager.can_hire() else C_TOO_POOR
			lbl.text = "🔓"
			plbl.text = "$" + _comma(GameManager.get_hire_cost())
			plbl.visible = true
		else:
			bg.color = C_LOCKED
			lbl.text = "🔒"
			plbl.visible = false

func _refresh_floor_visibility() -> void:
	var next: int = GameManager.total_miners
	for i in _floor_containers.size():
		_floor_containers[i].visible = i <= next

func _make_btn(text: String, color: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	for pair in [["normal", 0.0], ["hover", 0.4], ["pressed", 0.55]]:
		var s := StyleBoxFlat.new()
		s.bg_color = color.darkened(pair[1])
		s.set_corner_radius_all(3)
		s.content_margin_left = 5; s.content_margin_right = 5
		s.content_margin_top = 2;  s.content_margin_bottom = 2
		btn.add_theme_stylebox_override(pair[0], s)
	return btn

func _refresh_surface_table() -> void:
	for child in _surface_table.get_children():
		child.queue_free()
	var unlocked: int = GameManager.total_miners
	if unlocked == 0:
		var empty := Label.new()
		empty.text = "(비어있음)"
		empty.modulate = Color(0.6, 0.6, 0.6)
		_surface_table.add_child(empty)
		return
	for i in unlocked:
		var ore_idx := i
		var lvl: Dictionary = LEVELS[ore_idx]
		var count: float = GameManager.surface_ore.get(ore_idx, 0.0)
		var row := HBoxContainer.new()

		var lbl_name := Label.new()
		lbl_name.text = lvl.ore_name
		lbl_name.custom_minimum_size.x = 90
		lbl_name.modulate = lvl.color * 1.8

		var lbl_count := Label.new()
		lbl_count.text = "x" + _comma(count)
		lbl_count.custom_minimum_size.x = 70

		var lbl_value := Label.new()
		lbl_value.text = "$" + _comma(count * lvl.value)
		lbl_value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl_value.custom_minimum_size.x = 80

		var price_gap := Control.new()
		price_gap.custom_minimum_size.x = 8

		var btn_one := _make_btn("1개 판매", Color(0.20, 0.40, 0.65))
		btn_one.button_down.connect(func():
			_hold_ore_idx = ore_idx
			_hold_timer = 0.35
			GameManager.sell_one_ore(ore_idx, LEVELS))

		var btn_all := _make_btn("전체 판매", Color(0.15, 0.48, 0.15))
		btn_all.pressed.connect(func(): GameManager.sell_all_of_ore(ore_idx, LEVELS))

		row.add_child(lbl_name)
		row.add_child(lbl_count)
		row.add_child(lbl_value)
		row.add_child(price_gap)
		row.add_child(btn_one)
		row.add_child(btn_all)
		_surface_table.add_child(row)
		_surface_table.add_child(HSeparator.new())

	var total: float = 0.0
	for ore_idx in GameManager.surface_ore:
		total += GameManager.surface_ore[ore_idx] * LEVELS[ore_idx].value

	var total_row := HBoxContainer.new()
	var total_lbl := Label.new()
	total_lbl.text = "총 가격"
	total_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var total_val := Label.new()
	total_val.text = "$" + _comma(total)
	total_val.modulate = Color(1.0, 0.9, 0.3)
	total_row.add_child(total_lbl)
	total_row.add_child(total_val)
	_surface_table.add_child(total_row)

	var sell_all_btn := _make_btn("모든 광물 판매", Color(0.55, 0.18, 0.18))
	sell_all_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sell_all_btn.pressed.connect(func(): GameManager.sell_all_surface_ore(LEVELS))
	_surface_table.add_child(sell_all_btn)

func _get_upgrade_effect_desc(id: String, next_lvl: int) -> String:
	if id == "cart_capacity":
		var m: float = GameManager.LUCKY_MULTS[next_lvl]
		if m == float(int(m)):
			return "처음 채굴량의 %d배" % int(m)
		return "처음 채굴량의 %.1f배" % m
	if id == "extra_miners":
		return "층당 광부 총 %d명" % (next_lvl + 1)
	var pct: int = next_lvl * 50
	if id == "mining_speed":
		return "처음 대비 채굴 속도 +%d%%" % pct
	return "처음 대비 수레 속도 +%d%%" % pct

func _refresh_upgrade_btns() -> void:
	for id in _upgrade_btns:
		var upg: Dictionary = GameManager.UPGRADES[id]
		var lvl: int = GameManager.get(id + "_level")
		var btn: Button = _upgrade_btns[id]
		if lvl >= upg.max:
			var desc: String = _get_upgrade_effect_desc(id, lvl)
			btn.text = "%s  [MAX]\n%s" % [upg.name, desc]
			btn.disabled = true
		else:
			var desc: String = _get_upgrade_effect_desc(id, lvl + 1)
			btn.text = "%s  Lv.%d  $%s\n%s" % [upg.name, lvl, _comma(GameManager.upgrade_cost(id)), desc]
			btn.disabled = not GameManager.can_upgrade(id)

func _comma(n: float) -> String:
	var s := "%.0f" % n
	var result := ""
	var length := s.length()
	for i in range(length):
		if i > 0 and (length - i) % 3 == 0:
			result += ","
		result += s[i]
	return result
