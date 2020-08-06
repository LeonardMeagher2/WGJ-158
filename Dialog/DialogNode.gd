extends Spatial
class_name DialogNode

signal started()
signal done(next_trigger)

const no_evidence = preload("res://Evidence/none.tres")
const any_evidence = preload("res://Evidence/any.tres")
const yes_response = preload("res://Evidence/yes.tres")
const no_response = preload("res://Evidence/no.tres")

export var enabled:bool = true
export(Resource) var trigger = no_evidence setget ,get_trigger
export(Array, Resource) var evidence = []
export(String, MULTILINE) var text = "PLACE HOLDER TEXT"
export(Dictionary) var variables = {}
export(NodePath) var goto = @""
export var goto_distance:float = INF
export var ends:bool = false

var active = false
var ctx:Context.Ref = null

static func like_dialog_node(node:Node):
	return (
		node and
		node.has_method("can_trigger") and
		node.has_method("start") and
		node.has_signal("done")
	)

func get_trigger():
	match name:
		"yes":
			return yes_response
		"no":
			return no_response
		_:
			return trigger

func can_trigger(res = null):
	if not enabled or active:
		return false
	if get_trigger() == any_evidence or get_trigger() == res:
		return true
	return false

func _quit(res):
	if ends:
		res = null
	Ui.dialog.yes.visible = false
	Ui.dialog.no.visible = false
	call_deferred("emit_signal", "done", res)
	set_notify_transform(false)
	active = false

func start():
	if not enabled or active:
		return
	
	var res = no_evidence
	
	active = true
	set_notify_transform(true)
	emit_signal("started")
	
	var yes = get_node_or_null("yes")
	var no = get_node_or_null("no")
	
	Ui.dialog.yes.visible = yes != null
	Ui.dialog.no.visible = no != null
	
	if text:
		Ui.dialog.speak(text, ctx)
		Ui.dialog.emit_signal("speak_look_at", global_transform.origin)
		yield(Ui.dialog, "done_speaking")
		Game.collect_evidence(evidence)
		res = yield(Ui, "evidence_selected")
		
		if res == null:
			_quit(res)
			return
	else:
		Game.collect_evidence(evidence)
		
	if get_child_count():
		var index = 0
		var first_success = 0
		while res:
			var child = get_child(index)
			
			if like_dialog_node(child) and child.can_trigger(res):
				child.start()
				res = yield(child, "done")
				if res == null:
					_quit(res)
					return
				first_success = index
			
			index = (index + 1) % get_child_count()
			
			if index == first_success:
				break
	
	if goto:
		var node = get_node_or_null(goto) as Spatial
		var distance = node.global_transform.origin.distance_squared_to(global_transform.origin)
		
		if like_dialog_node(node) and distance < goto_distance*goto_distance and node.can_trigger(res):
			node.start()
			res = yield(node, "done")
	
			if res == null:
				_quit(res)
				return
	
	if res == get_trigger():
		res = no_evidence
	
	_quit(res)

func _enter_tree():
	if variables.size():
		ctx = Context.use(variables)
	else:
		ctx = Context.use()

func _notification(what):
	match what:
		NOTIFICATION_TRANSFORM_CHANGED:
			Ui.dialog.emit_signal("speak_look_at", global_transform.origin)
