extends Control

# ─────────────────────────────────────────────────────
#  REWARD SCENE
#  Shown after every battle victory:
#  - XP / digi / scan rewards
#  - 3 paid loot slots: 1 healing, 1 revive, 1 SP
#    (buy 1 with Digi; tiered by floor; 3 free rerolls, then digi)
#  - 3 free pick slots (rarer as floors rise)
#  - Continue → Stage Map
# ─────────────────────────────────────────────────────

# ── NODE REFERENCES ──────────────────────────────────
@onready var floor_label        = $HeaderPanel/HeaderHBox/FloorLabel
@onready var gold_label         = $HeaderPanel/HeaderHBox/GoldLabel
@onready var digi_label         = $HeaderPanel/HeaderHBox/DigiLabel
@onready var result_label       = $ResultLabel
@onready var free_item_label    = $FreeItemLabel

@onready var digimon_sprite     = $DigimonSprite
@onready var digimon_name_label = $InfoPanel/VBox/DigimonName
@onready var digimon_level_label= $InfoPanel/VBox/DigimonLevel
@onready var digimon_type_label = $InfoPanel/VBox/DigimonType
@onready var hp_label           = $InfoPanel/VBox/HPLabel
@onready var xp_bar             = $InfoPanel/VBox/XPBar
@onready var xp_label           = $InfoPanel/VBox/XPLabel

@onready var level_up_panel     = $LevelUpPanel
@onready var level_up_label     = $LevelUpPanel/VBox/LevelUpLabel
@onready var stat_changes_label = $LevelUpPanel/VBox/StatChangesLabel

@onready var item_panel         = $ItemPanel
@onready var item_title_label   = $ItemPanel/VBox/TitleLabel
@onready var item1_button       = $ItemPanel/VBox/PaidContainer/Item1Button
@onready var item2_button       = $ItemPanel/VBox/PaidContainer/Item2Button
@onready var item3_button       = $ItemPanel/VBox/PaidContainer/Item3Button
@onready var item4_button       = $ItemPanel/VBox/FreeContainer/Item5Button
@onready var item5_button       = $ItemPanel/VBox/FreeContainer/Item6Button
@onready var item6_button       = $ItemPanel/VBox/FreeContainer/Item7Button
@onready var reroll_label       = $ItemPanel/VBox/BottomRow/RerollLabel
@onready var reroll_button      = $ItemPanel/VBox/BottomRow/RerollButton

@onready var continue_button    = $ContinueButton

# Party summary label (created dynamically)
var party_summary_label: Label

# ── STATE ─────────────────────────────────────────────
var paid_offers: Array = []   # 3 buyable items (heal / revive / SP)
var free_offers: Array = []   # 3 free pick items
var paid_chosen: bool  = false
var free_chosen: bool  = false

# ─────────────────────────────────────────────────────
#  READY
# ─────────────────────────────────────────────────────

func _ready():
	level_up_panel.visible  = false
	item_panel.visible      = false
	continue_button.visible = false
	free_item_label.text    = ""

	item1_button.pressed.connect(_on_item_chosen.bind(0))
	item2_button.pressed.connect(_on_item_chosen.bind(1))
	item3_button.pressed.connect(_on_item_chosen.bind(2))
	item4_button.pressed.connect(_on_item_chosen.bind(3))
	item5_button.pressed.connect(_on_item_chosen.bind(4))
	item6_button.pressed.connect(_on_item_chosen.bind(5))
	reroll_button.pressed.connect(_on_reroll_pressed)

	# Create party summary label dynamically
	party_summary_label = Label.new()
	party_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	party_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	party_summary_label.add_theme_font_size_override("font_size", 14)
	party_summary_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	# Position it below InfoPanel (which ends at y=-30 from bottom)
	var summary_container = PanelContainer.new()
	summary_container.name = "PartySummaryPanel"
	summary_container.anchor_left = 0.0
	summary_container.anchor_top = 1.0
	summary_container.anchor_right = 0.4
	summary_container.anchor_bottom = 1.0
	summary_container.offset_left = 120.0
	summary_container.offset_top = -520.0
	summary_container.offset_right = 520.0
	summary_container.offset_bottom = -310.0
	summary_container.grow_vertical = 0
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 6)
	summary_container.add_child(vbox)
	vbox.add_child(party_summary_label)
	add_child(summary_container)

	_update_header()
	_update_digimon_display()
	_update_party_summary()

	SaveData.refresh_rerolls()

	await get_tree().create_timer(0.5).timeout
	await _play_reward_sequence()

# ─────────────────────────────────────────────────────
#  UI UPDATES
# ─────────────────────────────────────────────────────

func _update_header():
	floor_label.text = "Floor %d cleared!" % (SaveData.floor_number - 1)
	gold_label.text  = "Tickets: %d" % GachaData.tickets
	digi_label.text  = "Digi: %d" % SaveData.digi

func _update_digimon_display():
	var d = SaveData.current_digimon

	var sprite_path = d.get("sprite", "")
	if sprite_path != "" and ResourceLoader.exists(sprite_path):
		digimon_sprite.texture = load(sprite_path)

	digimon_name_label.text  = d.get("name", "???")
	digimon_level_label.text = "Level %d" % d.get("level", 1)
	digimon_type_label.text  = d.get("type", "???").capitalize()

	var cur_hp = d.get("current_hp", 0)
	var max_hp = d.get("hp", 1)
	hp_label.text = "HP  %d / %d" % [cur_hp, max_hp]

	var cur_xp  = d.get("experience", 0)
	var next_xp = SaveData.get_xp_for_level(d.get("level", 1) + 1)
	xp_bar.max_value = next_xp
	xp_bar.value     = cur_xp
	xp_label.text    = "XP  %d / %d" % [cur_xp, next_xp]

func _update_party_summary():
	var lines: PackedStringArray = []
	lines.append("— Party Status —")
	for d in SaveData.digimon_roster:
		var name_str = d.get("name", "???")
		var lvl = d.get("level", 1)
		var cur_hp = d.get("current_hp", 0)
		var max_hp = d.get("hp", 1)
		var cur_xp = d.get("experience", 0)
		var next_xp = SaveData.get_xp_for_level(lvl + 1)
		var status = ""
		if cur_hp <= 0:
			status = " [FAINTED]"
		elif d.get("status", "none") != "none":
			status = " [%s]" % d.get("status", "").to_upper()
		lines.append("%s  Lv.%d  HP %d/%d  XP %d/%d%s" % [
			name_str, lvl, cur_hp, max_hp, cur_xp, next_xp, status
		])
	party_summary_label.text = "\n".join(lines)

# ─────────────────────────────────────────────────────
#  REWARD SEQUENCE
# ─────────────────────────────────────────────────────

func _play_reward_sequence():
	result_label.text = "Victory!"
	result_label.visible = true
	await _animate_label_in(result_label)
	await get_tree().create_timer(1.0).timeout

	# Level up display (only if the partner actually leveled this battle)
	var d = SaveData.current_digimon
	if d.get("level", 1) > SaveData.last_battle_old_level:
		await _show_level_up_info()

	await get_tree().create_timer(0.5).timeout
	await _show_item_choice()

func _show_level_up_info():
	var d = SaveData.current_digimon
	var old = SaveData.last_battle_old_stats
	level_up_label.text = "%s reached Level %d!" % [d["name"], d["level"]]

	# Show each stat as "OLD → NEW" when it grew this battle
	var lines = []
	for stat in ["hp", "attack", "defense", "sp_attack", "speed"]:
		var after = d.get(stat, 0)
		var before = old.get(stat, after) if not old.is_empty() else after
		if after > before:
			lines.append("%s  %d → %d" % [stat.to_upper(), before, after])
		else:
			lines.append("%s  %d" % [stat.to_upper(), after])
	stat_changes_label.text = "\n".join(lines)

	level_up_panel.visible = true
	level_up_panel.modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.tween_property(level_up_panel, "modulate", Color(1, 1, 1, 1), 0.4)
	await get_tree().create_timer(1.6).timeout
	level_up_panel.visible = false

# ─────────────────────────────────────────────────────
#  ITEM CHOICE — 3 paid loot slots + 3 free pick slots
#  Paid: 1 healing, 1 revive, 1 SP (buy 1 with digi)
#  Free: pick 1 of 3 random items (rarer as floors rise)
# ─────────────────────────────────────────────────────

func _show_item_choice():
	paid_chosen = false
	free_chosen = false
	_generate_offers()
	_update_offer_buttons()
	_update_reroll_ui()

	item_title_label.text = "Rewards! (floor %d)" % SaveData.floor_number
	item_panel.visible  = true
	item_panel.modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.tween_property(item_panel, "modulate", Color(1, 1, 1, 1), 0.4)

func _generate_offers():
	var floor_num = SaveData.floor_number
	paid_offers = [
		ItemDB.get_heal_for_floor(floor_num),
		ItemDB.get_revive_for_floor(floor_num),
		ItemDB.get_sp_for_floor(floor_num),
	]

	free_offers = []
	while free_offers.size() < 3:
		var candidate = ItemDB.get_random_item(floor_num)
		if candidate not in free_offers:
			free_offers.append(candidate)

func _get_item_price(item_name: String) -> int:
	return ItemDB.get_scaled_price(item_name, SaveData.floor_number)

func _update_offer_buttons():
	var paid_buttons = [item1_button, item2_button, item3_button]
	for i in range(3):
		var item = ItemDB.get_item(paid_offers[i])
		var price = _get_item_price(paid_offers[i])
		paid_buttons[i].text = "%s\n%s\n[%s]  %d Digi" % [
			item["name"],
			item["description"],
			item["rarity"].capitalize(),
			price
		]
		paid_buttons[i].disabled = false
		paid_buttons[i].modulate = Color(1, 1, 1, 1)

	var free_buttons = [item4_button, item5_button, item6_button]
	for i in range(3):
		var item = ItemDB.get_item(free_offers[i])
		free_buttons[i].text = "%s\n%s\n[%s]  FREE" % [
			item["name"],
			item["description"],
			item["rarity"].capitalize()
		]
		free_buttons[i].disabled = false
		free_buttons[i].modulate = Color(1, 1, 1, 1)

func _get_reroll_cost() -> int:
	return 25 + SaveData.floor_number * 5

func _update_reroll_ui():
	if SaveData.rerolls_left > 0:
		reroll_label.text = "Free rerolls: %d left" % SaveData.rerolls_left
		reroll_button.text = "Reroll (free)"
	else:
		reroll_label.text = "Free rerolls used up"
		reroll_button.text = "Reroll — %d Digi" % _get_reroll_cost()
	reroll_button.disabled = false

func _on_reroll_pressed():
	if paid_chosen or free_chosen:
		return
	if SaveData.rerolls_left > 0:
		if not SaveData.use_reroll():
			return
	else:
		var cost = _get_reroll_cost()
		if not SaveData.spend_digi(cost):
			digi_label.text = "Digi: %d  (need %d to reroll!)" % [SaveData.digi, cost]
			return
	_generate_offers()
	_update_offer_buttons()
	_update_reroll_ui()
	_update_header()

func _on_item_chosen(index: int):
	var is_paid = index < 3
	if is_paid and paid_chosen:
		return
	if not is_paid and free_chosen:
		return

	var item_name = paid_offers[index] if is_paid else free_offers[index - 3]
	var item = ItemDB.get_item(item_name)
	var all_buttons = [item1_button, item2_button, item3_button, item4_button, item5_button, item6_button]

	if is_paid:
		var price = _get_item_price(item_name)
		# Buy the drop with digi
		if not SaveData.spend_digi(price):
			digi_label.text = "Digi: %d  (need %d!)" % [SaveData.digi, price]
			return
		paid_chosen = true
	else:
		free_item_label.text = "Free pick: %s — %s" % [
			item.get("name", item_name),
			item.get("description", "")
		]
		free_chosen = true

	# Add to inventory (Ticket auto-converts into gacha tickets)
	SaveData.add_item(item_name)

	# Lock the picked category's buttons; the other category stays usable
	reroll_button.disabled = true
	if is_paid:
		for i in range(3):
			all_buttons[i].disabled = true
	else:
		for i in range(3):
			all_buttons[3 + i].disabled = true

	# Highlight chosen
	all_buttons[index].modulate = Color(0.3, 1.0, 0.4)
	item_title_label.text = "Got: %s!" % item_name
	item_title_label.modulate = Color(0.4, 1.0, 0.5)

	await get_tree().create_timer(0.8).timeout
	_update_digimon_display()
	_update_party_summary()
	_update_header()

	# Once the free item is taken, move on to the next battle automatically
	if free_chosen:
		await get_tree().create_timer(0.4).timeout
		_go_next()

func _go_next():
	get_tree().change_scene_to_file("res://Scenes/StageMap.tscn")

# ─────────────────────────────────────────────────────
#  HELPER — fade label in
# ─────────────────────────────────────────────────────

func _animate_label_in(label: Label):
	label.modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.tween_property(label, "modulate", Color(1, 1, 1, 1), 0.5)
	await get_tree().create_timer(0.5).timeout
