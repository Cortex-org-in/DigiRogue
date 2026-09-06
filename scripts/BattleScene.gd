extends Node2D

# ─────────────────────────────────────────────────────
#  BATTLE SCENE
#  Pokemon-style menu: Fight | Digivice | Run | Digimon
#  Digivice holds items + 0–200% scan data (Time Stranger)
# ─────────────────────────────────────────────────────

enum BattleMenu { MAIN, FIGHT, DIGIVICE, DIGIMON }

# ── NODE REFERENCES ──────────────────────────────────
@onready var background        = $Background

@onready var enemy_name_label  = $UI/EnemyPanel/NameRow/EnemyName
@onready var enemy_level_label = $UI/EnemyPanel/EnemyLevel
@onready var enemy_hp_bar      = $UI/EnemyPanel/EnemyHPBar
@onready var enemy_hp_label    = $UI/EnemyPanel/EnemyHPLabel
@onready var enemy_type_icon   = $UI/EnemyPanel/NameRow/TypeIcon
@onready var enemy_status_icon = $UI/EnemyPanel/NameRow/StatusIcon
@onready var enemy_sprite      = $EnemySprite

@onready var player_name_label  = $UI/PlayerPanel/NameRow/PlayerName
@onready var player_level_label = $UI/PlayerPanel/PlayerLevel
@onready var player_hp_bar      = $UI/PlayerPanel/PlayerHPBar
@onready var player_hp_label    = $UI/PlayerPanel/PlayerHPLabel
@onready var player_xp_bar      = $UI/PlayerPanel/PlayerXPBar
@onready var player_sp_bar      = $UI/PlayerPanel/PlayerSPBar
@onready var player_sp_label    = $UI/PlayerPanel/PlayerSPLabel
@onready var scan_mini_bar      = $UI/BattleBottomPanel/HBoxRoot/RightColumn/ScanBox/ScanTopBar
@onready var scan_mini_label    = $UI/BattleBottomPanel/HBoxRoot/RightColumn/ScanBox/ScanTopLabel
@onready var player_sprite      = $PlayerSprite
@onready var player_type_icon   = $UI/PlayerPanel/NameRow/TypeIcon
@onready var player_status_icon = $UI/PlayerPanel/NameRow/StatusIcon
@onready var enemy_sand_ground  = $EnemySandGround
@onready var player_sand_ground = $PlayerSandGround

# Status condition → icon symbol (shown above the digimon)
const STATUS_ICONS = {
	"burn":      "res://assets/Party and Status/statusBURN.png",
	"freeze":    "res://assets/Party and Status/statusFROZEN.png",
	"paralysis": "res://assets/Party and Status/statusPARALYSIS.png",
	"stun":      "res://assets/Party and Status/statusPARALYSIS.png",
	"poison":    "res://assets/Party and Status/statusPOISONED.png",
	"sleep":     "res://assets/Party and Status/statusSLEEP.png",
	"confuse":   "res://assets/Party and Status/statusPKRS.png",
}

func _apply_status_icon_rect(tex: TextureRect, status: String):
	var path = STATUS_ICONS.get(status, "")
	if status != "none" and path != "" and ResourceLoader.exists(path):
		tex.texture = load(path)
		tex.visible = true
	else:
		tex.texture = null
		tex.visible = false

func _apply_type_icon(tex: TextureRect, digimon_type: String):
	var path = TYPE_ICONS.get(digimon_type, "")
	if path != "" and ResourceLoader.exists(path):
		tex.texture = load(path)
		tex.visible = true
	else:
		tex.texture = null
		tex.visible = false

# Type icon paths
const TYPE_ICONS = {
	"vaccine": "res://assets/type_icons/vaccine.png",
	"virus":   "res://assets/type_icons/virus.png",
	"data":    "res://assets/type_icons/data.png",
}

@onready var log_label         = $UI/BattleBottomPanel/HBoxRoot/RightColumn/BattleLog/LogLabel

@onready var main_action_panel = $UI/BattleBottomPanel/HBoxRoot/LeftPanel/MainActionPanel
@onready var fight_button      = $UI/BattleBottomPanel/HBoxRoot/LeftPanel/MainActionPanel/FightButton
@onready var digivice_button   = $UI/BattleBottomPanel/HBoxRoot/LeftPanel/MainActionPanel/DigiviceButton
@onready var run_button        = $UI/BattleBottomPanel/HBoxRoot/LeftPanel/MainActionPanel/RunButton
@onready var digimon_button    = $UI/BattleBottomPanel/HBoxRoot/LeftPanel/MainActionPanel/DigimonButton

@onready var move_panel        = $UI/BattleBottomPanel/HBoxRoot/LeftPanel/MovePanel
@onready var move1_button      = $UI/BattleBottomPanel/HBoxRoot/LeftPanel/MovePanel/MoveGrid/Move1Button
@onready var move2_button      = $UI/BattleBottomPanel/HBoxRoot/LeftPanel/MovePanel/MoveGrid/Move2Button
@onready var move3_button      = $UI/BattleBottomPanel/HBoxRoot/LeftPanel/MovePanel/MoveGrid/Move3Button
@onready var move4_button      = $UI/BattleBottomPanel/HBoxRoot/LeftPanel/MovePanel/MoveGrid/Move4Button

@onready var digivice_panel    = $UI/BattleBottomPanel/HBoxRoot/LeftPanel/DigivicePanel
@onready var digivice_sprite   = $UI/BattleBottomPanel/HBoxRoot/LeftPanel/DigivicePanel/Sprite
@onready var scan_label        = $UI/BattleBottomPanel/HBoxRoot/LeftPanel/DigivicePanel/VBox/ScanLabel
@onready var item_list         = $UI/BattleBottomPanel/HBoxRoot/LeftPanel/DigivicePanel/VBox/ItemList
@onready var item_grid         = $UI/BattleBottomPanel/HBoxRoot/LeftPanel/DigivicePanel/VBox/ItemList/Grid
@onready var catch_button      = $UI/BattleBottomPanel/HBoxRoot/LeftPanel/DigivicePanel/VBox/CatchButton
@onready var digivolve_button    = $UI/BattleBottomPanel/HBoxRoot/LeftPanel/DigivicePanel/VBox/DigivolveButton

@onready var tab_all    = $UI/BattleBottomPanel/HBoxRoot/LeftPanel/DigivicePanel/VBox/TabBar/TabAll
@onready var tab_heal   = $UI/BattleBottomPanel/HBoxRoot/LeftPanel/DigivicePanel/VBox/TabBar/TabHeal
@onready var tab_sp     = $UI/BattleBottomPanel/HBoxRoot/LeftPanel/DigivicePanel/VBox/TabBar/TabSP
@onready var tab_status = $UI/BattleBottomPanel/HBoxRoot/LeftPanel/DigivicePanel/VBox/TabBar/TabStatus
@onready var tab_battle = $UI/BattleBottomPanel/HBoxRoot/LeftPanel/DigivicePanel/VBox/TabBar/TabBattle

@onready var revive_popup      = $UI/RevivePopup
@onready var revive_list       = $UI/RevivePopup/Panel/VBox/ScrollContainer/List
@onready var revive_cancel_btn = $UI/RevivePopup/Panel/VBox/CancelButton

@onready var digimon_panel     = $UI/BattleBottomPanel/HBoxRoot/LeftPanel/DigimonPanel
@onready var digimon_sprite    = $UI/BattleBottomPanel/HBoxRoot/LeftPanel/DigimonPanel/TopRow/DigimonSprite
@onready var digimon_stats_label = $UI/BattleBottomPanel/HBoxRoot/LeftPanel/DigimonPanel/TopRow/RightVBox/DigimonStatsLabel
@onready var digimon_moves_label = $UI/BattleBottomPanel/HBoxRoot/LeftPanel/DigimonPanel/TopRow/RightVBox/DigimonMovesLabel
@onready var digimon_evo_label = $UI/BattleBottomPanel/HBoxRoot/LeftPanel/DigimonPanel/TopRow/RightVBox/DigimonEvoLabel
@onready var digimon_type_icon  = $UI/BattleBottomPanel/HBoxRoot/LeftPanel/DigimonPanel/TopRow/RightVBox/TypeIcon
@onready var member_scroll    = $UI/BattleBottomPanel/HBoxRoot/LeftPanel/DigimonPanel/MemberScroll
@onready var member_row       = $UI/BattleBottomPanel/HBoxRoot/LeftPanel/DigimonPanel/MemberScroll/MemberRow
@onready var party_label      = $UI/BattleBottomPanel/HBoxRoot/LeftPanel/DigimonPanel/PartyLabel
@onready var send_out_button   = $UI/BattleBottomPanel/HBoxRoot/RightColumn/BackMargin/HBox/SendOutButton

@onready var battle_bottom_panel = $UI/BattleBottomPanel
@onready var back_button         = $UI/BattleBottomPanel/HBoxRoot/RightColumn/BackMargin/HBox/BackButton
@onready var settings_panel      = $UI/SettingsPanel

# ── BATTLE STATE ─────────────────────────────────────
var player_digimon: Dictionary = {}
var enemy_digimon: Dictionary  = {}
var move_buttons: Array        = []
var member_list: Array         = []
var battle_over: bool          = false
var turn_number: int           = 0
var log_queue: Array           = []
var is_showing_log: bool       = false
var current_menu: BattleMenu   = BattleMenu.MAIN
var player_swapped_this_turn: bool = false
var strike_fallback: bool      = false
var current_item_tab: String   = "all"
var selected_member_idx: int   = 0
var member_sprite_buttons: Array = []

# ─────────────────────────────────────────────────────
#  READY
# ─────────────────────────────────────────────────────

func _ready():
	player_digimon = SaveData.current_digimon
	enemy_digimon = EncounterManager.spawn_random_enemy(SaveData.floor_number)

	move_buttons = [move1_button, move2_button, move3_button, move4_button]
	move1_button.pressed.connect(_on_move_pressed.bind(0))
	move2_button.pressed.connect(_on_move_pressed.bind(1))
	move3_button.pressed.connect(_on_move_pressed.bind(2))
	move4_button.pressed.connect(_on_move_pressed.bind(3))
	back_button.pressed.connect(_show_main_menu)

	fight_button.pressed.connect(_on_fight_pressed)
	digivice_button.pressed.connect(_on_digivice_pressed)
	run_button.pressed.connect(_on_run_pressed)
	digimon_button.pressed.connect(_on_digimon_pressed)

	catch_button.pressed.connect(_on_catch_pressed)
	digivolve_button.pressed.connect(_on_digivolve_pressed)
	send_out_button.pressed.connect(_on_send_out_pressed)

	tab_all.pressed.connect(_on_tab_pressed.bind("all"))
	tab_heal.pressed.connect(_on_tab_pressed.bind("heal"))
	tab_sp.pressed.connect(_on_tab_pressed.bind("sp"))
	tab_status.pressed.connect(_on_tab_pressed.bind("status"))
	tab_battle.pressed.connect(_on_tab_pressed.bind("battle"))
	revive_cancel_btn.pressed.connect(_on_revive_cancel)

	scan_mini_bar.max_value = SaveData.COLLECTION_MAX

	_setup_ui()
	_update_all_ui()
	_show_main_menu()
	_load_background()

	settings_panel.colors_changed.connect(_apply_ui_settings)
	settings_panel.settings_closed.connect(_on_settings_closed)
	_apply_ui_settings()

	var is_boss = SaveData.floor_number in EncounterManager.boss_floors
	if is_boss:
		_add_log("⚠ BOSS BATTLE!")
	_add_log("A wild %s appeared!" % enemy_digimon["name"])
	_add_log("Go, %s!" % player_digimon["name"])
	_show_next_log()

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel") and not settings_panel.visible:
		_open_settings()

func _open_settings():
	settings_panel.visible = true
	get_tree().paused = true

func _on_settings_closed():
	pass

# ─────────────────────────────────────────────────────
#  UI THEMING (Settings menu colors)
# ─────────────────────────────────────────────────────

func _make_button_style(border_color: Color, fill: Color) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border_color
	sb.set_border_width_all(2)
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	sb.set_content_margin_all(8)
	return sb

func _all_battle_buttons() -> Array:
	return [
		fight_button, digivice_button, run_button, digimon_button,
		move1_button, move2_button, move3_button, move4_button,
		back_button, catch_button, digivolve_button, send_out_button,
	]

func _apply_ui_settings():
	var fill      = Color(0.06, 0.06, 0.12)
	var normal    = _make_button_style(SaveData.button_normal_color, fill)
	var hover     = _make_button_style(SaveData.button_hover_color, fill)
	var pressed   = _make_button_style(SaveData.button_pressed_color, fill)
	var disabled  = _make_button_style(SaveData.button_normal_color.darkened(0.4), fill.darkened(0.3))
	var focus     = _make_button_style(SaveData.button_normal_color.lightened(0.12), fill)
	for btn in _all_battle_buttons():
		btn.add_theme_stylebox_override("normal", normal.duplicate())
		btn.add_theme_stylebox_override("hover", hover.duplicate())
		btn.add_theme_stylebox_override("pressed", pressed.duplicate())
		btn.add_theme_stylebox_override("disabled", disabled.duplicate())
		btn.add_theme_stylebox_override("focus", focus.duplicate())

	var panel_sb = battle_bottom_panel.get_theme_stylebox("panel")
	if panel_sb is StyleBoxFlat:
		panel_sb.border_color = SaveData.panel_color

# ─────────────────────────────────────────────────────
#  MENU NAVIGATION
# ─────────────────────────────────────────────────────

func _show_main_menu():
	current_menu = BattleMenu.MAIN
	main_action_panel.visible = true
	move_panel.visible = false
	digivice_panel.visible = false
	digimon_panel.visible = false
	back_button.visible = false
	send_out_button.visible = false
	if not battle_over:
		_set_buttons_enabled(true)

func _on_fight_pressed():
	if battle_over or is_showing_log:
		return
	current_menu = BattleMenu.FIGHT
	main_action_panel.visible = false
	move_panel.visible = true
	digivice_panel.visible = false
	digimon_panel.visible = false
	back_button.visible = true
	send_out_button.visible = false
	log_label.text = "What will %s do?" % player_digimon.get("name", "your Digimon")
	_update_move_buttons()

func _on_digivice_pressed():
	if battle_over or is_showing_log:
		return
	current_menu = BattleMenu.DIGIVICE
	main_action_panel.visible = false
	move_panel.visible = false
	digivice_panel.visible = true
	digimon_panel.visible = false
	back_button.visible = true
	send_out_button.visible = false
	log_label.text = ""
	_update_digivice_panel()

func _on_digivolve_pressed():
	if battle_over or is_showing_log:
		return
	if not SaveData.can_digivice_digivolve():
		var msg = "Reach the required level to digivolve!"
		if player_digimon.get("evolves_to", "") == "":
			msg = "%s has no further evolution." % player_digimon["name"]
		elif player_digimon.get("level", 1) < player_digimon.get("evolves_at", 0):
			msg = "Reach Level %d to digivolve into %s. (Currently Lv.%d)" % [
				player_digimon["evolves_at"], player_digimon["evolves_to"], player_digimon.get("level", 1)
			]
		_add_log(msg)
		_show_next_log()
		return

	_set_buttons_enabled(false)
	var result = SaveData.attempt_digivice_digivolution()
	_add_log(result.get("message", "Digivolution failed."))
	if result.get("success", false):
		player_digimon = SaveData.current_digimon
		_setup_ui()
		_update_player_ui()
		await _flash_sprite(player_sprite)
	_show_next_log()
	_update_digivice_panel()
	if not battle_over:
		_set_buttons_enabled(true)

func _on_digimon_pressed():
	if battle_over or is_showing_log:
		return
	current_menu = BattleMenu.DIGIMON
	main_action_panel.visible = false
	move_panel.visible = false
	digivice_panel.visible = false
	digimon_panel.visible = true
	back_button.visible = true
	send_out_button.visible = true
	_update_digimon_panel()

func _update_digivice_panel():
	_update_panel_sprite(digivice_sprite)
	var enemy_name = enemy_digimon.get("name", "")
	var scan = SaveData.get_collection_percent(enemy_name)
	scan_label.text = "Collection: %d / %d%%" % [scan, SaveData.COLLECTION_MAX]

	_update_catch_button()
	var current = SaveData.current_digimon
	if DigimonDB.can_digivolve(current):
		digivolve_button.text = "Digivolve → %s!" % current["evolves_to"]
		digivolve_button.disabled = false
	elif current.get("evolves_to", "") == "":
		digivolve_button.text = "Digivolve (Final Form)"
		digivolve_button.disabled = true
	else:
		digivolve_button.text = "Digivolve  Lv.%d" % current["evolves_at"]
		digivolve_button.disabled = true
	_build_item_list()

func _update_digimon_panel():
	selected_member_idx = 0
	_build_member_list()
	_build_member_sprites()

	_display_member(player_digimon)
	_update_panel_sprite(digimon_sprite)
	send_out_button.disabled = true
	send_out_button.text = "In Battle"

func _build_member_list():
	member_list = []
	var seen = {}
	for d in SaveData.digimon_roster:
		var n = d.get("name", "")
		if n != "" and not seen.has(n):
			seen[n] = true
			member_list.append(d)
	for d in SaveData.guest_roster:
		var n = d.get("name", "")
		if n != "" and not seen.has(n):
			seen[n] = true
			member_list.append(d)
	var cur_name = player_digimon.get("name", "")
	if cur_name != "" and not seen.has(cur_name):
		member_list.push_front(player_digimon)

func _build_member_sprites():
	for child in member_row.get_children():
		child.queue_free()
	member_sprite_buttons = []
	for i in range(member_list.size()):
		var d = member_list[i]
		var is_current = d.get("name", "") == player_digimon.get("name", "")
		var is_fainted = d.get("current_hp", 0) <= 0
		var is_selected = i == selected_member_idx

		var card = VBoxContainer.new()
		card.custom_minimum_size = Vector2(44, 48)
		card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		card.set("theme_override_constants/separation", 1)

		var sprite_tex = TextureRect.new()
		sprite_tex.custom_minimum_size = Vector2(36, 36)
		sprite_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sprite_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sprite_path = d.get("sprite_back", d.get("sprite", ""))
		if sprite_path != "" and ResourceLoader.exists(sprite_path):
			sprite_tex.texture = load(sprite_path)
		if is_fainted:
			sprite_tex.modulate = Color(0.35, 0.35, 0.35, 0.5)
		elif is_current:
			sprite_tex.modulate = Color(0.5, 1.0, 0.5)
		card.add_child(sprite_tex)

		var name_lbl = Label.new()
		name_lbl.text = d.get("name", "???")
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 8)
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if is_fainted:
			name_lbl.modulate = Color(1.0, 0.3, 0.3)
		elif is_current:
			name_lbl.modulate = Color(0.5, 1.0, 0.5)
		card.add_child(name_lbl)

		var hp_bar = ProgressBar.new()
		hp_bar.custom_minimum_size = Vector2(36, 4)
		hp_bar.max_value = maxf(d.get("hp", 1), 1)
		hp_bar.value = d.get("current_hp", 0)
		hp_bar.show_percentage = false
		var bg = StyleBoxFlat.new()
		bg.bg_color = Color(0.15, 0.15, 0.15)
		bg.set_corner_radius_all(1)
		hp_bar.add_theme_stylebox_override("background", bg)
		var fill = StyleBoxFlat.new()
		var hp_pct = hp_bar.value / hp_bar.max_value
		if hp_pct > 0.5:
			fill.bg_color = Color(0.2, 0.85, 0.2)
		elif hp_pct > 0.25:
			fill.bg_color = Color(0.9, 0.8, 0.1)
		else:
			fill.bg_color = Color(0.9, 0.15, 0.15)
		fill.set_corner_radius_all(1)
		hp_bar.add_theme_stylebox_override("fill", fill)
		card.add_child(hp_bar)

		var btn = Button.new()
		btn.flat = true
		btn.add_child(card)
		card.set_anchors_preset(Control.PRESET_FULL_RECT)
		card.offset_left = 0
		card.offset_top = 0
		card.offset_right = 0
		card.offset_bottom = 0
		btn.custom_minimum_size = Vector2(44, 48)

		if is_fainted:
			btn.modulate = Color(0.5, 0.5, 0.5, 0.6)
		elif is_current:
			btn.modulate = Color(0.5, 1.0, 0.5, 0.7)
		elif is_selected:
			btn.modulate = Color(0.7, 0.85, 1.0)
		else:
			btn.modulate = Color.WHITE

		btn.pressed.connect(_on_member_sprite_pressed.bind(i))
		member_row.add_child(btn)
		member_sprite_buttons.append(btn)

	var party_names = SaveData.get_party_names()
	var guest_names = SaveData.get_guest_names()
	party_label.text = "Party (Cap: %d/%d): %s" % [SaveData.party_capacity, SaveData.MAX_CAPACITY, " ".join(party_names)]
	if not guest_names.is_empty():
		party_label.text += "\nGuests: %s" % " ".join(guest_names)

func _highlight_selected_member():
	for i in range(member_sprite_buttons.size()):
		if i >= member_list.size():
			break
		var d = member_list[i]
		var is_current = d.get("name", "") == player_digimon.get("name", "")
		var is_fainted = d.get("current_hp", 0) <= 0
		var is_selected = i == selected_member_idx
		if is_fainted:
			member_sprite_buttons[i].modulate = Color(0.5, 0.5, 0.5, 0.6)
		elif is_current:
			member_sprite_buttons[i].modulate = Color(0.5, 1.0, 0.5, 0.7)
		elif is_selected:
			member_sprite_buttons[i].modulate = Color(0.7, 0.85, 1.0)
		else:
			member_sprite_buttons[i].modulate = Color.WHITE

func _on_member_sprite_pressed(idx: int):
	if battle_over or is_showing_log:
		return
	if idx < 0 or idx >= member_list.size():
		return
	selected_member_idx = idx
	_highlight_selected_member()
	_update_member_display(idx)

func _update_member_display(idx: int):
	if idx < 0 or idx >= member_list.size():
		return
	var selected = member_list[idx]
	_display_member(selected)
	_update_panel_sprite(digimon_sprite)
	var is_current = selected.get("name", "") == player_digimon.get("name", "")
	var is_fainted = selected.get("current_hp", 0) <= 0
	send_out_button.disabled = is_current or is_fainted
	if is_current:
		send_out_button.text = "In Battle"
	elif is_fainted:
		send_out_button.text = "Fainted"
	else:
		send_out_button.text = "Send Out"

func _on_send_out_pressed():
	if battle_over or is_showing_log:
		return
	if member_list.size() <= 1:
		return
	if selected_member_idx < 0 or selected_member_idx >= member_list.size():
		return
	var selected = member_list[selected_member_idx]
	if selected.get("name", "") == player_digimon.get("name", ""):
		return
	if selected.get("current_hp", 0) <= 0:
		return
	var old_name = player_digimon.get("name", "???")
	SaveData.current_digimon = selected
	player_digimon = selected
	var p_back_path = player_digimon.get("sprite_back", "")
	var p_front_path = player_digimon.get("sprite", "")
	if p_back_path != "" and ResourceLoader.exists(p_back_path):
		player_sprite.texture = load(p_back_path)
	elif p_front_path != "" and ResourceLoader.exists(p_front_path):
		player_sprite.texture = load(p_front_path)
		player_sprite.flip_h = true
	_fit_sprite(player_sprite, 450.0, 540.0, player_digimon.get("stage", ""))
	_update_player_ui()
	_add_log("%s, come back!" % old_name)
	_add_log("Go, %s!" % selected.get("name", "???"))
	_show_next_log()
	await get_tree().create_timer(1.0).timeout
	_set_buttons_enabled(false)
	_show_main_menu()
	await _swap_enemy_turn()
	if not battle_over:
		await _process_end_of_turn_status()
	if not battle_over:
		_set_buttons_enabled(true)
		_update_all_ui()
		_show_main_menu()

func _swap_enemy_turn():
	var enemy_move = ""
	if not BattleSystem.is_frozen(enemy_digimon):
		enemy_move = BattleSystem.get_random_valid_enemy_move(enemy_digimon)
	await _enemy_turn(enemy_move)

func _display_member(d: Dictionary):
	digimon_stats_label.text = "%s Lv.%d [%s]  HP %d/%d  ATK %d  DEF %d  SP.ATK %d  SPD %d" % [
		d.get("name", "???"),
		d.get("level", 1),
		d.get("type", "?").capitalize(),
		d.get("current_hp", 0), d.get("hp", 1),
		d.get("attack", 0), d.get("defense", 0),
		d.get("sp_attack", 0), d.get("speed", 0),
	]

	var icon_path = TYPE_ICONS.get(d.get("type", ""), "")
	if icon_path != "" and ResourceLoader.exists(icon_path):
		digimon_type_icon.texture = load(icon_path)
	else:
		digimon_type_icon.texture = null

	var moves_text = ""
	for move_name in d.get("moves", []):
		var move = DigimonDB.get_move(move_name)
		var sp_cost = move.get("sp_cost", 0)
		moves_text += "%s(%s) SP %d  " % [move_name, move.get("type", "?"), sp_cost]
	digimon_moves_label.text = moves_text

	var enemy_name = enemy_digimon.get("name", "")
	var scan = SaveData.get_collection_percent(enemy_name)
	var caught = SaveData.get_caught_count()
	if SaveData.is_caught(enemy_name):
		digimon_evo_label.text = "%s in collection | %d caught" % [enemy_name, caught]
	elif SaveData.can_catch(enemy_name):
		digimon_evo_label.text = "%s scan COMPLETE | %d caught" % [enemy_name, caught]
	else:
		digimon_evo_label.text = "Scan %s to 200%% | %d caught" % [enemy_name, caught]

func _update_scan_display():
	var enemy_name = enemy_digimon.get("name", "")
	var scan = SaveData.get_collection_percent(enemy_name)
	scan_mini_bar.value = scan
	scan_mini_label.text = "Scan: %d%%" % scan
	if scan >= SaveData.COLLECTION_MAX:
		scan_mini_label.modulate = Color(1.0, 0.85, 0.2)
	elif scan >= int(SaveData.COLLECTION_MAX * 0.5):
		scan_mini_label.modulate = Color(0.4, 1.0, 0.5)
	else:
		scan_mini_label.modulate = Color(0.7, 0.85, 1.0)

# ─────────────────────────────────────────────────────
#  UI SETUP
# ─────────────────────────────────────────────────────

func _get_background_for_floor(floor_num: int) -> String:
	if floor_num <= 10:
		return "res://assets/background/beach.png"
	elif floor_num <= 20:
		return "res://assets/background/plains.png"
	elif floor_num <= 30:
		return "res://assets/background/forest.png"
	elif floor_num <= 40:
		return "res://assets/background/castle.png"
	else:
		return "res://assets/background/hell.png"

func _load_background():
	var bg_path = _get_background_for_floor(SaveData.floor_number)
	if ResourceLoader.exists(bg_path):
		var texture = load(bg_path)
		if background is TextureRect:
			background.texture = texture
		elif background is ColorRect:
			background.size = Vector2(1280, 520)
			background.position = Vector2.ZERO
			var tex_rect = TextureRect.new()
			tex_rect.name = "BackgroundTexture"
			tex_rect.texture = texture
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
			background.add_child(tex_rect)

func _setup_ui():
	var p_back_path = player_digimon.get("sprite_back", "")
	var p_front_path = player_digimon.get("sprite", "")
	if p_back_path != "" and ResourceLoader.exists(p_back_path):
		player_sprite.texture = load(p_back_path)
	elif p_front_path != "" and ResourceLoader.exists(p_front_path):
		player_sprite.texture = load(p_front_path)
		player_sprite.flip_h = true
	else:
		_set_placeholder_sprite(player_sprite, Color(1.0, 0.4, 0.1))

	_fit_sprite(player_sprite, 450.0, 540.0, player_digimon.get("stage", ""))

	var e_sprite_path = enemy_digimon.get("sprite", "")
	if e_sprite_path != "" and ResourceLoader.exists(e_sprite_path):
		enemy_sprite.texture = load(e_sprite_path)
	else:
		_set_placeholder_sprite(enemy_sprite, Color(0.3, 0.5, 1.0))
	var e_max_w = 280.0
	var e_max_h = 260.0
	var e_stretch = 1.15
	if enemy_digimon.get("name", "") == "Agumon":
		e_max_w = 290.0
		e_max_h = 270.0
	elif enemy_digimon.get("name", "") == "Devimon":
		e_max_w = 320.0
		e_max_h = 300.0
		e_stretch = 1.25
	_fit_sprite(enemy_sprite, e_max_w, e_max_h, enemy_digimon.get("stage", ""), e_stretch)
	if enemy_digimon.get("name", "") == "Agumon":
		enemy_sprite.position = Vector2(760, 260)

	# Lower enemy + platform on plains background
	var bg_path = _get_background_for_floor(SaveData.floor_number)
	if bg_path == "res://assets/background/plains.png":
		enemy_sprite.position.y += 60

	enemy_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	player_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	# Pick platform based on background
	var enemy_platform_path = "res://assets/enemybaseFieldSand2.png"
	var player_platform_path = "res://assets/enemybaseFieldSand.png"
	if bg_path == "res://assets/background/plains.png":
		enemy_platform_path = "res://assets/Platform/enemybaseFairyTale.png"
		player_platform_path = "res://assets/Platform/enemybaseFairyTale.png"
	elif bg_path == "res://assets/background/forest.png":
		enemy_platform_path = "res://assets/Platform/enemybaseForest.png"
		player_platform_path = "res://assets/Platform/enemybaseForest.png"
	elif bg_path == "res://assets/background/castle.png":
		enemy_platform_path = "res://assets/Platform/enemybaseCityNew.png"
		player_platform_path = "res://assets/Platform/enemybaseCityNew.png"
	elif bg_path == "res://assets/background/hell.png":
		enemy_platform_path = "res://assets/Platform/enemybaseBurning.png"
		player_platform_path = "res://assets/Platform/enemybaseBurning.png"

	# Position platforms at feet of each Digimon
	if ResourceLoader.exists(enemy_platform_path):
		enemy_sand_ground.texture = _make_outlined_sand(load(enemy_platform_path))
	enemy_sand_ground.position = Vector2(enemy_sprite.position.x, enemy_sprite.position.y + 120)

	if ResourceLoader.exists(player_platform_path):
		player_sand_ground.texture = _make_outlined_sand(load(player_platform_path))
	player_sand_ground.position = Vector2(player_sprite.position.x, player_sprite.position.y + 200)

	_update_move_buttons()

func _make_outlined_sand(src_tex: Texture2D) -> Texture2D:
	var img = src_tex.get_image()
	var w = img.get_width()
	var h = img.get_height()
	var outline = Image.create(w, h, false, Image.FORMAT_RGBA8)
	outline.fill(Color(0, 0, 0, 0))
	for y in range(h):
		for x in range(w):
			var c = img.get_pixel(x, y)
			if c.a > 0.1:
				outline.set_pixel(x, y, c)
			else:
				var found_edge = false
				for dx in range(-1, 2):
					for dy in range(-1, 2):
						if dx == 0 and dy == 0:
							continue
						var nx = x + dx
						var ny = y + dy
						if nx >= 0 and nx < w and ny >= 0 and ny < h:
							var neighbor = img.get_pixel(nx, ny)
							if neighbor.a > 0.1:
								found_edge = true
								break
					if found_edge:
						break
				if found_edge:
					outline.set_pixel(x, y, Color(0.15, 0.12, 0.08, 1))
	return ImageTexture.create_from_image(outline)

func _fit_sprite(sprite: Sprite2D, max_w: float, max_h: float, stage: String = "", stretch_w: float = 1.0):
	var tex = sprite.texture
	if not tex:
		return
	var tw = float(tex.get_width())
	var th = float(tex.get_height())
	var scale_x = max_w / tw
	var scale_y = max_h / th
	var s = minf(scale_x, scale_y)
	s *= _get_stage_size_multiplier(stage)
	sprite.scale = Vector2(s * stretch_w, s)

func _get_stage_size_multiplier(stage: String) -> float:
	match stage:
		"Baby":
			return 0.85
		"Rookie":
			return 1.0
		"Champion":
			return 1.15
		"Ultimate":
			return 1.3
		"Mega":
			return 1.45
	return 1.0

func _set_placeholder_sprite(sprite: Sprite2D, color: Color):
	var img = Image.create(128, 128, false, Image.FORMAT_RGBA8)
	img.fill(color)
	sprite.texture = ImageTexture.create_from_image(img)

func _get_item_count(item_name: String) -> int:
	for item in SaveData.items:
		if item["name"] == item_name:
			return item["quantity"]
	return 0

# ─────────────────────────────────────────────────────
#  UI UPDATE
# ─────────────────────────────────────────────────────

func _update_all_ui():
	_update_player_ui()
	_update_enemy_ui()
	_update_move_buttons()
	_update_scan_display()

func _update_player_ui():
	var p = player_digimon
	player_name_label.text = "%s" % p.get("name", "???")
	player_level_label.text = "Lv %d" % p.get("level", 1)

	_apply_type_icon(player_type_icon, p.get("type", ""))

	var cur_hp  = p.get("current_hp", 0)
	var max_hp  = p.get("hp", 1)
	var cur_xp  = p.get("experience", 0)
	var next_xp = SaveData.get_xp_for_level(p.get("level", 1) + 1)

	player_hp_bar.max_value = max_hp
	player_hp_bar.value     = cur_hp
	player_hp_label.text    = "%d / %d" % [cur_hp, max_hp]

	player_xp_bar.max_value = next_xp
	player_xp_bar.value     = cur_xp

	player_sp_bar.max_value = maxi(1, p.get("sp", 1))
	player_sp_bar.value     = p.get("current_sp", 0)
	player_sp_label.text    = "SP %d / %d" % [p.get("current_sp", 0), p.get("sp", 0)]

	var hp_pct = float(cur_hp) / float(max_hp)
	var hp_fill = player_hp_bar.get_theme_stylebox("fill").duplicate()
	if hp_pct > 0.5:
		hp_fill.bg_color = Color(0.1, 0.85, 0.3)
	elif hp_pct > 0.25:
		hp_fill.bg_color = Color(1.0, 0.75, 0.0)
	else:
		hp_fill.bg_color = Color(0.9, 0.2, 0.2)
	player_hp_bar.add_theme_stylebox_override("fill", hp_fill)

	_apply_status_icon_rect(player_status_icon, p.get("status", "none"))

func _update_enemy_ui():
	var e = enemy_digimon
	enemy_name_label.text = "%s" % e.get("name", "???")
	enemy_level_label.text = "Lv %d" % e.get("level", 1)

	_apply_type_icon(enemy_type_icon, e.get("type", ""))

	var cur_hp = e.get("current_hp", 0)
	var max_hp = e.get("hp", 1)

	enemy_hp_bar.max_value = max_hp
	enemy_hp_bar.value     = cur_hp
	enemy_hp_label.text    = "%d / %d" % [cur_hp, max_hp]

	var hp_pct = float(cur_hp) / float(max_hp)
	var hp_fill = enemy_hp_bar.get_theme_stylebox("fill").duplicate()
	if hp_pct > 0.5:
		hp_fill.bg_color = Color(0.1, 0.85, 0.3)
	elif hp_pct > 0.25:
		hp_fill.bg_color = Color(1.0, 0.75, 0.0)
	else:
		hp_fill.bg_color = Color(0.9, 0.2, 0.2)
	enemy_hp_bar.add_theme_stylebox_override("fill", hp_fill)

	_apply_status_icon_rect(enemy_status_icon, e.get("status", "none"))

func _update_move_buttons():
	var moves = player_digimon.get("moves", [])
	var cur_sp = player_digimon.get("current_sp", 0)
	var enemy_type = enemy_digimon.get("type", "")
	var any_affordable = false
	for i in range(move_buttons.size()):
		if i < moves.size():
			var move_name = moves[i]
			var move_data = DigimonDB.get_move(move_name)
			var sp_cost   = move_data.get("sp_cost", 0)
			var move_type = move_data.get("type", "")
			var affordable = cur_sp >= sp_cost
			if affordable:
				any_affordable = true
			var eff = DigimonDB.get_type_multiplier(move_type, enemy_type)
			var eff_tag = ""
			if eff >= 1.5:
				eff_tag = "  SE"
			elif eff <= 0.5:
				eff_tag = "  NVE"
			move_buttons[i].text = "%s\n%s  SP %d%s" % [
				move_name,
				move_type.capitalize(),
				sp_cost,
				eff_tag
			]
			move_buttons[i].visible = true
			move_buttons[i].disabled = not affordable or battle_over
		else:
			move_buttons[i].visible = false

	# Fallback free basic attack when out of SP or few moves learned
	strike_fallback = not any_affordable
	if strike_fallback and move_buttons.size() > 0:
		var eff = DigimonDB.get_type_multiplier("vaccine", enemy_type)
		var eff_tag = ""
		if eff >= 1.5:
			eff_tag = "  SE"
		elif eff <= 0.5:
			eff_tag = "  NVE"
		move_buttons[0].text = "Strike\nBasic  SP 0%s" % eff_tag
		move_buttons[0].visible = true
		move_buttons[0].disabled = battle_over

func _update_panel_sprite(sprite: TextureRect):
	var path = player_digimon.get("sprite", "")
	if path != "" and ResourceLoader.exists(path):
		sprite.texture = load(path)
		var name = player_digimon.get("name", "")
		if name in ["Gomamon", "Gabumon", "Patamon", "Tentomon", "Biyomon", "Palmon"]:
			sprite.custom_minimum_size = Vector2(72, 72)
			sprite.size = Vector2(72, 72)
		else:
			sprite.custom_minimum_size = Vector2(96, 96)
			sprite.size = Vector2(96, 96)

# ─────────────────────────────────────────────────────
#  BATTLE LOG
# ─────────────────────────────────────────────────────

func _add_log(message: String):
	log_queue.append(message)

func _show_next_log():
	if log_queue.is_empty():
		is_showing_log = false
		return
	is_showing_log = true
	log_label.text = log_queue.pop_front()
	await get_tree().create_timer(1.2).timeout
	_show_next_log()

# ─────────────────────────────────────────────────────
#  BUTTON STATE
# ─────────────────────────────────────────────────────

func _set_buttons_enabled(enabled: bool):
	fight_button.disabled = not enabled
	digivice_button.disabled = not enabled
	run_button.disabled = not enabled
	digimon_button.disabled = not enabled
	digivolve_button.disabled = not enabled
	back_button.disabled = not enabled
	if enabled:
		_update_move_buttons()
		if current_menu == BattleMenu.DIGIVICE:
			_update_digivice_panel()

# ─────────────────────────────────────────────────────
#  DIGIVICE ACTIONS
# ─────────────────────────────────────────────────────

func _build_item_list():
	for child in item_grid.get_children():
		child.queue_free()
	for item in SaveData.items:
		var item_data = ItemDB.get_item(item["name"])
		if item_data.get("effect", "") == "ticket":
			continue
		if not _item_matches_tab(item_data):
			continue
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(280, 36)
		btn.add_theme_font_size_override("font_size", 12)
		btn.text = "%s  x%d" % [item["name"], item["quantity"]]
		btn.pressed.connect(_on_item_pressed.bind(item["name"]))
		btn.mouse_entered.connect(_on_item_hover.bind(item_data))
		btn.mouse_exited.connect(_on_item_hover_exit)
		item_grid.add_child(btn)

func _item_matches_tab(item: Dictionary) -> bool:
	if current_item_tab == "all":
		return true
	var eff = item.get("effect", "")
	match current_item_tab:
		"heal":
			return eff in ["heal", "full_recovery", "revive"]
		"sp":
			return eff == "restore_sp"
		"status":
			return eff.begins_with("cure_")
		"battle":
			return eff in ["boost", "boost_all", "boost_two"]
	return true

func _on_tab_pressed(tab: String):
	current_item_tab = tab
	_build_item_list()

func _on_item_hover(item: Dictionary):
	if current_menu != BattleMenu.DIGIVICE:
		return
	log_label.text = "%s — %s" % [item.get("name", ""), item.get("description", "")]

func _on_item_hover_exit():
	if current_menu != BattleMenu.DIGIVICE:
		return
	log_label.text = ""

func _update_catch_button():
	var enemy_name = enemy_digimon.get("name", "")
	var can_catch = SaveData.can_catch(enemy_name) and not SaveData.is_caught(enemy_name)
	catch_button.disabled = not can_catch
	catch_button.text = "Catch %s!" % enemy_name if can_catch else "Catch"

func _on_item_pressed(item_name: String):
	if battle_over or is_showing_log:
		return

	var item = ItemDB.get_item(item_name)
	if item.is_empty() or _get_item_count(item_name) <= 0:
		return

	if item.get("effect", "") == "revive":
		_show_revive_popup(item_name)
		return

	var used = ItemDB.apply_item_effect(item, player_digimon)
	if not used:
		log_label.text = "%s won't have any effect!" % item_name
		return

	SaveData.use_item(item_name)

	_set_buttons_enabled(false)
	_add_log("%s used %s!" % [player_digimon["name"], item_name])
	_add_log(_get_item_effect_description(item))
	_show_next_log()
	_update_player_ui()
	_update_digivice_panel()
	_show_main_menu()
	await get_tree().create_timer(1.5).timeout
	await _enemy_turn()
	if not battle_over:
		_set_buttons_enabled(true)

func _on_catch_pressed():
	if battle_over or is_showing_log:
		return
	var enemy_name = enemy_digimon.get("name", "")
	if not SaveData.can_catch(enemy_name) or SaveData.is_caught(enemy_name):
		return

	_set_buttons_enabled(false)
	if SaveData.catch_digimon(enemy_name):
		_add_log("Gotcha! %s joined your party!" % enemy_name)
	else:
		_add_log("Party is full! %s couldn't be kept." % enemy_name)
	_show_next_log()
	await get_tree().create_timer(1.2).timeout
	await _handle_victory(true)

func _get_item_effect_description(item: Dictionary) -> String:
	match item["effect"]:
		"heal":
			return "Restored %d HP!" % item["value"]
		"full_recovery":
			return "HP, SP and status fully restored!"
		"revive":
			return "Fully restored and revived!"
		"restore_sp":
			if item["value"] >= 999:
				return "All SP restored!"
			return "Restored %d SP!" % item["value"]
		"cure_burn", "cure_freeze", "cure_paralysis", "cure_confusion", "cure_poison", "cure_sleep", "cure_stun", "cure_all":
			return "%s's status was cured!" % player_digimon["name"]
		"boost":
			return "%s permanently +%d!" % [item["stat"].to_upper(), item["value"]]
		"boost_all":
			return "All stats permanently +%d!" % item["value"]
		"boost_two":
			return "%s & %s permanently +%d!" % [item["stat1"].to_upper(), item["stat2"].to_upper(), item["value"]]
	return ""

func _gain_battle_scan(amount: int):
	var enemy_name = enemy_digimon.get("name", "")
	var before = SaveData.get_collection_percent(enemy_name)
	var after = SaveData.gain_enemy_scan(enemy_name, amount)
	SaveData.gain_digivice_scan(amount)
	if after > before and after >= SaveData.COLLECTION_MAX and not battle_over and not SaveData.is_caught(enemy_name):
		_add_log("Scan complete! %s can be caught!" % enemy_name)
		_show_next_log()
	_update_scan_display()
	if current_menu == BattleMenu.DIGIVICE:
		_update_digivice_panel()
	_pulse_scan_bars()

func _pulse_scan_bars():
	var tween = create_tween()
	tween.tween_property(scan_mini_bar, "modulate", Color(0.3, 1.0, 1.0), 0.15)
	tween.tween_property(scan_mini_bar, "modulate", Color.WHITE, 0.25)

# ─────────────────────────────────────────────────────
#  PLAYER MOVE
# ─────────────────────────────────────────────────────

func _on_move_pressed(move_index: int):
	if battle_over or is_showing_log:
		return

	var moves = player_digimon.get("moves", [])
	var move_name = ""
	if strike_fallback and move_index == 0:
		move_name = "Strike"
	else:
		if move_index >= moves.size():
			return
		move_name = moves[move_index]

	if not BattleSystem.can_use_move(player_digimon, move_name):
		log_label.text = "Not enough SP for %s!" % move_name
		return

	_set_buttons_enabled(false)
	move_panel.visible = false
	await _execute_full_turn(move_name)

# ─────────────────────────────────────────────────────
#  RUN
# ─────────────────────────────────────────────────────

func _on_run_pressed():
	if battle_over or is_showing_log:
		return

	if randf() < 0.7:
		_add_log("Got away safely!")
		_show_next_log()
		await get_tree().create_timer(1.5).timeout
		get_tree().change_scene_to_file("res://Scenes/StageMap.tscn")
	else:
		_set_buttons_enabled(false)
		_show_main_menu()
		_add_log("Couldn't escape!")
		_show_next_log()
		await get_tree().create_timer(1.2).timeout
		await _enemy_turn()
		if not battle_over:
			_set_buttons_enabled(true)

# ─────────────────────────────────────────────────────
#  FULL TURN
# ─────────────────────────────────────────────────────

func _execute_full_turn(player_move_name: String):
	turn_number += 1
	player_swapped_this_turn = false
	BattleSystem.use_move_sp(player_digimon, player_move_name)

	var player_can_act = not BattleSystem.is_frozen(player_digimon)
	if not player_can_act:
		if randf() < 0.3:
			player_digimon["status"] = "none"
			player_can_act = true
			_add_log("%s thawed out!" % player_digimon["name"])

	# Pre-pick the enemy's move so priority moves (e.g. Guard) act first
	var enemy_move = ""
	if not BattleSystem.is_frozen(enemy_digimon):
		enemy_move = BattleSystem.get_random_valid_enemy_move(enemy_digimon)

	var player_first = BattleSystem.who_goes_first(player_digimon, enemy_digimon, player_move_name, enemy_move) == 1

	if player_first:
		if player_can_act:
			await _player_attack(player_move_name)
		else:
			_add_log("%s is frozen and can't move!" % player_digimon["name"])
		if not battle_over:
			await get_tree().create_timer(0.8).timeout
			await _enemy_turn(enemy_move)
	else:
		await _enemy_turn(enemy_move)
		if not battle_over:
			await get_tree().create_timer(0.8).timeout
			if player_swapped_this_turn:
				_add_log("%s takes the front line!" % player_digimon["name"])
				_show_next_log()
				await get_tree().create_timer(1.0).timeout
			elif player_can_act:
				await _player_attack(player_move_name)
			else:
				_add_log("%s is frozen and can't move!" % player_digimon["name"])

	if not battle_over:
		await _process_end_of_turn_status()

	if not battle_over:
		_set_buttons_enabled(true)
		_update_all_ui()
		_show_main_menu()

# ─────────────────────────────────────────────────────
#  ATTACKS
# ─────────────────────────────────────────────────────

func _player_attack(move_name: String):
	if BattleSystem.is_confused(player_digimon):
		if BattleSystem.should_hit_self_when_confused():
			_add_log("%s is confused and hit itself!" % player_digimon["name"])
			var self_damage = int(player_digimon["hp"] * 0.1)
			player_digimon["current_hp"] = max(0, player_digimon["current_hp"] - self_damage)
			_update_player_ui()
			_show_next_log()
			await get_tree().create_timer(1.0).timeout
			await _check_player_fainted()
			return

	await _lunge_attack(player_sprite, enemy_sprite)
	var result = BattleSystem.calculate_damage(player_digimon, enemy_digimon, move_name)

	_add_log(result["description"])
	_show_next_log()
	await get_tree().create_timer(1.0).timeout

	if result["damage"] > 0:
		enemy_digimon["current_hp"] = max(0, enemy_digimon["current_hp"] - result["damage"])
		_update_enemy_ui()
		_gain_battle_scan(randi_range(2, 5))

	BattleSystem.apply_status_effect(player_digimon, enemy_digimon, move_name)
	var new_status = enemy_digimon.get("status", "none")
	if new_status != "none":
		_add_log("%s is now %s!" % [enemy_digimon["name"], new_status])
		_show_next_log()
		await get_tree().create_timer(1.0).timeout

	_update_enemy_ui()
	await _check_enemy_fainted()

func _enemy_turn(enemy_move: String = ""):
	if battle_over:
		return

	if BattleSystem.is_frozen(enemy_digimon):
		if randf() < 0.3:
			enemy_digimon["status"] = "none"
			_add_log("%s thawed out!" % enemy_digimon["name"])
		else:
			_add_log("%s is frozen and can't move!" % enemy_digimon["name"])
			_show_next_log()
			await get_tree().create_timer(1.0).timeout
			return

	if BattleSystem.is_confused(enemy_digimon):
		if BattleSystem.should_hit_self_when_confused():
			_add_log("%s is confused and hit itself!" % enemy_digimon["name"])
			var self_damage = int(enemy_digimon["hp"] * 0.1)
			enemy_digimon["current_hp"] = max(0, enemy_digimon["current_hp"] - self_damage)
			_update_enemy_ui()
			_show_next_log()
			await get_tree().create_timer(1.0).timeout
			await _check_enemy_fainted()
			return

	if enemy_move == "":
		enemy_move = BattleSystem.get_random_valid_enemy_move(enemy_digimon)
	BattleSystem.use_move_sp(enemy_digimon, enemy_move)

	await _lunge_attack(enemy_sprite, player_sprite)
	var result = BattleSystem.calculate_damage(enemy_digimon, player_digimon, enemy_move)

	_add_log(result["description"])
	_show_next_log()
	await get_tree().create_timer(1.0).timeout

	if result["damage"] > 0:
		player_digimon["current_hp"] = max(0, player_digimon["current_hp"] - result["damage"])
		SaveData.current_digimon["current_hp"] = player_digimon["current_hp"]
		_update_player_ui()

	BattleSystem.apply_status_effect(enemy_digimon, player_digimon, enemy_move)
	var new_status = player_digimon.get("status", "none")
	if new_status != "none":
		_add_log("%s is now %s!" % [player_digimon["name"], new_status])
		_show_next_log()
		await get_tree().create_timer(1.0).timeout

	_update_player_ui()
	await _check_player_fainted()

# ─────────────────────────────────────────────────────
#  STATUS DAMAGE
# ─────────────────────────────────────────────────────

func _process_end_of_turn_status():
	var player_status_dmg = BattleSystem.process_status_damage(player_digimon)
	if player_status_dmg > 0:
		player_digimon["current_hp"] = max(0, player_digimon["current_hp"] - player_status_dmg)
		SaveData.current_digimon["current_hp"] = player_digimon["current_hp"]
		_add_log("%s took %d damage from %s!" % [
			player_digimon["name"], player_status_dmg, player_digimon.get("status", "")
		])
		_show_next_log()
		_update_player_ui()
		await get_tree().create_timer(1.0).timeout
		await _check_player_fainted()

	if battle_over:
		return

	var enemy_status_dmg = BattleSystem.process_status_damage(enemy_digimon)
	if enemy_status_dmg > 0:
		enemy_digimon["current_hp"] = max(0, enemy_digimon["current_hp"] - enemy_status_dmg)
		_add_log("%s took %d damage from %s!" % [
			enemy_digimon["name"], enemy_status_dmg, enemy_digimon.get("status", "")
		])
		_show_next_log()
		_update_enemy_ui()
		await get_tree().create_timer(1.0).timeout
		await _check_enemy_fainted()

# ─────────────────────────────────────────────────────
#  WIN / LOSE
# ─────────────────────────────────────────────────────

func _check_enemy_fainted():
	if enemy_digimon["current_hp"] <= 0 and not battle_over:
		battle_over = true
		await _handle_victory()

func _check_player_fainted():
	if player_digimon["current_hp"] <= 0 and not battle_over:
		battle_over = true
		_set_buttons_enabled(false)
		_add_log("%s fainted!" % player_digimon["name"])
		_show_next_log()
		await get_tree().create_timer(1.0).timeout
		if _try_party_swap():
			_add_log("Go, %s!" % player_digimon["name"])
			_show_next_log()
			await get_tree().create_timer(1.0).timeout
			battle_over = false
		elif _try_guest_swap():
			_setup_ui()
			_update_all_ui()
			_add_log("Go, %s!" % player_digimon["name"])
			_show_next_log()
			await get_tree().create_timer(1.0).timeout
			battle_over = false
		elif _try_revive_item():
			_update_all_ui()
			_add_log("Come back, %s!" % player_digimon["name"])
			_show_next_log()
			await get_tree().create_timer(1.0).timeout
			battle_over = false
		else:
			await _handle_defeat()

var _pending_revive_item: String = ""

func _show_revive_popup(item_name: String):
	_pending_revive_item = item_name
	for child in revive_list.get_children():
		child.queue_free()
	for d in SaveData.digimon_roster:
		if d.get("current_hp", 1) <= 0:
			var btn = Button.new()
			btn.custom_minimum_size = Vector2(0, 36)
			btn.add_theme_font_size_override("font_size", 14)
			btn.text = "%s  (Lv.%d)  HP: %d/%d" % [d.get("name","???"), d.get("level",1), d.get("current_hp",0), d.get("hp",1)]
			btn.pressed.connect(_on_revive_target.bind(d))
			revive_list.add_child(btn)
	if revive_list.get_child_count() == 0:
		var lbl = Label.new()
		lbl.text = "No fainted Digimon to revive."
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		revive_list.add_child(lbl)
	revive_popup.visible = true
	revive_popup.mouse_filter = Control.MOUSE_FILTER_STOP

func _on_revive_target(d: Dictionary):
	revive_popup.visible = false
	var item = ItemDB.get_item(_pending_revive_item)
	if item.is_empty():
		return
	ItemDB.apply_item_effect(item, d)
	SaveData.use_item(_pending_revive_item)
	_add_log("%s was revived!" % d.get("name", "???"))
	_show_next_log()
	_update_all_ui()
	_build_member_list()
	_build_member_sprites()
	_display_member(d)
	_update_panel_sprite(digimon_sprite)
	_update_digivice_panel()

func _on_revive_cancel():
	revive_popup.visible = false
	_pending_revive_item = ""

func _try_revive_item() -> bool:
	"""Use a revive/full-recovery item from inventory to bring the fainted digimon back."""
	for entry in SaveData.items:
		var item = ItemDB.get_item(entry["name"])
		if item.is_empty():
			continue
		var eff = item.get("effect", "")
		if eff != "revive" and eff != "full_recovery":
			continue
		if SaveData.use_item(entry["name"]):
			ItemDB.apply_item_effect(item, player_digimon)
			return true
	return false

func _try_party_swap() -> bool:
	var fainted_name = player_digimon.get("name", "")
	for d in SaveData.digimon_roster:
		if d.get("name", "") == fainted_name:
			continue
		if d.get("current_hp", 0) <= 0:
			continue
		player_digimon = d
		SaveData.current_digimon = d
		var p_back_path = player_digimon.get("sprite_back", "")
		var p_front_path = player_digimon.get("sprite", "")
		if p_back_path != "" and ResourceLoader.exists(p_back_path):
			player_sprite.texture = load(p_back_path)
		elif p_front_path != "" and ResourceLoader.exists(p_front_path):
			player_sprite.texture = load(p_front_path)
			player_sprite.flip_h = true
		_fit_sprite(player_sprite, 450.0, 540.0, player_digimon.get("stage", ""))
		_setup_ui()
		_update_all_ui()
		player_swapped_this_turn = true
		return true
	return false

func _try_guest_swap() -> bool:
	if SaveData.guest_roster.is_empty():
		return false
	var guest: Dictionary = SaveData.guest_roster.pop_front()
	guest["current_hp"] = guest["hp"]
	guest["status"] = "none"
	guest["current_sp"] = guest["sp"]
	player_digimon = guest
	SaveData.current_digimon = guest
	player_swapped_this_turn = true
	return true

func _handle_victory(caught: bool = false):
	_set_buttons_enabled(false)

	var tween = create_tween()
	tween.tween_property(enemy_sprite, "modulate", Color(0.3, 0.3, 0.3), 0.5)
	await get_tree().create_timer(0.5).timeout

	if caught:
		_add_log("%s was caught and joined your collection!" % enemy_digimon["name"])
	else:
		_add_log("%s fainted!" % enemy_digimon["name"])
	_show_next_log()
	await get_tree().create_timer(1.2).timeout

	SaveData.last_defeated_enemy = enemy_digimon.get("name", "")

	var rewards = BattleSystem.get_victory_rewards(enemy_digimon, SaveData.floor_number)
	_add_log("You won!")
	_add_log("Gained %d XP!" % rewards["xp"])
	_add_log("Gained %d Digi!" % rewards["digi"])
	_show_next_log()

	SaveData.add_digi(rewards["digi"])
	var old_level = player_digimon.get("level", 1)
	SaveData.last_battle_old_level = old_level
	# Snapshot stats so RewardScene can show the "old → new" arrows
	SaveData.last_battle_old_stats = {
		"hp": player_digimon.get("hp", 0),
		"attack": player_digimon.get("attack", 0),
		"defense": player_digimon.get("defense", 0),
		"sp_attack": player_digimon.get("sp_attack", 0),
		"speed": player_digimon.get("speed", 0),
	}
	# Active digimon AND the whole bench gain XP
	SaveData.gain_battle_experience(rewards["xp"])

	# Collection scan: 15–25% per defeated enemy
	var scan_gain = randi_range(15, 25)
	SaveData.gain_enemy_scan(enemy_digimon.get("name", ""), scan_gain)
	SaveData.gain_digivice_scan(scan_gain)
	_add_log("Scanned %s! +%d%% collection" % [enemy_digimon["name"], scan_gain])
	var enemy_name = enemy_digimon.get("name", "")
	if SaveData.can_catch(enemy_name) and not SaveData.is_caught(enemy_name):
		_add_log("%s scan COMPLETE — catch it next time!" % enemy_name)
	_show_next_log()

	player_digimon = SaveData.current_digimon
	_update_all_ui()
	await get_tree().create_timer(2.0).timeout

	if player_digimon.get("level", 1) > old_level:
		_add_log("%s is now Level %d!" % [player_digimon["name"], player_digimon["level"]])
		_show_next_log()
		await get_tree().create_timer(1.5).timeout

	SaveData.advance_floor()
	get_tree().change_scene_to_file("res://Scenes/RewardScene.tscn")

func _handle_defeat():
	_set_buttons_enabled(false)

	var tween = create_tween()
	tween.tween_property(player_sprite, "modulate", Color(0.3, 0.3, 0.3), 0.5)
	await get_tree().create_timer(0.5).timeout

	_add_log("%s fainted!" % player_digimon["name"])
	_show_next_log()
	await get_tree().create_timer(1.5).timeout
	_add_log("You were defeated...")
	_show_next_log()
	await get_tree().create_timer(1.5).timeout
	_add_log("Reached Floor %d" % SaveData.floor_number)
	_show_next_log()
	await get_tree().create_timer(1.5).timeout

	SaveData.end_run(false)
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")

func _flash_sprite(sprite: Sprite2D):
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(2.0, 2.0, 2.0), 0.1)
	tween.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0), 0.1)
	tween.tween_property(sprite, "modulate", Color(2.0, 2.0, 2.0), 0.1)
	tween.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0), 0.1)
	await get_tree().create_timer(0.4).timeout

func _lunge_attack(attacker: Sprite2D, target: Sprite2D):
	var original_pos = attacker.position
	var dir = (target.position - original_pos).normalized()
	var lunge_dist = original_pos.distance_to(target.position) * 0.45
	var target_pos = original_pos + dir * lunge_dist

	var tween = create_tween()
	tween.tween_property(attacker, "position", target_pos, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(attacker, "scale", Vector2(attacker.scale.x * 1.1, attacker.scale.y * 1.1), 0.08)
	tween.tween_property(attacker, "scale", Vector2(attacker.scale.x, attacker.scale.y), 0.08)
	await tween.finished

	await _flash_sprite(target)

	var return_tween = create_tween()
	return_tween.tween_property(attacker, "position", original_pos, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await return_tween.finished
