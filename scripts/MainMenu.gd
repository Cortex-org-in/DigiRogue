extends Control

# ─────────────────────────────────────────────────────
#  MAIN MENU
#  Entry point of DigiRogue.
#  Shows title, best run stats, New Run button.
# ─────────────────────────────────────────────────────

@onready var title_label      = $VBoxContainer/TitleLabel
@onready var subtitle_label   = $VBoxContainer/SubtitleLabel
@onready var new_run_button   = $VBoxContainer/NewRunButton
@onready var best_run_label   = $VBoxContainer/BestRunLabel
@onready var version_label    = $VersionLabel

var best_floor: int = 0

func _ready():
	_fit_window_to_screen()

	title_label.text    = "DigiRogue"
	subtitle_label.text = "A Digimon Roguelike"
	version_label.text  = "v0.1"

	new_run_button.pressed.connect(_on_new_run_pressed)

	# Load best floor from file if exists
	_load_best_run()
	if best_floor > 0:
		best_run_label.text = "Best run: Floor %d / 50" % best_floor
	else:
		best_run_label.text = "No runs yet. Begin your journey!"

	# If a run just ended, save its result
	if SaveData.is_run_active == false and SaveData.floor_number > 1:
		_save_best_run()

func _on_new_run_pressed():
	# Reset run state
	SaveData.is_run_active = false
	SaveData.floor_number  = 1
	SaveData.digi          = 0
	SaveData.items         = []
	SaveData.digivice_scan_rate = 0
	SaveData.digimon_collection = {}
	SaveData.digimon_roster = []
	SaveData.guest_roster = []
	SaveData.rerolls_left = SaveData.REROLLS_PER_SEGMENT
	SaveData.reroll_segment = -1
	SaveData.current_digimon = {}

	# Go to starter selection
	get_tree().change_scene_to_file("res://Scenes/StarterSelect.tscn")

func _fit_window_to_screen():
	var screen = DisplayServer.screen_get_size()
	var target = Vector2i(int(screen.x * 0.9), int(screen.y * 0.9))
	target.x = maxi(target.x, 640)
	target.y = maxi(target.y, 480)
	var window = get_window()
	window.size = target
	window.position = (screen - target) / 2

func _save_best_run():
	if SaveData.floor_number > best_floor:
		best_floor = SaveData.floor_number
		var file = FileAccess.open("user://best_run.dat", FileAccess.WRITE)
		if file:
			file.store_32(best_floor)
			file.close()

func _load_best_run():
	if FileAccess.file_exists("user://best_run.dat"):
		var file = FileAccess.open("user://best_run.dat", FileAccess.READ)
		if file:
			best_floor = file.get_32()
			file.close()
