extends Node

# ─────────────────────────────────────────────────────
#  GACHADATA — persistent Digimon gacha (account-wide)
#  • Tickets are the gacha currency — gained ONLY from
#    rare "Ticket" items, never from battle rewards.
#  • Pull digimon with 1x / 5x / 10x draws.
#  • 10x guarantees one Champion digimon.
#  • Duplicates raise a digimon's star level:
#      - 2 stars  → dormant ability ("Rage Mode": +25% dmg below half HP)
#      - 5 stars  → rare passive ("Lucky Growth": +25% XP)
#  • Owned digimon are usable as starters in future runs.
# ─────────────────────────────────────────────────────

const SAVE_PATH = "user://gacha_data.cfg"

const COST_1X  = 1
const COST_5X  = 5
const COST_10X = 10

const CHAMPION_CHANCE_1X  = 0.08   # 1x mostly gives battle digimon
const CHAMPION_CHANCE_5X  = 0.15   # 5x better odds for champions
const CHAMPION_CHANCE_10X = 0.15   # 10x: same odds on 9 pulls + 1 guaranteed

const MAX_STARS   = 5
const DORMANT_AT  = 2   # star level that unlocks the dormant ability
const RARE_AT     = 5   # star level that unlocks the rare passive

const CHAMPION_START_LEVEL = 15  # owned champions start runs at Lv15
const BATTLE_START_LEVEL   = 10  # owned battle digimon start at Lv10

var tickets: int = 0
var owned: Dictionary = {}   # name -> { "stars": int, "dormant": bool, "rare": bool, "start_level": int }

func _ready():
	load_data()

# ─────────────────────────────────────────────────────
#  POOLS
# ─────────────────────────────────────────────────────

func get_champion_pool() -> Array:
	return DigimonDB.get_by_stage("Champion")

func get_battle_pool() -> Array:
	# Battle digimon = Rookies you encounter and fight at levels 10-20
	return DigimonDB.get_all_rookies()

func get_pool_size() -> int:
	return get_champion_pool().size() + get_battle_pool().size()

# ─────────────────────────────────────────────────────
#  PULLS
# ─────────────────────────────────────────────────────

func pull(count: int) -> Dictionary:
	"""
	Spend tickets and roll `count` digimon.
	Returns: {
	  "ok": bool, "reason": String,
	  "results": Array of { "name", "new", "stars", "upgraded", "unlock" },
	  "tickets_left": int
	}
	"""
	var cost = _cost_for(count)
	if tickets < cost:
		return {"ok": false, "reason": "Not enough tickets! (need %d)" % cost}

	var champion_chance = _champion_chance_for(count)
	var results = []

	for i in range(count):
		var force_champion = count == 10 and i == count - 1
		var name = _roll_digimon(champion_chance, force_champion)
		results.append(_apply_pull(name))

	tickets -= cost
	save_data()
	return {"ok": true, "reason": "", "results": results, "tickets_left": tickets}

func _cost_for(count: int) -> int:
	match count:
		5:  return COST_5X
		10: return COST_10X
	return COST_1X

func _champion_chance_for(count: int) -> float:
	match count:
		5:  return CHAMPION_CHANCE_5X
		10: return CHAMPION_CHANCE_10X
	return CHAMPION_CHANCE_1X

func _roll_digimon(champion_chance: float, force_champion: bool) -> String:
	if force_champion:
		return _random_from(get_champion_pool())
	if randf() < champion_chance:
		return _random_from(get_champion_pool())
	return _random_from(get_battle_pool())

func _random_from(pool: Array) -> String:
	if pool.is_empty():
		return "Agumon"
	return pool[randi() % pool.size()]

func _apply_pull(name: String) -> Dictionary:
	var info = {
		"name": name,
		"new": false,
		"stars": 1,
		"upgraded": false,
		"unlock": "",
	}
	if owned.has(name):
		var entry = owned[name]
		var before = entry["stars"]
		entry["stars"] = mini(entry["stars"] + 1, MAX_STARS)
		entry["start_level"] = maxi(entry["start_level"], _start_level_for(name))
		info["stars"] = entry["stars"]
		if entry["stars"] > before:
			info["upgraded"] = true
		if before < DORMANT_AT and entry["stars"] >= DORMANT_AT:
			entry["dormant"] = true
			info["unlock"] = "dormant"
		if before < RARE_AT and entry["stars"] >= RARE_AT:
			entry["rare"] = true
			info["unlock"] = "rare"
		return info

	owned[name] = {
		"stars": 1,
		"dormant": false,
		"rare": false,
		"start_level": _start_level_for(name),
	}
	info["new"] = true
	return info

func _start_level_for(name: String) -> int:
	var d = DigimonDB.get_digimon(name)
	if d.get("stage", "") == "Champion":
		return CHAMPION_START_LEVEL
	return BATTLE_START_LEVEL

# ─────────────────────────────────────────────────────
#  QUERIES
# ─────────────────────────────────────────────────────

func has_digimon(name: String) -> bool:
	return owned.has(name)

func get_stars(name: String) -> int:
	if owned.has(name):
		return owned[name].get("stars", 0)
	return 0

func get_owned_names() -> Array:
	return owned.keys()

func get_entry(name: String) -> Dictionary:
	return owned.get(name, {})

# ─────────────────────────────────────────────────────
#  APPLY TO A RUN DIGIMON
# ─────────────────────────────────────────────────────

func apply_to_digimon(digimon: Dictionary):
	var name = digimon.get("name", "")
	if not owned.has(name):
		return
	var entry = owned[name]
	digimon["stars"] = entry["stars"]
	digimon["start_level"] = entry["start_level"]
	digimon["dormant"] = entry["dormant"]
	digimon["rare_passive"] = entry["rare"]

	# Every star grants +5% to all stats
	var bonus = 1.0 + entry["stars"] * 0.05
	digimon["hp"] = int(digimon["hp"] * bonus)
	digimon["attack"] = int(digimon["attack"] * bonus)
	digimon["defense"] = int(digimon["defense"] * bonus)
	digimon["sp_attack"] = int(digimon["sp_attack"] * bonus)
	digimon["speed"] = int(digimon["speed"] * bonus)

# ─────────────────────────────────────────────────────
#  TICKETS
# ─────────────────────────────────────────────────────

func add_tickets(amount: int):
	tickets += amount
	save_data()

func spend_tickets(amount: int) -> bool:
	if tickets >= amount:
		tickets -= amount
		save_data()
		return true
	return false

# ─────────────────────────────────────────────────────
#  PERSISTENCE
# ─────────────────────────────────────────────────────

func save_data():
	var cfg = ConfigFile.new()
	cfg.set_value("gacha", "tickets", tickets)
	cfg.set_value("gacha", "owned", owned)
	cfg.save(SAVE_PATH)

func load_data():
	tickets = 0
	owned.clear()
	var cfg = ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	tickets = int(cfg.get_value("gacha", "tickets", 0))
	var data = cfg.get_value("gacha", "owned", {})
	if data is Dictionary:
		owned = data
