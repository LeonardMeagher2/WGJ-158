extends Control

const mouse_sensitivity = Vector2(3.0, 3.0)

export(int, LAYERS_3D_PHYSICS) var click_mask

var velocity = Vector2()
var distance = 1.0
var collision

func _ready():
	Game.connect("inspecting", self, "_on_Game_inspecting")
	Game.connect("done_inspecting", self, "_on_Game_done_inspecting")

func _process(delta):
	return
	var pressed = Input.is_action_pressed("interact")
	var player = get_tree().get_nodes_in_group("player")[0]
	var rt = player.get_node("Camera/RemoteTransform") as RemoteTransform
	
	rt.rotate_x(deg2rad(velocity.y) * delta)
	rt.rotate_y(deg2rad(velocity.x) * delta)
	
	velocity = velocity * 0.9
	
	mouse_default_cursor_shape = Control.CURSOR_DRAG
	if collision and collision.has("collider"):
		if collision.collider is EvidenceArea and collision.collider.enabled:
			mouse_default_cursor_shape = Control.CURSOR_ARROW
			if Input.is_action_just_released("interact"):
				collision.collider.interact()
				collision = null

func _notification(what):
	match what:
		NOTIFICATION_VISIBILITY_CHANGED:
			var v = is_visible_in_tree()
			collision = null
			if v:
				call_deferred("set_process",v)
			else:
				
				set_process(v)
				

func interact_ray(event):
	var camera = get_viewport().get_camera()
	var space = get_viewport().world.direct_space_state
	var mouse_position = get_global_mouse_position()

	var from = camera.project_ray_origin(mouse_position)
	var normal = camera.project_ray_normal(mouse_position)
	
	var to = from + normal * distance * PI
	
	return space.intersect_ray(from, to, [], click_mask, true, true)


func _gui_input(event):
	if event is InputEventMouseMotion:
		velocity += event.relative * mouse_sensitivity * event.pressure
		collision = interact_ray(event)
		accept_event()
	

func _on_Game_inspecting(_spatial, inspect_distance):
	distance = inspect_distance
func _on_Game_done_inspecting(_spatial):
	self.distance = 1.0
