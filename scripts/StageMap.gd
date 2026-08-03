extends Control

# ─────────────────────────────────────────────────────
#  STAGE MAP — PokeRogue-style progression
#
#  HOW IT WORKS:
#  • 50 stages total laid out as a path
#  • Each stage is either a Battle or a Mystery Door
#  • Mystery Door = 3 unknown choices:
#      - Demon Realm  → jump ahead to a hard floor instantly
#      - Training Ground → free heals, gain up to 5 bonus levels
#      - Ally Digimon → a Digimon joins your party
#  • Every 10 stages = a Boss fight
#  • Reach Stage 50 → Final Boss
# ─────────────────────────────────────────────────────

# ── NODE REFS ─────────────────────────────────────────
@onready var stage_container    = $ScrollContainer/StageContainer
@onready var stage_label        = $HUD/HUDPanel/HBoxContainer/StageLabel
@onready var digimon_label      = $HUD/HUDPanel/HBoxContainer/DigimonLabel
@onready var hp_label           = $HUD/HUDPanel/HBoxContainer/HPLabel
@onready var gold_label         = $HUD/HUDPanel/HBoxContainer/GoldLabel
@onready var scan_label         = $HUD/HUDPanel/HBoxContainer/ScanLabel
@onready var ally_label         = $HUD/HUDPanel/HBoxContainer/AllyLabel

@onready var choice_panel       = $ChoicePanel
@onready var choice_title       = $ChoicePanel/VBoxContainer/ChoiceTitle
@onready var choice_desc        = $ChoicePanel/VBoxContainer/ChoiceDesc
@onready var door1_button       = $ChoicePanel/VBoxContainer/Door1Button
@onready var door2_button       = $ChoicePanel/VBoxContainer/Door2Button
@onready var door3_button       = $ChoicePanel/VBoxContainer/Door3Button

@onready var result_panel       = $ResultPanel
@onready var result_label       = $ResultPanel/VBoxContainer/ResultLabel
@onready var result_continue    = $ResultPanel/VBoxContainer/ContinueButton

@onready var training_panel     = $TrainingPanel
@onready var training_label     = $TrainingPanel/VBoxContainer/TrainingLabel
@onready var training_heal_btn  = $TrainingPanel/VBoxContainer/HealButton
@onready var training_train_btn = $TrainingPanel/VBoxContainer/TrainButton
@onready var training_leave_btn = $TrainingPanel/VBoxContainer/LeaveButton
@onready var training_level_label = $TrainingPanel/VBoxContainer/LevelLabel

@onready var shop_panel         = $ShopPanel
@onready var shop_title_label   = $ShopPanel/VBoxContainer/ShopTitle
@onready var shop_gold_label    = $ShopPanel/VBoxContainer/ShopGoldLabel
@onready var shop_list          = $ShopPanel/VBoxContainer/ShopList
@onready var leave_shop_button  = $ShopPanel/VBoxContainer/LeaveShopButton

@onready var encounter_flash    = $EncounterFlash

# ── STAGE TYPES ───────────────────────────────────────
enum StageType { BATTLE, MYSTERY, BOSS, FINAL_BOSS }

# ── STATE ─────────────────────────────────────────────
var stage_layout: Array      = []   # StageType for each stage 1-50
var current_stage: int       = 1
var mystery_outcome: String  = ""   # "demon" / "training" / "ally" / "shop"
var training_levels_used: int = 0   # max 5 bonus levels per training ground
var stage_buttons: Array     = []
var can_interact: bool       = true
var shop_stock: Array        = []   # shop items for the current shop

# ── MYSTERY DOOR OUTCOMES ────────────────────────────
# ally (Digimon joins as a guest) is the most common outcome
const DOOR_WEIGHTS = {
	"ally": 0.62,
	"training": 0.19,
	"shop": 0.14,
	"demon": 0.05,
}

# ── TRAINING GROUND ───────────────────────────────────
const MAX_TRAINING_LEVELS = 5
const TRAIN_XP_AMOUNT     = 500   # XP gained per training session

# ─────────────────────────────────────────────────────
#  GENERATE STAGE LAYOUT
#  Pattern: 3-4 battles then 1 mystery, boss every 10
# ─────────────────────────────────────────────────────

func _generate_stage_layout():
	stage_layout.clear()
	stage_layout.append(StageType.BATTLE)  # Stage 0 placeholder

	for i in range(1, 51):
		if i == 50:
			stage_layout.append(StageType.FINAL_BOSS)
		elif i % 10 == 0:
			stage_layout.append(StageType.BOSS)
		elif i % 4 == 0:  # Every 4th stage = mystery door
			stage_layout.append(StageType.MYSTERY)
		else:
			stage_layout.append(StageType.BATTLE)

# ─────────────────────────────────────────────────────
#  READY
# ─────────────────────────────────────────────────────

func _ready():
	_generate_stage_layout()
	current_stage = SaveData.floor_number

	choice_panel.visible  = false
	result_panel.visible  = false
	training_panel.visible = false
	shop_panel.visible    = false
	encounter_flash.modulate = Color(1, 1, 1, 0)

	# The stage button row is hidden — the game auto-advances through stages
	$ScrollContainer.visible = false

	# Connect result continue button
	result_continue.pressed.connect(_on_result_continue)
	training_heal_btn.pressed.connect(_on_training_heal)
	training_train_btn.pressed.connect(_on_training_train)
	training_leave_btn.pressed.connect(_on_training_leave)
	leave_shop_button.pressed.connect(_on_leave_shop)

	_build_stage_ui()
	_update_hud()

	# Auto-start the current stage — no need to click the stage button
	await _auto_start()

# ─────────────────────────────────────────────────────
#  BUILD STAGE UI — row of stage buttons
# ─────────────────────────────────────────────────────

func _build_stage_ui():
	# Stage buttons were removed — the run auto-advances. Keep the container empty.
	for child in stage_container.get_children():
		child.queue_free()
	stage_buttons.clear()

# ─────────────────────────────────────────────────────
#  STAGE PRESSED — player clicks current stage
# ─────────────────────────────────────────────────────

func _on_stage_pressed(stage_num: int):
	if not can_interact or stage_num != current_stage:
		return

	var stage_type = stage_layout[stage_num]

	match stage_type:
		StageType.BATTLE:
			await _start_battle()
		StageType.MYSTERY:
			_open_mystery_door()
		StageType.BOSS:
			await _start_boss_battle()
		StageType.FINAL_BOSS:
			await _start_final_boss()

# ─────────────────────────────────────────────────────
#  AUTO-ADVANCE — battles and mystery doors run on their own
# ─────────────────────────────────────────────────────

func _auto_start():
	can_interact = false
	await get_tree().create_timer(0.6).timeout
	await _trigger_current_stage()

func _auto_advance():
	can_interact = false
	_advance_stage()
	_build_stage_ui()
	_update_hud()
	await get_tree().create_timer(0.4).timeout
	await _trigger_current_stage()

func _trigger_current_stage():
	if current_stage > 50:
		return  # run finished

	var stage_type = stage_layout[current_stage]
	match stage_type:
		StageType.BATTLE:
			await _start_battle()
		StageType.MYSTERY:
			_open_mystery_door()
		StageType.BOSS:
			await _start_boss_battle()
		StageType.FINAL_BOSS:
			await _start_final_boss()

# ─────────────────────────────────────────────────────
#  BATTLE — go to BattleScene
# ─────────────────────────────────────────────────────

func _start_battle():
	can_interact = false
	SaveData.floor_number = current_stage
	await _flash_screen()
	get_tree().change_scene_to_file("res://Scenes/BattleScene.tscn")

func _start_boss_battle():
	can_interact = false
	SaveData.floor_number = current_stage
	# Mark as boss fight in SaveData so BattleScene knows
	SaveData.current_digimon["next_is_boss"] = true
	await _flash_screen()
	get_tree().change_scene_to_file("res://Scenes/BattleScene.tscn")

func _start_final_boss():
	can_interact = false
	SaveData.floor_number = 50
	SaveData.current_digimon["next_is_boss"] = true
	SaveData.current_digimon["is_final_boss"] = true
	await _flash_screen()
	get_tree().change_scene_to_file("res://Scenes/BattleScene.tscn")

# ─────────────────────────────────────────────────────
#  MYSTERY DOOR — show 3 unknown choices
# ─────────────────────────────────────────────────────

func _open_mystery_door():
	can_interact = false

	# Reset door button labels to always be unknown
	choice_title.text = "A mysterious door appears..."
	choice_desc.text  = "Three doors stand before you. Each leads somewhere different. Choose wisely."

	door1_button.text = "Door 1"
	door2_button.text = "Door 2"
	door3_button.text = "Door 3"

	# Randomly assign weighted outcomes to doors (player doesn't know which is which)
	var outcomes = _roll_door_outcomes()

	# Disconnect previous connections to avoid stacking
	if door1_button.pressed.is_connected(_on_door_chosen):
		door1_button.pressed.disconnect(_on_door_chosen)
	if door2_button.pressed.is_connected(_on_door_chosen):
		door2_button.pressed.disconnect(_on_door_chosen)
	if door3_button.pressed.is_connected(_on_door_chosen):
		door3_button.pressed.disconnect(_on_door_chosen)

	door1_button.pressed.connect(_on_door_chosen.bind(outcomes[0]))
	door2_button.pressed.connect(_on_door_chosen.bind(outcomes[1]))
	door3_button.pressed.connect(_on_door_chosen.bind(outcomes[2]))

	choice_panel.visible = true

func _roll_door_outcomes() -> Array:
	"""3 door outcomes, weighted. A Digimon ally is the most common reward."""
	var outcomes = []
	for i in range(3):
		outcomes.append(_weighted_door_pick())
	# Guarantee at least one ally door so friendly rooms appear often
	if not outcomes.has("ally"):
		outcomes[randi() % 3] = "ally"
	return outcomes

func _weighted_door_pick() -> String:
	var total = 0.0
	for value in DOOR_WEIGHTS.values():
		total += value
	var roll = randf() * total
	for key in DOOR_WEIGHTS:
		roll -= DOOR_WEIGHTS[key]
		if roll <= 0:
			return key
	return "ally"

func _on_door_chosen(outcome: String):
	mystery_outcome = outcome
	choice_panel.visible = false

	match outcome:
		"demon":
			await _trigger_demon_realm()
		"training":
			_open_training_ground()
		"ally":
			await _recruit_ally()
		"shop":
			_open_shop()

# ─────────────────────────────────────────────────────
#  OUTCOME 1 — DEMON REALM
#  Player is warped to a hard floor immediately
# ─────────────────────────────────────────────────────

func _trigger_demon_realm():
	# Flash red
	var tween = create_tween()
	encounter_flash.modulate = Color(0.8, 0.1, 0.1, 0)
	tween.tween_property(encounter_flash, "modulate", Color(0.8, 0.1, 0.1, 1), 0.2)
	tween.tween_property(encounter_flash, "modulate", Color(0.8, 0.1, 0.1, 0), 0.3)
	await get_tree().create_timer(0.5).timeout

	# Jump player to a hard floor in Demon range (41-49)
	var demon_floor = randi_range(41, 49)
	SaveData.floor_number = demon_floor
	current_stage = demon_floor

	result_label.text = "The door leads to the DEMON REALM!\nYou are warped to Floor %d!\nFight for your life!" % demon_floor
	result_panel.visible = true
	result_continue.text = "Fight!"

func _on_result_continue():
	result_panel.visible = false

	match mystery_outcome:
		"demon":
			# Force battle immediately
			await _flash_screen()
			get_tree().change_scene_to_file("res://Scenes/BattleScene.tscn")
		_:
			# Continue on to the next stage automatically
			await _auto_advance()

# ─────────────────────────────────────────────────────
#  OUTCOME 2 — TRAINING GROUND
#  Free heals, up to 5 bonus levels before moving on
# ─────────────────────────────────────────────────────

func _open_training_ground():
	training_levels_used = 0
	_update_training_ui()
	training_panel.visible = true

func _update_training_ui():
	var d = SaveData.current_digimon
	training_label.text  = "Training Ground — Free Healing!"
	training_level_label.text = "Bonus levels used: %d / %d\n%s is Level %d" % [
		training_levels_used,
		MAX_TRAINING_LEVELS,
		d.get("name", "???"),
		d.get("level", 1)
	]
	training_train_btn.disabled = training_levels_used >= MAX_TRAINING_LEVELS

func _on_training_heal():
	SaveData.heal_digimon()
	_update_training_ui()
	_update_hud()
	print("[StageMap] Free heal at training ground!")

func _on_training_train():
	if training_levels_used >= MAX_TRAINING_LEVELS:
		return

	# Grant bonus XP = enough for 1 level (adjust for XP multiplier)
	var level = SaveData.current_digimon.get("level", 1)
	var xp_needed = SaveData.get_xp_for_level(level + 1)
	var mult = SaveData.get_xp_multiplier_for_level(level)
	SaveData.gain_experience(ceili(float(xp_needed) / float(mult)))
	training_levels_used += 1
	_update_training_ui()
	_update_hud()
	print("[StageMap] Training session! Level now: %d" % SaveData.current_digimon.get("level", 1))

func _on_training_leave():
	training_panel.visible = false
	await _auto_advance()

# ─────────────────────────────────────────────────────
#  OUTCOME — SHOP
#  A lucky door that lets you buy items with digi
# ─────────────────────────────────────────────────────

func _open_shop():
	shop_stock = []
	# 4 random items purchasable with digi
	var random_stock = ItemDB.get_shop_stock(current_stage, 4)
	for entry in random_stock:
		shop_stock.append(entry)
	# Guaranteed revive slot — costs digi currency
	shop_stock.append({
		"name": "Revive",
		"price": ItemDB.get_scaled_price("Revive", current_stage),
		"currency": "digi",
	})
	# Guaranteed heal slot — costs digi
	var heal_name = ItemDB.get_heal_for_floor(current_stage)
	shop_stock.append({
		"name": heal_name,
		"price": ItemDB.get_scaled_price(heal_name, current_stage),
		"currency": "digi",
	})

	shop_title_label.text = "Lucky! A Shop! (Floor %d)" % current_stage
	_build_shop_ui()
	shop_panel.visible = true

func _build_shop_ui():
	for child in shop_list.get_children():
		child.queue_free()

	shop_gold_label.text = "Tickets: %d   |   Digi: %d" % [GachaData.tickets, SaveData.digi]

	for entry in shop_stock:
		var item = ItemDB.get_item(entry["name"])
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(0, 50)
		btn.add_theme_font_size_override("font_size", 13)
		var currency_tag = "Digi"
		btn.text = "%s — %s\n[%s]  (%d %s)" % [
			item["name"], item["description"],
			item["rarity"].capitalize(), entry["price"], currency_tag
		]
		btn.pressed.connect(_on_buy_item.bind(entry["name"], entry["price"], btn))
		shop_list.add_child(btn)

func _on_buy_item(item_name: String, price: int, btn: Button):
	if btn.disabled:
		return
	if not SaveData.spend_digi(price):
		shop_gold_label.text = "Tickets: %d   |   Digi: %d (not enough digi!)" % [GachaData.tickets, SaveData.digi]
		return
	SaveData.add_item(item_name)
	btn.disabled = true
	btn.modulate = Color(0.3, 1.0, 0.4)
	shop_gold_label.text = "Tickets: %d   |   Digi: %d" % [GachaData.tickets, SaveData.digi]
	_update_hud()

func _on_leave_shop():
	shop_panel.visible = false
	await _auto_advance()

# ─────────────────────────────────────────────────────
#  OUTCOME 3 — ALLY RECRUITMENT
#  A Digimon joins your party as a helper
# ─────────────────────────────────────────────────────

func _recruit_ally():
	if SaveData.get_guest_count() >= SaveData.MAX_GUEST_SIZE:
		result_label.text = "A Digimon wants to join you,\nbut you already have many guests.\nYou passed on the offer."
		result_panel.visible = true
		result_continue.text = "Continue"
		mystery_outcome = "ally_done"
		return

	# Pick a random ally Digimon appropriate to current floor
	var possible_allies = _get_ally_pool()
	var ally_name = possible_allies[randi() % possible_allies.size()]
	var guest = DigimonDB.get_digimon(ally_name)

	if guest.is_empty():
		result_label.text = "Nothing was found behind the door..."
		result_panel.visible = true
		result_continue.text = "Continue"
		mystery_outcome = "none"
		return

	# Set up guest — a bit stronger than party recruits (+3 levels) and buffed in every stat
	guest["level"]      = mini(SaveData.current_digimon.get("level", 1) + 3, SaveData.MAX_LEVEL)
	guest["experience"] = 0
	for stat in ["hp", "attack", "defense", "sp_attack", "speed"]:
		guest[stat] = int(guest[stat] * 1.5)
	DigimonDB.recompute_sp(guest)
	guest["current_hp"] = guest["hp"]
	guest["status"]     = "none"
	guest["current_sp"] = guest["sp"]

	SaveData.add_guest(guest)

	result_label.text = "A wild %s wants to join you!\n%s joined your guest party!" % [
		guest["name"],
		guest["name"]
	]
	result_panel.visible = true
	result_continue.text = "Welcome %s!" % guest["name"]
	mystery_outcome = "ally_done"

func _get_ally_pool() -> Array:
	var floor_num = current_stage

	if floor_num <= 10:
		return ["Patamon", "Tentomon", "Palmon", "Biyomon", "Gomamon"]
	elif floor_num <= 20:
		return ["Angemon", "Kabuterimon", "Togemon", "Birdramon", "Ikkakumon"]
	elif floor_num <= 35:
		return ["MagnaAngemon", "MetalGreymon", "WereGarurumon", "Garudamon", "Myotismon"]
	else:
		return ["Seraphimon", "MetalGarurumon", "WarGreymon", "Phoenixmon", "VenomMyotismon"]

# ─────────────────────────────────────────────────────
#  ADVANCE STAGE
# ─────────────────────────────────────────────────────

func _advance_stage():
	current_stage += 1
	SaveData.floor_number = current_stage
	print("[StageMap] Advanced to stage %d" % current_stage)

# Called from BattleScene after winning — go to reward then come back here
func return_from_battle():
	current_stage = SaveData.floor_number
	can_interact  = true
	_build_stage_ui()
	_update_hud()

# ─────────────────────────────────────────────────────
#  HUD UPDATE
# ─────────────────────────────────────────────────────

func _update_hud():
	var d = SaveData.current_digimon
	stage_label.text   = "Stage %d / 50" % current_stage
	digimon_label.text = "%s  Lv.%d" % [d.get("name","???"), d.get("level",1)]
	hp_label.text      = "HP  %d/%d" % [d.get("current_hp",0), d.get("hp",1)]
	gold_label.text    = "Tickets: %d" % GachaData.tickets
	scan_label.text    = "Collection: %d caught" % SaveData.get_caught_count()

	if SaveData.get_caught_count() > 0:
		scan_label.modulate = Color(0.4, 1.0, 0.5)
	else:
		scan_label.modulate = Color(0.7, 0.85, 1.0)

	if SaveData.get_guest_count() > 0:
		var guest_names = " ".join(SaveData.get_guest_names())
		ally_label.text    = "Guests: %s" % guest_names
		ally_label.visible = true
	else:
		ally_label.visible = false

# ─────────────────────────────────────────────────────
#  FLASH SCREEN — white flash before battle
# ─────────────────────────────────────────────────────

func _flash_screen():
	var tween = create_tween()
	tween.tween_property(encounter_flash, "modulate", Color(1,1,1,1), 0.1)
	tween.tween_property(encounter_flash, "modulate", Color(1,1,1,0), 0.1)
	tween.tween_property(encounter_flash, "modulate", Color(1,1,1,1), 0.1)
	tween.tween_property(encounter_flash, "modulate", Color(1,1,1,0), 0.1)
	await get_tree().create_timer(0.4).timeout
