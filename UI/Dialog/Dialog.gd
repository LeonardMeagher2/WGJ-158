extends Control

signal speaking()
signal done_speaking()
signal end_speaking()
signal speak_look_at(location)

const no_evidence = preload("res://Evidence/none.tres")
const yes_response = preload("res://Evidence/yes.tres")
const no_response = preload("res://Evidence/no.tres")

onready var speak_timer = $SpeakTimer
onready var tween = $Tween

onready var label = $Panel/MarginContainer/HBoxContainer/RichTextLabel
onready var yes = $Panel/MarginContainer/HBoxContainer/VBoxContainer/yes
onready var no = $Panel/MarginContainer/HBoxContainer/VBoxContainer/no
onready var next = $Panel/MarginContainer/HBoxContainer/VBoxContainer/Next

var variables = {}

func _ready():
	yes.visible = false
	no.visible = false

func speak(text:String, context = null):
	yes.disabled = true
	no.disabled = true
	next.disabled = true
	emit_signal("speaking")
	
	if context:
		text = text.format(context)
	
	label.bbcode_text = text
	
	tween.interpolate_property(label, "percent_visible", 0.0, 1.0, speak_timer.wait_time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, 0.0)
	if not tween.is_active():
		tween.start()
	
	speak_timer.start()

func end(text:String):
	if text:
		speak(text)
		yield(self, "done_speaking")
	emit_signal("speak_look_at", null)
	call_deferred("emit_signal", "end_speaking", bool(text))

func done_speaking():
	yes.disabled = false
	no.disabled = false
	next.disabled = false
	next.grab_focus()
	call_deferred("emit_signal", "done_speaking")

func _on_SpeakTimer_timeout():
	done_speaking()

func _on_Next_pressed():
	Ui.emit_signal("evidence_selected", no_evidence)
func _on_yes_pressed():
	Ui.emit_signal("evidence_selected", yes_response)
func _on_no_pressed():
	Ui.emit_signal("evidence_selected", no_response)
