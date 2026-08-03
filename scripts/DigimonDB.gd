extends Node

# ─────────────────────────────────────────────
#  TYPE CHART - ATTRIBUTE TRIANGLE
#  Vaccine beats Virus, Virus beats Data, Data beats Vaccine
#  1.5 = super effective, 0.5 = not very effective, 1.0 = normal
# ─────────────────────────────────────────────
var type_chart = {
	"vaccine": { "vaccine":1.0, "virus":1.5, "data":0.5 },
	"virus":   { "vaccine":0.5, "virus":1.0, "data":1.5 },
	"data":    { "vaccine":1.5, "virus":0.5, "data":1.0 },
}

# ─────────────────────────────────────────────
#  MOVES DATABASE
#  power: base damage (0 = status move)
#  accuracy: 0-100
#  pp: uses per battle
#  effect: what extra thing it does
#  effect_chance: % chance of effect triggering
# ─────────────────────────────────────────────
var moves_db = {
	# VACCINE MOVES (elemental holy/fire)
	"Pepper Breath": { "power":40, "type":"vaccine", "accuracy":100, "pp":30, "category":"physical", "effect":"none", "effect_chance":0, "description":"A basic fire attack." },
	"Fire Breath":   { "power":60, "type":"vaccine", "accuracy":95,  "pp":20, "category":"physical", "effect":"burn", "effect_chance":20, "description":"May burn the target." },
	"Mega Flame":    { "power":90, "type":"vaccine", "accuracy":85,  "pp":10, "category":"special",  "effect":"burn", "effect_chance":30, "description":"Powerful flame attack." },
	"Nova Blast":    { "power":120,"type":"vaccine", "accuracy":80,  "pp":5,  "category":"special",  "effect":"burn", "effect_chance":50, "description":"Massive fire explosion." },
	"Holy Beam":     { "power":60, "type":"vaccine", "accuracy":100, "pp":20, "category":"special",  "effect":"none", "effect_chance":0,  "description":"A beam of holy light." },
	"Angel Blast":   { "power":85, "type":"vaccine", "accuracy":90,  "pp":12, "category":"special",  "effect":"stun",  "effect_chance":15, "description":"May stun the enemy." },
	"Heaven's Gate": { "power":130,"type":"vaccine", "accuracy":75,  "pp":5,  "category":"special",  "effect":"stun",  "effect_chance":40, "description":"Ultimate light attack." },

	# VIRUS MOVES (elemental dark)
	"Shadow Wing":   { "power":55, "type":"virus", "accuracy":100, "pp":25, "category":"physical", "effect":"none", "effect_chance":0,  "description":"Dark wing slash." },
	"Dark Claw":     { "power":75, "type":"virus", "accuracy":95,  "pp":15, "category":"physical", "effect":"atk_down","effect_chance":20,"description":"Lowers enemy attack." },
	"Chaos Flare":   { "power":110,"type":"virus", "accuracy":80,  "pp":8,  "category":"special",  "effect":"burn",  "effect_chance":30, "description":"Dark fire explosion." },
	"Drain Life":    { "power":50, "type":"virus", "accuracy":90,  "pp":12, "category":"special",  "effect":"drain",  "effect_chance":100,"description":"Drains enemy HP to heal self." },

	# DATA MOVES (elemental neutral)
	"Bubble Blow":   { "power":40, "type":"data", "accuracy":100, "pp":30, "category":"special",  "effect":"none", "effect_chance":0,  "description":"Shoots bubbles at foe." },
	"Tidal Wave":    { "power":70, "type":"data", "accuracy":90,  "pp":15, "category":"special",  "effect":"none", "effect_chance":0,  "description":"A wave of water." },
	"Aqua Blast":    { "power":95, "type":"data", "accuracy":85,  "pp":10, "category":"special",  "effect":"none", "effect_chance":0,  "description":"Blasts water at high speed." },
	"Wind Claw":     { "power":45, "type":"data", "accuracy":100, "pp":30, "category":"physical", "effect":"none", "effect_chance":0,  "description":"Slashes with wind." },
	"Storm Claw":    { "power":75, "type":"data", "accuracy":90,  "pp":15, "category":"physical", "effect":"speed_down","effect_chance":25,"description":"May lower enemy speed." },
	"Hurricane":     { "power":100,"type":"data", "accuracy":80,  "pp":8,  "category":"special",  "effect":"confuse","effect_chance":30,"description":"A chaotic hurricane." },
	"Rock Fist":     { "power":50, "type":"data", "accuracy":100, "pp":25, "category":"physical", "effect":"none", "effect_chance":0,  "description":"Punches with rock." },
	"Quake Stomp":   { "power":80, "type":"data", "accuracy":90,  "pp":12, "category":"physical", "effect":"def_down","effect_chance":20,"description":"Stomps to lower defense." },
	"Thunder Clap":  { "power":45, "type":"data", "accuracy":100,"pp":30,"category":"special", "effect":"none", "effect_chance":0,  "description":"Electric clap." },
	"Lightning":     { "power":70, "type":"data", "accuracy":90, "pp":15,"category":"special",  "effect":"stun",  "effect_chance":20, "description":"May stun." },
	"Thunder Blast": { "power":100,"type":"data", "accuracy":85, "pp":10,"category":"special",  "effect":"stun",  "effect_chance":30, "description":"Massive lightning." },
	"Tundra Breath": { "power":50, "type":"data", "accuracy":100, "pp":25, "category":"special",  "effect":"freeze","effect_chance":15, "description":"Icy breath." },
	"Blizzard":      { "power":85, "type":"data", "accuracy":85,  "pp":12, "category":"special",  "effect":"freeze","effect_chance":25, "description":"Freezing blizzard." },

	# STATUS / SUPPORT MOVES
	"Refresh":    { "power":0, "type":"vaccine","accuracy":100,"pp":10,"category":"status","effect":"heal_self",     "effect_chance":100,"description":"Restores 30% of max HP." },
	"Guard":      { "power":0, "type":"data","accuracy":100,"pp":15,"category":"status","effect":"def_up",        "effect_chance":100,"priority":1,"description":"Raises own defense." },
	"Charge Up":  { "power":0, "type":"data","accuracy":100,"pp":15,"category":"status","effect":"atk_up",    "effect_chance":100,"description":"Raises own attack." },
	"Swift Step": { "power":0, "type":"data","accuracy":100,"pp":15,"category":"status","effect":"speed_up",       "effect_chance":100,"description":"Raises own speed." },

	# FREE BASIC ATTACK (always available, costs 0 SP)
	"Strike":     { "power":30, "type":"data","accuracy":100,"pp":999,"sp_cost":0,"category":"physical","effect":"none","effect_chance":0,  "description":"A basic physical attack." },
}

# ─────────────────────────────────────────────
#  DIGIMON DATABASE
#  stage: Baby / Rookie / Champion / Ultimate / Mega
#  evolves_to: name of next evolution (empty if final)
#  evolves_at: level required
# ─────────────────────────────────────────────
var digimon_db = {

	# ── ROOKIE TIER ──────────────────────────────────
	"Agumon": {
		"name":"Agumon",   "stage":"Rookie",
		"type":"vaccine",  "hp":137, "attack":60, "defense":53, "sp_attack":41, "speed":37,
		"moves":["Pepper Breath","Fire Breath","Rock Fist","Guard"],
		"evolves_to":"Greymon", "evolves_at":16,
		"sprite":"res://assets/sprites/agumon.png",
		"sprite_back":"res://assets/sprites/agumon_back.png",
		"description":"A reptile Digimon with powerful claws and fire breath.",
		"xp_yield":60,
	},
	"Gabumon": {
		"name":"Gabumon",  "stage":"Rookie",
		"type":"data",     "hp":137, "attack":44, "defense":37, "sp_attack":51, "speed":39,
		"moves":["Tundra Breath","Rock Fist","Guard","Swift Step"],
		"evolves_to":"Garurumon", "evolves_at":16,
		"sprite":"res://assets/sprites/gabumon.png",
		"sprite_back":"res://assets/sprites/gabumon_back.png",
		"description":"A mysterious Digimon wearing a beast pelt.",
		"xp_yield":60,
	},
	"Patamon": {
		"name":"Patamon",  "stage":"Rookie",
		"type":"data",     "hp":118, "attack":32, "defense":30, "sp_attack":60, "speed":37,
		"moves":["Wind Claw","Bubble Blow","Refresh","Swift Step"],
		"evolves_to":"Angemon", "evolves_at":16,
		"sprite":"res://assets/sprites/patamon.png",
		"sprite_back":"res://assets/sprites/patamon_back.png",
		"description":"A small Digimon that flies with large ears.",
		"xp_yield":60,
	},
	"Tentomon": {
		"name":"Tentomon", "stage":"Rookie",
		"type":"vaccine",  "hp":112, "attack":35, "defense":55, "sp_attack":58, "speed":32,
		"moves":["Thunder Clap","Wind Claw","Charge Up","Guard"],
		"evolves_to":"Kabuterimon", "evolves_at":16,
		"sprite":"res://assets/sprites/tentomon.png",
		"sprite_back":"res://assets/sprites/tentomon_back.png",
		"description":"An insect Digimon with electric powers.",
		"xp_yield":60,
	},
	"Palmon": {
		"name":"Palmon",   "stage":"Rookie",
		"type":"data",     "hp":139, "attack":47, "defense":44, "sp_attack":52, "speed":33,
		"moves":["Rock Fist","Bubble Blow","Guard","Refresh"],
		"evolves_to":"Togemon", "evolves_at":16,
		"sprite":"res://assets/sprites/palmon.png",
		"sprite_back":"res://assets/sprites/palmon_back.png",
		"description":"A plant Digimon that can use its vines to attack.",
		"xp_yield":60,
	},
	"Biyomon": {
		"name":"Biyomon",  "stage":"Rookie",
		"type":"data",     "hp":109, "attack":37, "defense":36, "sp_attack":55, "speed":39,
		"moves":["Wind Claw","Fire Breath","Storm Claw","Swift Step"],
		"evolves_to":"Birdramon", "evolves_at":16,
		"sprite":"res://assets/sprites/biyomon.png",
		"sprite_back":"res://assets/sprites/biyomon_back.png",
		"description":"A bird Digimon with feathers like pink flames.",
		"xp_yield":60,
	},
	"Gomamon": {
		"name":"Gomamon",  "stage":"Rookie",
		"type":"data",     "hp":144, "attack":39, "defense":47, "sp_attack":52, "speed":33,
		"moves":["Bubble Blow","Tidal Wave","Rock Fist","Refresh"],
		"evolves_to":"Ikkakumon", "evolves_at":16,
		"sprite":"res://assets/sprites/gomamon.png",
		"sprite_back":"res://assets/sprites/gomamon_back.png",
		"description":"A sea animal Digimon.",
		"xp_yield":60,
	},
	"DemiDevimon": {
		"name":"DemiDevimon","stage":"Rookie",
		"type":"virus",     "hp":113, "attack":47, "defense":36, "sp_attack":52, "speed":58,
		"moves":["Shadow Wing","Dark Claw","Drain Life","Swift Step"],
		"evolves_to":"Devimon", "evolves_at":16,
		"sprite":"res://assets/sprites/demidevimon.png",
		"sprite_back":"res://assets/sprites/demidevimon_back.png",
		"description":"A mischievous dark Digimon.",
		"xp_yield":65,
	},

	# ── CHAMPION TIER ─────────────────────────────────
	"Greymon": {
		"name":"Greymon",  "stage":"Champion",
		"type":"vaccine",  "hp":226, "attack":98, "defense":86, "sp_attack":58, "speed":56,
		"moves":["Fire Breath","Mega Flame","Rock Fist","Guard"],
		"evolves_to":"MetalGreymon", "evolves_at":36,
		"sprite":"res://assets/sprites/greymon.png",
		"sprite_back":"res://assets/sprites/greymon_back.png",
		"description":"A giant dinosaur Digimon with horned helmet.",
		"xp_yield":150,
	},
	"Garurumon": {
		"name":"Garurumon","stage":"Champion",
		"type":"data",     "hp":189, "attack":72, "defense":69, "sp_attack":76, "speed":92,
		"moves":["Blizzard","Tundra Breath","Swift Step","Storm Claw"],
		"evolves_to":"WereGarurumon", "evolves_at":36,
		"sprite":"res://assets/sprites/garurumon.png",
		"sprite_back":"res://assets/sprites/garurumon_back.png",
		"description":"A wolf Digimon encased in cold fur.",
		"xp_yield":150,
	},
	"Angemon": {
		"name":"Angemon",  "stage":"Champion",
		"type":"vaccine",  "hp":189, "attack":87, "defense":69, "sp_attack":98, "speed":47,
		"moves":["Holy Beam","Angel Blast","Refresh","Guard"],
		"evolves_to":"MagnaAngemon", "evolves_at":36,
		"sprite":"res://assets/sprites/angemon.png",
		"sprite_back":"res://assets/sprites/angemon_back.png",
		"description":"An angel Digimon that fights for justice.",
		"xp_yield":160,
	},
	"Kabuterimon": {
		"name":"Kabuterimon","stage":"Champion",
		"type":"vaccine","hp":180, "attack":76, "defense":92, "sp_attack":92, "speed":33,
		"moves":["Lightning","Thunder Blast","Charge Up","Rock Fist"],
		"evolves_to":"MegaKabuterimon", "evolves_at":36,
		"sprite":"res://assets/sprites/kabuterimon.png",
		"sprite_back":"res://assets/sprites/kabuterimon_back.png",
		"description":"A giant insect Digimon with electric horn.",
		"xp_yield":150,
	},
	"Togemon": {
		"name":"Togemon",  "stage":"Champion",
		"type":"data",    "hp":235, "attack":76, "defense":86, "sp_attack":75, "speed":40,
		"moves":["Quake Stomp","Rock Fist","Guard","Refresh"],
		"evolves_to":"Lillymon", "evolves_at":36,
		"sprite":"res://assets/sprites/togemon.png",
		"sprite_back":"res://assets/sprites/togemon_back.png",
		"description":"A cactus Digimon that packs a powerful punch.",
		"xp_yield":150,
	},
	"Birdramon": {
		"name":"Birdramon", "stage":"Champion",
		"type":"data",      "hp":199, "attack":68, "defense":58, "sp_attack":89, "speed":74,
		"moves":["Mega Flame","Storm Claw","Wind Claw","Fire Breath"],
		"evolves_to":"Garudamon", "evolves_at":36,
		"sprite":"res://assets/sprites/birdramon.png",
		"sprite_back":"res://assets/sprites/birdramon_back.png",
		"description":"A giant fire bird Digimon.",
		"xp_yield":155,
	},
	"Devimon": {
		"name":"Devimon",  "stage":"Champion",
		"type":"virus",    "hp":199, "attack":96, "defense":69, "sp_attack":89, "speed":35,
		"moves":["Dark Claw","Chaos Flare","Drain Life","Shadow Wing"],
		"evolves_to":"Myotismon", "evolves_at":36,
		"sprite":"res://assets/sprites/devimon.png",
		"sprite_back":"res://assets/sprites/devimon_back.png",
		"description":"A fallen angel Digimon of darkness.",
		"xp_yield":170,
	},
	"Ikkakumon": {
		"name":"Ikkakumon","stage":"Champion",
		"type":"data",    "hp":235, "attack":83, "defense":74, "sp_attack":76, "speed":40,
		"moves":["Aqua Blast","Tidal Wave","Rock Fist","Guard"],
		"evolves_to":"Zudomon", "evolves_at":36,
		"sprite":"res://assets/sprites/ikkakumon.png",
		"sprite_back":"res://assets/sprites/ikkakumon_back.png",
		"description":"A sea mammal Digimon with a large horn.",
		"xp_yield":150,
	},

	# ── ULTIMATE TIER ─────────────────────────────────
	"MetalGreymon": {
		"name":"MetalGreymon","stage":"Ultimate",
		"type":"vaccine",  "hp":355, "attack":147,"defense":122,"sp_attack":113,"speed":113,
		"moves":["Nova Blast","Mega Flame","Guard","Charge Up"],
		"evolves_to":"WarGreymon", "evolves_at":50,
		"sprite":"res://assets/sprites/metalgreymon.png",
		"sprite_back":"res://assets/sprites/metalgreymon_back.png",
		"description":"Half machine, half Digimon powerhouse.",
		"xp_yield":280,
	},
	"WereGarurumon": {
		"name":"WereGarurumon","stage":"Ultimate",
		"type":"data",       "hp":338, "attack":152,"defense":98,"sp_attack":112,"speed":152,
		"moves":["Blizzard","Storm Claw","Swift Step","Dark Claw"],
		"evolves_to":"MetalGarurumon", "evolves_at":50,
		"sprite":"res://assets/sprites/weregararumon.png",
		"sprite_back":"res://assets/sprites/weregararumon_back.png",
		"description":"A werewolf Digimon of incredible speed.",
		"xp_yield":280,
	},
	"MagnaAngemon": {
		"name":"MagnaAngemon","stage":"Ultimate",
		"type":"vaccine",    "hp":303, "attack":118,"defense":111,"sp_attack":158,"speed":88,
		"moves":["Heaven's Gate","Angel Blast","Refresh","Holy Beam"],
		"evolves_to":"Seraphimon", "evolves_at":50,
		"sprite":"res://assets/sprites/magnaangemon.png",
		"sprite_back":"res://assets/sprites/magnaangemon_back.png",
		"description":"The most powerful angel Digimon.",
		"xp_yield":290,
	},
	"Myotismon": {
		"name":"Myotismon", "stage":"Ultimate",
		"type":"virus",      "hp":329, "attack":137,"defense":113,"sp_attack":150,"speed":88,
		"moves":["Chaos Flare","Drain Life","Dark Claw","Shadow Wing"],
		"evolves_to":"VenomMyotismon", "evolves_at":50,
		"sprite":"res://assets/sprites/myotismon.png",
		"sprite_back":"res://assets/sprites/myotismon_back.png",
		"description":"A vampire Digimon of the night.",
		"xp_yield":300,
	},
	"Garudamon": {
		"name":"Garudamon", "stage":"Ultimate",
		"type":"data",       "hp":295, "attack":132,"defense":106,"sp_attack":142,"speed":123,
		"moves":["Hurricane","Storm Claw","Nova Blast","Swift Step"],
		"evolves_to":"Phoenixmon", "evolves_at":50,
		"sprite":"res://assets/sprites/garudamon.png",
		"sprite_back":"res://assets/sprites/garudamon_back.png",
		"description":"A giant warrior bird Digimon.",
		"xp_yield":285,
	},
	"MegaKabuterimon": {
		"name":"MegaKabuterimon","stage":"Ultimate",
		"type":"vaccine",   "hp":325, "attack":119,"defense":122,"sp_attack":131,"speed":88,
		"moves":["Thunder Blast","Lightning","Charge Up","Hurricane"],
		"evolves_to":"HerculesKabuterimon", "evolves_at":50,
		"sprite":"res://assets/sprites/megakabuterimon.png",
		"sprite_back":"res://assets/sprites/megakabuterimon_back.png",
		"description":"A colossal insect Digimon with a golden horn of thunder.",
		"xp_yield":290,
	},
	"Lillymon": {
		"name":"Lillymon", "stage":"Ultimate",
		"type":"data",       "hp":338, "attack":130,"defense":98,"sp_attack":116,"speed":93,
		"moves":["Angel Blast","Holy Beam","Refresh","Swift Step"],
		"evolves_to":"Rosemon", "evolves_at":50,
		"sprite":"res://assets/sprites/lillymon.png",
		"sprite_back":"res://assets/sprites/lillymon_back.png",
		"description":"A beautiful flower Digimon blooming with holy light.",
		"xp_yield":290,
	},
	"Zudomon": {
		"name":"Zudomon", "stage":"Ultimate",
		"type":"data",       "hp":355, "attack":143,"defense":111,"sp_attack":123,"speed":95,
		"moves":["Aqua Blast","Tidal Wave","Rock Fist","Guard"],
		"evolves_to":"Vikemon", "evolves_at":50,
		"sprite":"res://assets/sprites/zudomon.png",
		"sprite_back":"res://assets/sprites/zudomon_back.png",
		"description":"A sea creature Digimon wielding a mighty hammer.",
		"xp_yield":295,
	},

	# ── MEGA TIER ─────────────────────────────────────
	"WarGreymon": {
		"name":"WarGreymon", "stage":"Mega",
		"type":"vaccine",    "hp":505, "attack":209,"defense":178,"sp_attack":182,"speed":171,
		"moves":["Nova Blast","Mega Flame","Guard","Charge Up"],
		"evolves_to":"", "evolves_at":0,
		"sprite":"res://assets/sprites/wargreymon.png",
		"sprite_back":"res://assets/sprites/wargreymon_back.png",
		"description":"The ultimate form of the Agumon line.",
		"xp_yield":500,
	},
	"MetalGarurumon": {
		"name":"MetalGarurumon","stage":"Mega",
		"type":"data",       "hp":455, "attack":197,"defense":165,"sp_attack":193,"speed":140,
		"moves":["Blizzard","Thunder Blast","Swift Step","Drain Life"],
		"evolves_to":"", "evolves_at":0,
		"sprite":"res://assets/sprites/metalgararumon.png",
		"sprite_back":"res://assets/sprites/metalgararumon_back.png",
		"description":"A cybernetic wolf Digimon of the Mega level.",
		"xp_yield":500,
	},
	"Seraphimon": {
		"name":"Seraphimon","stage":"Mega",
		"type":"vaccine",    "hp":491, "attack":173,"defense":164,"sp_attack":222,"speed":171,
		"moves":["Heaven's Gate","Angel Blast","Refresh","Holy Beam"],
		"evolves_to":"", "evolves_at":0,
		"sprite":"res://assets/sprites/seraphimon.png",
		"sprite_back":"res://assets/sprites/seraphimon_back.png",
		"description":"The highest angel Digimon of pure light.",
		"xp_yield":510,
	},
	"VenomMyotismon": {
		"name":"VenomMyotismon","stage":"Mega",
		"type":"virus",      "hp":505, "attack":212,"defense":154,"sp_attack":198,"speed":138,
		"moves":["Chaos Flare","Drain Life","Dark Claw","Nova Blast"],
		"evolves_to":"", "evolves_at":0,
		"sprite":"res://assets/sprites/venommyotismon.png",
		"sprite_back":"res://assets/sprites/venommyotismon_back.png",
		"description":"The most evil Digimon in existence.",
		"xp_yield":520,
	},
	"Phoenixmon": {
		"name":"Phoenixmon","stage":"Mega",
		"type":"data",       "hp":498, "attack":168,"defense":152,"sp_attack":219,"speed":202,
		"moves":["Nova Blast","Hurricane","Refresh","Mega Flame"],
		"evolves_to":"", "evolves_at":0,
		"sprite":"res://assets/sprites/phoenixmon.png",
		"sprite_back":"res://assets/sprites/phoenixmon_back.png",
		"description":"The legendary fire bird reborn from ash.",
		"xp_yield":510,
	},
	"HerculesKabuterimon": {
		"name":"HerculesKabuterimon","stage":"Mega",
		"type":"vaccine",    "hp":494, "attack":180,"defense":178,"sp_attack":193,"speed":150,
		"moves":["Thunder Blast","Nova Blast","Charge Up","Quake Stomp"],
		"evolves_to":"", "evolves_at":0,
		"sprite":"res://assets/sprites/herculeskabuterimon.png",
		"sprite_back":"res://assets/sprites/herculeskabuterimon_back.png",
		"description":"The ultimate insect Digimon, protector of the forest.",
		"xp_yield":505,
	},
	"Rosemon": {
		"name":"Rosemon","stage":"Mega",
		"type":"data",       "hp":466, "attack":192,"defense":165,"sp_attack":203,"speed":171,
		"moves":["Nova Blast","Holy Beam","Refresh","Storm Claw"],
		"evolves_to":"", "evolves_at":0,
		"sprite":"res://assets/sprites/rosemon.png",
		"sprite_back":"res://assets/sprites/rosemon_back.png",
		"description":"A rose Digimon whose thorned whip delivers deadly strikes.",
		"xp_yield":505,
	},
	"Vikemon": {
		"name":"Vikemon","stage":"Mega",
		"type":"data",       "hp":505, "attack":197,"defense":170,"sp_attack":193,"speed":163,
		"moves":["Blizzard","Tundra Breath","Aqua Blast","Guard"],
		"evolves_to":"", "evolves_at":0,
		"sprite":"res://assets/sprites/vikemon.png",
		"sprite_back":"res://assets/sprites/vikemon_back.png",
		"description":"An ice-warrior walrus Digimon of overwhelming strength.",
		"xp_yield":510,
	},
}

# ─────────────────────────────────────────────
#  HELPER FUNCTIONS
# ─────────────────────────────────────────────

func get_digimon(digimon_name: String) -> Dictionary:
	if digimon_db.has(digimon_name):
		var d = digimon_db[digimon_name].duplicate(true)
		recompute_sp(d)
		return d
	push_error("DigimonDB: Digimon not found: " + digimon_name)
	return {}

func recompute_sp(digimon: Dictionary) -> void:
	"""Set the digimon's SP capacity from its special ability (SP.ATK).
	Bigger / more capable digimon carry more SP, like Time Stranger."""
	digimon["sp"] = maxi(25, int(digimon.get("sp_attack", 20) * 0.6) + 10)
	if not digimon.has("current_sp"):
		digimon["current_sp"] = digimon["sp"]

func has_digimon(digimon_name: String) -> bool:
	return digimon_db.has(digimon_name)

func get_move(move_name: String) -> Dictionary:
	if moves_db.has(move_name):
		var m = moves_db[move_name].duplicate(true)
		if not m.has("sp_cost"):
			if m.get("category", "") == "status":
				m["sp_cost"] = 0
			else:
				m["sp_cost"] = maxi(2, int(m.get("power", 0) / 10))
		return m
	push_error("DigimonDB: Move not found: " + move_name)
	return {}

func get_move_sp_cost(move_name: String) -> int:
	"""SP a move costs to use. Status moves and Strike are free."""
	return get_move(move_name).get("sp_cost", 1)

func get_type_multiplier(attacking_type: String, defending_type: String) -> float:
	if type_chart.has(attacking_type) and type_chart[attacking_type].has(defending_type):
		return type_chart[attacking_type][defending_type]
	return 1.0

func get_all_rookies() -> Array:
	var result = []
	for key in digimon_db:
		if digimon_db[key]["stage"] == "Rookie":
			result.append(key)
	return result

func get_by_stage(stage: String) -> Array:
	var result = []
	for key in digimon_db:
		if digimon_db[key]["stage"] == stage:
			result.append(key)
	return result

func can_digivolve(digimon: Dictionary) -> bool:
	if digimon["evolves_to"] == "":
		return false
	return digimon.get("level", 1) >= digimon["evolves_at"]

func get_digivolution(digimon: Dictionary) -> String:
	return digimon.get("evolves_to", "")
