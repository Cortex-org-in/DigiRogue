extends Control

# ─────────────────────────────────────────────────────
#  SETTINGS PANEL
#  Opened with Esc during a battle. Lets the player pick
#  colors for the battle buttons and panel live.
#  process_mode = ALWAYS so it works while the tree is
#  paused (the game pauses while settings are open).
# ─────────────────────────────────────────────────────

signal colors_changed
signal settings_closed

@onready var normal_picker   = $Panel/VBox/NormalRow/NormalPicker
@onready var hover_picker    = $Panel/VBox/HoverRow/HoverPicker
@onready var pressed_picker  = $Panel/VBox/PressedRow/PressedPicker
@onready var panel_picker    = $Panel/VBox/PanelRow/PanelPicker

func _ready():
	normal_picker.color = SaveData.button_normal_color
	hover_picker.color = SaveData.button_hover_color
	pressed_picker.color = SaveData.button_pressed_color
	panel_picker.color = SaveData.panel_color

	normal_picker.color_changed.connect(_on_normal_changed)
	hover_picker.color_changed.connect(_on_hover_changed)
	pressed_picker.color_changed.connect(_on_pressed_changed)
	panel_picker.color_changed.connect(_on_panel_changed)
	$Panel/VBox/BottomRow/ResetButton.pressed.connect(_on_reset_pressed)
	$Panel/VBox/BottomRow/CloseButton.pressed.connect(_on_close_pressed)

func _unhandled_input(event):
	if visible and event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()

func _on_normal_changed(color: Color):
	SaveData.button_normal_color = color
	SaveData.save_ui_settings()
	colors_changed.emit()

func _on_hover_changed(color: Color):
	SaveData.button_hover_color = color
	SaveData.save_ui_settings()
	colors_changed.emit()

func _on_pressed_changed(color: Color):
	SaveData.button_pressed_color = color
	SaveData.save_ui_settings()
	colors_changed.emit()

func _on_panel_changed(color: Color):
	SaveData.panel_color = color
	SaveData.save_ui_settings()
	colors_changed.emit()

func _on_reset_pressed():
	SaveData.reset_ui_settings()
	normal_picker.color = SaveData.button_normal_color
	hover_picker.color = SaveData.button_hover_color
	pressed_picker.color = SaveData.button_pressed_color
	panel_picker.color = SaveData.panel_color
	colors_changed.emit()

func _on_close_pressed():
	visible = false
	get_tree().paused = false
	settings_closed.emit()
