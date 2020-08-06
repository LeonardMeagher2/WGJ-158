extends ToolButton

signal reading(reading)

export(Resource) var evidence setget set_evidence

onready var star = $Star

var hover = false

func set_evidence(value:Evidence):
	evidence = value
	if evidence and is_inside_tree():
		text = evidence.concept
		icon = evidence.image
		star.visible = evidence.new

func _notification(what):
	match what:
		NOTIFICATION_MOUSE_ENTER, NOTIFICATION_FOCUS_ENTER:
			if evidence.new:
				evidence.new = false
				star.visible = false

var toggle = false
func _on_Read_pressed():
	toggle = not  toggle
	emit_signal("reading", toggle)

func _on_Read_focus_exited():
	toggle = false
	emit_signal("reading", toggle)
