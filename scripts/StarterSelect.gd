extends Control

# ─────────────────────────────────────────────────────
#  STARTER SELECT SCENE
#  Like PokeRogue - shows all 8 starters, lets player
#  click to preview stats, then confirm their pick
# ─────────────────────────────────────────────────────

# ── SCENE NODE REFERENCES ────────────────────────────
# (These match the node names you'll create in the .tscn)
@onready var starter_grid    = $MarginContainer/VBox/HBox/StarterGrid
@onready var detail_panel    = $MarginContainer/VBox/HBox/DetailPanel
@onready var detail_name     = $MarginContainer/VBox/HBox/DetailPanel/VBox/InnerMargin/Scroll/DetailScroll/DigimonName
@onready var detail_type     = $MarginContainer/VBox/HBox/DetailPanel/VBox/InnerMargin/Scroll/DetailScroll/TypeLabel
@onready var detail_desc     = $MarginContainer/VBox/HBox/DetailPanel/VBox/InnerMargin/Scroll/DetailScroll/Description
@onready var detail_sprite   = $MarginContainer/VBox/HBox/DetailPanel/VBox/InnerMargin/Scroll/DetailScroll/SpritePreview
@onready var stat_hp         = $MarginContainer/VBox/HBox/DetailPanel/VBox/InnerMargin/Scroll/DetailScroll/Stats/HPBar
@onready var stat_atk        = $MarginContainer/VBox/HBox/DetailPanel/VBox/InnerMargin/Scroll/DetailScroll/Stats/ATKBar
@onready var stat_def        = $MarginContainer/VBox/HBox/DetailPanel/VBox/InnerMargin/Scroll/DetailScroll/Stats/DEFBar
@onready var stat_spd        = $MarginContainer/VBox/HBox/DetailPanel/VBox/InnerMargin/Scroll/DetailScroll/Stats/SPDBar
@onready var stat_hp_val     = $MarginContainer/VBox/HBox/DetailPanel/VBox/InnerMargin/Scroll/DetailScroll/Stats/HPVal
@onready var stat_atk_val    = $MarginContainer/VBox/HBox/DetailPanel/VBox/InnerMargin/Scroll/DetailScroll/Stats/ATKVal
@onready var stat_def_val    = $MarginContainer/VBox/HBox/DetailPanel/VBox/InnerMargin/Scroll/DetailScroll/Stats/DEFVal
@onready var stat_spd_val    = $MarginContainer/VBox/HBox/DetailPanel/VBox/InnerMargin/Scroll/DetailScroll/Stats/SPDVal
@onready var moves_label     = $MarginContainer/VBox/HBox/DetailPanel/VBox/InnerMargin/Scroll/DetailScroll/MovesLabel
@onready var evo_label       = $MarginContainer/VBox/HBox/DetailPanel/VBox/InnerMargin/Scroll/DetailScroll/EvoLabel
@onready var confirm_button  = $MarginContainer/VBox/HBox/DetailPanel/VBox/ConfirmButton
@onready var title_label     = $MarginContainer/VBox/TitleLabel
@onready var sub_label       = $MarginContainer/VBox/SubLabel

# ── STATE ────────────────────────────────────────────
var selected_starters: Array = []   # names the player picked
var selected_starter: String = ""   # currently previewed starter name
var starter_buttons = {}            # name → Button (card) node
const STARTER_COST = 6              # capacity cost per starter
const MAX_PARTY_CAPACITY = 20

# ── GACHA UI (built at runtime) ──────────────────────
var ticket_label: Label
var gacha_panel_ticket_label: Label
var gacha_result_label: Label
var gacha_overlay: Control = null

# ── STARTER LIST ─────────────────────────────────────
# The 8 available starters
const STARTERS = [
	"Agumon",
	"Gabumon",
	"Patamon",
	"Tentomon",
	"Palmon",
	"Biyomon",
	"Gomamon",
	"DemiDevimon",
]

# ── TYPE COLORS ──────────────────────────────────────
# Used to color the type badge on each card
const TYPE_COLORS = {
	"vaccine": Color(0.3, 0.8, 1.0),
	"virus":   Color(1.0, 0.3, 0.3),
	"data":    Color(1.0, 0.85, 0.2),
}

const TYPE_ICONS = {
	"vaccine": "res://assets/type_icons/vaccine.png",
	"virus":   "res://assets/type_icons/virus.png",
	"data":    "res://assets/type_icons/data.png",
}

# ─────────────────────────────────────────────────────
#  READY - build the scene
# ─────────────────────────────────────────────────────

func _ready():
	title_label.text = "Choose your Digimon party"
	sub_label.text   = "Capacity: 0 / %d  (each starter costs %d)" % [MAX_PARTY_CAPACITY, STARTER_COST]
	
	confirm_button.text = "Start Run!"
	confirm_button.disabled = true
	confirm_button.pressed.connect(_on_confirm_pressed)
	
	_build_starter_grid()
	_build_gacha_ui()
	
	# Auto-select the first one to show detail panel
	_preview_starter("Agumon")

# ─────────────────────────────────────────────────────
#  BUILD THE GRID OF STARTER CARDS
# ─────────────────────────────────────────────────────

func _get_all_starter_names() -> Array:
	"""The 8 base starters + any Digimon pulled from the gacha."""
	var names = []
	for n in STARTERS:
		names.append(n)
	for n in GachaData.get_owned_names():
		if n not in names:
			names.append(n)
	return names

func _build_starter_grid():
	# Clear existing children
	for child in starter_grid.get_children():
		child.queue_free()
	
	for starter_name in _get_all_starter_names():
		var data = DigimonDB.get_digimon(starter_name)
		if data.is_empty():
			continue
		
		# ── Build card container ─────────────────────
		var card = PanelContainer.new()
		card.custom_minimum_size = Vector2(110, 130)
		card.name = starter_name + "Card"

		var card_bg = StyleBoxFlat.new()
		card_bg.bg_color = Color(0.08, 0.08, 0.15, 0.92)
		card_bg.corner_radius_top_left     = 8
		card_bg.corner_radius_top_right    = 8
		card_bg.corner_radius_bottom_left  = 8
		card_bg.corner_radius_bottom_right = 8
		card_bg.content_margin_left   = 4
		card_bg.content_margin_right  = 4
		card_bg.content_margin_top    = 4
		card_bg.content_margin_bottom = 4
		card.add_theme_stylebox_override("panel", card_bg)
		
		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		card.add_child(vbox)
		
		# Sprite or colored placeholder
		var sprite = TextureRect.new()
		sprite.custom_minimum_size = Vector2(64, 64)
		sprite.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		if ResourceLoader.exists(data["sprite"]):
			sprite.texture = load(data["sprite"])
		else:
			# Placeholder colored box when sprite not yet downloaded
			var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
			img.fill(TYPE_COLORS.get(data["type"], Color.WHITE))
			sprite.texture = ImageTexture.create_from_image(img)
		
		vbox.add_child(sprite)
		
		# Name label
		var name_label = Label.new()
		name_label.text = starter_name
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 12)
		vbox.add_child(name_label)
		
		# Star level (from gacha duplicates)
		var stars = GachaData.get_stars(starter_name)
		if stars > 0:
			var star_label = Label.new()
			star_label.text = "★" + "★".repeat(maxi(stars - 1, 0))
			star_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			star_label.add_theme_font_size_override("font_size", 12)
			star_label.modulate = Color(1.0, 0.85, 0.2)
			vbox.add_child(star_label)
		
		# Type badge with icon
		var type_hbox = HBoxContainer.new()
		type_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		type_hbox.add_theme_constant_override("separation", 4)
		vbox.add_child(type_hbox)
		
		var type_icon = TextureRect.new()
		type_icon.custom_minimum_size = Vector2(14, 14)
		type_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		type_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var icon_path = TYPE_ICONS.get(data["type"], "")
		if icon_path != "" and ResourceLoader.exists(icon_path):
			type_icon.texture = load(icon_path)
		type_hbox.add_child(type_icon)
		
		var type_label = Label.new()
		type_label.text = data["type"].capitalize()
		type_label.add_theme_font_size_override("font_size", 10)
		type_label.modulate = TYPE_COLORS.get(data["type"], Color.WHITE)
		type_hbox.add_child(type_label)
		
		# Capacity cost
		var cost_label = Label.new()
		cost_label.text = "Cost: %d" % STARTER_COST
		cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cost_label.add_theme_font_size_override("font_size", 9)
		cost_label.modulate = Color(0.7, 0.7, 0.7)
		vbox.add_child(cost_label)
		
		# Clickable button (invisible, overlays the whole card)
		var btn = Button.new()
		btn.flat = true
		btn.name = starter_name + "Btn"
		btn.pressed.connect(_on_card_pressed.bind(starter_name))
		card.add_child(btn)
		
		starter_buttons[starter_name] = card
		starter_grid.add_child(card)

# ─────────────────────────────────────────────────────
#  TOGGLE SELECTION + PREVIEW
# ─────────────────────────────────────────────────────

func _on_card_pressed(starter_name: String):
	"""Click a card: toggle it in/out of selection, always preview details."""
	var data = DigimonDB.get_digimon(starter_name)
	if data.is_empty():
		return
	
	if starter_name in selected_starters:
		selected_starters.erase(starter_name)
	else:
		var cost = STARTER_COST
		var used = selected_starters.size() * STARTER_COST
		if used + cost > MAX_PARTY_CAPACITY:
			return  # can't fit
		selected_starters.append(starter_name)
	
	_refresh_card_highlights()
	_update_capacity_label()
	_preview_starter(starter_name)

func _preview_starter(starter_name: String):
	selected_starter = starter_name
	_update_detail_panel(starter_name)
	_update_confirm_button()

func _refresh_card_highlights():
	for name in starter_buttons:
		var card = starter_buttons[name]
		if name in selected_starters:
			card.add_theme_stylebox_override("panel", _make_selected_style())
		else:
			card.remove_theme_stylebox_override("panel")

func _update_capacity_label():
	var used = selected_starters.size() * STARTER_COST
	sub_label.text = "Capacity: %d / %d  (%d Digimon)" % [used, MAX_PARTY_CAPACITY, selected_starters.size()]

func _update_confirm_button():
	if selected_starters.is_empty():
		confirm_button.disabled = true
		confirm_button.text = "Start Run!"
	else:
		confirm_button.disabled = false
		if selected_starters.size() == 1:
			confirm_button.text = "Start with %s!" % selected_starters[0]
		else:
			confirm_button.text = "Start with %d Digimon!" % selected_starters.size()

# ─────────────────────────────────────────────────────
#  UPDATE DETAIL PANEL
# ─────────────────────────────────────────────────────

func _update_detail_panel(starter_name: String):
	var data = DigimonDB.get_digimon(starter_name)
	if data.is_empty():
		return
	
	# Name and type
	detail_name.text = data["name"]
	detail_type.text = data["type"].capitalize()
	detail_type.modulate = TYPE_COLORS.get(data["type"], Color.WHITE)
	
	# Description
	detail_desc.text = data.get("description", "A powerful Digimon partner.")
	
	# Sprite preview
	if ResourceLoader.exists(data["sprite"]):
		detail_sprite.texture = load(data["sprite"])
	else:
		var img = Image.create(128, 128, false, Image.FORMAT_RGBA8)
		img.fill(TYPE_COLORS.get(data["type"], Color.GRAY))
		detail_sprite.texture = ImageTexture.create_from_image(img)
	
	if starter_name == "DemiDevimon":
		detail_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		detail_sprite.custom_minimum_size = Vector2(200, 200)
		detail_sprite.size = Vector2(200, 200)
	else:
		detail_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		detail_sprite.custom_minimum_size = Vector2(192, 192)
		detail_sprite.size = Vector2(192, 192)
	
	# Stat bars (max values for scaling: HP=150, others=60)
	stat_hp.value  = float(data["hp"]) / 150.0 * 100.0
	stat_atk.value = float(data["attack"]) / 60.0 * 100.0
	stat_def.value = float(data["defense"]) / 60.0 * 100.0
	stat_spd.value = float(data["speed"]) / 60.0 * 100.0
	
	stat_hp_val.text  = str(data["hp"])
	stat_atk_val.text = str(data["attack"])
	stat_def_val.text = str(data["defense"])
	stat_spd_val.text = str(data["speed"])
	
	# Moves list
	var moves_text = "Moves: "
	for move_name in data["moves"]:
		var move = DigimonDB.get_move(move_name)
		if not move.is_empty():
			moves_text += "%s (%s)  " % [move_name, move["type"]]
	moves_label.text = moves_text
	
	# Evolution chain
	var evo_text = "Evolution: " + starter_name
	var current = starter_name
	var steps = 0
	
	while steps < 5:
		if not DigimonDB.has_digimon(current):
			break
		var current_data = DigimonDB.get_digimon(current)
		if current_data.is_empty() or current_data["evolves_to"] == "":
			break
		current = current_data["evolves_to"]
		evo_text += " → " + current
		steps += 1
	
	evo_label.text = evo_text

# ─────────────────────────────────────────────────────
#  CONFIRM SELECTION
# ─────────────────────────────────────────────────────

func _on_confirm_pressed():
	if selected_starters.is_empty():
		return
	
	# Flash confirm animation
	var tween = create_tween()
	tween.tween_property(confirm_button, "modulate", Color.GREEN, 0.2)
	tween.tween_interval(0.5)
	tween.tween_callback(_start_game_with_starters)

func _start_game_with_starters():
	SaveData.start_new_run(selected_starters)
	
	print("[StarterSelect] Player chose %s. Starting run!" % selected_starters)
	
	get_tree().change_scene_to_file("res://Scenes/StageMap.tscn")

# ─────────────────────────────────────────────────────
#  HELPER - selected card style
# ─────────────────────────────────────────────────────

func _make_selected_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.25, 0.2, 0.55, 0.92)
	style.border_width_top    = 2
	style.border_width_bottom = 2
	style.border_width_left   = 2
	style.border_width_right  = 2
	style.border_color = Color(0.5, 0.4, 1.0)
	style.corner_radius_top_left     = 8
	style.corner_radius_top_right    = 8
	style.corner_radius_bottom_left  = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left   = 4
	style.content_margin_right  = 4
	style.content_margin_top    = 4
	style.content_margin_bottom = 4
	return style

# ─────────────────────────────────────────────────────
#  GACHA — side button + pull overlay
# ─────────────────────────────────────────────────────

func _build_gacha_ui():
	var side = VBoxContainer.new()
	side.custom_minimum_size = Vector2(140, 0)
	side.add_theme_constant_override("separation", 8)

	ticket_label = Label.new()
	ticket_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ticket_label.add_theme_font_size_override("font_size", 13)
	side.add_child(ticket_label)

	var gacha_btn = Button.new()
	gacha_btn.text = "Digimon Gacha"
	gacha_btn.add_theme_font_size_override("font_size", 13)
	gacha_btn.pressed.connect(_open_gacha_panel)
	side.add_child(gacha_btn)

	var hint = Label.new()
	hint.text = "Pull Champion Digimon!\n\nTickets come only\nfrom rare item drops."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 11)
	hint.modulate = Color(0.8, 0.85, 1.0)
	side.add_child(hint)

	$MarginContainer/VBox/HBox.add_child(side)
	_refresh_ticket_label()

func _refresh_ticket_label():
	ticket_label.text = "Tickets: %d" % GachaData.tickets

func _open_gacha_panel():
	if gacha_overlay != null:
		return

	gacha_overlay = Control.new()
	gacha_overlay.name = "GachaOverlay"
	gacha_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	gacha_overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	gacha_overlay.add_child(dim)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	gacha_overlay.add_child(center)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(580, 0)
	center.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "Digimon Gacha"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)

	gacha_panel_ticket_label = Label.new()
	gacha_panel_ticket_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gacha_panel_ticket_label.text = "Tickets: %d" % GachaData.tickets
	gacha_panel_ticket_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(gacha_panel_ticket_label)

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	vbox.add_child(row)

	var b1 = Button.new()
	b1.text = "Pull 1x\n1 Ticket"
	b1.custom_minimum_size = Vector2(180, 70)
	b1.pressed.connect(_do_pull.bind(1))
	row.add_child(b1)

	var b5 = Button.new()
	b5.text = "Pull 5x\n5 Tickets\nbetter odds"
	b5.custom_minimum_size = Vector2(180, 70)
	b5.pressed.connect(_do_pull.bind(5))
	row.add_child(b5)

	var b10 = Button.new()
	b10.text = "Pull 10x\n10 Tickets\n★ 1 Champion Guaranteed!"
	b10.custom_minimum_size = Vector2(180, 70)
	b10.pressed.connect(_do_pull.bind(10))
	row.add_child(b10)

	gacha_result_label = Label.new()
	gacha_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	gacha_result_label.custom_minimum_size = Vector2(0, 240)
	gacha_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gacha_result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	gacha_result_label.add_theme_font_size_override("font_size", 14)
	gacha_result_label.text = "Spend tickets to pull Digimon.\nDuplicates raise star levels → rare abilities!"
	vbox.add_child(gacha_result_label)

	var close_btn = Button.new()
	close_btn.text = "Close"
	close_btn.pressed.connect(_close_gacha_panel)
	vbox.add_child(close_btn)

	add_child(gacha_overlay)

func _do_pull(count: int):
	var res = GachaData.pull(count)
	if not res["ok"]:
		gacha_result_label.text = res["reason"]
		return

	_refresh_ticket_label()
	gacha_panel_ticket_label.text = "Tickets: %d" % res["tickets_left"]

	var lines = []
	for info in res["results"]:
		var line = info["name"]
		var extras = []
		if info["new"]:
			extras.append("NEW!")
		if info["upgraded"]:
			extras.append("★ +1 (now ★%d)" % info["stars"])
		if info["unlock"] == "dormant":
			extras.append("DORMANT ABILITY UNLOCKED!")
		if info["unlock"] == "rare":
			extras.append("RARE PASSIVE UNLOCKED!")
		if not extras.is_empty():
			line += "  [" + " | ".join(extras) + "]"
		lines.append(line)
	gacha_result_label.text = "\n".join(lines)

	# New pulls are now selectable as starters next run
	_build_starter_grid()
	if selected_starter != "":
		_preview_starter(selected_starter)

func _close_gacha_panel():
	if gacha_overlay != null:
		gacha_overlay.queue_free()
		gacha_overlay = null
