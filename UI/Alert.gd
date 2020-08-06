extends Control

onready var tween = $Tween
onready var timer = $Timer

func _init():
	visible = false

func show():
	if visible == false:
		visible = true
		modulate = Color.white
		timer.start()
		yield(timer, "timeout")
		tween.interpolate_property(self, "modulate", Color(1,1,1), Color(1,1,1,0.0), 0.3)
		tween.start()
		
		yield(tween, "tween_all_completed")
		visible = false
