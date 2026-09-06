extends Control

# ─────────────────────────────────────────────────────
#  MAIN MENU
#  Entry point of DigiRogue.
#  Shows title, login/guest buttons, best run stats.
# ─────────────────────────────────────────────────────

@onready var subtitle_label    = $VBoxContainer/SubtitleLogo
@onready var login_button      = $VBoxContainer/LoginButton
@onready var guest_button      = $VBoxContainer/GuestButton
@onready var logged_in_label   = $VBoxContainer/LoggedInLabel
@onready var logout_button     = $VBoxContainer/LogoutButton
@onready var best_run_label    = $VBoxContainer/BestRunLabel
@onready var version_label     = $VersionLabel

var best_floor: int = 0

func _ready():
	if not OS.has_feature("web"):
		_fit_window_to_screen()

	version_label.text  = "v0.1"

	login_button.pressed.connect(_on_login_pressed)
	guest_button.pressed.connect(_on_guest_pressed)
	logout_button.pressed.connect(_on_logout_pressed)

	AuthManager.auth_changed.connect(_on_auth_changed)

	# Hide guest button on desktop (Google login required)
	if not AuthManager.is_web:
		guest_button.visible = false

	# Check if already logged in
	if AuthManager.is_logged_in():
		_show_logged_in_ui(AuthManager.current_user)

	# Load best floor from file if exists
	_load_best_run()
	if best_floor > 0:
		best_run_label.text = "Best run: Floor %d / 50" % best_floor
	else:
		best_run_label.text = "No runs yet. Begin your journey!"

	# If a run just ended, save its result
	if SaveData.is_run_active == false and SaveData.floor_number > 1:
		_save_best_run()

func _on_login_pressed():
	login_button.text = "Logging in..."
	login_button.disabled = true
	guest_button.disabled = true
	AuthManager.login_google()

func _on_guest_pressed():
	_start_run()

func _on_logout_pressed():
	AuthManager.logout()

func _on_auth_changed(user_info: Dictionary):
	login_button.disabled = false
	guest_button.disabled = false
	login_button.text = "Login with Google"
	if user_info.has("_loading"):
		login_button.text = "Logging in..."
		login_button.disabled = true
		return
	if user_info.is_empty():
		print("MainMenu: auth_changed → empty (login failed or logged out)")
		_show_login_ui()
	else:
		print("MainMenu: auth_changed → logged in as ", user_info.get("email", "?"))
		_pending_user = user_info
		call_deferred("_apply_logged_in")

var _pending_user: Dictionary = {}

func _apply_logged_in():
	if _pending_user.is_empty():
		print("MainMenu: _apply_logged_in → _pending_user is empty, skipping")
		return
	print("MainMenu: _apply_logged_in → transitioning to StarterSelect")
	_show_logged_in_ui(_pending_user)
	_pending_user = {}

func _show_logged_in_ui(user_info: Dictionary):
	print("MainMenu: _show_logged_in_ui called for ", user_info.get("email", "?"))
	var display = user_info.get("displayName", user_info.get("email", "Player"))
	logged_in_label.text = "Logged in as: " + str(display)
	logged_in_label.visible = true
	logout_button.visible = true
	login_button.visible = false
	guest_button.visible = false

	# Load cloud gacha data
	GachaData.load_from_cloud()

	_start_run()

func _show_login_ui():
	logged_in_label.visible = false
	logout_button.visible = false
	guest_button.visible = AuthManager.is_web
	login_button.visible = true

func _start_run():
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
	print("MainMenu: calling change_scene_to_file")
	call_deferred("_deferred_start_run")

func _deferred_start_run():
	var err = get_tree().change_scene_to_file("res://Scenes/StarterSelect.tscn")
	print("MainMenu: change_scene_to_file returned: ", err)

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
