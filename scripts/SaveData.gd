extends Node

# ─────────────────────────────────────────────────────
#  SAVEDATA - Global run state manager
#  Tracks: current Digimon, floor, items, run status
# ─────────────────────────────────────────────────────

# ── RUN STATE ────────────────────────────────────────
var is_run_active = false
var floor_number = 1
var total_enemies_defeated = 0
var total_battles_won = 0
var run_start_time = 0

# ── PLAYER DIGIMON ───────────────────────────────────
var current_digimon = {}
var digimon_roster = []  # party — full digimon dicts, max 6
var guest_roster = []    # guests from door events, max 4

# ── INVENTORY ────────────────────────────────────────
var items = []  # items collected this run
var digi = 0    # digi currency (revive items, earned in battles, shop buys)

# ── LEGACY DIGIVICE SCAN (kept for old code compatibility) ─
const DIGIVICE_SCAN_MAX = 200
const DIGIVICE_SCAN_MIN_EVOLVE = 100
var digivice_scan_rate = 0

# ── DIGIMON COLLECTION (Time Stranger style) ─────────
# Per-enemy scan data 0-200%. At 200% you can catch the Digimon.
const COLLECTION_MAX = 200
const MAX_PARTY_SIZE = 6   # max Digimon kept in your fighting party
const MAX_GUEST_SIZE = 4   # max guest Digimon from door events
var digimon_collection = {}  # { name: 0-200 }
var last_defeated_enemy = ""
var last_battle_old_level = 1
var last_battle_old_stats = {}  # snapshot of active digimon stats before XP gain

# ── LEVELING ──────────────────────────────────────────
const MAX_LEVEL = 50  # hard cap for the partner Digimon

# ── REWARD REROLLS (3 per 10-level segment) ──────────
const REROLLS_PER_SEGMENT = 3
var rerolls_left = REROLLS_PER_SEGMENT
var reroll_segment = -1

# ── STATS FOR THIS RUN ───────────────────────────────
var battles_stats = {
	"total_damage_dealt": 0,
	"total_damage_taken": 0,
	"highest_single_damage": 0,
	"status_effects_applied": 0,
	"moves_used": {},  # tracks which moves used
}

# ── UI SETTINGS (battle menu colors, persisted) ──────
const UI_SETTINGS_PATH = "user://settings.cfg"
var button_normal_color:  Color = Color(0.16, 0.20, 0.30)
var button_hover_color:   Color = Color(0.24, 0.30, 0.45)
var button_pressed_color: Color = Color(0.10, 0.13, 0.20)
var panel_color:          Color = Color(0.08, 0.08, 0.18)

# ─────────────────────────────────────────────────────
#  INITIALIZATION & RUN MANAGEMENT
# ─────────────────────────────────────────────────────

func _ready():
	load_ui_settings()

# ─────────────────────────────────────────────────────
#  UI SETTINGS — persistent color customization
# ─────────────────────────────────────────────────────

func load_ui_settings():
	var cfg = ConfigFile.new()
	if cfg.load(UI_SETTINGS_PATH) != OK:
		return
	button_normal_color  = _ui_color(cfg.get_value("ui", "button_normal", button_normal_color))
	button_hover_color   = _ui_color(cfg.get_value("ui", "button_hover", button_hover_color))
	button_pressed_color = _ui_color(cfg.get_value("ui", "button_pressed", button_pressed_color))
	panel_color          = _ui_color(cfg.get_value("ui", "panel", panel_color))

func save_ui_settings():
	var cfg = ConfigFile.new()
	cfg.set_value("ui", "button_normal", button_normal_color.to_html())
	cfg.set_value("ui", "button_hover", button_hover_color.to_html())
	cfg.set_value("ui", "button_pressed", button_pressed_color.to_html())
	cfg.set_value("ui", "panel", panel_color.to_html())
	cfg.save(UI_SETTINGS_PATH)

func reset_ui_settings():
	button_normal_color  = Color(0.16, 0.20, 0.30)
	button_hover_color   = Color(0.24, 0.30, 0.45)
	button_pressed_color = Color(0.10, 0.13, 0.20)
	panel_color          = Color(0.08, 0.08, 0.18)
	save_ui_settings()

func _ui_color(variant) -> Color:
	if variant is Color:
		return variant
	if variant is String and variant != "":
		return Color(variant)
	return Color(0.16, 0.20, 0.30)

func start_new_run(starter_names: Array):
	"""Begin a fresh roguelike run with the chosen party of starters."""
	is_run_active = true
	floor_number = 1
	total_enemies_defeated = 0
	total_battles_won = 0
	digi = 0
	items = []
	digivice_scan_rate = 0
	digimon_collection = {}
	digimon_roster = []
	guest_roster = []
	last_defeated_enemy = ""
	rerolls_left = REROLLS_PER_SEGMENT
	reroll_segment = -1
	run_start_time = Time.get_ticks_msec()
	battles_stats = {
		"total_damage_dealt": 0,
		"total_damage_taken": 0,
		"highest_single_damage": 0,
		"status_effects_applied": 0,
		"moves_used": {},
	}

	# Build the starting party from the chosen starters
	for starter_name in starter_names:
		var d = DigimonDB.get_digimon(starter_name)
		if d.is_empty():
			continue
		# Apply persistent gacha bonuses (stars, abilities, start level) if owned
		if GachaData.has_digimon(starter_name):
			GachaData.apply_to_digimon(d)
		d["level"] = d.get("start_level", 5)
		d["experience"] = 0
		# Starters get a 25% stat edge over wild digimon of the same species
		for stat in ["hp", "attack", "defense", "sp_attack", "speed"]:
			d[stat] = int(d[stat] * 1.25)
		DigimonDB.recompute_sp(d)
		d["current_hp"] = d["hp"]
		d["current_sp"] = d["sp"]
		d["status"] = "none"  # none, burn, freeze, paralysis, etc.
		d["slot"] = digimon_roster.size()
		digimon_roster.append(d)

	if digimon_roster.is_empty():
		digimon_roster.append(DigimonDB.get_digimon("Agumon"))

	# The first pick leads the party / battle
	current_digimon = digimon_roster[0]

	print("[SaveData] Started new run with party: %s (Level %d)" % [starter_names, current_digimon["level"]])

func end_run(victory: bool):
	"""End the current run (either victory or defeat)."""
	is_run_active = false
	var run_duration = Time.get_ticks_msec() - run_start_time
	print("[SaveData] Run ended. Victory: %s. Duration: %dms. Reached floor %d" % [victory, run_duration, floor_number])

# ─────────────────────────────────────────────────────
#  DIGIMON MANAGEMENT
# ─────────────────────────────────────────────────────

func get_xp_multiplier_for_level(level: int) -> int:
	"""XP gain multiplier based on the Digimon's current level."""
	if level <= 10:
		return 15   # levels 1-10: 15x exp (very fast early game)
	elif level <= 20:
		return 13   # levels 11-20: 13x exp
	else:
		return 12   # levels 21-50: steady 12x exp

func gain_experience(amount: int, digimon: Dictionary = {}):
	"""Award XP (boosted by level multiplier) and handle level ups."""
	if digimon.is_empty():
		digimon = current_digimon
	if digimon.get("level", 1) >= MAX_LEVEL:
		digimon["experience"] = 0
		return

	# Rare passive "Lucky Growth" — +25% XP
	if digimon.get("rare_passive", false):
		amount = int(amount * 1.25)

	var multiplier = get_xp_multiplier_for_level(digimon.get("level", 1))
	digimon["experience"] += amount * multiplier

	while digimon["level"] < MAX_LEVEL:
		var xp_to_level_up = get_xp_for_level(digimon["level"] + 1)
		if digimon["experience"] < xp_to_level_up:
			break
		digimon["experience"] -= xp_to_level_up
		level_up(digimon)

	if digimon["level"] >= MAX_LEVEL:
		digimon["experience"] = 0

func gain_battle_experience(amount: int):
	"""Award battle XP to the active digimon AND the whole bench (party + guests)."""
	var cur_name = current_digimon.get("name", "")
	gain_experience(amount, current_digimon)
	for d in digimon_roster:
		if d.get("name", "") != cur_name:
			gain_experience(amount, d)
	for g in guest_roster:
		if g.get("name", "") != cur_name:
			gain_experience(amount, g)

func level_up(digimon: Dictionary = {}):
	"""Increase Digimon level and boost stats."""
	if digimon.is_empty():
		digimon = current_digimon
	digimon["level"] += 1
	var level = digimon["level"]
	
	# Stats grow by ~10% per level (simple scaling)
	var hp_growth = int(digimon["hp"] * 0.1)
	var atk_growth = int(digimon["attack"] * 0.1)
	var def_growth = int(digimon["defense"] * 0.1)
	var sp_atk_growth = int(digimon["sp_attack"] * 0.1)
	var spd_growth = int(digimon["speed"] * 0.1)
	
	digimon["hp"] += hp_growth
	digimon["attack"] += atk_growth
	digimon["defense"] += def_growth
	digimon["sp_attack"] += sp_atk_growth
	digimon["speed"] += spd_growth
	DigimonDB.recompute_sp(digimon)
	digimon["current_hp"] = digimon["hp"]  # full heal on level up
	digimon["current_sp"] = digimon["sp"]  # SP fully restored on level up
	
	print("[SaveData] %s leveled up to Level %d!" % [digimon["name"], level])

func get_xp_for_level(level: int) -> int:
	"""XP required to reach a specific level."""
	return level * 300  # linear curve: level 2 = 600, level 50 = 15000

func gain_digivice_scan(amount: int):
	"""Add scan data from battles — capped at 200%."""
	var before = digivice_scan_rate
	digivice_scan_rate = mini(digivice_scan_rate + amount, DIGIVICE_SCAN_MAX)
	if digivice_scan_rate > before:
		print("[SaveData] Digivice scan: %d%% → %d%%" % [before, digivice_scan_rate])

# ─────────────────────────────────────────────────────
#  DIGIMON COLLECTION & CATCH (Time Stranger style)
#  Scan enemies to 200% to add them to your roster
# ─────────────────────────────────────────────────────

func gain_enemy_scan(enemy_name: String, amount: int) -> int:
	"""Add collection % for one enemy type. Returns new value."""
	if enemy_name == "":
		return 0
	var before = digimon_collection.get(enemy_name, 0)
	var after = mini(before + amount, COLLECTION_MAX)
	digimon_collection[enemy_name] = after
	if after > before:
		print("[SaveData] Collection %s: %d%% → %d%%" % [enemy_name, before, after])
	return after

func get_collection_percent(enemy_name: String) -> int:
	return digimon_collection.get(enemy_name, 0)

func can_catch(enemy_name: String) -> bool:
	if enemy_name == "":
		return false
	return get_collection_percent(enemy_name) >= COLLECTION_MAX

func is_caught(enemy_name: String) -> bool:
	for d in digimon_roster:
		if d.get("name", "") == enemy_name:
			return true
	return false

func catch_digimon(enemy_name: String) -> bool:
	"""Add a fully scanned Digimon to the party. Returns true if newly caught."""
	if enemy_name == "" or not can_catch(enemy_name):
		return false
	if is_caught(enemy_name):
		return false
	if digimon_roster.size() >= MAX_PARTY_SIZE:
		return false  # party full — max 6 kept
	var d = DigimonDB.get_digimon(enemy_name)
	if d.is_empty():
		return false
	if GachaData.has_digimon(enemy_name):
		GachaData.apply_to_digimon(d)
	d["level"]      = current_digimon.get("level", 1)
	d["experience"] = 0
	d["current_hp"] = d["hp"]
	d["status"]     = "none"
	DigimonDB.recompute_sp(d)
	d["current_sp"] = d["sp"]
	digimon_roster.append(d)
	print("[SaveData] %s joined your party! (%d/%d kept)" % [enemy_name, digimon_roster.size(), MAX_PARTY_SIZE])
	return true

func get_caught_count() -> int:
	return digimon_roster.size()

func get_guest_count() -> int:
	return guest_roster.size()

func add_guest(digimon: Dictionary) -> bool:
	"""Add a Digimon from a door event to the guest roster."""
	if guest_roster.size() >= MAX_GUEST_SIZE:
		return false
	guest_roster.append(digimon)
	return true

func get_party_names() -> Array:
	var names = []
	for d in digimon_roster:
		names.append(d.get("name", "?"))
	return names

func get_guest_names() -> Array:
	var names = []
	for d in guest_roster:
		names.append(d.get("name", "?"))
	return names

# ─────────────────────────────────────────────────────
#  REWARD REROLLS (3 per 10-level segment)
# ─────────────────────────────────────────────────────

func refresh_rerolls():
	"""Reset reroll count when entering a new 10-level segment."""
	var segment = int((floor_number - 1) / 10)
	if segment != reroll_segment:
		reroll_segment = segment
		rerolls_left = REROLLS_PER_SEGMENT
		print("[SaveData] New segment (%d) — rerolls reset to %d" % [segment, REROLLS_PER_SEGMENT])

func use_reroll() -> bool:
	"""Spend one reroll. Returns true if successful."""
	refresh_rerolls()
	if rerolls_left <= 0:
		return false
	rerolls_left -= 1
	return true

func get_digivice_scan_percent() -> float:
	return float(digivice_scan_rate) / float(DIGIVICE_SCAN_MAX) * 100.0

func can_digivice_digivolve() -> bool:
	if DigimonDB.can_digivolve(current_digimon):
		return true
	return false

func get_digivice_scan_tier() -> String:
	if DigimonDB.can_digivolve(current_digimon):
		return "ready"
	return "scanning"

func attempt_digivice_digivolution() -> Dictionary:
	"""
	Evolves partner based on LEVEL only (uses evolves_at in DigimonDB).
	Returns { "success": bool, "message": String, "evolved": bool }
	"""
	var digimon = current_digimon
	if not DigimonDB.can_digivolve(digimon):
		if digimon.get("evolves_to", "") == "":
			return {"success": false, "message": "No further digivolution data available.", "evolved": false}
		return {
			"success": false,
			"message": "Reach Level %d to digivolve into %s. (Currently Lv.%d)" % [
				digimon["evolves_at"], digimon["evolves_to"], digimon.get("level", 1)
			],
			"evolved": false
		}

	var next_stage = DigimonDB.get_digivolution(digimon)
	var old_name = digimon["name"]

	var evolved_form = DigimonDB.get_digimon(next_stage)
	if evolved_form.is_empty():
		return {"success": false, "message": "Digivolution data not available yet.", "evolved": false}
	evolved_form["level"] = digimon["level"]
	evolved_form["experience"] = digimon["experience"]
	evolved_form["current_hp"] = evolved_form["hp"]
	evolved_form["status"] = "none"
	DigimonDB.recompute_sp(evolved_form)
	evolved_form["current_sp"] = evolved_form["sp"]

	current_digimon = evolved_form

	# Keep the party roster entry in sync with the digivolved form
	for i in range(digimon_roster.size()):
		if digimon_roster[i].get("name", "") == old_name:
			digimon_roster[i] = evolved_form
			break

	var msg = "%s digivolved into %s!" % [old_name, next_stage]
	print("[SaveData] Digivolution at Lv.%d: %s" % [digimon["level"], next_stage])
	return {"success": true, "message": msg, "evolved": true, "perfect": false}

func heal_digimon():
	"""Full heal current Digimon."""
	current_digimon["current_hp"] = current_digimon["hp"]
	current_digimon["status"] = "none"
	current_digimon["current_sp"] = current_digimon.get("sp", current_digimon["current_sp"])
	
	print("[SaveData] %s has been fully healed!" % current_digimon["name"])

func apply_status(status_name: String):
	"""Apply a status effect to current Digimon."""
	current_digimon["status"] = status_name
	print("[SaveData] %s is now %s!" % [current_digimon["name"], status_name])

func remove_status():
	"""Clear status effect."""
	current_digimon["status"] = "none"

# ─────────────────────────────────────────────────────
#  BATTLE STATS TRACKING
# ─────────────────────────────────────────────────────

func record_damage_dealt(damage: int, move_name: String):
	"""Record damage dealt in this run."""
	battles_stats["total_damage_dealt"] += damage
	battles_stats["highest_single_damage"] = max(battles_stats["highest_single_damage"], damage)
	
	if move_name not in battles_stats["moves_used"]:
		battles_stats["moves_used"][move_name] = 0
	battles_stats["moves_used"][move_name] += 1

func record_damage_taken(damage: int):
	"""Record damage taken in this run."""
	battles_stats["total_damage_taken"] += damage

func record_status_effect_applied(_status: String):
	"""Record a status effect applied."""
	battles_stats["status_effects_applied"] += 1

# ─────────────────────────────────────────────────────
#  INVENTORY & ITEMS
# ─────────────────────────────────────────────────────

func add_item(item_name: String, quantity: int = 1):
	"""Add item to inventory. Ticket items convert straight into gacha tickets."""
	var item_data = ItemDB.get_item(item_name)
	if item_data.get("effect", "") == "ticket":
		GachaData.add_tickets(item_data.get("value", 1) * quantity)
		print("[SaveData] +%d gacha ticket(s)! (Total: %d)" % [item_data.get("value", 1) * quantity, GachaData.tickets])
		return

	var found = false
	for item in items:
		if item["name"] == item_name:
			item["quantity"] += quantity
			found = true
			break
	
	if not found:
		items.append({"name": item_name, "quantity": quantity})
	
	print("[SaveData] Added %d x %s" % [quantity, item_name])

func use_item(item_name: String) -> bool:
	"""Use an item from inventory."""
	for item in items:
		if item["name"] == item_name and item["quantity"] > 0:
			item["quantity"] -= 1
			if item["quantity"] == 0:
				items.erase(item)
			print("[SaveData] Used %s" % item_name)
			return true
	return false

func add_gold(amount: int):
	"""Legacy stub kept for safety — gold was replaced by gacha tickets."""
	push_warning("[SaveData] add_gold called — gold has been replaced by tickets.")
	GachaData.add_tickets(amount)

func spend_gold(amount: int) -> bool:
	"""Legacy stub kept for safety — gold was replaced by gacha tickets."""
	push_warning("[SaveData] spend_gold called — gold has been replaced by tickets.")
	return GachaData.spend_tickets(amount)

func add_digi(amount: int):
	"""Add digi currency."""
	digi += amount

func spend_digi(amount: int) -> bool:
	"""Spend digi currency, returns true if successful."""
	if digi >= amount:
		digi -= amount
		print("[SaveData] Spent %d digi! (Remaining: %d)" % [amount, digi])
		return true
	return false

# ─────────────────────────────────────────────────────
#  FLOOR & PROGRESSION
# ─────────────────────────────────────────────────────

func advance_floor():
	"""Move to next floor."""
	floor_number += 1
	total_enemies_defeated += 1
	print("[SaveData] Advanced to floor %d!" % floor_number)

func get_floor_difficulty() -> int:
	"""Returns a difficulty multiplier based on floor."""
	return floor_number

# ─────────────────────────────────────────────────────
#  RUN SUMMARY / STATS
# ─────────────────────────────────────────────────────

func get_run_summary() -> Dictionary:
	"""Return a summary of the entire run for display."""
	return {
		"digimon_name": current_digimon.get("name", "Unknown"),
		"digimon_level": current_digimon.get("level", 1),
		"floor_reached": floor_number,
		"enemies_defeated": total_enemies_defeated,
		"total_damage_dealt": battles_stats["total_damage_dealt"],
		"total_damage_taken": battles_stats["total_damage_taken"],
		"items_collected": items.size(),
	}

func print_run_stats():
	"""Print run statistics to console."""
	var summary = get_run_summary()
	print("\n========== RUN SUMMARY ==========")
	print("Digimon: %s (Level %d)" % [summary["digimon_name"], summary["digimon_level"]])
	print("Floor Reached: %d" % summary["floor_reached"])
	print("Enemies Defeated: %d" % summary["enemies_defeated"])
	print("Total Damage Dealt: %d" % summary["total_damage_dealt"])
	print("Total Damage Taken: %d" % summary["total_damage_taken"])
	print("==================================\n")
