extends Node

"""
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!                                       !
! Context should be used in _enter_tree !
!                                       !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
"""

const META_KEY = "shared_context"
const GROUP = "__shared_context"

class Ref extends Reference:
	var _new:bool = true
	
	var data:Dictionary = {}
	var parent:Ref
	
	func _init(data:Dictionary, parent:Ref = null):
		self.data = data
		self.parent = parent
		
	func _set(property, value):
		# we have the property exit early
		if data.has(property):
			data[property] = value
			return true
		
		var p = parent
		var nearest_parent = null
		# search for parents who might have this property
		while(p):
			if p.data.has(property):
				p.data[property] = value
				return true
			p = p.parent
		
		data[property] = value
		return true
		
	func assign(state:Dictionary):
		for key in state:
			data[key] = state[key]
		return true
	
	func _get(property):
		if parent and not data.has(property):
			return parent._get(property)
		return data.get(property)
		
	func get(property, default = null):
		if parent and not data.has(property):
			return parent.get(property, default)
		return data.get(property, default)
		
	func flatten_to_dict():
		return data
	
	func on(event_name:String, target:Object, method:String, binds:Array = [], flags:int = 0):
		if has_signal(event_name):
			return connect(event_name, target, method, binds, flags)
		
		var p = parent
		while(p):
			if p.has_signal(event_name):
				return p.connect(event_name, target, method, binds, flags)
			p = p.parent
		
		add_user_signal(event_name)
		return connect(event_name, target, method, binds, flags)
	
	func off(event_name:String, target:Object, method:String):
		if is_connected(event_name, target, method):
			return disconnect(event_name, target, method)
		if parent:
			return parent.off(event_name, target, method)
	
	func fire(event_name:String, args:Array = []):
		if has_signal(event_name):
			callv("emit_signal", [event_name] + args)
		elif parent:
			parent.fire(event_name, args)

class DynamicRef extends Reference:
	var ref = null
	func _init(variant):
		ref = variant

var current_node:Node = null

func _node_exiting(node_ref:WeakRef):
	var node = node_ref.get_ref()
	if node:
		node.remove_meta(META_KEY)

func _node_added(node:Node) -> void:
	current_node = node
	node.connect("ready", self, "_node_ready", [weakref(node)], CONNECT_ONESHOT)
func _node_ready(node_ref:WeakRef):
	var node = node_ref.get_ref()
	if node:
		var ref = node.get_meta(META_KEY)
		var children = node.get_tree().get_nodes_in_group(GROUP)
		for child in children:
			child.remove_from_group(GROUP)
			var child_ref = child.get_meta(META_KEY)
			if child_ref.ref == null:
				child_ref.ref = ref.ref
			else:
				child_ref.ref.parent = ref.ref
		
		current_node = node.get_parent()
	else:
		current_node = null

func _enter_tree():
	get_tree().connect("node_added", self, "_node_added")

func use(data = null) -> DynamicRef:
	assert(current_node)
	
	var ref = DynamicRef.new(null)
	current_node.set_meta(META_KEY, ref)
	current_node.add_to_group(GROUP)
	
	current_node.connect("tree_exiting", self, "_node_exitinig", [weakref(current_node)], CONNECT_ONESHOT)
	
	if data != null:
		ref.ref = Ref.new(data)
	
	return ref

func from(node:Node) -> DynamicRef:
	var p = node
	while(p):
		if p.has_meta(META_KEY):
			return p.get_meta(META_KEY)
		p = p.get_parent()
	return null
