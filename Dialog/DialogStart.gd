extends Spatial
class_name DialogStart

signal started()
signal done()

const no_evidence = preload("res://Evidence/none.tres")

export var enabled:bool = true
export(PoolStringArray) var intros = ["Yes?"]
export(PoolStringArray) var outros = ["Bye."]
export(PoolStringArray) var unknown = ["I don't know anything about that."]
export(Dictionary) var variables = {}

var rng = RandomNumberGenerator.new()
var active:bool = false
var ctx:Context.Ref = null

func _enter_tree():
	if variables.size():
		ctx = Context.use(variables)
	else:
		ctx = Context.use()

func _ready():
	rng.seed = Game.random.randi()
	
	var area_parent = get_parent() as EvidenceArea
	
	if area_parent and area_parent.type == Evidence.TYPE.STATEMENT:
		get_parent().connect("interact", self, "start")
		
		var ai = area_parent.find_parent(area_parent.name)
		
		if ai:
			connect("started", ai, "start_conversation")
			connect("done", ai, "end_conversation")

func _quit(text = ""):
	Ui.dialog.end(text)
	if text:
		Ui.dialog.emit_signal("speak_look_at", global_transform.origin)
		yield(Ui, "evidence_selected")
	set_notify_transform(false)
	call_deferred("emit_signal", "done")

func can_trigger(_trigger):
	return enabled

func start():
	
	var first = get_node_or_null("first")
	var res = no_evidence
	set_notify_transform(true)
	emit_signal("started")
	
	if DialogNode.like_dialog_node(first) and first.can_trigger(res):
		first.start()
		res = yield(first, "done")
		if res:
			remove_child(first)
	else:
		var r = int(rng.randf_range(0, intros.size()))
		Ui.dialog.speak(intros[r], ctx)
		Ui.dialog.emit_signal("speak_look_at", global_transform.origin)
		yield(Ui.dialog, "done_speaking")
		res = yield(Ui, "evidence_selected")
		
	if res == null:
		_quit()
		return
	
	if get_child_count():
		
		var index = 0
		var first_success = 0
		while res and res != no_evidence:
			var child = get_child(index)
			var known = false
			
			if DialogNode.like_dialog_node(child) and child.enabled:
				known = child.active
				if child.can_trigger(res):
					child.start()
					res = yield(child, "done")
					if res == null:
						_quit()
						return
					first_success = index
			
			index = (index + 1) % get_child_count()
			
			if res and index == first_success:
				if known:
					break
				elif res != no_evidence:
					var r = int(rng.randf_range(0, unknown.size()))
					Ui.dialog.speak(unknown[r], ctx)
					Ui.dialog.emit_signal("speak_look_at", global_transform.origin)
					yield(Ui.dialog, "done_speaking")
					var unknown_res = yield(Ui, "evidence_selected")
					
					if res == unknown_res:
						break
					res = unknown_res

	var r = int(rng.randf_range(0, outros.size()))
	_quit(outros[r])
	
func _notification(what):
	match what:
		NOTIFICATION_TRANSFORM_CHANGED:
			Ui.dialog.emit_signal("speak_look_at", global_transform.origin)
