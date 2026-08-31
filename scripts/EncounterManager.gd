extends Node

# ─────────────────────────────────────────────────────
#  ENCOUNTER MANAGER
#  Spawns random enemies based on floor_num difficulty
#  and manages enemy pools for roguelike progression
# ─────────────────────────────────────────────────────

# ── ENEMY POOLS BY FLOOR ────────────────────────────
# Each floor_num has enemies that spawn there
var floor_pools = {
	1: ["Agumon", "Biyomon"],
	2: ["Agumon", "Biyomon", "DemiDevimon"],
	3: ["Agumon", "Greymon", "Biyomon"],
	4: ["Greymon", "Birdramon", "DemiDevimon"],
	5: ["Greymon", "Birdramon"],
	6: ["Gomamon", "Gabumon", "Patamon"],
	7: ["Gomamon", "Ikkakumon", "Gabumon"],
	8: ["Ikkakumon", "Garurumon", "Patamon"],
	9: ["Garurumon", "Ikkakumon", "Angemon"],
	10: ["Garurumon", "Angemon"],
	11: ["Tentomon", "Palmon", "DemiDevimon"],
	12: ["Tentomon", "Kabuterimon", "Togemon"],
	13: ["Kabuterimon", "Togemon", "Devimon"],
	14: ["Kabuterimon", "Devimon", "Birdramon"],
	15: ["Devimon", "Kabuterimon"],
	16: ["Angemon", "MagnaAngemon", "Patamon"],
	17: ["Angemon", "MagnaAngemon", "Tentomon"],
	18: ["MagnaAngemon", "MetalGreymon", "WereGarurumon"],
	19: ["MagnaAngemon", "MetalGreymon", "Myotismon"],
	20: ["MagnaAngemon", "MetalGreymon"],
	21: ["Togemon", "Birdramon", "Garurumon"],
	22: ["Togemon", "Garudamon", "WereGarurumon"],
	23: ["Garudamon", "WereGarurumon", "MetalGreymon"],
	24: ["Garudamon", "WereGarurumon", "Myotismon"],
	25: ["Garudamon", "WereGarurumon"],
	26: ["Ikkakumon", "Garudamon", "WereGarurumon"],
	27: ["WereGarurumon", "Garudamon", "MagnaAngemon"],
	28: ["WereGarurumon", "MetalGreymon", "Myotismon"],
	29: ["MetalGarurumon", "MetalGreymon", "Myotismon"],
	30: ["MetalGarurumon", "MetalGreymon"],
	31: ["MetalGreymon", "Myotismon", "Garudamon"],
	32: ["MetalGreymon", "VenomMyotismon", "Garudamon"],
	33: ["WarGreymon", "VenomMyotismon", "Phoenixmon"],
	34: ["WarGreymon", "VenomMyotismon", "Seraphimon"],
	35: ["WarGreymon", "VenomMyotismon"],
	36: ["VenomMyotismon", "MetalGarurumon", "WarGreymon"],
	37: ["VenomMyotismon", "MetalGarurumon", "Seraphimon"],
	38: ["VenomMyotismon", "WarGreymon", "Phoenixmon"],
	39: ["VenomMyotismon", "Seraphimon", "Phoenixmon"],
	40: ["VenomMyotismon", "WarGreymon"],
	41: ["WarGreymon", "MetalGarurumon", "VenomMyotismon"],
	42: ["WarGreymon", "MetalGarurumon", "Seraphimon"],
	43: ["VenomMyotismon", "Seraphimon", "Phoenixmon"],
	44: ["WarGreymon", "VenomMyotismon", "Phoenixmon"],
	45: ["WarGreymon", "MetalGarurumon"],
	46: ["VenomMyotismon", "Seraphimon", "WarGreymon"],
	47: ["VenomMyotismon", "MetalGarurumon", "Phoenixmon"],
	48: ["WarGreymon", "VenomMyotismon", "Seraphimon"],
	49: ["WarGreymon", "MetalGarurumon", "VenomMyotismon"],
	50: ["WarGreymon"],
}

# ── BOSS ENCOUNTERS ─────────────────────────────────
var boss_floors = {
	5:  "Greymon",
	10: "Garurumon",
	15: "Devimon",
	20: "MagnaAngemon",
	25: "Garudamon",
	30: "MetalGarurumon",
	35: "WarGreymon",
	40: "VenomMyotismon",
	45: "MetalGarurumon",
	50: "WarGreymon",
}

# ─────────────────────────────────────────────────────
#  SPAWN ENEMY
# ─────────────────────────────────────────────────────

func spawn_random_enemy(floor_num: int) -> Dictionary:
	"""
	Spawn a random enemy for this floor_num.
	Returns a fully initialized enemy Digimon with stats.
	"""
	
	# Check if this is a boss floor_num
	if floor_num in boss_floors:
		return spawn_boss(floor_num)
	
	# Get enemy pool for this floor_num
	var pool = get_enemy_pool_for_floor(floor_num)
	var chosen_name = pool[randi() % pool.size()]
	
	var enemy = DigimonDB.get_digimon(chosen_name)
	
	# Apply difficulty scaling
	scale_enemy_for_floor(enemy, floor_num)
	
	# Initialize battle-specific fields
	enemy["current_hp"] = enemy["hp"]
	enemy["status"] = "none"
	DigimonDB.recompute_sp(enemy)
	enemy["current_sp"] = enemy["sp"]
	
	print("[EncounterManager] Spawned %s (Floor %d)" % [enemy["name"], floor_num])
	return enemy

func spawn_boss(floor_num: int) -> Dictionary:
	"""Spawn a boss Digimon for boss floors."""
	var boss_name = boss_floors[floor_num]
	var boss = DigimonDB.get_digimon(boss_name)
	
	# Bosses are significantly stronger
	boss["hp"] = int(boss["hp"] * 1.5)
	boss["attack"] = int(boss["attack"] * 1.3)
	boss["defense"] = int(boss["defense"] * 1.3)
	boss["sp_attack"] = int(boss["sp_attack"] * 1.3)
	boss["speed"] = int(boss["speed"] * 1.2)
	
	DigimonDB.recompute_sp(boss)
	boss["current_hp"] = boss["hp"]
	boss["status"] = "none"
	boss["current_sp"] = boss["sp"]
	
	print("[EncounterManager] BOSS ENCOUNTER: %s (Floor %d)" % [boss["name"], floor_num])
	return boss

# ─────────────────────────────────────────────────────
#  DIFFICULTY SCALING
# ─────────────────────────────────────────────────────

func scale_enemy_for_floor(enemy: Dictionary, floor_num: int):
	"""
	Scale enemy stats based on floor number.
	Enemies level up ~1 per floor to match player growth.
	Stat multiplier is aggressive so enemies stay threatening.
	"""
	
	# Level scaling: +1 level per floor (matches player growth rate)
	enemy["level"] = max(1, floor_num)
	
	# Stat multiplier: +10% per floor (compounds with level)
	var multiplier = 1.0 + (floor_num * 0.10)
	
	enemy["hp"] = int(enemy["hp"] * multiplier)
	enemy["attack"] = int(enemy["attack"] * multiplier)
	enemy["defense"] = int(enemy["defense"] * multiplier)
	enemy["sp_attack"] = int(enemy["sp_attack"] * multiplier)
	enemy["speed"] = int(enemy["speed"] * multiplier)

# ─────────────────────────────────────────────────────
#  POOL MANAGEMENT
# ─────────────────────────────────────────────────────

func get_enemy_pool_for_floor(floor_num: int) -> Array:
	"""Get the list of possible enemies for a given floor_num."""
	
	if floor_num in floor_pools:
		return floor_pools[floor_num]
	
	# Default: use the highest available pool if floor_num exceeds defined pools
	var highest_floor = floor_pools.keys().max()
	return floor_pools[highest_floor]

func add_to_pool(floor_num: int, digimon_name: String):
	"""Add a Digimon to an encounter pool (for custom encounters)."""
	if floor_num not in floor_pools:
		floor_pools[floor_num] = []
	
	if digimon_name not in floor_pools[floor_num]:
		floor_pools[floor_num].append(digimon_name)

func print_pool_for_floor(floor_num: int):
	"""Debug: print which Digimon are in a floor_num's pool."""
	var pool = get_enemy_pool_for_floor(floor_num)
	print("[EncounterManager] Floor %d pool: %s" % [floor_num, pool])

# ─────────────────────────────────────────────────────
#  ENCOUNTER CHANCE
# ─────────────────────────────────────────────────────

func calculate_encounter_chance(floor_num: int) -> float:
	"""
	Chance of encountering enemy per step.
	Higher floors = more encounters.
	Returns 0.0 to 1.0 (0% to 100%)
	"""
	var base_chance = 0.35  # 35% base encounter rate
	var floor_bonus = floor_num * 0.02  # +2% per floor_num
	return min(0.75, base_chance + floor_bonus)  # Cap at 75%

func should_trigger_encounter(floor_num: int) -> bool:
	"""Check if an encounter should trigger this step."""
	return randf() < calculate_encounter_chance(floor_num)

# ─────────────────────────────────────────────────────
#  SPECIAL EVENTS
# ─────────────────────────────────────────────────────

func get_random_event(floor_num: int) -> Dictionary:
	"""
	Chance of random event instead of battle (future feature).
	Returns event data.
	"""
	var events = [
		{"type": "shop", "gold_reward": 0},
		{"type": "healing", "gold_reward": 0},
		{"type": "item_find", "gold_reward": 0},
		{"type": "treasure", "gold_reward": floor_num * 10},
	]
	
	return events[randi() % events.size()]

# ─────────────────────────────────────────────────────
#  STATISTICS
# ─────────────────────────────────────────────────────

func get_encounter_stats(floor_num: int) -> Dictionary:
	"""Get difficulty stats for current floor_num."""
	return {
		"floor_num": floor_num,
		"encounter_chance": calculate_encounter_chance(floor_num),
		"pool_size": get_enemy_pool_for_floor(floor_num).size(),
		"is_boss_floor": floor_num in boss_floors,
	}
