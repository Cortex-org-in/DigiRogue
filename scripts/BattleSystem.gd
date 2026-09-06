extends Node

# ─────────────────────────────────────────────────────
#  BATTLESYSTEM - Handles all combat calculations
#  Damage, accuracy, type advantage, status effects
# ─────────────────────────────────────────────────────

# ─────────────────────────────────────────────────────
#  CONSTANTS
# ─────────────────────────────────────────────────────

const CRITICAL_CHANCE = 15  # % chance to deal 1.5x damage
const BASE_BURN_DAMAGE_PERCENT = 12.5  # % damage per turn when burned
const BASE_POISON_DAMAGE_PERCENT = 12.5  # % damage per turn when poisoned
const ACCURACY_VARIANCE = 0.85  # 85% to 115% of base accuracy

# ─────────────────────────────────────────────────────
#  MAIN DAMAGE CALCULATION
# ─────────────────────────────────────────────────────

func calculate_damage(attacker: Dictionary, defender: Dictionary, move_name: String) -> Dictionary:
	"""
	Calculate damage from attack.
	Returns: {
		"damage": int,
		"critical": bool,
		"is_accurate": bool,
		"type_advantage": float,
		"description": String
	}
	"""
	
	var move = DigimonDB.get_move(move_name)
	if move.is_empty():
		return {"damage": 0, "critical": false, "is_accurate": false, "type_advantage": 1.0, "description": "Move not found!"}
	
	var base_power = move["power"]
	
	# ── MISS CALCULATION ────────────────────────────────
	if not check_accuracy(move["accuracy"]):
		return {
			"damage": 0,
			"critical": false,
			"is_accurate": false,
			"type_advantage": 1.0,
			"description": "%s used %s but missed!" % [attacker["name"], move_name]
		}
	
	# ── STATUS MOVES (Damage = 0) ──────────────────────
	if move["category"] == "status":
		return {
			"damage": 0,
			"critical": false,
			"is_accurate": true,
			"type_advantage": 1.0,
			"description": "%s used %s!" % [attacker["name"], move_name]
		}
	
	# ── PHYSICAL/SPECIAL DAMAGE CALCULATION ───────────
	var attack_stat = attacker["attack"] if move["category"] == "physical" else attacker["sp_attack"]
	var defense_stat = defender["defense"] if move["category"] == "physical" else defender["sp_attack"]
	
	# Base damage formula: (2 * level / 5 + 2) * power * (attack / defense) / 50 + 2
	# Damage multiplied by 10 globally (player AND enemy) for faster, punchier battles
	var level = attacker.get("level", 1)
	var damage = int((2.0 * level / 5.0 + 2.0) * base_power * attack_stat / defense_stat / 50.0 + 2.0) * 12
	
	# ── TYPE ADVANTAGE ─────────────────────────────────
	var type_multiplier = DigimonDB.get_type_multiplier(move["type"], defender["type"])
	damage = int(damage * type_multiplier)
	
	# ── CRITICAL HIT ───────────────────────────────────
	var is_critical = randf() * 100 < CRITICAL_CHANCE
	if is_critical:
		damage = int(damage * 1.5)
	
	# ── RANDOM VARIANCE (0.85 to 1.0) ──────────────────
	var variance = randf() * (1.0 - ACCURACY_VARIANCE) + ACCURACY_VARIANCE
	damage = int(damage * variance)
	
	# ── DORMANT ABILITY "Rage Mode" ───────────────────
	# Star-2 gacha digimon deal +25% damage when below half HP
	if attacker.get("dormant", false):
		var cur = attacker.get("current_hp", attacker.get("hp", 1))
		var max = attacker.get("hp", 1)
		if cur <= max * 0.5:
			damage = int(damage * 1.25)
	
	# ── MINIMUM DAMAGE ─────────────────────────────────
	damage = max(1, damage)
	
	# Record stats
	SaveData.record_damage_dealt(damage, move_name)
	
	# Build description
	var desc = "%s used %s!" % [attacker["name"], move_name]
	if is_critical:
		desc += " CRITICAL HIT!"
	if type_multiplier > 1.0:
		desc += " Super effective!"
	elif type_multiplier < 1.0:
		desc += " Not very effective..."
	
	return {
		"damage": damage,
		"critical": is_critical,
		"is_accurate": true,
		"type_advantage": type_multiplier,
		"description": desc
	}

func check_accuracy(base_accuracy: int) -> bool:
	"""Check if move hits based on accuracy stat (0-100)."""
	return randf() * 100 < base_accuracy

# ─────────────────────────────────────────────────────
#  STATUS EFFECT HANDLING
# ─────────────────────────────────────────────────────

func apply_status_effect(attacker: Dictionary, defender: Dictionary, move_name: String):
	"""Apply status effect from move if it triggers."""
	var move = DigimonDB.get_move(move_name)
	if move.is_empty() or move["effect"] == "none":
		return
	
	if randf() * 100 > move["effect_chance"]:
		return  # Effect didn't trigger
	
	var effect = move["effect"]
	
	match effect:
		"burn":
			defender["status"] = "burn"
			print("  [EFFECT] %s is burned!" % defender["name"])
			SaveData.record_status_effect_applied("burn")
		
		"freeze":
			defender["status"] = "freeze"
			print("  [EFFECT] %s is frozen!" % defender["name"])
			SaveData.record_status_effect_applied("freeze")
		
		"stun":
			defender["status"] = "paralysis"
			print("  [EFFECT] %s is paralyzed!" % defender["name"])
			SaveData.record_status_effect_applied("paralysis")
		
		"confuse":
			defender["status"] = "confuse"
			print("  [EFFECT] %s is confused!" % defender["name"])
			SaveData.record_status_effect_applied("confuse")
		
		"atk_down":
			defender["attack"] = int(defender["attack"] * 0.85)
			print("  [EFFECT] %s's attack dropped!" % defender["name"])
		
		"def_down":
			defender["defense"] = int(defender["defense"] * 0.85)
			print("  [EFFECT] %s's defense dropped!" % defender["name"])
		
		"speed_down":
			defender["speed"] = int(defender["speed"] * 0.85)
			print("  [EFFECT] %s's speed dropped!" % defender["name"])
		
		"heal_self":
			var heal_amount = int(attacker["hp"] * 0.3)
			attacker["current_hp"] = min(attacker["current_hp"] + heal_amount, attacker["hp"])
			print("  [EFFECT] %s restored %d HP!" % [attacker["name"], heal_amount])
		
		"atk_up":
			attacker["attack"] = int(attacker["attack"] * 1.15)
			print("  [EFFECT] %s's attack rose!" % attacker["name"])
		
		"def_up":
			attacker["defense"] = int(attacker["defense"] * 1.15)
			print("  [EFFECT] %s's defense rose!" % attacker["name"])
		
		"speed_up":
			attacker["speed"] = int(attacker["speed"] * 1.15)
			print("  [EFFECT] %s's speed rose!" % attacker["name"])
		
		"drain":
			var heal_amount = int(defender["current_hp"] * 0.5)
			attacker["current_hp"] = min(attacker["current_hp"] + heal_amount, attacker["hp"])
			print("  [EFFECT] %s drained %d HP!" % [attacker["name"], heal_amount])

func process_status_damage(digimon: Dictionary) -> int:
	"""Apply damage from status effects at end of turn."""
	var damage = 0
	
	match digimon.get("status", "none"):
		"burn":
			damage = int(digimon["hp"] * BASE_BURN_DAMAGE_PERCENT / 100.0)
			print("  [STATUS] %s takes %d damage from burn!" % [digimon["name"], damage])
		
		"poison":
			damage = int(digimon["hp"] * BASE_POISON_DAMAGE_PERCENT / 100.0)
			print("  [STATUS] %s takes %d damage from poison!" % [digimon["name"], damage])
		
		"freeze":
			# Freeze prevents next move (handled in battle scene)
			pass
		
		"paralysis":
			# Paralysis reduces speed (already applied)
			pass
		
		"confuse":
			# Confuse handled in battle scene
			pass
	
	return damage

# ─────────────────────────────────────────────────────
#  SPEED & TURN ORDER
# ─────────────────────────────────────────────────────

func get_move_priority(move_name: String) -> int:
	"""Priority value for a move. Guard-type moves act before normal attacks."""
	if move_name == "":
		return 0
	var move = DigimonDB.get_move(move_name)
	return move.get("priority", 0)

func who_goes_first(player: Dictionary, enemy: Dictionary, player_move: String = "", enemy_move: String = "") -> int:
	"""
	Determine who attacks first this turn.
	Higher-priority moves (e.g. Guard) always go first.
	Returns: 1 = player, 0 = enemy
	"""
	var player_priority = get_move_priority(player_move)
	var enemy_priority = get_move_priority(enemy_move)
	if player_priority != enemy_priority:
		return 1 if player_priority > enemy_priority else 0

	var player_speed = player["speed"]
	var enemy_speed = enemy["speed"]
	
	# Paralysis reduces speed
	if player.get("status") == "paralysis":
		player_speed = int(player_speed * 0.5)
	if enemy.get("status") == "paralysis":
		enemy_speed = int(enemy_speed * 0.5)
	
	# Add randomness (±20%)
	var player_roll = player_speed * randf_range(0.8, 1.2)
	var enemy_roll = enemy_speed * randf_range(0.8, 1.2)
	
	return 1 if player_roll > enemy_roll else 0

func is_frozen(digimon: Dictionary) -> bool:
	"""Check if Digimon is frozen (can't move)."""
	return digimon.get("status") == "freeze"

func is_confused(digimon: Dictionary) -> bool:
	"""Check if Digimon is confused (may attack self)."""
	return digimon.get("status") == "confuse"

func should_hit_self_when_confused() -> bool:
	"""When confused, 50% chance to hit self instead of opponent."""
	return randf() > 0.5

# ─────────────────────────────────────────────────────
#  SP (Special Points) MANAGEMENT
#  Elemental / special moves cost SP. Status moves and the
#  basic Strike attack are free. SP pool scales with the
#  digimon's capability (sp_attack).
# ─────────────────────────────────────────────────────

func can_use_move(digimon: Dictionary, move_name: String) -> bool:
	"""Check if the digimon has enough SP for this move."""
	return digimon.get("current_sp", 0) >= DigimonDB.get_move_sp_cost(move_name)

func use_move_sp(digimon: Dictionary, move_name: String):
	"""Consume SP from using a move."""
	var cost = DigimonDB.get_move_sp_cost(move_name)
	digimon["current_sp"] = maxi(0, digimon.get("current_sp", 0) - cost)

func get_move_sp_cost(move_name: String) -> int:
	return DigimonDB.get_move_sp_cost(move_name)

# ─────────────────────────────────────────────────────
#  REWARD CALCULATION
# ─────────────────────────────────────────────────────

func calculate_xp_reward(enemy: Dictionary, floor_num: int) -> int:
	"""Calculate XP earned from defeating enemy."""
	var base_xp = enemy.get("xp_yield", 50)
	var floor_multiplier = 1.0 + (floor_num * 0.1)  # +10% per floor_num
	return int(base_xp * floor_multiplier)

# ─────────────────────────────────────────────────────
#  DAMAGE TAKEN BY PLAYER
# ─────────────────────────────────────────────────────

func apply_damage(digimon: Dictionary, damage: int) -> bool:
	"""
	Apply damage to a Digimon.
	Returns: true if Digimon is still alive, false if defeated.
	"""
	SaveData.record_damage_taken(damage)
	digimon["current_hp"] -= damage
	
	if digimon["current_hp"] < 0:
		digimon["current_hp"] = 0
		return false  # Defeated
	
	return true  # Still alive

# ─────────────────────────────────────────────────────
#  SPECIAL MOVES
# ─────────────────────────────────────────────────────

func get_random_valid_enemy_move(enemy: Dictionary) -> String:
	"""Get a random move the enemy can use this turn."""
	var available_moves = []
	
	for move_name in enemy["moves"]:
		if can_use_move(enemy, move_name):
			available_moves.append(move_name)
	
	if available_moves.is_empty():
		return "Strike"  # Fallback free basic attack when out of SP
	
	return available_moves[randi() % available_moves.size()]

func enemy_can_act(enemy: Dictionary) -> bool:
	"""Check if enemy can use any move (SP permitting)."""
	for move_name in enemy["moves"]:
		if can_use_move(enemy, move_name):
			return true
	return true  # Strike is always available

# ─────────────────────────────────────────────────────
#  BATTLE CONCLUSION
# ─────────────────────────────────────────────────────

func determine_winner(player: Dictionary, enemy: Dictionary) -> int:
	"""
	Determine battle winner.
	Returns: 1 = player wins, 0 = enemy wins, -1 = tie (shouldn't happen)
	"""
	if player["current_hp"] <= 0 and enemy["current_hp"] <= 0:
		return -1  # Both defeated (impossible in normal battle)
	elif player["current_hp"] <= 0:
		return 0  # Enemy wins
	elif enemy["current_hp"] <= 0:
		return 1  # Player wins
	
	return -1  # Battle still ongoing

func calculate_digi_reward(floor_num: int) -> int:
	"""Calculate digi currency earned from defeating enemy."""
	return 30 + floor_num * 8  # digi is now the main currency (35 at floor 1, 430 at floor 50)

func get_victory_rewards(enemy: Dictionary, floor_num: int) -> Dictionary:
	"""Calculate all rewards for defeating an enemy. Gold was removed —
	digi is the battle currency, tickets only come from rare items."""
	var xp = calculate_xp_reward(enemy, floor_num)
	var digi = calculate_digi_reward(floor_num)
	
	return {
		"xp": xp,
		"digi": digi,
		"items": [],  # Can add item drops here
	}
