extends Control

signal speaking()
signal done_speaking()

signal evidence_selected(evidence)

signal showing_menu(showing)


export(Array, Resource) var cursors

onready var Q = $Hovering/Q
onready var alert_box = $Hovering/Alert
onready var hand = $Center
onready var investigation = $HBoxContainer
onready var dialog = $HBoxContainer/Dialog
onready var tools = $HBoxContainer/Tools
onready var dialog_text = $HBoxContainer/Dialog/Panel/MarginContainer/HBoxContainer/RichTextLabel
onready var tabs = $HBoxContainer/EvidenceProof/Control/Panel/MarginContainer/VBoxContainer/Evidence/Tabs
onready var category_buttons = $HBoxContainer/EvidenceProof/Control/Panel/MarginContainer/VBoxContainer/Evidence/Categories

func _ready():
	for cursor in cursors:
		cursor.release()
	toggle_menu(false)
	Game.connect("evidence_changed", self, "_on_Game_evidence_changed")
	Game.connect("inspecting", self, "_on_Game_inspecting")

func toggle_menu(show:bool, type:String = "chat"):
	emit_signal("showing_menu", show)
	Q.pressed = show
	Q.visible = show
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if show else Input.MOUSE_MODE_CAPTURED)
	
	investigation.visible = show
	hand.visible = not show
	if not show:
		Game.stop_inspecting()
	
	match type:
		"inspect":
			dialog.visible = false
			tools.visible = show
		_, "chat":
			tools.visible = false
			dialog.visible = show

func _on_evidence_selected(evidence):
	emit_signal("evidence_selected", evidence)

func _on_Tabs_tab_changed(tab):
	var button = category_buttons.get_child(tab)
	button.pressed = true

func _input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			for cursor in cursors:
				cursor.press()
		else:
			for cursor in cursors:
				cursor.release()

func _unhandled_input(event):
	if event.is_action_pressed("show_investigation"):
		if not investigation.visible:
			toggle_menu(true, "inspect")
		else:
			toggle_menu(false, "inspect")
			call_deferred("emit_signal","done_speaking")
			call_deferred("emit_signal", "evidence_selected", null)
	if event.is_action_pressed("toggle_fullscreen"):
		OS.window_fullscreen = not OS.window_fullscreen

func _on_Game_inspecting(_spatial, _location):
	toggle_menu(true, "inspect")

func _on_Game_evidence_changed(type):
	if type != null:
		match type:
			Evidence.TYPE.STATEMENT:
				tabs.current_tab = 0
			Evidence.TYPE.OBSERVATION:
				tabs.current_tab = 1
			Evidence.TYPE.ITEM:
				tabs.current_tab = 2
		alert_box.show()

func _on_Q_toggled(button_pressed):
	toggle_menu(button_pressed, "inspect")

func _on_category_pressed(tab):
	tabs.current_tab = tab

func _on_Dialog_speaking():
	toggle_menu(true, "chat")

func _on_Dialog_end_speaking(has_spoken):
	if has_spoken:
		yield(self, "evidence_selected")
	toggle_menu(false, "chat")
