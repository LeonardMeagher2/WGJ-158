extends Area
class_name EvidenceArea

signal player_entered()
signal player_exited()
signal interact()
signal inspecting()
signal done_inspecting()



export var enabled:bool = true setget set_enabled
export(Evidence.TYPE) var type:int = 0
export(int, "nothing", "disable", "free") var when_no_evidence:int = 0
export var inspect:bool = false
export var inspect_distance:float = 1.0
export(Array, Resource) var evidence = []
export(int, "disable", "on_enter", "on_exit") var auto_trigger = 0 setget set_auto_trigger

var has_player = false
var inside_area = false
var inside_ai = false

func set_enabled(value):
	if evidence.size() == 0:
		match when_no_evidence:
			1: 
				value = false
			2:
				queue_free()
			
	enabled = value
	
	set_collision_layer_bit(12 if inside_area else 11, not auto_trigger and enabled)
	set_collision_mask_bit(1, bool(auto_trigger) and enabled)

func set_auto_trigger(value):
	auto_trigger = value
	
	set_collision_layer_bit(12 if inside_area else 11, not auto_trigger and enabled)
	set_collision_mask_bit(1, bool(auto_trigger) and enabled)

func _ready():
	collision_layer = 0
	collision_mask = 0
	inside_area = get_parent() is get_script() and get_parent().inspect
	inside_ai = get_parent() is AI and inspect
	
	if inside_area :
		# Parent is in inspecting area, hide the clues
		enabled = false
		inspect = false
		type = Evidence.TYPE.OBSERVATION
		auto_trigger = 0
		
		var parent = get_parent()
		parent.connect("inspecting", self, "set_enabled", [true])
		parent.connect("done_inspecting", self, "set_enabled", [false])
	
	set_enabled(enabled)
	set_auto_trigger(auto_trigger)
	
	connect("body_entered", self, "_body_entered")
	connect("body_exited", self, "_body_exited")
	connect("interact", self, "interact")

func _body_entered(body):
	if body.is_in_group("player"):
		has_player = true
		if enabled:
			emit_signal("player_entered")
			if auto_trigger == 1:
				emit_signal("interact")

func _body_exited(body):
	if body.is_in_group("player"):
		has_player = false
		if enabled:
			emit_signal("player_exited")
			if auto_trigger == 2:
				emit_signal("interact")

func add_evidence(new_evidence:Array):
	if new_evidence.size() == 0:
		return
	
	if enabled and has_player and auto_trigger == 1:
		Game.collect_evidence(new_evidence)
		return
	for e in new_evidence:
		evidence.append(e)
	
	set_enabled(enabled)

func interact():
	
	if enabled:
		if evidence.size():
			Game.collect_evidence(evidence)
			evidence = []
		if inspect:
			set_enabled(false)
			set_collision_layer_bit(12, true)
			if inside_ai:
				get_parent().enabled = false
			emit_signal("inspecting")
			Game.inspect_item(self, inspect_distance)
			
			yield(Game, "done_inspecting")
			set_collision_layer_bit(12, false)
			set_enabled(true)
			if inside_ai:
				get_parent().enabled = true
			emit_signal("done_inspecting")
		set_enabled(enabled)
