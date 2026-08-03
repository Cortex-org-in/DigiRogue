extends Node

# ─────────────────────────────────────────────────────
#  ITEMDB - All items in the game
#
#  item["effect"] values:
#    heal_X          -> restore X HP
#    full_recovery   -> full HP + full SP + clear status
#    revive          -> full HP + full SP + clear status (usable on faint)
#    restore_sp      -> restore X SP
#    cure_burn / cure_freeze / cure_paralysis / cure_confusion /
#    cure_poison / cure_sleep / cure_all
#    boost           -> permanently raise one stat by `stat` + `value`
#    boost_all       -> permanently raise all stats by `value`
#    boost_two       -> permanently raise two stats (stat1/stat2 + value)
# ─────────────────────────────────────────────────────

var items = {
	# ── HP RECOVERY ───────────────────────────────────
	"Small Recovery": {
		"name": "Small Recovery", "category": "heal",
		"description": "Restores little HP (30)",
		"effect": "heal", "value": 30, "stat": "hp",
		"rarity": "common", "price": 30,
	},
	"Recovery": {
		"name": "Recovery", "category": "heal",
		"description": "Restores HP (70)",
		"effect": "heal", "value": 70, "stat": "hp",
		"rarity": "common", "price": 60,
	},
	"Large Recovery": {
		"name": "Large Recovery", "category": "heal",
		"description": "Restores much HP (140)",
		"effect": "heal", "value": 140, "stat": "hp",
		"rarity": "uncommon", "price": 120,
	},
	"Mega Recovery": {
		"name": "Mega Recovery", "category": "heal",
		"description": "Restores massive HP (250)",
		"effect": "heal", "value": 250, "stat": "hp",
		"rarity": "rare", "price": 220,
	},
	"Full Recovery": {
		"name": "Full Recovery", "category": "heal",
		"description": "Restores HP/SP and cures status",
		"effect": "full_recovery", "value": 0, "stat": "",
		"rarity": "epic", "price": 400,
	},
	"Medical Spray": {
		"name": "Medical Spray", "category": "heal",
		"description": "Heals HP (100)",
		"effect": "heal", "value": 100, "stat": "hp",
		"rarity": "uncommon", "price": 90,
	},
	"HP Capsule": {
		"name": "HP Capsule", "category": "heal",
		"description": "Recovers HP (40)",
		"effect": "heal", "value": 40, "stat": "hp",
		"rarity": "common", "price": 35,
	},
	"HP Disk": {
		"name": "HP Disk", "category": "heal",
		"description": "Recovers HP (120)",
		"effect": "heal", "value": 120, "stat": "hp",
		"rarity": "uncommon", "price": 100,
	},

	# ── REVIVE ────────────────────────────────────────
	"Revive": {
		"name": "Revive", "category": "revive",
		"description": "Revive fainted Digimon with full HP/SP",
		"effect": "revive", "value": 0, "stat": "",
		"rarity": "epic", "price": 350,
	},
	"Revival Capsule": {
		"name": "Revival Capsule", "category": "revive",
		"description": "Revive with HP",
		"effect": "revive", "value": 0, "stat": "",
		"rarity": "epic", "price": 300,
	},
	"Full Revive": {
		"name": "Full Revive", "category": "revive",
		"description": "Fully revive Digimon",
		"effect": "revive", "value": 0, "stat": "",
		"rarity": "legendary", "price": 600,
	},

	# ── SP RECOVERY ───────────────────────────────────
	"SP Capsule": {
		"name": "SP Capsule", "category": "sp",
		"description": "Recovers 30 SP",
		"effect": "restore_sp", "value": 30, "stat": "",
		"rarity": "common", "price": 30,
	},
	"SP Spray": {
		"name": "SP Spray", "category": "sp",
		"description": "Restores 60 SP",
		"effect": "restore_sp", "value": 60, "stat": "",
		"rarity": "uncommon", "price": 60,
	},
	"SP Disk": {
		"name": "SP Disk", "category": "sp",
		"description": "Recovers 120 SP",
		"effect": "restore_sp", "value": 120, "stat": "",
		"rarity": "rare", "price": 120,
	},
	"Full Restore": {
		"name": "Full Restore", "category": "sp",
		"description": "Restores everything (HP/SP/status)",
		"effect": "full_recovery", "value": 0, "stat": "",
		"rarity": "legendary", "price": 500,
	},

	# ── STATUS RECOVERY ───────────────────────────────
	"Antidote": {
		"name": "Antidote", "category": "cure",
		"description": "Cures poison",
		"effect": "cure_poison", "value": 0, "stat": "",
		"rarity": "common", "price": 25,
	},
	"Burn Heal": {
		"name": "Burn Heal", "category": "cure",
		"description": "Cures burn",
		"effect": "cure_burn", "value": 0, "stat": "",
		"rarity": "uncommon", "price": 40,
	},
	"Freeze Heal": {
		"name": "Freeze Heal", "category": "cure",
		"description": "Cures freeze",
		"effect": "cure_freeze", "value": 0, "stat": "",
		"rarity": "uncommon", "price": 40,
	},
	"Paralyze Heal": {
		"name": "Paralyze Heal", "category": "cure",
		"description": "Cures paralysis",
		"effect": "cure_paralysis", "value": 0, "stat": "",
		"rarity": "uncommon", "price": 40,
	},
	"Awakening": {
		"name": "Awakening", "category": "cure",
		"description": "Wake sleeping Digimon",
		"effect": "cure_sleep", "value": 0, "stat": "",
		"rarity": "uncommon", "price": 40,
	},
	"Panic Recovery": {
		"name": "Panic Recovery", "category": "cure",
		"description": "Cures panic/stun",
		"effect": "cure_stun", "value": 0, "stat": "",
		"rarity": "uncommon", "price": 40,
	},
	"Mind Restore": {
		"name": "Mind Restore", "category": "cure",
		"description": "Cures confusion",
		"effect": "cure_confusion", "value": 0, "stat": "",
		"rarity": "uncommon", "price": 40,
	},
	"Eye Drop": {
		"name": "Eye Drop", "category": "cure",
		"description": "Cures blindness / any ailment",
		"effect": "cure_all", "value": 0, "stat": "",
		"rarity": "uncommon", "price": 60,
	},
	"Curse Recovery": {
		"name": "Curse Recovery", "category": "cure",
		"description": "Removes curse / any ailment",
		"effect": "cure_all", "value": 0, "stat": "",
		"rarity": "uncommon", "price": 60,
	},
	"All Recover": {
		"name": "All Recover", "category": "cure",
		"description": "Cures all ailments",
		"effect": "cure_all", "value": 0, "stat": "",
		"rarity": "epic", "price": 150,
	},

	# ── STAT BOOST (permanent) ────────────────────────
	"HP Chip": {
		"name": "HP Chip", "category": "boost",
		"description": "Permanently +10 max HP",
		"effect": "boost", "value": 10, "stat": "hp",
		"rarity": "rare", "price": 180,
	},
	"MP Chip": {
		"name": "MP Chip", "category": "boost",
		"description": "Permanently +10 SP.ATK",
		"effect": "boost", "value": 10, "stat": "sp_attack",
		"rarity": "rare", "price": 180,
	},
	"Attack Chip": {
		"name": "Attack Chip", "category": "boost",
		"description": "Permanently +8 ATK",
		"effect": "boost", "value": 8, "stat": "attack",
		"rarity": "rare", "price": 160,
	},
	"Defense Chip": {
		"name": "Defense Chip", "category": "boost",
		"description": "Permanently +8 DEF",
		"effect": "boost", "value": 8, "stat": "defense",
		"rarity": "rare", "price": 160,
	},
	"Speed Chip": {
		"name": "Speed Chip", "category": "boost",
		"description": "Permanently +8 SPD",
		"effect": "boost", "value": 8, "stat": "speed",
		"rarity": "uncommon", "price": 150,
	},
	"Wisdom Chip": {
		"name": "Wisdom Chip", "category": "boost",
		"description": "Permanently +8 SP.ATK",
		"effect": "boost", "value": 8, "stat": "sp_attack",
		"rarity": "rare", "price": 160,
	},
	"Brain Chip": {
		"name": "Brain Chip", "category": "boost",
		"description": "Permanently +5 to all stats",
		"effect": "boost_all", "value": 5, "stat": "",
		"rarity": "epic", "price": 400,
	},
	"Plugin A": {
		"name": "Plugin A", "category": "boost",
		"description": "Permanently +10 ATK and SP.ATK",
		"effect": "boost_two", "value": 10, "stat1": "attack", "stat2": "sp_attack",
		"rarity": "rare", "price": 250,
	},
	"Plugin B": {
		"name": "Plugin B", "category": "boost",
		"description": "Permanently +10 DEF and SPD",
		"effect": "boost_two", "value": 10, "stat1": "defense", "stat2": "speed",
		"rarity": "rare", "price": 250,
	},
	"Offense Disk": {
		"name": "Offense Disk", "category": "boost",
		"description": "Permanently +15 ATK",
		"effect": "boost", "value": 15, "stat": "attack",
		"rarity": "epic", "price": 350,
	},
	"Defense Disk": {
		"name": "Defense Disk", "category": "boost",
		"description": "Permanently +15 DEF",
		"effect": "boost", "value": 15, "stat": "defense",
		"rarity": "epic", "price": 350,
	},

	# ── FOOD ──────────────────────────────────────────
	"Meat": {
		"name": "Meat", "category": "food",
		"description": "Permanently +2 to all stats",
		"effect": "boost_all", "value": 2, "stat": "",
		"rarity": "common", "price": 60,
	},
	"Giant Meat": {
		"name": "Giant Meat", "category": "food",
		"description": "Permanently +5 to all stats",
		"effect": "boost_all", "value": 5, "stat": "",
		"rarity": "rare", "price": 150,
	},
	"Golden Carrot": {
		"name": "Golden Carrot", "category": "food",
		"description": "Permanently +10 DEF",
		"effect": "boost", "value": 10, "stat": "defense",
		"rarity": "uncommon", "price": 120,
	},
	"Golden Apple": {
		"name": "Golden Apple", "category": "food",
		"description": "Permanently +20 max HP",
		"effect": "boost", "value": 20, "stat": "hp",
		"rarity": "uncommon", "price": 120,
	},

	# ── GACHA TICKET ──────────────────────────────────
	# Very rare — grants gacha currency. Never usable in battle,
	# never sold in shops. Only obtainable as a lucky drop.
	"Ticket": {
		"name": "Ticket", "category": "ticket",
		"description": "A rare ticket for the Digimon Gacha.",
		"effect": "ticket", "value": 1, "stat": "",
		"rarity": "legendary", "price": 999,
	},
}

# Rarity weights — higher = more common in drops
const RARITY_WEIGHTS = {
	"common": 5.0,
	"uncommon": 3.0,
	"rare": 1.6,
	"epic": 0.7,
	"legendary": 1.0,
}

# ─────────────────────────────────────────────────────
#  HELPERS
# ─────────────────────────────────────────────────────

func get_item(item_name: String) -> Dictionary:
	if items.has(item_name):
		return items[item_name].duplicate(true)
	push_error("ItemDB: Item not found: " + item_name)
	return {}

func get_all_names() -> Array:
	var names = []
	for key in items:
		names.append(key)
	return names

func get_category_count(category: String) -> int:
	var count = 0
	for item in items.values():
		if item["category"] == category:
			count += 1
	return count

func get_items_by_category(category: String) -> Array:
	var result = []
	for item_name in items:
		if items[item_name]["category"] == category:
			result.append(item_name)
	return result

# ─────────────────────────────────────────────────────
#  RANDOM SELECTION
# ─────────────────────────────────────────────────────

func get_random_item(floor_num: int = 1) -> String:
	"""Pick one random item name, weighted by rarity + floor."""
	var weighted = []
	for item_name in items:
		var item = items[item_name]
		var weight = RARITY_WEIGHTS.get(item["rarity"], 1.0)
		# Higher floors push toward rarer items
		var floor_boost = floor_num * 0.06
		match item["rarity"]:
			"rare":
				weight += floor_boost * 0.4
			"epic":
				weight += floor_boost * 0.15
			"legendary":
				weight += floor_boost * 0.1
		weighted.append([item_name, weight])

	var total = 0.0
	for entry in weighted:
		total += entry[1]

	var roll = randf() * total
	for entry in weighted:
		roll -= entry[1]
		if roll <= 0:
			return entry[0]
	return weighted[weighted.size() - 1][0]

func get_random_offers(count: int, floor_num: int = 1) -> Array:
	"""Return `count` distinct items from DIFFERENT categories so offers stay varied."""
	var category_weights = {
		"heal": 3.0,
		"boost": 3.0,
		"sp": 2.0,
		"food": 2.0,
		"cure": 1.5,
		"revive": 1.0,
		"ticket": 0.8,   # very rare gacha ticket offer
	}
	var chosen = []
	var available = category_weights.duplicate()

	for i in range(count):
		if available.is_empty():
			break
		var total = 0.0
		for w in available.values():
			total += w
		var roll = randf() * total
		var picked_cat = ""
		for cat in available:
			roll -= available[cat]
			if roll <= 0:
				picked_cat = cat
				break
		if picked_cat == "":
			picked_cat = available.keys()[available.size() - 1]
		available.erase(picked_cat)

		var pool = get_items_by_category(picked_cat)
		if pool.is_empty():
			continue
		chosen.append(_pick_weighted_from_pool(pool, floor_num))

	# Pad in the unlikely case we run out of categories
	while chosen.size() < count:
		var extra = get_random_item(floor_num)
		if extra not in chosen:
			chosen.append(extra)
	return chosen

func _pick_weighted_from_pool(pool: Array, floor_num: int) -> String:
	"""Pick one item from a category, weighted by rarity + floor."""
	var weighted = []
	for item_name in pool:
		var item = items[item_name]
		var weight = RARITY_WEIGHTS.get(item["rarity"], 1.0)
		var floor_boost = floor_num * 0.06
		match item["rarity"]:
			"rare":
				weight += floor_boost * 0.4
			"epic":
				weight += floor_boost * 0.15
			"legendary":
				weight += floor_boost * 0.1
		weighted.append([item_name, weight])

	var total = 0.0
	for entry in weighted:
		total += entry[1]

	var roll = randf() * total
	for entry in weighted:
		roll -= entry[1]
		if roll <= 0:
			return entry[0]
	return weighted[weighted.size() - 1][0]

func get_scaled_price(item_name: String, floor_num: int) -> int:
	"""
	Item price scaled with floor (PokeRogue-style economy).
	Early floors keep prices well below the per-battle digi income
	(30 + floor*8), so post-battle drops are always buyable; prices
	grow with floor as your digi income grows.
	"""
	var item = get_item(item_name)
	if item.is_empty():
		return 10
	var factor = 0.4 + floor_num * 0.06
	return maxi(1, int(item["price"] * factor))

func get_heal_for_floor(floor_num: int) -> String:
	"""Pick a heal item scaled to the current floor tier."""
	var pool = get_heal_pool_for_floor(floor_num)
	return pool[randi() % pool.size()]

func get_heal_pool_for_floor(floor_num: int) -> Array:
	"""Compulsory heal tier — two heals available per tier."""
	if floor_num <= 10:
		return ["Small Recovery", "Recovery"]
	elif floor_num <= 20:
		return ["Recovery", "Large Recovery"]
	elif floor_num <= 30:
		return ["Large Recovery", "Mega Recovery"]
	else:
		return ["Mega Recovery", "Full Recovery"]

func get_revive_for_floor(floor_num: int) -> String:
	if floor_num <= 15:
		return "Revive"
	elif floor_num <= 30:
		return "Revival Capsule"
	else:
		return "Full Revive"

func get_sp_for_floor(floor_num: int) -> String:
	if floor_num <= 10:
		return "SP Capsule"
	elif floor_num <= 20:
		return "SP Spray"
	else:
		return "SP Disk"

func get_shop_stock(floor_num: int = 1, stock_size: int = 4) -> Array:
	"""Return random shop stock (item name + digi price). Tickets are never sold."""
	var stock = []
	var attempts = 0
	while stock.size() < stock_size and attempts < 200:
		var item_name = get_random_item(floor_num)
		var item = items[item_name]
		if item.get("effect", "") == "ticket":
			attempts += 1
			continue  # gacha tickets are never purchasable in shops
		var exists = false
		for entry in stock:
			if entry["name"] == item_name:
				exists = true
				break
		if not exists:
			var price = get_scaled_price(item_name, floor_num)
			stock.append({"name": item_name, "price": price, "currency": "digi"})
		attempts += 1
	return stock

# ─────────────────────────────────────────────────────
#  APPLY ITEM EFFECT
#  Returns true if the item had an effect (so it gets consumed)
# ─────────────────────────────────────────────────────

func apply_item_effect(item: Dictionary, digimon: Dictionary) -> bool:
	var used = true
	match item["effect"]:
		"heal":
			var value = item["value"]
			if digimon["current_hp"] >= digimon["hp"]:
				return false
			digimon["current_hp"] = min(digimon["current_hp"] + value, digimon["hp"])

		"full_recovery":
			digimon["current_hp"] = digimon["hp"]
			digimon["status"] = "none"
			digimon["current_sp"] = digimon.get("sp", digimon.get("current_sp", 0))

		"revive":
			digimon["current_hp"] = digimon["hp"]
			digimon["status"] = "none"
			digimon["current_sp"] = digimon.get("sp", digimon.get("current_sp", 0))

		"restore_sp":
			var sp_value = item["value"]
			if digimon.get("current_sp", 0) >= digimon.get("sp", 0):
				return false
			digimon["current_sp"] = min(digimon.get("current_sp", 0) + sp_value, digimon.get("sp", 0))

		"cure_burn":
			if digimon.get("status") != "burn":
				return false
			digimon["status"] = "none"
		"cure_freeze":
			if digimon.get("status") != "freeze":
				return false
			digimon["status"] = "none"
		"cure_paralysis":
			if digimon.get("status") != "paralysis":
				return false
			digimon["status"] = "none"
		"cure_confusion":
			if digimon.get("status") != "confuse":
				return false
			digimon["status"] = "none"
		"cure_poison":
			if digimon.get("status") != "poison":
				return false
			digimon["status"] = "none"
		"cure_sleep":
			if digimon.get("status") != "sleep":
				return false
			digimon["status"] = "none"
		"cure_stun":
			if digimon.get("status") != "stun":
				return false
			digimon["status"] = "none"
		"cure_all":
			if digimon.get("status") == "none":
				return false
			digimon["status"] = "none"

		"boost":
			var stat = item["stat"]
			if digimon.has(stat):
				digimon[stat] += item["value"]
				if stat == "hp":
					digimon["current_hp"] = min(digimon["current_hp"] + item["value"], digimon["hp"])

		"boost_all":
			for stat in ["hp", "attack", "defense", "sp_attack", "speed"]:
				digimon[stat] += item["value"]
			digimon["current_hp"] = min(digimon["current_hp"] + item["value"], digimon["hp"])

		"boost_two":
			var s1 = item["stat1"]
			var s2 = item["stat2"]
			if digimon.has(s1):
				digimon[s1] += item["value"]
			if digimon.has(s2):
				digimon[s2] += item["value"]

		_:
			used = false

	return used
